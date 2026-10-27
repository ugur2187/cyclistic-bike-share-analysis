-- 10_yolculuk_suresi.sql
-- Amaç: Üye ve casual yolculuk sürelerini ortalama ve medyan olarak karşılaştırmak
-- Tarih: 2026-10-20
-- Veri: tripdata_clean (6.007.779 yolculuk; süre 1,00 dk ile 1439,97 dk arası; ride_length_min saniyeden dakikaya çevrilip 2 haneye yuvarlandı)
-- Not: MySQL 8.0.46; pencere fonksiyonları kullanılabilir (medyan için gerekli).
--      Süre filtresinin sınırları (60 sn, 24 saat) bulgu değil, filtrenin izidir.


-- ---------------------------------------------------------------------------
-- Kontrol 1: Ortalama ve uç değerler
-- Beklenen: (çalıştırmadan önce yazdığın tahmini ekle: hangi grubun ortalaması uzun, fark kaç dakika?)
-- Sonuç: member 3897201 satır | ortalama 12,17 dk | en_kisa 1,00 | en_uzun 1439,90
--        casual 2110578 satır | ortalama 18,17 dk | en_kisa 1,00 | en_uzun 1439,97
-- Yorum: Satır toplamı tutuyor (3897201 + 2110578 = 6007779); casual sayısı 09 dosyasıyla aynı.
--        Casual ortalaması member'ın yaklaşık %49 üstünde (6,00 dk).
--        Ortalama uç değerlerden etkilenir; medyan Kontrol 2'de.
SELECT member_casual,
       COUNT(*) AS satir,
       ROUND(AVG(ride_length_min), 2) AS ortalama_dk,
       MIN(ride_length_min) AS en_kisa_dk,
       MAX(ride_length_min) AS en_uzun_dk
FROM tripdata_clean
GROUP BY member_casual;


-- ---------------------------------------------------------------------------
-- Kontrol 2: Medyan süre
-- Yöntem: Her grubun sürelerini küçükten büyüğe sırala, ortadaki satırı al; satır sayısı çiftse ortadaki iki değerin ortalaması.
-- Beklenen: (çalıştırmadan önce yazdığın tahmini ekle: medyan ortalamanın üstünde mi altında mı?)
-- Sonuç: casual 11,13 dk | member 8,68 dk
-- Yorum: Medyan iki grupta da ortalamanın altında; dağılım sağa çarpık (çoğu yolculuk kısa, az sayıda uzun yolculuk
--        ortalamayı yukarı çekiyor).
--        Casual - member farkı: ortalamada 6,00 dk (%49), medyanda 2,45 dk (%28) (elle hesaplandı).
--        Ortalama - medyan mesafesi: casual'da 7,04 dk, member'da 3,49 dk (elle hesaplandı); casual'da uzun yolculuk
--        kuyruğunun daha ağır olduğu düşünülüyor (sınanmadı, Kontrol 3'te ölçülecek).
--        Karıştıran etkenler (bisiklet tipi, mevsim) henüz kontrol edilmedi.
SELECT member_casual,
       ROUND(AVG(ride_length_min), 2) AS medyan_dk
FROM (
  SELECT member_casual, ride_length_min,
         ROW_NUMBER() OVER (PARTITION BY member_casual ORDER BY ride_length_min) AS sira,
         COUNT(*)     OVER (PARTITION BY member_casual) AS adet
  FROM tripdata_clean
) x
WHERE sira IN (FLOOR((adet + 1) / 2), CEIL((adet + 1) / 2))
GROUP BY member_casual;


-- ---------------------------------------------------------------------------
-- Kontrol 3: Uzun yolculukların payı
-- Eşikler sonuçlar görülmeden belirlendi: 30, 60 ve 180 dakika.
-- Hipotez: Casual'da uzun yolculukların payı member'dan daha yüksek.
-- Sonuç: member_casual, toplam, yuzde_30_ustu, yuzde_60_ustu, yuzde_180_ustu
--             'member', '3897201', '5.38', '0.66', '0.11'
--             'casual', '2110578', '13.31', '3.89', '0.28'

-- Yorum:  Hipotez destekleniyor. Üç eşikte de casual'da uzun yolculukların payı member'dan yüksek
--        (30 dk üstü yaklaşık 2,5 kat, 60 dk üstü yaklaşık 5,9 kat, 180 dk üstü yaklaşık 2,5 kat; elle hesaplandı).
--        Fark en çok 60 dakikada; nedeni bilinmiyor. 180 dk oranı yuvarlanmış yüzdelerden hesaplandığı için yaklaşık.
--        Mutlak sayıda (yaklaşık, yuvarlanmış yüzdelerden) 60 dk üstü yolculuk member'da ~26 bin, casual'da ~82 bin.
--        Kaba hesap: 60 dk üstü yolculuklar ortalamaya en az 2,3 dk (casual) ve 0,4 dk (member) katkı yapar;
--        6 dk'lık ortalama farkının en az yaklaşık üçte biri bu kuyruktan gelebilir (alt sınır).
--        Sınır: Bisiklet tipi ve mevsim etkisi kontrol edilmedi; ölçülen şey yolculuktur, kullanıcı değil.
SELECT member_casual,
       COUNT(*) AS toplam,
       ROUND(SUM(ride_length_min > 30)  / COUNT(*) * 100, 2) AS yuzde_30_ustu,
       ROUND(SUM(ride_length_min > 60)  / COUNT(*) * 100, 2) AS yuzde_60_ustu,
       ROUND(SUM(ride_length_min > 180) / COUNT(*) * 100, 2) AS yuzde_180_ustu
FROM tripdata_clean
GROUP BY member_casual;


-- ---------------------------------------------------------------------------
-- SONUÇ ÖZETİ
--   Casual yolculukları hem tipik olarak biraz daha uzun (medyan farkı 2,45 dk, yaklaşık %28)
--   hem de ortalamada belirgin daha uzun (6,00 dk, yaklaşık %49); ortalama farkının bir kısmı uzun kuyruktan gelebilir.
--   Sınırlar: Bisiklet tipi (casual yolculuklarda elektrikli payı daha yüksek) ve mevsim (casual yazın yoğun) etkileri
--   kontrol edilmedi; "casual kullanıcılar daha uzun biniyor" demek için bu etkenlerin sınanması gerekir.
--   Ölçülen şey yolculuk süresidir, kullanıcı davranışı değil.

-- Kontrol 4: Süre farkı bisiklet tipinin içinde de sürüyor mu?
-- Amaç: Casual ile member arasındaki süre farkının bisiklet tipinden kaynaklanıp kaynaklanmadığını görmek
--       (casual yolculuklarda elektrikli payı daha yüksek).
-- Sonuç (member_casual | rideable_type | toplam | ortalama_dk | yuzde_60_ustu):
--               casual | classic_bike  | 544453  | 28,59 | 9,13
--               member | classic_bike  | 1234604 | 13,92 | 0,73
--               casual | electric_bike | 1566125 | 14,54 | 2,07
--               member | electric_bike | 2662597 | 11,36 | 0,62
-- Yorum: Casual her iki bisiklet tipinde de member'dan daha uzun; fark bisiklet tipinden kaynaklanmıyor.
--        Fark klasikte 14,67 dk (yaklaşık 2,1 kat), elektrikte 3,18 dk (yaklaşık 1,3 kat) (elle hesaplandı).
--        60 dk üstü yolculuk payı klasikte casual %9,13 / member %0,73 (yaklaşık 12,5 kat), elektrikte %2,07 / %0,62 (yaklaşık 3,3 kat).
--        Casual'ın 60 dk üstü yolculuklarının yaklaşık %60'ı klasik bisiklette (casual yolculukların %26'sı klasik).
--        Casual yolculukların %74,2'si elektrikli, member'larda %68,3; casual member'ın bisiklet karışımına sahip olsaydı
--        ortalama farkı yaklaşık 6,8 dk olurdu (yaklaşık, elle hesaplandı): karışım farkı açıklamıyor.
--        Sınır: Neden bilinmiyor; mevsim kontrol edilmedi; ortalama uzun kuyruktan etkileniyor olabilir.

SELECT member_casual, rideable_type,
       COUNT(*) AS toplam,
       ROUND(AVG(ride_length_min), 2) AS ortalama_dk,
       ROUND(SUM(ride_length_min > 60) / COUNT(*) * 100, 2) AS yuzde_60_ustu
FROM tripdata_clean
GROUP BY member_casual, rideable_type
ORDER BY rideable_type, member_casual;

-- Kontrol 5: Medyan süre, bisiklet tipine göre
-- Beklenen: (çalıştırmadan önce yazdığın tahmini ekle)
-- Sonuç (member_casual | rideable_type | medyan_dk):
--   casual | classic_bike  | 15,55
--   member | classic_bike  | 9,17
--   casual | electric_bike | 10,08
--   member | electric_bike | 8,50
-- Yorum: Casual klasikte medyan (15,55) ortalamanın (28,59) yaklaşık %54'ü; ortalama uzun kuyruktan şişmiş.
--        Ortalama - medyan: casual klasik 13,04 | member klasik 4,75 | casual elektrik 4,46 | member elektrik 2,86 dk (elle hesaplandı).
--        Casual medyanda da daha uzun: klasikte 6,38 dk (yaklaşık 1,7 kat), elektrikte 1,58 dk (yaklaşık 1,19 kat).
--        Fark yalnızca kuyruktan gelmiyor, tipik yolculuk da casual'da daha uzun. Fark klasikte yoğunlaşıyor; nedeni bilinmiyor.
--        Sınır: Mevsim kontrol edilmedi.
SELECT member_casual, rideable_type,
       ROUND(AVG(ride_length_min), 2) AS medyan_dk
FROM (
  SELECT member_casual, rideable_type, ride_length_min,
         ROW_NUMBER() OVER (PARTITION BY member_casual, rideable_type ORDER BY ride_length_min) AS sira,
         COUNT(*)     OVER (PARTITION BY member_casual, rideable_type) AS adet
  FROM tripdata_clean
) x
WHERE sira IN (FLOOR((adet + 1) / 2), CEIL((adet + 1) / 2))
GROUP BY member_casual, rideable_type
ORDER BY rideable_type, member_casual;


-- Kontrol 6: Ortalama süre, sıcak dönem ve diğer dönem
-- Sonuç (donem | member_casual | toplam | ortalama_dk):
--   diger  | casual | 896264  | 16,89      sicak | casual | 1214314 | 19,11
--   diger  | member | 2041904 | 11,76      sicak | member | 1855297 | 12,63
-- Yorum: Toplamlar tutuyor (dönem toplamları 2938168 ve 3069611; 09 dosyasıyla aynı).
--        Ortalama farkı (casual - member): diğer 8 ay 5,13 dk, sıcak dönem 6,48 dk (elle hesaplandı).

SELECT CASE WHEN start_month IN ('2026-05','2026-06','2026-07','2026-08')
            THEN 'sicak (Mayis-Agustos)' ELSE 'diger (8 ay)' END AS donem,
       member_casual,
       COUNT(*) AS toplam,
       ROUND(AVG(ride_length_min), 2) AS ortalama_dk
FROM tripdata_clean
GROUP BY donem, member_casual
ORDER BY donem, member_casual;


-- Kontrol 7: Medyan süre, sıcak dönem ve diğer dönem
-- Sonuç (donem | member_casual | medyan_dk):
--   diger | casual 10,08 | diger | member 8,18 | sicak | casual 11,97 | sicak | member 9,27
-- Yorum: Casual her iki dönemde de daha uzun; medyan farkı diğer 8 ayda 1,90 dk (yaklaşık 1,23 kat), sıcak dönemde 2,70 dk
--        (yaklaşık 1,29 kat). Mevsim farkın nedeni değil, farkı büyütüyor. Casual'ın süresi yazın daha çok uzuyor:
--        ortalama +%13 (member +%7), medyan +%19 (member +%13) (elle hesaplandı).
--        Sınır: Bisiklet tipi ve mevsim birlikte kontrol edilmedi; hava durumu verisi yok.

SELECT donem, member_casual,
       ROUND(AVG(ride_length_min), 2) AS medyan_dk
FROM (
  SELECT donem, member_casual, ride_length_min,
         ROW_NUMBER() OVER (PARTITION BY donem, member_casual ORDER BY ride_length_min) AS sira,
         COUNT(*)     OVER (PARTITION BY donem, member_casual) AS adet
  FROM (
    SELECT CASE WHEN start_month IN ('2026-05','2026-06','2026-07','2026-08')
                THEN 'sicak (Mayis-Agustos)' ELSE 'diger (8 ay)' END AS donem,
           member_casual, ride_length_min
    FROM tripdata_clean
  ) t
) x
WHERE sira IN (FLOOR((adet + 1) / 2), CEIL((adet + 1) / 2))
GROUP BY donem, member_casual
ORDER BY donem, member_casual;



-- Casual yolculukları member'dan hem ortalamada hem medyanda uzun. 
-- Bu fark her iki bisiklet tipinde (klasikte çok daha büyük) ve her iki mevsim diliminde sürüyor. 
-- Mevsim farkı büyütüyor, bisiklet tipi ve mevsim birlikte kontrol edilmedi.
