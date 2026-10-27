-- 08_tripdata_clean_olustur.sql
-- Amaç: Önceki kontrollerin kararlarını uygulayarak analiz için temiz tabloyu (tripdata_clean) oluşturmak
-- Tarih: 2026-10-19
-- Günlük adımı: Dönem filtresi, yinelenen kayıtlar, süre filtresi, analiz sütunları
-- Not: Bu dosyadaki sorgular henüz çalıştırılmadı. Ham tablolara ve tripdata_all'a dokunulmaz;
--      yalnızca yeni tablo (tripdata_clean) oluşturulur.
--
-- UYGULANAN KARARLAR
--   1) Dönem:        started_at 2025-10-01 ile 2026-10-01 arası (71 satır dönem dışı)       [03, 05 dosyaları]
--   2) Yinelenen:    35 ride_id iki kez kayıtlı, çiftler birebir aynı; her ID'den bir satır [06 dosyası]
--   3) Süre:         60 sn <= süre <= 24 saat (86400 sn); <= 0, < 60 sn ve > 24 saat çıkar  [07 dosyası]
--   4) İstasyon:     Eksik istasyon bilgisi olan satırlar ÇIKARILMAZ (NULL olarak kalır);
--                    istasyon analizinde sorguda dışarıda bırakılır                          [04 dosyası]
--   5) Koordinat:    Eksik/0 bitiş koordinatları (classic'te 586, Ekim) bu adımda değiştirilmez; incelenecek
--
-- SATIR SAYISI BEKLENTİSİ (elle hesaplandı, sorguyla doğrulanacak)
--   tripdata_all                      6.171.785
--   dönem filtresinden sonra          6.171.714   (-71)
--   yinelenenler çıktıktan sonra      6.171.679   (-35)
--   süre filtresinden sonra           6.007.772 ile 6.007.807 arası
--     (süre filtresi dönem içindeki 163.907 satırı çıkarıyor; 35 yinelenen satırın bir kısmı 24 saati aşıyorsa
--      o satırlar yinelenen adımında zaten çıkmış olur, bu yüzden aralık var)
--
-- YÖNTEM: İki adım.
--   Adım 1: Yinelenen olmayan satırlar (tekrar_ride_id yardımcı tablosunda olmayanlar) filtrelerle alınır.
--   Adım 2: Yinelenen 35 ID'nin her biri için tek satır eklenir (SELECT DISTINCT).
--   Neden: Tüm tabloda SELECT DISTINCT çalıştırmak 6 milyon satırda çok yavaş olabilir (ölçülmedi; ride_id mediumtext).
--          DISTINCT yalnızca 70 satıra uygulanır. Çiftler birebir aynı olduğu için hangi kopyanın kaldığı önemli değil.
--   Dikkat: İki SELECT'teki sütun listesi birebir aynı olmalı (INSERT sütun adı yazmadan sırayla eşleştirir).
--
-- Yeniden oluşturmak gerekirse önce (yalnızca türetilmiş tablo silinir):
--   DROP TABLE IF EXISTS tripdata_clean;
-- Sorgu uzun sürebilir. Bağlantı koparsa yeniden çalıştırmadan önce SHOW FULL PROCESSLIST ile sorgunun sürüp sürmediğine bak.


-- ---------------------------------------------------------------------------
-- Adım 1: Yinelenen olmayan satırlar
-- Sonuç: 6007751 satır, 134 saniye
CREATE TABLE tripdata_clean AS
SELECT a.ride_id,
       a.rideable_type,
       a.started_at,
       a.ended_at,
       a.start_station_name,
       a.start_station_id,
       a.end_station_name,
       a.end_station_id,
       a.start_lat, a.start_lng, a.end_lat, a.end_lng,
       a.member_casual,
       ROUND(TIMESTAMPDIFF(SECOND, a.started_at, a.ended_at) / 60, 2) AS ride_length_min,
       DAYNAME(a.started_at)              AS day_of_week,
       WEEKDAY(a.started_at)              AS day_num,
       HOUR(a.started_at)                 AS start_hour,
       DATE_FORMAT(a.started_at, '%Y-%m') AS start_month
FROM tripdata_all a
LEFT JOIN tekrar_ride_id t ON t.ride_id = a.ride_id
WHERE t.ride_id IS NULL
  AND a.started_at >= '2025-10-01' AND a.started_at < '2026-10-01'
  AND TIMESTAMPDIFF(SECOND, a.started_at, a.ended_at) BETWEEN 60 AND 86400;


-- ---------------------------------------------------------------------------
-- Adım 2: Yinelenen ID'lerden her biri için tek satır
-- Beklenen: en fazla 35 satır eklenir (yinelenen satırlardan bazıları süre filtresine takılabilir)
-- Sonuç: 28 satır eklendi
--   Yorum: 35 yinelenen ID'den 28'i süre filtresini geçti. Çiftler birebir aynı olduğu için iki kopyanın süresi de aynı;
--          kalan 7 ID'nin iki kopyası da süre filtresine takıldı (muhtemelen > 24 saat; hangi kuralın çıkardığı ayrıca sorgulanmadı).
INSERT INTO tripdata_clean
SELECT DISTINCT
       a.ride_id,
       a.rideable_type,
       a.started_at,
       a.ended_at,
       a.start_station_name,
       a.start_station_id,
       a.end_station_name,
       a.end_station_id,
       a.start_lat, a.start_lng, a.end_lat, a.end_lng,
       a.member_casual,
       ROUND(TIMESTAMPDIFF(SECOND, a.started_at, a.ended_at) / 60, 2) AS ride_length_min,
       DAYNAME(a.started_at)              AS day_of_week,
       WEEKDAY(a.started_at)              AS day_num,
       HOUR(a.started_at)                 AS start_hour,
       DATE_FORMAT(a.started_at, '%Y-%m') AS start_month
FROM tripdata_all a
JOIN tekrar_ride_id t ON t.ride_id = a.ride_id
WHERE a.started_at >= '2025-10-01' AND a.started_at < '2026-10-01'
  AND TIMESTAMPDIFF(SECOND, a.started_at, a.ended_at) BETWEEN 60 AND 86400;


-- ---------------------------------------------------------------------------
-- Adım 3: ride_id indeksi (performans için; veri değişmez)
CREATE INDEX idx_clean_ride_id ON tripdata_clean (ride_id(16));


-- ---------------------------------------------------------------------------
-- DOĞRULAMA 1: Satır sayısı
-- Beklenen: 6.007.772 ile 6.007.807 arası
-- Sonuç: 6007779  (Adım 1: 6007751 + Adım 2: 28; beklenen aralığın içinde)
SELECT COUNT(*) AS satir FROM tripdata_clean;

-- DOĞRULAMA 2: Yinelenen ride_id kalmadı mı?
-- Beklenen: 0
-- Sonuç: 0
SELECT COUNT(*) - COUNT(DISTINCT ride_id) AS yinelenen FROM tripdata_clean;

-- DOĞRULAMA 3: Dönem sınırları
-- Beklenen: en_erken >= 2025-10-01, en_gec < 2026-10-01
-- Sonuç: en_erken = 2025-10-01 00:00:12 | en_gec = 2026-09-30 23:57:18  ->  beklenen aralığın içinde
SELECT MIN(started_at) AS en_erken, MAX(started_at) AS en_gec FROM tripdata_clean;

-- DOĞRULAMA 4: Süre sınırları
-- Beklenen: en_kisa >= 1,00 dk (60 sn), en_uzun <= 1440,00 dk (24 saat)
-- Sonuç: en_kisa_dk = 1,00 | en_uzun_dk = 1439,97  ->  beklenen aralığın içinde
SELECT MIN(ride_length_min) AS en_kisa_dk, MAX(ride_length_min) AS en_uzun_dk FROM tripdata_clean;

-- DOĞRULAMA 5: Aylık dağılım
-- Beklenen: 12 satır (2025-10 ... 2026-09), NULL ay yok
-- Sonuç: 12 satır (2025-10 ... 2026-09), NULL ay yok
-- start_month, satir
-- 2025-10	628542
-- 2025-11	346670
-- 2025-12	136475
-- 2026-01	133758
-- 2026-02	197331
-- 2026-03	308513
-- 2026-04	435520
-- 2026-05	635456
-- 2026-06	741465
-- 2026-07	846090
-- 2026-08	846600
-- 2026-09	751359


SELECT start_month, COUNT(*) AS satir
FROM tripdata_clean
GROUP BY start_month
ORDER BY start_month;

-- DOĞRULAMA 6: Kategori değerleri
-- Beklenen: rideable_type yalnızca classic_bike ve electric_bike; member_casual yalnızca member ve casual
-- Sonuç: rideable_type classic_bike ve electric_bike; member_casual member ve casual (başka değer yok)
SELECT rideable_type, member_casual, COUNT(*) AS satir
FROM tripdata_clean
GROUP BY rideable_type, member_casual
ORDER BY rideable_type, member_casual;

-- DOĞRULAMA 7: Sütun tipleri
-- Beklenen: started_at, ended_at datetime; ride_length_min decimal; start_hour, day_num sayısal
-- Sonuç: started_at, ended_at datetime; ride_length_min decimal; start_hour, day_num sayısal
DESCRIBE tripdata_clean;

-- DOĞRULAMA 8: Çıkarılan satır sayısı (tripdata_all'a göre)
-- Beklenen: 6.171.785 - satır (DOĞRULAMA 1) = 163.978 ile 164.013 arası
-- Sonuç: 164006  ->  beklenen aralığın içinde
SELECT (SELECT COUNT(*) FROM tripdata_all) - (SELECT COUNT(*) FROM tripdata_clean) AS cikarilan;


-- ---------------------------------------------------------------------------
-- SATIR SAYISI AKIŞI (sırayla uygulanan adımlar; günlük için)
--   tripdata_all                      6.171.785
--   dönem filtresi (-71)              6.171.714
--   yinelenenler (-35)                6.171.679
--   süre filtresi (-163.900)          6.007.779   = tripdata_clean (Doğrulama 1)
--   toplam çıkarılan                  164.006     (71 + 35 + 163.900; Doğrulama 8 ile tutuyor; yaklaşık %2,66)
--   Not: Süre filtresi tek başına dönem içinde 163.907 satır çıkarıyordu (07 dosyası). Yinelenen adımı 7 kopya satırı
--        önceden çıkardığı için süre adımında 163.900 satır kalıyor (163.907 - 7); 35 yinelenen ID'den 28'i kaldı,
--        yani 7 ID'nin iki kopyası da süre filtresine takıldı.
