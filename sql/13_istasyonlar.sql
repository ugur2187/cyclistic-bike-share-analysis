-- 13_istasyonlar.sql

-- Kontrol 1: İstasyon bilgisi kapsamı
-- Sonuç: member 3897201 toplam, 3126829 istasyonlu (%80,2) | casual 2110578 toplam, 1678712 istasyonlu (%79,5)
-- Sınırlılık: İstasyon analizi yalnızca başlangıç istasyonu bilgisi olan yolculukları kapsar (%80,0).
--   Dışarıda kalan yaklaşık %20'lik kısım elektrikli bisiklet; elektrikli yolculukların yaklaşık %29-30'u dışarıda.
--   Sonuçlar klasik bisiklet kullanımına doğru kayabilir. Dışarıda kalanların başlangıç noktaları bilinmediği için
--   sonuçların nasıl değişeceği bilinmiyor.

SELECT member_casual,
       COUNT(*) AS toplam,
       SUM(start_station_name IS NOT NULL) AS istasyonlu,
       ROUND(SUM(start_station_name IS NOT NULL) / COUNT(*) * 100, 1) AS yuzde
FROM tripdata_clean
GROUP BY member_casual;

-- Kontrol 2: Her grubun en çok kullandığı 10 başlangıç istasyonu
-- Hipotez: önceden yazılmadı (keşif amaçlı)
-- Sonuç: İlk 10'da ortak istasyon yok.
--   Casual: Navy Pier 49562 | DuSable Lake Shore Dr & Monroe St 28570 | Michigan Ave & Oak St 20662 | DuSable Lake Shore Dr & North Blvd 16932
--     Millennium Park 16837 | Shedd Aquarium 16059 | Theater on the Lake 14757 | Dusable Harbor 13630 | Field Museum 10024 | Adler Planetarium 9994
--   Member: Canal St & Madison St 22697 | State St & Chicago Ave 22162 | Clinton St & Jackson Blvd 19876 | Wells St & Elm St 19180
--     Wells St & Concord Ln 19049 | Clinton St & Madison St 18529 | Kingsbury St & Kinzie St 2 18137 | Wells St & Hubbard St 17773
--     Wells St & Huron St 17328 | Clinton St & Washington Blvd 2 17308
-- Yorum: Casual'ın ilk 10'u turistik yerler ve göl kıyısı gibi görünüyor, member'ınki cadde kesişimleri (adlardan yorum, konumlar doğrulanmadı).
--   İlk 10'un payı casual %11,7, member %6,1 (elle hesaplandı): casual kullanım daha yoğunlaşmış.
--   Sınır: Kapsam %80 (dışarıdaki yolculuklar elektrikli); 12 aylık toplam, mevsim ayrılmadı.

SELECT member_casual, sira, start_station_name, yolculuk
FROM (
  SELECT member_casual, start_station_name, COUNT(*) AS yolculuk,
         ROW_NUMBER() OVER (PARTITION BY member_casual ORDER BY COUNT(*) DESC) AS sira
  FROM tripdata_clean
  WHERE start_station_name IS NOT NULL
  GROUP BY member_casual, start_station_name
) x
WHERE sira <= 10
ORDER BY member_casual, sira;


-- Kontrol 3: İki istasyon bilgisi olan yolculuk kapsamı
-- Sonuç: member 3897201 toplam, 2653071 iki istasyon var (%68,1) | casual 2110578 toplam, 1396540 iki istasyon var (%66,2)
-- Sınırlılık: Gidiş-dönüş analizi yalnızca başlangıç ve bitiş istasyonu dolu yolculukları kapsar (yaklaşık %67).

SELECT member_casual,
       COUNT(*) AS toplam,
       SUM(start_station_id IS NOT NULL AND end_station_id IS NOT NULL) AS iki_istasyon_var,
       ROUND(SUM(start_station_id IS NOT NULL AND end_station_id IS NOT NULL) / COUNT(*) * 100, 1) AS yuzde
FROM tripdata_clean
GROUP BY member_casual;


-- Kontrol 4: Gidiş-dönüş payı (başlangıç ve bitiş istasyonu aynı)
-- Hipotez: Casual'da gidiş-dönüş payı member'dan yüksek olacak.
-- Eşik: Casual payı member payının en az 1,5 katı
-- Çürütme koşulu: Casual payı member'a eşit ya da düşükse çürür; yüksek ama 1,5 katın altındaysa desteklenmedi.
-- Sonuç: member 2653071 iki istasyonlu, 58613 gidiş-dönüş (%2,21) | casual 1396540 iki istasyonlu, 103556 gidiş-dönüş (%7,42)
-- Yorum: Hipotez destekleniyor; casual payı member'ın yaklaşık 3,4 katı (eşik 1,5), fark 5,2 puan (elle hesaplandı).
--   Casual, gidiş-dönüş yolculukların yaklaşık %64'ü, iki istasyonlu yolculukların yaklaşık %34'ü.
--   Sınır: Kapsam yaklaşık %67; neden (turistik bölge) sınanmadı.

SELECT member_casual,
       COUNT(*) AS iki_istasyon_var,
       SUM(start_station_id = end_station_id) AS gidis_donus,
       ROUND(SUM(start_station_id = end_station_id) / COUNT(*) * 100, 2) AS yuzde
FROM tripdata_clean
WHERE start_station_id IS NOT NULL AND end_station_id IS NOT NULL
GROUP BY member_casual;

-- Kontrol 5: Gidiş-dönüş yolculukların en çok görüldüğü 10 başlangıç istasyonu
-- Hipotez (çalıştırılmadan önce yazıldı): Casual'ın gidiş-dönüş ilk 10 istasyonu, Kontrol 2'deki casual ilk 10 ile örtüşecek.
-- Eşik: En az 5 ortak istasyon (10 üzerinden)
-- Çürütme koşulu: 5'in altında ortak istasyon varsa örtüşmüyor.
-- Sonuç: Casual gidiş-dönüş ilk 10: Navy Pier 9162 | DuSable Lake Shore Dr & Monroe St 5371 | Michigan Ave & Oak St 3485 | Millennium Park 2201
--     Dusable Harbor 2119 | Shedd Aquarium 1571 | Adler Planetarium 1433 | Montrose Harbor 1400
--     DuSable Lake Shore Dr & North Blvd 1370 | Michigan Ave & 8th St 1316
--   Member gidiş-dönüş ilk 10: Navy Pier 884 | Clarendon Ave & Gordon Ter 615 | Loomis St & Lexington St 583 | Montrose Harbor 560
--     Marine Dr & Ainslie St 429 | Sheridan Rd & Columbia Ave 416 | Michigan Ave & Oak St 383 | Indiana Ave & Roosevelt Rd 374
--     McClurg Ct & Ohio St 369 | Shore Dr & 55th St 352
-- Yorum: Hipotez destekleniyor; 8 / 10 ortak istasyon (eşik 5).
--   İlk 10'un gidiş-dönüş payı casual %28,4, member %8,5 (elle hesaplandı); Navy Pier casual %8,8, member %1,5.
--   Member'ın gidiş-dönüş ilk 10'unda Kontrol 2'deki member ilk 10 ile ortak istasyon yok; casual ve member gidiş-dönüş listelerinde 3 ortak istasyon var.
--   Sınır: Konum yorumları istasyon adlarından, doğrulanmadı; kapsam yaklaşık %67.


SELECT member_casual, sira, start_station_name, gidis_donus
FROM (
  SELECT member_casual, start_station_name, COUNT(*) AS gidis_donus,
         ROW_NUMBER() OVER (PARTITION BY member_casual ORDER BY COUNT(*) DESC) AS sira
  FROM tripdata_clean
  WHERE start_station_id IS NOT NULL AND end_station_id IS NOT NULL
    AND start_station_id = end_station_id
  GROUP BY member_casual, start_station_name
) x
WHERE sira <= 10
ORDER BY member_casual, sira;