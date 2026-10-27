-- 01_profil_ve_kontrol.sql
-- Amaç: Ham aylık tabloların yapısını ve tutarlılığını doğrulamak
-- Tarih: 2026-10-15

-- Kontrol 1: Kaç aylık tablo var?
-- Beklenen: 12
SELECT COUNT(*) AS tablo_sayisi
FROM information_schema.tables
WHERE table_schema = DATABASE()
  AND table_name LIKE 'tripdata\_2%';

-- Kontrol 2: Sütun tipleri tüm tablolarda aynı mı?
-- Beklenen: 13 satır, hepsinde tablo_sayisi = 12
SELECT column_name, data_type,
       COUNT(DISTINCT table_name) AS tablo_sayisi
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name LIKE 'tripdata\_2%'
GROUP BY column_name, data_type
ORDER BY column_name;

-- Kontrol 3: Aylık satır sayıları
-- Beklenen: tripdata_all oluşturulunca toplamla eşleşmeli
SELECT 'tripdata_202510' AS tablo, COUNT(*) AS satir FROM tripdata_202510
UNION ALL
SELECT 'tripdata_202511', COUNT(*) FROM tripdata_202511
SELECT 'tripdata_202512', COUNT(*) FROM tripdata_202512
SELECT 'tripdata_202601', COUNT(*) FROM tripdata_202601
SELECT 'tripdata_202602', COUNT(*) FROM tripdata_202602
SELECT 'tripdata_202603', COUNT(*) FROM tripdata_202603
SELECT 'tripdata_202604', COUNT(*) FROM tripdata_202604
SELECT 'tripdata_202605', COUNT(*) FROM tripdata_202605
SELECT 'tripdata_202606', COUNT(*) FROM tripdata_202606
SELECT 'tripdata_202607', COUNT(*) FROM tripdata_202607
SELECT 'tripdata_202608', COUNT(*) FROM tripdata_202608
SELECT 'tripdata_202609', COUNT(*) FROM tripdata_202609;
