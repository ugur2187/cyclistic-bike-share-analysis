-- 09_mevsim_ve_yolculuk_payi.sql
-- Amaç: Casual yolculukların payının mevsime göre değişip değişmediğini sınamak
-- Tarih: 2026-10-20
-- Veri: tripdata_clean (6.007.779 yolculuk, 10/2025 - 09/2026)
-- Not: Ölçülen şey YOLCULUK payıdır, kullanıcı payı değil (kullanıcı kimliği yok). Tek yıllık veri olduğu için
--      mevsim etkisi o yıla özgü etkilerden ayrılamaz. Hava durumu verisi yok: "sıcaklık yüzünden" denemez,
--      yalnızca "sıcak aylarda daha yüksek" denir.


-- ---------------------------------------------------------------------------
-- HİPOTEZ (sonuçlar görülmeden yazıldı)
--   Hipotez: İlkbahar ve yaz aylarında casual yolculukların payı diğer aylara göre daha yüksek olacak.
--   Sıcak dönem: Mayıs, Haziran, Temmuz, Ağustos 2026
--   Eşik: "en az %15'lik artış". Puan olarak okunursa 15 puanlık fark; göreli okunursa sıcak dönem payının
--         diğer dönemin payından en az %15 yüksek olması. (Okuma sonuçlar görülmeden yazılı olarak netleştirilmediyse
--         bu dosyada her iki okuma da raporlanır; ana okuma olarak puan farkı kullanıldı.)
--   Çürütme koşulu: Casual payı sıcak aylarda yüksek değilse ya da fark çok küçükse hipotez desteklenmez.


-- ---------------------------------------------------------------------------
-- Kontrol 1: Sıcak dönem ile kalan 8 ayın karşılaştırması
-- Beklenen: Sıcak dönemde casual payı diğer dönemden en az 15 puan yüksek (sayısal tahmin kaydedilmedi)
-- Sonuç: sıcak (Mayıs-Ağustos) | toplam 3069611 | casual 1214314 | %39,6
--        diğer (8 ay)          | toplam 2938168 | casual 896264  | %30,5
-- Yorum: Fark yaklaşık 9 puan. Yön hipotezle tutuyor, büyüklük 15 puanlık eşiğe ulaşmadı.
--        Göreli okumada sıcak dönem payı diğerinden yaklaşık %30 yüksek (elle hesaplandı).
--        Pay = toplam casual / toplam yolculuk olarak hesaplandı; aylık yüzdelerin ortalaması kullanılmadı
--        (138 bin ile 846 bin yolculuklu aylar eşit sayılmasın diye).
--        Toplam kontrolü: 3069611 + 2938168 = 6007779 (tripdata_clean ile tutuyor).
SELECT CASE WHEN start_month IN ('2026-05','2026-06','2026-07','2026-08')
            THEN 'sicak (Mayis-Agustos)' ELSE 'diger (8 ay)' END AS donem,
       COUNT(*) AS toplam,
       SUM(member_casual = 'casual') AS casual,
       ROUND(SUM(member_casual = 'casual') / COUNT(*) * 100, 1) AS casual_yuzde
FROM tripdata_clean
GROUP BY donem;


-- ---------------------------------------------------------------------------
-- Kontrol 2: Casual payı ay ay
-- Beklenen: (çalıştırmadan önce yazdığın tahmini ekle: en yüksek ve en düşük ay)
-- Sonuç (start_month | toplam | casual | casual_yuzde):
--   2025-10 | 628542 | 214407 | 34.1
--   2025-11 | 346670 | 94729  | 27.3
--   2025-12 | 136475 | 27094  | 19.9
--   2026-01 | 133758 | 23880  | 17.9
--   2026-02 | 197331 | 40077  | 20.3
--   2026-03 | 308513 | 84824  | 27.5
--   2026-04 | 435520 | 127035 | 29.2
--   2026-05 | 635456 | 235900 | 37.1
--   2026-06 | 741465 | 297273 | 40.1
--   2026-07 | 846090 | 345591 | 40.8
--   2026-08 | 846600 | 335550 | 39.6
--   2026-09 | 751359 | 284218 | 37.8
-- Yorum: Toplamlar tutuyor (6007779 yolculuk, 2110578 casual). Casual payı kademeli bir mevsim eğrisi izliyor:
--        en düşük Ocak %17,9, en yüksek Temmuz %40,8 (yaklaşık 23 puan fark). Eğri bir basamak değil:
--        Aralık-Şubat %18-20, Mart-Nisan %27-29, Mayıs-Ağustos %37-41.
--        Eylül (%37,8) Mayıs'a (%37,1) yaklaşık eşit; Ekim (%34,1) Mart ve Nisan'ın belirgin üstünde.
SELECT start_month,
       COUNT(*) AS toplam,
       SUM(member_casual = 'casual') AS casual,
       ROUND(SUM(member_casual = 'casual') / COUNT(*) * 100, 1) AS casual_yuzde
FROM tripdata_clean
GROUP BY start_month
ORDER BY start_month;


-- ---------------------------------------------------------------------------
-- Kontrol 3 (KEŞİF AMAÇLI, SONUÇLAR GÖRÜLDÜKTEN SONRA; ana sonucun yerine geçmez): Sıcak dönem tanımı genişletilirse?
-- Elle hesaplanan değerler (sorgu henüz çalıştırılmadı):
--   Sıcak = Mayıs-Ekim: sıcak %38,5 (1712939 / 4449512) | diğer %25,5 (397639 / 1558267) | fark yaklaşık 13 puan
--   Sıcak = Mayıs-Eylül: fark yaklaşık 11 puan
-- Yorum: İki genişletmede de fark 15 puanın altında kalıyor. Bu hesaplar duyarlılık analizi olarak yazılır;
--        sıcak dönemi sonuçtan sonra değiştirip eşiği karşıladığını söylemek hipotezi veriye uydurmak olur.
-- Sonuç: donem, toplam, casual, casual_yuzde
--   sicak (Mayis-Ekim), 4449512, 1712939, 38.5
--  diger (Kasim-Nisan), 1558267, 397639, 25.5

SELECT CASE WHEN start_month IN ('2025-10','2026-05','2026-06','2026-07','2026-08','2026-09')
            THEN 'sicak (Mayis-Ekim)' ELSE 'diger (Kasim-Nisan)' END AS donem,
       COUNT(*) AS toplam,
       SUM(member_casual = 'casual') AS casual,
       ROUND(SUM(member_casual = 'casual') / COUNT(*) * 100, 1) AS casual_yuzde
FROM tripdata_clean
GROUP BY donem;


-- ---------------------------------------------------------------------------
-- Kontrol 4: Member ve casual yolculuk sayısı ay ay
-- Elle hesaplanan değerler: Ocak 2026'da casual 23880, member 109878; Temmuz 2026'da casual 345591, member 500499
--   Ocak'tan Temmuz'a casual yaklaşık 14,5 kat, member yaklaşık 4,6 kat arttı.
-- Sonuç: start_month, member_yolculuk, casual_yolculuk
-- '2025-10', '414135', '214407'
-- '2025-11', '251941', '94729'
-- '2025-12', '109381', '27094'
-- '2026-01', '109878', '23880'
-- '2026-02', '157254', '40077'
-- '2026-03', '223689', '84824'
-- '2026-04', '308485', '127035'
-- '2026-05', '399556', '235900'
-- '2026-06', '444192', '297273'
-- '2026-07', '500499', '345591'
-- '2026-08', '511050', '335550'
-- '2026-09', '467141', '284218'

SELECT start_month,
       SUM(member_casual = 'member') AS member_yolculuk,
       SUM(member_casual = 'casual') AS casual_yolculuk
FROM tripdata_clean
GROUP BY start_month
ORDER BY start_month;


-- ---------------------------------------------------------------------------
-- SONUÇ ÖZETİ
--   Ana sonuç: Casual payı sıcak aylarda daha yüksek (yaklaşık 9 puan); önceden belirlenen 15 puanlık eşiğe ulaşılmadı.
--   Ek bulgu: Pay kademeli bir mevsim eğrisi izliyor (Ocak %17,9 - Temmuz %40,8).
--   Ek bulgu (elle hesaplandı): Casual kullanım member kullanımından çok daha mevsimsel
--             (Ocak-Temmuz arasında casual yaklaşık 14,5 kat, member yaklaşık 4,6 kat arttı).
--   Sınırlar: yolculuk payı (kullanıcı payı değil); tek yıl; hava durumu verisi yok.
