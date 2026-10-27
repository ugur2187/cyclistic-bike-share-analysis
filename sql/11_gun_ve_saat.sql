-- 11_gun_ve_saat.sql
-- Amaç: Üye ve casual yolculukların haftanın gününe ve günün saatine göre dağılımını karşılaştırmak
-- Veri: tripdata_clean (6.007.779 yolculuk); day_num = WEEKDAY(started_at): 0 Pazartesi ... 6 Pazar
-- Not: Yüzdeler her grubun kendi toplamına göre. Ölçülen şey yolculuktur, kullanıcı değil.
--
-- Hipotez: Casual yolculukların Cuma, Cumartesi ve Pazar günlerindeki payı member'ınkinden yüksek.
-- Kontrol 1: Haftanın gününe göre yolculuk sayısı ve yüzdesi
-- Sonuç: day_num, day_of_week, member_yolculuk, casual_yolculuk, member_yuzde, casual_yuzde
-- '0', 'Monday', '543987', '242923', '14.0', '11.5'
-- '1', 'Tuesday', '627746', '241587', '16.1', '11.4'
-- '2', 'Wednesday', '631387', '246760', '16.2', '11.7'
-- '3', 'Thursday', '615088', '263159', '15.8', '12.5'
-- '4', 'Friday', '572567', '331232', '14.7', '15.7'
-- '5', 'Saturday', '497133', '447337', '12.8', '21.2'
-- '6', 'Sunday', '409293', '337580', '10.5', '16.0'
-- Yorum: Casual yolculukların %52,9'u, member yolculuklarının %38,0'ı Cuma-Pazar'a düşüyor (yaklaşık 15 puan fark; elle hesaplandı).
--        Casual yolculuk sayısı hiçbir günde member'ı geçmiyor (Cumartesi 447 bin casual, 497 bin member).
--        Fark neredeyse tamamen Cumartesi-Pazar'dan geliyor (+13,9 puan); Cuma yalnızca +1,0 puan.
--        Sınır: Mevsim etkisi kontrol edilmedi.

SELECT day_num, day_of_week,
       SUM(member_casual = 'member') AS member_yolculuk,
       SUM(member_casual = 'casual') AS casual_yolculuk,
       ROUND(SUM(member_casual = 'member') / (SELECT COUNT(*) FROM tripdata_clean WHERE member_casual = 'member') * 100, 1) AS member_yuzde,
       ROUND(SUM(member_casual = 'casual') / (SELECT COUNT(*) FROM tripdata_clean WHERE member_casual = 'casual') * 100, 1) AS casual_yuzde
FROM tripdata_clean
GROUP BY day_num, day_of_week
ORDER BY day_num;

-- Kontrol 2

SELECT CASE WHEN day_num <= 3 THEN '1) Pazartesi-Persembe'
            WHEN day_num = 4  THEN '2) Cuma'
            ELSE '3) Cumartesi-Pazar' END AS gun_grubu,
       ROUND(SUM(member_casual = 'member') / (SELECT COUNT(*) FROM tripdata_clean WHERE member_casual = 'member') * 100, 1) AS member_yuzde,
       ROUND(SUM(member_casual = 'casual') / (SELECT COUNT(*) FROM tripdata_clean WHERE member_casual = 'casual') * 100, 1) AS casual_yuzde
FROM tripdata_clean
GROUP BY gun_grubu
ORDER BY gun_grubu;

-- Kontrol 3: Hafta içi (Pzt-Cuma) saatlik dağılım
-- Beklenen: (çalıştırmadan önce yazdığın tahmini ekle)
-- Sonuç: 24 satır; toplamlar member 2990775, casual 1325661 (gün bazlı tablodan beklenenle tutuyor).
--   Member: sabah tepesi saat 8 (%8,4; komşular 06: %3,4, 10: %3,2), akşam tepesi saat 17 (%11,9; komşular 15: %6,3, 19: %6,1).
--   Casual: sabah tepesi saat 8 (%4,4; komşular 06: %1,8, 10: %3,3), akşam tepesi saat 17 (%10,8; komşular 15: %6,8, 19: %7,0).
-- Yorum (tepe tanımına göre): Member'da iki tepe var (hipotez destekleniyor). Casual'da da iki tepe var;
--        hipotezin "casual'da bu iki tepe görülmeyecek" kısmı çürüdü.
--        Keşif amaçlı (kural dışı, sonuç görüldükten sonra): Casual'ın sabah tepesi zayıf (%4,4; öğle ortalaması %5,1'in altında;
--        member'da sabah tepesi öğle ortalamasının yaklaşık 2 katı). Sabah penceresi payı member %19,6, casual %10,9;
--        akşam penceresi payı member %30,8, casual %29,1. Fark sabahta.
--        Zamanlama yolculuğun amacını göstermez; "ulaşım aracı" ve "toplu taşımaya alternatif" bu veriyle söylenemez.

SELECT start_hour,
       SUM(member_casual = 'member') AS member_yolculuk,
       SUM(member_casual = 'casual') AS casual_yolculuk,
       ROUND(SUM(member_casual = 'member') / (SELECT COUNT(*) FROM tripdata_clean WHERE member_casual = 'member' AND day_num <= 4) * 100, 1) AS member_yuzde,
       ROUND(SUM(member_casual = 'casual') / (SELECT COUNT(*) FROM tripdata_clean WHERE member_casual = 'casual' AND day_num <= 4) * 100, 1) AS casual_yuzde
FROM tripdata_clean
WHERE day_num <= 4
GROUP BY start_hour
ORDER BY start_hour;

-- Kontrol 4: Hafta sonu (Cmt-Paz) saatlik dağılım, kontrol grubu
-- Beklenen: Sabah ve akşam tepesi yok, öğleden sonra geniş tek bir plato
-- Sonuç: Toplamlar member 906426, casual 784917 (tutuyor). Tepe kuralına göre iki grupta da sabah ve akşam tepesi yok.
--        En yüksek saat 15 (member %7,8, casual %8,5), plato 11-16.
--        Pencere payları hafta içi → hafta sonu: member sabah %19,6 → %10,0, akşam %30,8 → %21,9;
--        casual sabah %10,9 → %6,9, akşam %29,1 → %21,4.
-- Yorum: Tepeler hafta içine özgü. Zamanlama işe gidiş-gelişle uyumlu, amaç veride yok.

SELECT start_hour,
       SUM(member_casual = 'member') AS member_yolculuk,
       SUM(member_casual = 'casual') AS casual_yolculuk,
       ROUND(SUM(member_casual = 'member') / (SELECT COUNT(*) FROM tripdata_clean WHERE member_casual = 'member' AND day_num >= 5) * 100, 1) AS member_yuzde,
       ROUND(SUM(member_casual = 'casual') / (SELECT COUNT(*) FROM tripdata_clean WHERE member_casual = 'casual' AND day_num >= 5) * 100, 1) AS casual_yuzde
FROM tripdata_clean
WHERE day_num >= 5
GROUP BY start_hour
ORDER BY start_hour;


