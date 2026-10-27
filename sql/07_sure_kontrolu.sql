-- 07_sure_kontrolu.sql
-- Amaç: Süresi sıfır/negatif, çok kısa veya çok uzun yolculukların sayısını ve niteliğini ölçmek,
--       süre eşiklerine (60 sn, 24 saat) verinin kendisinden dayanak bulmak
-- Tarih: 2026-10-18
-- Günlük adımı: Süre sorunları
-- Not: Tüm sorgular dönem filtresi (10/2025 - 09/2026) içinde çalışır; 71 dönem dışı satır dahil değildir.
--      35 yinelenen satır henüz çıkarılmadı; etkisi çok küçük, ama günlükte yinelenen adımı önce, süre adımı sonra sayılır.
-- Karar: < 60 sn, <= 0 ve > 24 saat çıkarılacak (ayrıntı dosyanın sonunda).


-- ---------------------------------------------------------------------------
-- Kontrol 1: Kaç satır süre sorunlu?
-- Beklenen: (çalıştırmadan önce yazdığın tahmini buraya ekle)
-- Sonuç: toplam 6171714 | sifir_veya_negatif 29 | altmis_sn_alti 158596 | yirmidort_saat_ustu 5311
-- Yorum: toplam = 6.171.785 - 71 (dönem dışı) ile tutuyor.
--        29 satır altmis_sn_alti içinde. < 60 sn ve > 24 saat grupları ayrık; birlikte 163.907 satır (yaklaşık %2,66).
--        Üç sayı toplanmaz: sıfır/negatif grubu altmis_sn_alti grubunun içindedir.
SELECT COUNT(*) AS toplam,
       SUM(ended_at <= started_at) AS sifir_veya_negatif,
       SUM(TIMESTAMPDIFF(SECOND, started_at, ended_at) < 60) AS altmis_sn_alti,
       SUM(TIMESTAMPDIFF(SECOND, started_at, ended_at) > 86400) AS yirmidort_saat_ustu
FROM tripdata_all
WHERE started_at >= '2025-10-01' AND started_at < '2026-10-01';


-- ---------------------------------------------------------------------------
-- Kontrol 2: 60 saniyenin altındaki yolculuklar nasıl dağılıyor?
-- Beklenen: Süresi 60 saniyenin altındaki yolculukların çoğu, istasyon bilgisi olanlar arasında aynı istasyona dönmüş olacak
-- Hipotez (sınanmadı): Negatif süreler veri girişi/sistem hatası; 60 sn altında aynı istasyona dönüş,
--                      işlemden vazgeçmeyi (ya da bisiklet arızasını) gösterir
-- Sonuç (sure_grubu | satir | ayni_istasyon | electric | casual | istasyon_bilgisi_var):
--   0 sn ya da negatif | 29    | 1     | 17    | 9     | 19
--   1-9 sn             | 36602 | 11573 | 36602 | 13336 | 11799
--   10-29 sn           | 73348 | 18104 | 73348 | 37508 | 18700
--   30-59 sn           | 48617 | 15191 | 48617 | 23350 | 17727
-- Yorum: 1-59 sn aralığındaki yolculukların hepsi electric_bike (klasik bisiklette yok); nedeni bilinmiyor.
--        İstasyon bilgisi olan 48226 satırın 44868'i (%93) aynı istasyona dönmüş; tahmin bu alt kümede tuttu.
--        Oran süre uzadıkça düşüyor (1-9 sn %98,1 | 10-29 sn %96,8 | 30-59 sn %85,7).
--        Grubun yaklaşık %70'inde istasyon bilgisi eksik olduğu için oran onlar için bilinmiyor.
--        Sıfır/negatif süreli 29 satırda yalnızca 1'i aynı istasyona dönmüş (19 istasyonlu satırdan);
--        bu, veri girişi/sistem hatası hipoteziyle tutarlı ama kanıt değil.
--        Elle hesaplanan (yaklaşık): çıkacak 158596 satırın 74203'ü casual (%46,8).
SELECT CASE WHEN TIMESTAMPDIFF(SECOND, started_at, ended_at) <= 0  THEN '1) 0 sn ya da negatif'
            WHEN TIMESTAMPDIFF(SECOND, started_at, ended_at) < 10  THEN '2) 1-9 sn'
            WHEN TIMESTAMPDIFF(SECOND, started_at, ended_at) < 30  THEN '3) 10-29 sn'
            ELSE '4) 30-59 sn' END AS sure_grubu,
       COUNT(*) AS satir,
       SUM(start_station_id = end_station_id)  AS ayni_istasyon,
       SUM(rideable_type = 'electric_bike')    AS electric,
       SUM(member_casual = 'casual')           AS casual,
       SUM(start_station_id IS NOT NULL AND end_station_id IS NOT NULL) AS istasyon_bilgisi_var
FROM tripdata_all
WHERE started_at >= '2025-10-01' AND started_at < '2026-10-01'
  AND TIMESTAMPDIFF(SECOND, started_at, ended_at) < 60
GROUP BY sure_grubu
ORDER BY sure_grubu;


-- ---------------------------------------------------------------------------
-- TEKNİK NOT (numarasız): "dolu istasyon" için iki yazım aynı sonucu veriyor mu?
-- tripdata_all'da boş metinler NULLIF ile NULL yapıldığı için IS NOT NULL ve <> '' eşdeğer olmalı.
-- (Ham aylık tablolarda boşlar '' olduğu için orada yalnızca <> '' doğru çalışır.)
-- Beklenen: iki sayı eşit
-- Sonuç: iki sayı eşit (tripdata_all'da boş metin kalmamış)
SELECT SUM(start_station_id IS NOT NULL AND end_station_id IS NOT NULL) AS not_null_yontemi,
       SUM(start_station_id <> '' AND end_station_id <> '')            AS bos_metin_yontemi
FROM tripdata_all;


-- ---------------------------------------------------------------------------
-- Kontrol 3: 24 saatten uzun yolculuklar kimler?
-- Beklenen: (çalıştırmadan önce yazdığın tahmini buraya ekle)
-- Sonuç (rideable_type | member_casual | satir | en_uzun_saat):
--   classic_bike | casual | 4200 | 25
--   classic_bike | member | 1111 | 25
-- Yorum: 24 saati aşan 5311 yolculuğun hepsi classic_bike (60 sn altındakilerin hepsi electric'ti); %79'u casual.
--        en_uzun_saat 25 yalnızca üst sınırı gösterir (TIMESTAMPDIFF saati keser); yığılma Kontrol 4 ve 5'te sınandı.
SELECT rideable_type, member_casual,
       COUNT(*) AS satir,
       MAX(TIMESTAMPDIFF(HOUR, started_at, ended_at)) AS en_uzun_saat
FROM tripdata_all
WHERE started_at >= '2025-10-01' AND started_at < '2026-10-01'
  AND TIMESTAMPDIFF(SECOND, started_at, ended_at) > 86400
GROUP BY rideable_type, member_casual;


-- ---------------------------------------------------------------------------
-- Kontrol 4: 20-27 saat arası sürelerin 30 dakikalık gruplarla dağılımı
-- Beklenen: (çalıştırmadan önce yazdığın tahmini buraya ekle)
-- Hipotez: Süreler tek bir değerde yığılıyorsa sistem kaynaklı bir kesme olabilir (sistem kesmesi yorumu için
--          sonucun net bir değerde toplanması gerekir).
-- Sonuç (dakika_grubu | satir):
--   1200 66 | 1230 77 | 1260 62 | 1290 63 | 1320 66 | 1350 79 | 1380 55 | 1410 84
--   1440 65 | 1470 5234 | 1500 2 | 1530 10
-- Yorum: 1470. grup (24:30-24:59) 5234 satır içeriyor; diğer grupların 55-85 satırlık tabanından çok yüksek.
--        65 + 5234 + 2 + 10 = 5311, 24 saati aşan yolculuk sayısıyla eşit (yaklaşık %98,6 tek pencerede).
--        24. saat sınırında bir kırılma yok (65). Yığılma 30 dakikalık bir pencerede; tek değer Kontrol 5'te.
SELECT FLOOR(TIMESTAMPDIFF(MINUTE, started_at, ended_at) / 30) * 30 AS dakika_grubu,
       COUNT(*) AS satir
FROM tripdata_all
WHERE started_at >= '2025-10-01' AND started_at < '2026-10-01'
  AND TIMESTAMPDIFF(MINUTE, started_at, ended_at) BETWEEN 1200 AND 1620
GROUP BY dakika_grubu
ORDER BY dakika_grubu;


-- ---------------------------------------------------------------------------
-- Kontrol 5: 24 saati aşan yolculuklarda en sık görülen süreler (dakika)
-- Beklenen: (çalıştırmadan önce yazdığın tahmini buraya ekle)
-- Sonuç (dakika | satir): 1499 5189 | 1559 10 | 1467 5 | 1458 4 | 1451 4 | 1490 4 | 1478 4 | 1476 4
--                         1470 4 | 1465 3 | 1469 3 | 1456 3 | 1463 3 | 1475 3 | 1494 3
-- Yorum: 24 saati aşan 5311 satırın 5189'u (%97,7) 1499. dakikada (24 saat 59 dk 00-59 sn); geri kalan 122 satır
--        3-5 satırlık değerlere dağınık. Yığılma tek bir dakika değerinde: hipotez destekleniyor.
--        Yığılma yuvarlak bir sayıda (24:00 ya da 25:00) değil, 24:59'da. Nedeni bilinmiyor; "sistem kaynaklı olabilir".
--        1559. dakikadaki 10 satır tabanın (3-5) üstünde ama ikinci bir yığılma olduğu söylenemez.
SELECT TIMESTAMPDIFF(MINUTE, started_at, ended_at) AS dakika,
       COUNT(*) AS satir
FROM tripdata_all
WHERE started_at >= '2025-10-01' AND started_at < '2026-10-01'
  AND TIMESTAMPDIFF(SECOND, started_at, ended_at) > 86400
GROUP BY dakika
ORDER BY satir DESC
LIMIT 15;


-- ---------------------------------------------------------------------------
-- Kontrol 6: 1-179 sn aralığında 10 saniyelik gruplarla bisiklet tipine göre dağılım
-- Beklenen: (çalıştırmadan önce yazdığın tahmini buraya ekle)
-- Sonuç (saniye_grubu | classic_bike | electric_bike); classic için 'yok' = o grupta satır çıkmadı:
--   0 (1-9) | yok   | 36602
--   10      | yok   | 42821
--   20      | yok   | 30527
--   30      | yok   | 19852
--   40      | yok   | 15567
--   50      | yok   | 13198
--   60      | 4571  | 11932
--   70      | 5497  | 12318
--   80      | 6225  | 14144
--   90      | 7157  | 15821
--   100     | 8211  | 18239
--   110     | 9236  | 21177
--   120     | 10288 | 24366
--   130     | 11209 | 27469
--   140     | 11975 | 30954
--   150     | 12770 | 34622
--   160     | 13445 | 37755
--   170     | 14112 | 41021
-- Yorum: Klasik bisiklette 60 sn altında hiç yolculuk yok; 60-69 sn grubunda 4571 satırla başlıyor ve düzgün artıyor.
--        Divvy'nin veri açıklaması 60 sn altı yolculukların çıkarıldığını söylüyor (kaynak: divvybikes.com/system-data);
--        klasik bisiklet buna uyuyor, elektrikli bisiklet uymuyor (nedeni bilinmiyor).
--        Elektrikli dağılım iki tümsekli: sol tümsek 10-19 sn'de tepe yapıyor (42821), çukurun dibi 60-69 sn (11932),
--        sonra yükseliyor. 60 sn eşiği bu çukura yakın düşüyor.
--        Eşik bir yargıdır: çukurun dibi sıfır değil, 60 sn sahte başlangıçları gerçek kullanımdan temiz ayıramaz.
SELECT FLOOR(TIMESTAMPDIFF(SECOND, started_at, ended_at) / 10) * 10 AS saniye_grubu,
       rideable_type,
       COUNT(*) AS satir
FROM tripdata_all
WHERE started_at >= '2025-10-01' AND started_at < '2026-10-01'
  AND TIMESTAMPDIFF(SECOND, started_at, ended_at) BETWEEN 1 AND 179
GROUP BY saniye_grubu, rideable_type
ORDER BY saniye_grubu, rideable_type;


-- ---------------------------------------------------------------------------
-- KARAR (günlük için)
--   Süre <= 0 (29 satır):        Çıkar. Fiziksel olarak imkânsız.
--   Süre < 60 sn (158596 satır, 29'u dahil): Çıkar (yargı). Dayanak: Divvy'nin belgelenmiş 60 sn kuralı,
--                                klasik bisiklette 60 sn'de keskin başlangıç, elektrikli dağılımın çukuru 60-69 sn'de.
--   Süre > 24 saat (5311 satır): Çıkar. %97,7'si tek bir değerde (24:59) toplanıyor; gerçek kullanımı yansıtmıyor olabilir.
--                                Geri kalan 122 satır dağınık; onlar için gerekçe 24 saat eşiği (yargı).
--   Birlikte 163907 satır (yaklaşık %2,66). Önce/Sonra yinelenen adımından (6.171.750) sonra ayrı yazılacak;
--   35 yinelenen satırın bir kısmı 24 saati aşıyorsa sayı birkaç satır değişebilir.
--   Etki iki gruba asimetrik (elle, yaklaşık): casual yolculukların yaklaşık %3,6'sı (78403), member yolculukların
--   yaklaşık %2,1'i (85504) çıkıyor. Raporda sınırlılık olarak yazılacak.
--   tripdata_clean kuralı: AND TIMESTAMPDIFF(SECOND, started_at, ended_at) BETWEEN 60 AND 86400
