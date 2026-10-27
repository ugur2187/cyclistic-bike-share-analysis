-- 06_yinelenen_ride_id.sql
-- Amaç: Aynı yolculuğun birden fazla kez kaydedilip kaydedilmediğini ölçmek ve nedenini araştırmak
-- Tarih: 2026-10-17
-- Günlük adımı: Yinelenen ride_id
-- Karar özeti: 35 ride_id iki kez geçiyor, çiftlerin hepsi birebir aynı (tripdata_all'da, 13 sütun).
--              tripdata_clean'de her ID'den bir satır bırakılacak.
-- Neden (Kontrol 7 ile destekleniyor): 35 yolculuk 30 Nisan'da başlayıp 1 Mayıs'ta biten, ay sınırını geçen yolculuklar;
--              hem Nisan hem Mayıs tablosunda yer alıyorlar.


-- ---------------------------------------------------------------------------
-- Kontrol 1: Toplam satır ile benzersiz ride_id karşılaştırması
-- Beklenen: fark = 0 (ya da çok küçük bir sayı)
-- Sonuç: toplam_satir | dolu_ride_id | benzersiz_ride_id | fark | bos_metin_ride_id
--        6171785      | 6171785      | 6171750           | 35   | 0
-- Yorum: dolu_ride_id = toplam_satir ve bos_metin_ride_id = 0; fark NULL ya da boş ride_id'den gelmiyor.
--        35 fazla satır gerçek yinelenen kayıt (yaklaşık %0,0006).
SELECT COUNT(*)                           AS toplam_satir,
       COUNT(ride_id)                     AS dolu_ride_id,
       COUNT(DISTINCT ride_id)            AS benzersiz_ride_id,
       COUNT(*) - COUNT(DISTINCT ride_id) AS fark,
       SUM(ride_id = '')                  AS bos_metin_ride_id
FROM tripdata_all;


-- ---------------------------------------------------------------------------
-- Kontrol 2: Tekrar eden ride_id'lerin hangileri ve kaç kez tekrarlandığı
-- Beklenen: Tekrar eden her ride_id 2 kez geçecek
-- Sonuç: 35 ride_id döndü, hepsinde adet = 2  ->  beklenen ile tutuyor
--        Örnekler: D582320F33836B82, D28B306F00821227, E923A7ACDD4A9293 (tam liste için sorguyu çalıştır)
-- Yorum: 35 ID x 1 fazla satır = 35, Kontrol 1'deki fark ile tutuyor. Hiçbir ID ikiden fazla tekrar etmiyor.
SELECT ride_id, COUNT(*) AS adet
FROM tripdata_all
GROUP BY ride_id
HAVING COUNT(*) > 1
ORDER BY adet DESC;


-- ---------------------------------------------------------------------------
-- HAZIRLIK (teknik not, numarasız; veriyi değiştirmez)
--
-- Zaman aşımı: Kontrol 3'ün ilk hâli IN (alt sorgu) ile yazılmıştı ve 3600 saniye sonra
--   "Error Code: 2013. Lost connection to MySQL server during query" ile bitti.
--   Sunucuda sorgu çalışmaya devam ediyordu (SHOW FULL PROCESSLIST, Id 11); KILL QUERY 11 ile durduruldu.
--   Neden: ride_id mediumtext ve indeks yok (hipotez, ölçülmedi).
--   Çözüm: 35 ID'lik yardımcı tablo + ride_id indeksi + JOIN.
--
-- Yardımcı tablo (günlükte "yardımcı tablo" olarak not edilecek):
-- Sonuç: 35 row(s) affected, Records: 35, Duplicates: 0, Warnings: 0 (143,719 sn)
CREATE TABLE tekrar_ride_id AS
SELECT ride_id
FROM tripdata_all
GROUP BY ride_id
HAVING COUNT(*) > 1;

-- ride_id uzunluğu (indeks uzunluğunu seçmek için)
-- Beklenen: hepsi aynı uzunlukta
-- Sonuç: en_kisa = 16, en_uzun = 16  ->  beklenen ile tutuyor
SELECT MIN(LENGTH(ride_id)) AS en_kisa,
       MAX(LENGTH(ride_id)) AS en_uzun
FROM tripdata_all;

-- İndeks (performans için; veri değişmez)
-- Sonuç: SHOW INDEX -> Key_name idx_ride_id | Column_name ride_id | Sub_part 16 | BTREE | Visible YES
--        (Cardinality 6145340 tahmini bir istatistiktir; kesin sayı için COUNT(DISTINCT) kullanılır)
CREATE INDEX idx_ride_id ON tripdata_all (ride_id(16));
SHOW INDEX FROM tripdata_all;

-- İndeks sonrası satır sayısı
-- Beklenen: 6171785 (indeks veriyi değiştirmez)
-- Sonuç: (çalıştırınca buraya yaz)
SELECT COUNT(*) FROM tripdata_all;


-- ---------------------------------------------------------------------------
-- Kontrol 3: Tekrar eden satırların ay, bisiklet tipi ve kullanıcı tipine göre dağılımı
-- Beklenen: Belirgin bir örüntü görülmeyecek (hipotez)
-- Sonuç: 70 satır, hepsi 2026-04
--        classic_bike  casual 16 | classic_bike  member 22
--        electric_bike casual 8  | electric_bike member 24
--        (classic 38, electric 32; member 46, casual 24)
-- Yorum: Beklenen ay boyutunda tutmadı; tekrarlar tek bir aya toplanmış.
--        Bisiklet ve kullanıcı tipinde yoğunlaşma görünmüyor, ama Nisan'ın genel dağılımıyla karşılaştırılmadı.
SELECT DATE_FORMAT(a.started_at, '%Y-%m') AS ay,
       a.rideable_type,
       a.member_casual,
       COUNT(*) AS satir
FROM tripdata_all a
JOIN tekrar_ride_id t ON t.ride_id = a.ride_id
GROUP BY DATE_FORMAT(a.started_at, '%Y-%m'), a.rideable_type, a.member_casual
ORDER BY ay;


-- ---------------------------------------------------------------------------
-- Kontrol 4: Tekrar eden satırlar birebir aynı mı?
-- Beklenen: 35 (çiftler birebir aynı) ya da 70 (yalnızca ID aynı)
-- Sonuç: farkli_satir = 35  ->  her çift birebir aynı (tripdata_all'da, 13 sütun)
-- Yorum: Gerçek kopya; silme gerekçesi var.
--        Sınır: tripdata_all'da tarihler saniyeye kırpılmıştı (LEFT(x,19)); milisaniye farkı bu sorguda görünmez.
SELECT COUNT(*) AS farkli_satir
FROM (SELECT DISTINCT a.*
      FROM tripdata_all a
      JOIN tekrar_ride_id t ON t.ride_id = a.ride_id) x;


-- ---------------------------------------------------------------------------
-- Kontrol 5: Tekrar eden ID'ler Nisan 2026 tablosunda kaç kez geçiyor?
-- Beklenen: 70 (iki kopya da Nisan tablosunda) ya da 35 (biri başka tabloda)
-- Sonuç: satir = 35  ->  her ID Nisan tablosunda bir kez; diğer kopya başka bir tabloda
-- Hipotez: Ay sınırında iki tabloya birden yazılan yolculuklar (Kontrol 7 ile destekleniyor).
SELECT COUNT(*) AS satir
FROM tripdata_202604 r
JOIN tekrar_ride_id t ON t.ride_id = r.ride_id;


-- ---------------------------------------------------------------------------
-- Kontrol 6: Diğer kopya Mart ve Mayıs tablolarında mı?
-- Beklenen: Kopyaların hepsi Mart tablosunda
-- Sonuç: tripdata_202603 = 0 | tripdata_202605 = 35
-- Yorum: Beklenen tutmadı. Yolculuklar Nisan'da başladığı için Mart'ta bitmiş olamazlar; Mayıs tablosunda bulunmaları mümkün.
--        İkisinin toplamı 35: kopyaların hepsi komşu tablolarda, diğer tablolara bakmaya gerek yok.
SELECT 'tripdata_202603' AS tablo, COUNT(*) AS satir
FROM tripdata_202603 r
JOIN tekrar_ride_id t ON t.ride_id = r.ride_id
UNION ALL
SELECT 'tripdata_202605', COUNT(*)
FROM tripdata_202605 r
JOIN tekrar_ride_id t ON t.ride_id = r.ride_id;


-- ---------------------------------------------------------------------------
-- Kontrol 7: 35 yolculuğun başlangıç ve bitiş zamanları ay sınırına yakın mı?
-- Beklenen: Yolculuk tarihleri ay geçişi etrafına olmalı
-- Sonuç: en_erken_bas 2026-04-30 00:24:47 | en_gec_bas 2026-04-30 23:58:56
--        en_erken_bitis 2026-05-01 00:00:34 | en_gec_bitis 2026-05-01 18:27:01
-- Yorum: 35 yolculuğun hepsi 30 Nisan'da başlamış, 1 Mayıs'ta bitmiş; ay sınırını geçen yolculuklar. Hipotez destekleniyor.
--        Neden hem Nisan hem Mayıs tablosuna yazıldıkları bu veriyle öğrenilemez.
--        Karşılaştırma: Eylül 2026 sınırındaki 51 satırın Ağustos tablosuyla ortak ride_id'si yoktu (0);
--        Nisan-Mayıs sınırında 35 yolculuk iki tabloda yer alıyor.
SELECT MIN(a.started_at) AS en_erken_bas,
       MAX(a.started_at) AS en_gec_bas,
       MIN(a.ended_at)   AS en_erken_bitis,
       MAX(a.ended_at)   AS en_gec_bitis
FROM tripdata_all a
JOIN tekrar_ride_id t ON t.ride_id = a.ride_id;


-- ---------------------------------------------------------------------------
-- KARAR (günlük için)
-- Sorun: 35 ride_id iki kez kayıtlı, çiftler birebir aynı
-- Etkilenen: 35 fazla satır (yaklaşık %0,0006)
-- Karar: Çıkar (tripdata_clean'de her ID'den bir satır)
-- Önce / Sonra: 6.171.785 -> 6.171.750 (filtre çalışınca teyit edilecek)
-- Uygulama: tripdata_clean'de SELECT DISTINCT; çiftler birebir aynı olduğu için hangi kopyanın kaldığı önemli değil.


CREATE TABLE tripdata_temp AS 
SELECT DISTINCT * FROM tripdata_all;
DROP TABLE tripdata_all;
RENAME TABLE tripdata_temp TO tripdata_all;

-- tekrar eden değerler kaldırıldı. 6.171.750 satır veri kaldı.