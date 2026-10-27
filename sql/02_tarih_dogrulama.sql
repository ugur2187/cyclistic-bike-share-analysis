-- 02_tarih_dogrulama.sql
-- Amaç: Ham aylık tablolarda started_at / ended_at (text) değerlerinin
--       YYYY-MM-DD HH:MM:SS kalıbına uyduğunu ve datetime'a çevrilebildiğini doğrulamak
-- Tarih: 2026-10-15
-- Günlük adımı: #3 (started_at / ended_at text tipinde)
-- Not: LEFT(x,19) kesirli saniyeyi (.123) atar; dakika bazlı analiz için gerekmiyor.
--      STR_TO_DATE kalıba uymayan metinde hata vermez, NULL döndürür; bu yüzden NULL sayıyoruz.


-- Kontrol 1: Her tabloda kaç satır dönüşemiyor?
-- Beklenen: Tüm tablolarda baslangic_hatali = 0 ve bitis_hatali = 0
-- Sonuç:	Tüm tablolarda baslangic_hatali = 0 ve bitis_hatali = 0
SELECT 'tripdata_202510' AS tablo,
       COUNT(*) AS toplam,
       SUM(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL) AS baslangic_hatali,
       SUM(STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL) AS bitis_hatali
FROM tripdata_202510
UNION ALL
SELECT 'tripdata_202511', COUNT(*),
       SUM(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL),
       SUM(STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL)
FROM tripdata_202511
UNION ALL
SELECT 'tripdata_202512', COUNT(*),
       SUM(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL),
       SUM(STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL)
FROM tripdata_202512
UNION ALL
SELECT 'tripdata_202601', COUNT(*),
       SUM(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL),
       SUM(STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL)
FROM tripdata_202601
UNION ALL
SELECT 'tripdata_202602', COUNT(*),
       SUM(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL),
       SUM(STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL)
FROM tripdata_202602
UNION ALL
SELECT 'tripdata_202603', COUNT(*),
       SUM(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL),
       SUM(STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL)
FROM tripdata_202603
UNION ALL
SELECT 'tripdata_202604', COUNT(*),
       SUM(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL),
       SUM(STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL)
FROM tripdata_202604
UNION ALL
SELECT 'tripdata_202605', COUNT(*),
       SUM(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL),
       SUM(STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL)
FROM tripdata_202605
UNION ALL
SELECT 'tripdata_202606', COUNT(*),
       SUM(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL),
       SUM(STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL)
FROM tripdata_202606
UNION ALL
SELECT 'tripdata_202607', COUNT(*),
       SUM(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL),
       SUM(STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL)
FROM tripdata_202607
UNION ALL
SELECT 'tripdata_202608', COUNT(*),
       SUM(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL),
       SUM(STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL)
FROM tripdata_202608
UNION ALL
SELECT 'tripdata_202609', COUNT(*),
       SUM(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL),
       SUM(STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL)
FROM tripdata_202609;


-- Kontrol 2: Hata varsa hangi satırlar dönüşmedi? (Yalnızca Kontrol 1'de 0'dan büyük sayı çıkarsa çalıştır.)
-- Tablo adını sorunlu tabloyla değiştir.
-- Beklenen: boş sonuç
-- Sonuç: Kontrol 1'de tüm sonuçlar 0 çıktığı için bu adıma gerek yok
SELECT ride_id, started_at, ended_at
FROM tripdata_202510
WHERE STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') IS NULL
   OR STR_TO_DATE(LEFT(ended_at,19),   '%Y-%m-%d %H:%i:%s') IS NULL
LIMIT 20;


-- Kontrol 3: Ham metin ile dönüştürülmüş değeri yan yana görmek
-- Beklenen: ham_metin 23 karakter (.123 dahil), donusturulmus 19 karakterlik datetime
SELECT started_at AS ham_metin,
       STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') AS donusturulmus
FROM tripdata_202510
LIMIT 10;