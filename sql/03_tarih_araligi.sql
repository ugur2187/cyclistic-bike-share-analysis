-- 03_tarih_araligi.sql
-- Amaç: Aylık tabloların içindeki tarih aralığını kontrol etmek, ay sınırından taşan kayıtları
--       ve olası yinelenen ride_id'leri tespit etmek
-- Tarih: 2026-10-15
-- Günlük adımı: #4 (Eylül 2026 tablosunda Ağustos tarihli kayıt), analiz dönemi kararı
-- Not: Ham tablolarda started_at hâlâ text olduğu için her sorguda STR_TO_DATE(LEFT(x,19), ...) kullanılır.


-- Kontrol 1: Eylül 2026 tablosunun tarih aralığı (ay tam mı?)
-- Beklenen: en_erken Eylül başı, en_gec 30 Eylül sonu
-- Sonuç: en_erken = 2026-08-31 00:53:20 | en_gec = 2026-09-30 23:59:38 | toplam = 770562
--        Eylül tam bir ay; ama en_erken 31 Ağustos'ta, yani tablo ay sınırından taşıyor.
SELECT
  MIN(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s')) AS en_erken,
  MAX(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s')) AS en_gec,
  COUNT(*) AS toplam
FROM tripdata_202609;


-- Kontrol 2: Ağustos 2026 tablosunun tarih aralığı
-- Beklenen: en_gec 31 Ağustos'a uzanıyorsa aynı günler iki tabloda olabilir (çakışma şüphesi)
-- Sonuç: en_erken = 2026-07-30 23:01:41 | en_gec = 2026-08-31 23:55:36 | toplam = 868191
--        Aynı kayma Ağustos'un başında da var; tablolar ay sınırında taşıyor.
SELECT
  MIN(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s')) AS en_erken,
  MAX(STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s')) AS en_gec,
  COUNT(*) AS toplam
FROM tripdata_202608;


-- Kontrol 3: Eylül tablosunda 1 Eylül'den önce başlayan kaç yolculuk var?
-- Beklenen: küçük bir sayı (ay sınırı kayması)
-- Sonuç: 51 (yaklaşık %0,007)
SELECT COUNT(*) AS eylul_oncesi_satir
FROM tripdata_202609
WHERE STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') < '2026-09-01';


-- Kontrol 4: Çakışan pencerede her iki tabloda kaç satır var?
-- Beklenen: sayılar birbirine yakınsa aynı yolculuklar iki tabloda duruyor olabilir
-- Sonuç: ağustos tablosu = 17153 | eylül tablosu = 51
--        Sayılar çok farklı; kayıtlar neredeyse tamamen Ağustos tablosunda.
SELECT 'ağustos tablosu' AS tablo, COUNT(*) AS satir
FROM tripdata_202608
WHERE STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') >= '2026-08-31 00:53:20'
  AND STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') <  '2026-09-01'
UNION ALL
SELECT 'eylül tablosu', COUNT(*)
FROM tripdata_202609
WHERE STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') < '2026-09-01';


-- Kontrol 5: Eylül'deki 51 satırın ride_id'leri Ağustos tablosunda da var mı?
-- Not: İki tablo önce tarihle daraltıldı; tüm tabloları JOIN'lemek yavaş olurdu.
-- Beklenen: 0 (tekrar yok)
-- Sonuç: ortak_ride_id = 0  ->  51 satır Ağustos'un tekrarı değil, silme gerekçesi yok
SELECT COUNT(*) AS ortak_ride_id
FROM (SELECT ride_id FROM tripdata_202609
      WHERE STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') < '2026-09-01') e
JOIN (SELECT ride_id FROM tripdata_202608
      WHERE STR_TO_DATE(LEFT(started_at,19), '%Y-%m-%d %H:%i:%s') >= '2026-08-31') a
  ON a.ride_id = e.ride_id;


-- Kontrol 6: Eylül tablosu bitiş tarihine göre mi ayrılmış?
-- Hipotez: en_erken_bitis >= 2026-09-01 ise tablolar yolculuğun bittiği aya göre ayrılmış.
-- Sonuç: en_erken_bitis = 2026-09-01 00:00:18 | en_gec_bitis = 2026-09-30 23:59:48
--        Tablodaki hiçbir yolculuk Eylül'den önce bitmemiş; hipotezle uyumlu.
--        Yorum: 31 Ağustos'ta başlayan 51 yolculuk 1 Eylül'de bitmiş ve Eylül tablosuna yazılmış.
--        Sınırlılık: 30 Eylül 2026'da başlayıp Ekim'de biten yolculuklar bizde olmayan tabloda.
SELECT
  MIN(STR_TO_DATE(LEFT(ended_at,19), '%Y-%m-%d %H:%i:%s')) AS en_erken_bitis,
  MAX(STR_TO_DATE(LEFT(ended_at,19), '%Y-%m-%d %H:%i:%s')) AS en_gec_bitis
FROM tripdata_202609;
