-- 12_bisiklet_tipi.sql

-- Kontrol 1: Bisiklet tipi dağılımı
-- Sonuç: member_casual, rideable_type, yolculuk, yuzde
-- 'casual', 'classic_bike', '544453', '25.8'
-- 'casual', 'electric_bike', '1566125', '74.2'
-- 'member', 'classic_bike', '1234604', '31.7'
-- 'member', 'electric_bike', '2662597', '68.3'

SELECT member_casual, rideable_type, COUNT(*) AS yolculuk,
       ROUND(COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY member_casual) * 100, 1) AS yuzde
FROM tripdata_clean
GROUP BY member_casual, rideable_type
ORDER BY member_casual, rideable_type;

-- Kontrol 2: Aylık elektrikli bisiklet payı

SELECT start_month,
       ROUND(SUM(member_casual = 'member' AND rideable_type = 'electric_bike') / SUM(member_casual = 'member') * 100, 1) AS member_elektrik_yuzde,
       ROUND(SUM(member_casual = 'casual' AND rideable_type = 'electric_bike') / SUM(member_casual = 'casual') * 100, 1) AS casual_elektrik_yuzde
FROM tripdata_clean
GROUP BY start_month
ORDER BY start_month;