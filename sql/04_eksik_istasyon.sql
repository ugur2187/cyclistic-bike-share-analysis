-- 04_eksik_istasyon.sql
-- Amaç: Eksik istasyon ad/ID ve koordinat bilgisinin dağılımını (bisiklet tipi, kullanıcı tipi) ölçmek
-- Tarih: 2026-10-15
-- Günlük adımı: Eksik istasyon bilgisi (karar: Etiketle, silme ve doldurma yok)
-- Not: Kontrol 1-5 yalnızca Ekim 2025 (tripdata_202510, ham tablo) üzerinde; Kontrol 6-11 12 ay için tripdata_all üzerinde.
--      Ham tabloda boş değerler NULL değil boş metin ('') olarak geldiği için her iki durum da kontrol edilir.
--      Bütün kontroller çalıştırıldı. Tek istisna: Kontrol 1'e sonradan eklenen eksik_bas_koordinat sütunu (aşağıya bak).
--      Kontrol 6 ve 7, 05_tripdata_all_olustur.sql ile tripdata_all oluştuktan sonra çalıştırıldı.


-- Kontrol 1: Bisiklet tipine göre eksik istasyon ve koordinat sayıları (Ekim 2025)
-- Beklenen: Eksiklik elektrikli bisikletlerde yoğun, klasikte az
-- Sonuç:
--   classic_bike  | toplam 209928 | eksik_bas_ad 0      | eksik_bas_id 0      | eksik_bit_ad 597    | eksik_bit_id 597    | eksik_bit_koordinat 586
--   electric_bike | toplam 436111 | eksik_bas_ad 144979 | eksik_bas_id 144979 | eksik_bit_ad 152869 | eksik_bit_id 152869 | eksik_bit_koordinat 0
--   (Bu sonuç eksik_bas_koordinat sütunu OLMADAN alındı. Başlangıç koordinatı için 12 aylık Kontrol 8 sonucu 0; Ekim'de de 0.
--    Sorguyu aşağıdaki hâliyle çalıştırınca eksik_bas_koordinat doğrudan teyit edilir.)
--   Başlangıç istasyonu eksik satırların hepsi electric (144979 / 646039, yaklaşık %22,4).
--   Classic bisiklette 586 satırın bitiş koordinatı eksik; 12 ay için Kontrol 8 ve 9'da incelendi.
SELECT rideable_type,
       COUNT(*) AS toplam,
       SUM(start_station_name IS NULL OR start_station_name = '') AS eksik_bas_ad,
       SUM(start_station_id   IS NULL OR start_station_id   = '') AS eksik_bas_id,
       SUM(end_station_name   IS NULL OR end_station_name   = '') AS eksik_bit_ad,
       SUM(end_station_id     IS NULL OR end_station_id     = '') AS eksik_bit_id,
       SUM(start_lat IS NULL OR start_lat = 0 OR start_lng IS NULL OR start_lng = 0) AS eksik_bas_koordinat,
       SUM(end_lat IS NULL OR end_lat = 0 OR end_lng IS NULL OR end_lng = 0) AS eksik_bit_koordinat
FROM tripdata_202510
GROUP BY rideable_type;


-- Kontrol 2: Başlangıçta istasyon adı ile ID birlikte mi eksik?
-- Beklenen: 0 (yalnızca biri eksik olan satır yok)
-- Sonuç: 0  ->  başlangıç istasyonu için ad ve ID birlikte eksik
SELECT COUNT(*) AS yalniz_biri_eksik
FROM tripdata_202510
WHERE (start_station_name = '') <> (start_station_id = '');


-- Kontrol 3: Eksik başlangıç istasyonu oranı kullanıcı tipine göre değişiyor mu? (Ekim 2025)
-- Beklenen: Bilinmiyor (tahmin yapılmadı)
-- Sonuç:
--   classic_bike  | member | toplam 143303 | eksik 0     | %0
--   classic_bike  | casual | toplam 66625  | eksik 0     | %0
--   electric_bike | member | toplam 278726 | eksik 93610 | %33,5850
--   electric_bike | casual | toplam 157385 | eksik 51369 | %32,6391
--   Elle hesaplanan genel oranlar: member %22,2 (93610 / 422029), casual %22,9 (51369 / 224010).
--   Yorum: Fark yaklaşık 1 puan; eksiklik kullanıcı tipinden çok bisiklet tipine bağlı görünüyor.
SELECT rideable_type, member_casual,
       COUNT(*) AS toplam,
       SUM(start_station_name IS NULL OR start_station_name = '') AS eksik_bas_ad,
       (SUM(start_station_name IS NULL OR start_station_name = '') / COUNT(*)) * 100 AS yuzdelik
FROM tripdata_202510
GROUP BY rideable_type, member_casual;


-- Kontrol 4: Bitiş tarafında ad/ID birlikte mi eksik? Gerçek NULL var mı? (Ekim 2025)
-- Beklenen: ikisi de 0
-- Sonuç: bitis_yalniz_biri_bos = 0 | gercek_null = 0  ->  beklenen ile tutuyor
-- Yorum: Bitiş istasyonu için de ad ve ID birlikte eksik; hiçbir sütunda gerçek NULL yok, boşlar boş metin olarak gelmiş
--        (ham tabloda boş metin kontrolü bu yüzden gerekliydi). Yalnızca Ekim 2025 için doğrulandı.
SELECT
  SUM((end_station_name = '') <> (end_station_id = ''))       AS bitis_yalniz_biri_bos,
  SUM(start_station_name IS NULL OR start_station_id IS NULL
      OR end_station_name IS NULL OR end_station_id IS NULL)  AS gercek_null
FROM tripdata_202510;


-- Kontrol 5: Yalnızca boşluktan oluşan istasyon adı var mı?
-- NULLIF(x,'') yalnızca tam boş metni yakalar; ' ' gibi değerler olduğu gibi kalır.
-- Beklenen: 0 (çıkarsa NULLIF(TRIM(x), '') kullanılmalı)
-- Sonuç: 0  ->  Ekim 2025'te start_station_name için yalnızca boşluktan oluşan değer yok.
--        Sınır: Yalnızca bir sütun ve bir ay ölçüldü; diğer sütunlar ve aylar için Kontrol 10 (isteğe bağlı).
SELECT COUNT(*) AS yalniz_bosluk_olan
FROM tripdata_202510
WHERE start_station_name <> ''
  AND TRIM(start_station_name) = '';


-- Kontrol 6: Aynı ölçüm 12 ay için, birleşik tabloda
-- tripdata_all oluştuğu için boşlar artık NULL; '' kontrolüne gerek yok.
-- Beklenen: Ekim 2025'teki örüntü (klasikte 0, elektrikte yaklaşık üçte bir) diğer aylarda da geçerli mi?
-- Sonuç:
--   classic_bike  | member | toplam 1235746 | eksik_bas_ad 0      | %0,0
--   classic_bike  | casual | toplam 548686  | eksik_bas_ad 0      | %0,0
--   electric_bike | member | toplam 2747015 | eksik_bas_ad 811987 | %29,6
--   electric_bike | casual | toplam 1640338 | eksik_bas_ad 477499 | %29,1
--   Toplam 6171785 (tripdata_all ile eşit). Eksik başlangıç istasyonu: 1289486 satır, yaklaşık %20,9.
--   Elle hesaplanan genel oranlar: member %20,4 (811987 / 3982761), casual %21,8 (477499 / 2189024).
--   Elektrik payı: member %69,0, casual %74,9. Genel farkın büyük kısmı bisiklet tipi dağılımından geliyor.
--   Not: Tablo henüz dönem filtresinden geçmedi (71 dönem dışı satır dahil).
SELECT rideable_type, member_casual,
       COUNT(*) AS toplam,
       SUM(start_station_name IS NULL) AS eksik_bas_ad,
       ROUND(SUM(start_station_name IS NULL) / COUNT(*) * 100, 1) AS yuzdelik
FROM tripdata_all
GROUP BY rideable_type, member_casual;


-- Kontrol 7: Eksiklik oranı aylar arasında değişiyor mu?
-- Beklenen: Bilinmiyor
-- Sonuç (ay | toplam | eksik_bas_yuzde):
--   2025-09 | 71     | 15,5  (dönem dışı, 71 satır; oran güvenilir değil)
--   2025-10 | 646096 | 22,4
--   2025-11 | 356512 | 21,4
--   2025-12 | 140545 | 19,2
--   2026-01 | 137782 | 17,8
--   2026-02 | 201454 | 15,9
--   2026-03 | 317015 | 18,2
--   2026-04 | 448287 | 20,5
--   2026-05 | 653747 | 21,0
--   2026-06 | 762595 | 20,8
--   2026-07 | 869101 | 21,8
--   2026-08 | 868069 | 21,8
--   2026-09 | 770511 | 20,8
--   Aylık toplamların toplamı 6171785 (tripdata_all ile eşit).
--   Yorum: Dönem içinde oran %15,9 (Şubat) ile %22,4 (Ekim) arasında; kış aylarında daha düşük.
--   Nedeni bilinmiyor (hipotez: kışın elektrikli bisiklet payı daha düşük); sınanmadı.
SELECT DATE_FORMAT(started_at, '%Y-%m') AS ay,
       COUNT(*) AS toplam,
       ROUND(SUM(start_station_name IS NULL) / COUNT(*) * 100, 1) AS eksik_bas_yuzde
FROM tripdata_all
GROUP BY DATE_FORMAT(started_at, '%Y-%m')
ORDER BY ay;


-- Kontrol 8: Koordinat eksikliği, 12 ay (tripdata_all)
-- Beklenen: Boş koordinat yok
-- Sonuç (rideable_type | toplam | eksik_bas_koordinat | eksik_bit_koordinat):
--   classic_bike  | 1784432 | 0 | 5451
--   electric_bike | 4387353 | 0 | 0
-- Yorum: Toplamlar tutuyor (1784432 + 4387353 = 6171785). Başlangıç koordinatı iki tipte de tam (beklenen tuttu).
--   Klasik bisiklette 5451 satırın (yaklaşık %0,31; elle hesaplandı) bitiş koordinatı eksik; elektrikte hiç eksik yok.
--   Sorgu NULL ve 0 değerlerini birlikte saydı; hangisi olduğu ayrılmadı.
SELECT rideable_type,
       COUNT(*) AS toplam,
       SUM(start_lat IS NULL OR start_lat = 0
           OR start_lng IS NULL OR start_lng = 0) AS eksik_bas_koordinat,
       SUM(end_lat IS NULL OR end_lat = 0
           OR end_lng IS NULL OR end_lng = 0)     AS eksik_bit_koordinat
FROM tripdata_all
GROUP BY rideable_type;


-- Kontrol 9: Eksik bitiş koordinatlı klasik yolculuklar ve süreleri
-- Beklenen: (tahmin: çoğu 24:59 grubunda, yani 24 saatin üstü yolculuklarla aynı satırlar)
-- Hipotez (sınanmadı): İade edilmeyen klasik bisiklet 24:59'da kapanıyor ve bitiş konumu kaydedilmiyor olabilir.
-- Sonuç: eksik_bit_koordinat 5451 | dakika_1499 5128 | yirmidort_saat_ustu 5143 | tripdata_clean'de kalan 308
-- Yorum: Satırların yaklaşık %94'ü 1499. dakikada (24:59), yaklaşık %94,3'ü 24 saatin üstünde (elle hesaplandı).
--   5451 - 308 = 5143: temiz tablodan çıkan satır sayısı 24 saatin üstü sayısıyla tutuyor; süre filtresi bu satırların
--   büyük kısmını zaten çıkarıyor. Hipotez büyük ölçüde destekleniyor; nedeni veri göstermiyor.
--   Kalan 308 satırın (klasik yolculukların yaklaşık %0,017'si) nedeni bilinmiyor; etkisi ihmal edilebilir.
--   Günlükteki "İncelenecek" maddesi kapanır.
SELECT COUNT(*) AS eksik_bit_koordinat,
       SUM(TIMESTAMPDIFF(MINUTE, started_at, ended_at) = 1499) AS dakika_1499,
       SUM(TIMESTAMPDIFF(SECOND, started_at, ended_at) > 86400) AS yirmidort_saat_ustu
FROM tripdata_all
WHERE rideable_type = 'classic_bike'
  AND (end_lat IS NULL OR end_lat = 0 OR end_lng IS NULL OR end_lng = 0);

-- Aynı koşul, temiz tabloda (08_tripdata_clean_olustur.sql, Doğrulama 9 ile aynı)
SELECT COUNT(*) AS eksik_bit_koordinat_clean
FROM tripdata_clean
WHERE rideable_type = 'classic_bike'
  AND (end_lat IS NULL OR end_lat = 0 OR end_lng IS NULL OR end_lng = 0);


-- Kontrol 10: Eksik bitiş koordinatı NULL mı 0 mı? (classic, tripdata_all)
-- Amaç: Mesafe ya da harita analizine geçilirse 0 koordinatın sahte konum üretmesini önlemek
-- Beklenen: (tahmin kaydedilmedi)
-- Sonuç: bos_null = 0 | sifir = 5451
-- Yorum: 5451 satırın hiçbirinde koordinat NULL değil; hepsi 0 olarak kaydedilmiş.
--        Şimdiki analizde koordinat kullanılmadığı için sonuca etkisi yok. Mesafe ya da harita analizi yapılırsa
--        0 enlem / 0 boylam gerçek bir konum gibi hesaplanır (binlerce kilometrelik sahte yolculuk); bu satırlar dışarıda
--        bırakılmalı ya da NULLIF(end_lat, 0), NULLIF(end_lng, 0) ile NULL yapılmalı.
--        tripdata_clean'de bu kural için 308 satır kalıyor (Kontrol 9).
SELECT SUM(end_lat IS NULL OR end_lng IS NULL) AS bos_null,
       SUM(end_lat = 0 OR end_lng = 0)         AS sifir
FROM tripdata_all
WHERE rideable_type = 'classic_bike'
  AND (end_lat IS NULL OR end_lat = 0 OR end_lng IS NULL OR end_lng = 0);


-- Kontrol 11: Yalnızca boşluktan oluşan istasyon adı/ID var mı? (12 ay, 4 sütun)
-- tripdata_all'da boş metinler NULL olduğu için IS NOT NULL kontrolü yeterli.
-- Beklenen: dört sütunda da 0
-- Sonuç: bas_ad = 0 | bas_id = 0 | bit_ad = 0 | bit_id = 0  ->  beklenen ile tutuyor
-- Yorum: NULLIF(x, '') dönüşümü yeterliydi; yalnızca boşluktan oluşan değer yok (12 ay, 4 sütun).
SELECT
  SUM(start_station_name IS NOT NULL AND TRIM(start_station_name) = '') AS bas_ad,
  SUM(start_station_id   IS NOT NULL AND TRIM(start_station_id)   = '') AS bas_id,
  SUM(end_station_name   IS NOT NULL AND TRIM(end_station_name)   = '') AS bit_ad,
  SUM(end_station_id     IS NOT NULL AND TRIM(end_station_id)     = '') AS bit_id
FROM tripdata_all;


-- ---------------------------------------------------------------------------
-- SONUÇ ÖZETİ
--   Eksik başlangıç istasyonu: tripdata_all'da 1289486 satır (yaklaşık %20,9), hepsi electric; classic'te 0.
--     Ad ve ID birlikte eksik (Ekim'de doğrulandı). Üye tipinden çok bisiklet tipine bağlı. Aylara göre %15,9 - %22,4.
--   Karar: Etiketle (NULL). Silme ve doldurma yok.
--   Eksik bitiş koordinatı: yalnızca classic, 5451 satır; hepsi 0 olarak kaydedilmiş (NULL değil). Çoğu 24 saatin üstü yolculuk,
--     süre filtresiyle çıkıyor; temiz tabloda 308 kalıyor. Mesafe ya da harita analizinde bu satırlar dışarıda bırakılmalı.
--   Başlangıç koordinatı: 12 ayda iki tipte de tam.
--   Boşluk kontrolü (12 ay, 4 sütun): yalnızca boşluktan oluşan değer yok.
--   Sınırlar: Kontrol 1-5 yalnızca Ekim 2025; Kontrol 1'e eklenen eksik_bas_koordinat sütunu bu ay için çalıştırılmadı
--     (12 aylık Kontrol 8 sonucundan 0 olarak çıkarıldı); 0 koordinatın nedeni bilinmiyor.
