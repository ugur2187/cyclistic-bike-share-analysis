-- 05_tripdata_all_olustur.sql
-- Amaç: 12 aylık ham tabloyu (10/2025 - 09/2026) tek tabloda birleştirmek ve birleştirmeyi doğrulamak
-- Tarih: 2026-10-15
-- Günlük adımı: #2 (started_at / ended_at text), #7 (boş metin), #10 (birleştirme doğruluğu)
-- Not: Bu dosya tripdata_all tablosunu NASIL oluşturduğumuzu kayıt altına alır; tablo zaten oluşturuldu.
--      Yeniden oluşturmak gerekirse önce aşağıdaki DROP satırı çalıştırılır (yalnızca türetilmiş tablo silinir, ham tablolara dokunulmaz).
-- Dönem filtresi, süre filtresi ve yinelenen kayıtların çıkarılması burada UYGULANMAZ; onlar tripdata_clean'e aittir.
--   Yapılanlar: (1) started_at / ended_at -> datetime (STR_TO_DATE, kesirli saniye atılır)
--               (2) istasyon ad/ID sütunlarında boş metin -> NULL (NULLIF)
--               (3) sütunlar tek tek ve aynı sırada yazıldı (SELECT * kullanılmadı); UNION ALL (yinelenenler silinmez)


-- Adım 1: Tabloyu oluştur
-- Yeniden oluşturma gerekirse önce: DROP TABLE IF EXISTS tripdata_all;
-- Dikkat: noktalı virgül yalnızca en sonda; 12 SELECT, her ay bir kez.
CREATE TABLE tripdata_all AS
SELECT ride_id,
       rideable_type,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS started_at,
       STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') AS ended_at,
       NULLIF(start_station_name,'') AS start_station_name,
       NULLIF(start_station_id,'')   AS start_station_id,
       NULLIF(end_station_name,'')   AS end_station_name,
       NULLIF(end_station_id,'')     AS end_station_id,
       start_lat, start_lng, end_lat, end_lng,
       member_casual
FROM tripdata_202510
UNION ALL
SELECT ride_id,
       rideable_type,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS started_at,
       STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') AS ended_at,
       NULLIF(start_station_name,'') AS start_station_name,
       NULLIF(start_station_id,'')   AS start_station_id,
       NULLIF(end_station_name,'')   AS end_station_name,
       NULLIF(end_station_id,'')     AS end_station_id,
       start_lat, start_lng, end_lat, end_lng,
       member_casual
FROM tripdata_202511
UNION ALL
SELECT ride_id,
       rideable_type,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS started_at,
       STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') AS ended_at,
       NULLIF(start_station_name,'') AS start_station_name,
       NULLIF(start_station_id,'')   AS start_station_id,
       NULLIF(end_station_name,'')   AS end_station_name,
       NULLIF(end_station_id,'')     AS end_station_id,
       start_lat, start_lng, end_lat, end_lng,
       member_casual
FROM tripdata_202512
UNION ALL
SELECT ride_id,
       rideable_type,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS started_at,
       STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') AS ended_at,
       NULLIF(start_station_name,'') AS start_station_name,
       NULLIF(start_station_id,'')   AS start_station_id,
       NULLIF(end_station_name,'')   AS end_station_name,
       NULLIF(end_station_id,'')     AS end_station_id,
       start_lat, start_lng, end_lat, end_lng,
       member_casual
FROM tripdata_202601
UNION ALL
SELECT ride_id,
       rideable_type,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS started_at,
       STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') AS ended_at,
       NULLIF(start_station_name,'') AS start_station_name,
       NULLIF(start_station_id,'')   AS start_station_id,
       NULLIF(end_station_name,'')   AS end_station_name,
       NULLIF(end_station_id,'')     AS end_station_id,
       start_lat, start_lng, end_lat, end_lng,
       member_casual
FROM tripdata_202602
UNION ALL
SELECT ride_id,
       rideable_type,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS started_at,
       STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') AS ended_at,
       NULLIF(start_station_name,'') AS start_station_name,
       NULLIF(start_station_id,'')   AS start_station_id,
       NULLIF(end_station_name,'')   AS end_station_name,
       NULLIF(end_station_id,'')     AS end_station_id,
       start_lat, start_lng, end_lat, end_lng,
       member_casual
FROM tripdata_202603
UNION ALL
SELECT ride_id,
       rideable_type,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS started_at,
       STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') AS ended_at,
       NULLIF(start_station_name,'') AS start_station_name,
       NULLIF(start_station_id,'')   AS start_station_id,
       NULLIF(end_station_name,'')   AS end_station_name,
       NULLIF(end_station_id,'')     AS end_station_id,
       start_lat, start_lng, end_lat, end_lng,
       member_casual
FROM tripdata_202604
UNION ALL
SELECT ride_id,
       rideable_type,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS started_at,
       STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') AS ended_at,
       NULLIF(start_station_name,'') AS start_station_name,
       NULLIF(start_station_id,'')   AS start_station_id,
       NULLIF(end_station_name,'')   AS end_station_name,
       NULLIF(end_station_id,'')     AS end_station_id,
       start_lat, start_lng, end_lat, end_lng,
       member_casual
FROM tripdata_202605
UNION ALL
SELECT ride_id,
       rideable_type,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS started_at,
       STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') AS ended_at,
       NULLIF(start_station_name,'') AS start_station_name,
       NULLIF(start_station_id,'')   AS start_station_id,
       NULLIF(end_station_name,'')   AS end_station_name,
       NULLIF(end_station_id,'')     AS end_station_id,
       start_lat, start_lng, end_lat, end_lng,
       member_casual
FROM tripdata_202606
UNION ALL
SELECT ride_id,
       rideable_type,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS started_at,
       STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') AS ended_at,
       NULLIF(start_station_name,'') AS start_station_name,
       NULLIF(start_station_id,'')   AS start_station_id,
       NULLIF(end_station_name,'')   AS end_station_name,
       NULLIF(end_station_id,'')     AS end_station_id,
       start_lat, start_lng, end_lat, end_lng,
       member_casual
FROM tripdata_202607
UNION ALL
SELECT ride_id,
       rideable_type,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS started_at,
       STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') AS ended_at,
       NULLIF(start_station_name,'') AS start_station_name,
       NULLIF(start_station_id,'')   AS start_station_id,
       NULLIF(end_station_name,'')   AS end_station_name,
       NULLIF(end_station_id,'')     AS end_station_id,
       start_lat, start_lng, end_lat, end_lng,
       member_casual
FROM tripdata_202608
UNION ALL
SELECT ride_id,
       rideable_type,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS started_at,
       STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') AS ended_at,
       NULLIF(start_station_name,'') AS start_station_name,
       NULLIF(start_station_id,'')   AS start_station_id,
       NULLIF(end_station_name,'')   AS end_station_name,
       NULLIF(end_station_id,'')     AS end_station_id,
       start_lat, start_lng, end_lat, end_lng,
       member_casual
FROM tripdata_202609;



-- Doğrulama 1: Satır sayıları (aylık tablolar ve tripdata_all)
-- Beklenen: AYLARIN TOPLAMI = TRIPDATA_ALL
-- Sonuç:
--   tripdata_202510 646039 | tripdata_202511 356628 | tripdata_202512 140534 | tripdata_202601 137787
--   tripdata_202602 201450 | tripdata_202603 317037 | tripdata_202604 448252 | tripdata_202605 653704
--   tripdata_202606 762550 | tripdata_202607 869051 | tripdata_202608 868191 | tripdata_202609 770562
--   AYLARIN TOPLAMI 6171785 | TRIPDATA_ALL 6171785  ->  eşit, satır kaybı/fazlalığı yok
--   Ek doğrulama: Aralık 2025 (140534) ve Ocak 2026 (137787) sayıları, orijinal CSV dosyalarındaki satır sayılarıyla aynı.
SELECT 'tripdata_202510' AS dosya_adi, COUNT(*) AS total FROM tripdata_202510
UNION ALL SELECT 'tripdata_202511', COUNT(*) FROM tripdata_202511
UNION ALL SELECT 'tripdata_202512', COUNT(*) FROM tripdata_202512
UNION ALL SELECT 'tripdata_202601', COUNT(*) FROM tripdata_202601
UNION ALL SELECT 'tripdata_202602', COUNT(*) FROM tripdata_202602
UNION ALL SELECT 'tripdata_202603', COUNT(*) FROM tripdata_202603
UNION ALL SELECT 'tripdata_202604', COUNT(*) FROM tripdata_202604
UNION ALL SELECT 'tripdata_202605', COUNT(*) FROM tripdata_202605
UNION ALL SELECT 'tripdata_202606', COUNT(*) FROM tripdata_202606
UNION ALL SELECT 'tripdata_202607', COUNT(*) FROM tripdata_202607
UNION ALL SELECT 'tripdata_202608', COUNT(*) FROM tripdata_202608
UNION ALL SELECT 'tripdata_202609', COUNT(*) FROM tripdata_202609
UNION ALL SELECT 'AYLARIN TOPLAMI', SUM(satir)
FROM (
  SELECT COUNT(*) AS satir FROM tripdata_202510
  UNION ALL SELECT COUNT(*) AS satir FROM tripdata_202511
  UNION ALL SELECT COUNT(*) AS satir FROM tripdata_202512
  UNION ALL SELECT COUNT(*) AS satir FROM tripdata_202601
  UNION ALL SELECT COUNT(*) AS satir FROM tripdata_202602
  UNION ALL SELECT COUNT(*) AS satir FROM tripdata_202603
  UNION ALL SELECT COUNT(*) AS satir FROM tripdata_202604
  UNION ALL SELECT COUNT(*) AS satir FROM tripdata_202605
  UNION ALL SELECT COUNT(*) AS satir FROM tripdata_202606
  UNION ALL SELECT COUNT(*) AS satir FROM tripdata_202607
  UNION ALL SELECT COUNT(*) AS satir FROM tripdata_202608
  UNION ALL SELECT COUNT(*) AS satir FROM tripdata_202609
) t
UNION ALL SELECT 'TRIPDATA_ALL', COUNT(*) FROM tripdata_all;


-- Doğrulama 2: Sütun tipleri
-- Beklenen: started_at ve ended_at = datetime
-- Sonuç: started_at datetime | ended_at datetime | start_lat, start_lng, end_lat, end_lng double
--        ride_id, rideable_type, istasyon ad/ID sütunları ve member_casual mediumtext (ham tablolarda text; UNION ALL sonrası MySQL mediumtext seçti)
DESCRIBE tripdata_all;


-- Doğrulama 3: Her tabloda 13 sütun var mı?
-- Beklenen: 12 aylık tablo + tripdata_all = 13 satır, hepsinde 13 sütun
-- Sonuç: 13 satır, hepsinde sutun_sayisi = 13
SELECT TABLE_NAME,
       COUNT(*) AS sutun_sayisi
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME LIKE 'tripdata\_%'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;


-- Doğrulama 4: started_at'e göre aylık dağılım
-- Beklenen: dönem içindeki 12 ay; NULL bir ay satırı çıkmamalı (dönüşüm hatası olmamalı)
-- Sonuç (ay | satir):
--   2025-09 71     | 2025-10 646096 | 2025-11 356512 | 2025-12 140545
--   2026-01 137782 | 2026-02 201454 | 2026-03 317015 | 2026-04 448287
--   2026-05 653747 | 2026-06 762595 | 2026-07 869101 | 2026-08 868069 | 2026-09 770511
--   Toplam 6171785. 2025-09 dönem dışıdır (71 satır, tripdata_clean'de dönem filtresiyle çıkarılacak).
SELECT DATE_FORMAT(started_at, '%Y-%m') AS ay, COUNT(*) AS satir
FROM tripdata_all
GROUP BY DATE_FORMAT(started_at, '%Y-%m')
ORDER BY ay;


-- Doğrulama 5: Dönem dışı 71 satırın bitiş tarihleri
-- Hipotez: Tablolar yolculuğun bittiği aya göre ayrılmış; bu satırlar ay sınırını geçen yolculuklar
-- Sonuç: satir = 71 | en_erken_bas 2025-09-30 08:37:53 | en_gec_bas 2025-09-30 23:59:28
--        en_erken_bitis 2025-10-01 00:00:07 | en_gec_bitis 2025-10-01 20:30:48  ->  hipotezle uyumlu
SELECT COUNT(*) AS satir,
       MIN(started_at) AS en_erken_bas,
       MAX(started_at) AS en_gec_bas,
       MIN(ended_at)   AS en_erken_bitis,
       MAX(ended_at)   AS en_gec_bitis
FROM tripdata_all
WHERE started_at < '2025-10-01';
