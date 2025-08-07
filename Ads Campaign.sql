
--I. Làm sạch dữ liệu
--1/ Tách cột [Target_Audience] ra thành Gender và  Age_Range
SELECT 
    -- Lấy giới tính: từ đầu chuỗi đến khoảng trắng đầu tiên
    LEFT(Target_Audience, CHARINDEX('n', Target_Audience)) AS Gender,

    -- Lấy độ tuổi: từ khoảng trắng đầu tiên đến hết chuỗi
    LTRIM(RIGHT(Target_Audience, LEN(Target_Audience) - CHARINDEX('n', Target_Audience))) AS Age_Range
FROM 
    marketing1

-- 2/ Update lại bảng Marketing1
Alter table Marketing1
	add Gender varchar(10),Age_Range varchar(10)

update Marketing1
	set Gender =
			LEFT(Target_Audience, CHARINDEX('n', Target_Audience)),
		Age_Range = 
			LTRIM(RIGHT(Target_Audience, LEN(Target_Audience) - CHARINDEX('n', Target_Audience)))
			from Marketing1

Alter table Marketing1
	Drop column [Target_Audience]

-- 3/ Update lại cột Duration
SELECT 
REPLACE([Duration],'Days','')
from marketing1

Alter table Marketing1
 add Durations float(10)

update Marketing1
	set Durations =
					REPLACE([Duration],'Days','')
					from marketing1
Alter table Marketing1
 Drop column Duration
--4/ Chuẩn hóa lại kiểu dữ liệu
--4.1/ Xử lý dữ liệu bẩn
DELETE FROM Marketing1
WHERE 
  ISNUMERIC([Clicks]) = 0 OR 
  ISNUMERIC([Impressions]) = 0 OR 
  ISNUMERIC([ROI]) = 0;
--4.2/ Chuẩn hóa kiểu dữ liệu
Update Marketing1
set		[Clicks] = 
    CAST(Clicks AS int),
		[Impressions] =
	CAST(Impressions AS int),
		[ROI] = 
	CAST(REPLACE(REPLACE(ROI, ',', ''), '%', '') as FLOAT),
		[Conversion_Rate] = 
	CAST(REPLACE(REPLACE(Conversion_Rate, ',', ''), '%', '') as FLOAT),
		[Spend] = 
	CAST(REPLACE(REPLACE(Spend, ',', ''), '%', '') as decimal(10,2)),
		[Durations] = 
	CAST([Durations] AS int)
FROM Marketing1;

 --II. Phân tích chiến dịch
 --1/ Phân biệt chiến dịch tốt và xấu
 ALTER TABLE Marketing1
 add CTR float

 UPDATE Marketing1
 set CTR = 
	[Clicks]*1.0/[Impressions]
	from Marketing1
 ALTER TABLE Marketing1
ADD Performance_Rating VARCHAR(10);

UPDATE Marketing1
SET Performance_Rating = 
    CASE
        -- Brand Awareness
        WHEN Campaign_Goal = 'Brand Awareness' AND Customer_Segment = 'Fashion' 
            AND Impressions >= 80000 AND CTR >= 0.25 THEN 'Good'
        WHEN Campaign_Goal = 'Brand Awareness' AND Customer_Segment = 'Fashion' 
            AND (Impressions < 50000 OR CTR < 0.12) THEN 'Bad'

        WHEN Campaign_Goal = 'Brand Awareness' AND Customer_Segment = 'Food' 
            AND Impressions >= 70000 AND CTR >= 0.20 THEN 'Good'
        WHEN Campaign_Goal = 'Brand Awareness' AND Customer_Segment = 'Food' 
            AND (Impressions < 40000 OR CTR < 0.10) THEN 'Bad'

        -- Increase Sales
        WHEN Campaign_Goal = 'Increase Sales' AND Customer_Segment = 'Fashion' 
            AND Conversion_Rate >= 0.12 AND ROI >= 2.5 THEN 'Good'
        WHEN Campaign_Goal = 'Increase Sales' AND Customer_Segment = 'Fashion' 
            AND (Conversion_Rate < 0.07 OR ROI < 1.5) THEN 'Bad'

        WHEN Campaign_Goal = 'Increase Sales' AND Customer_Segment = 'Food' 
            AND Conversion_Rate >= 0.15 AND ROI >= 3 THEN 'Good'
        WHEN Campaign_Goal = 'Increase Sales' AND Customer_Segment = 'Food' 
            AND (Conversion_Rate < 0.08 OR ROI < 1.8) THEN 'Bad'

        -- Market Expansion
        WHEN Campaign_Goal = 'Market Expansion' AND Customer_Segment = 'Fashion' 
            AND Impressions >= 100000 AND ROI >= 2.5 THEN 'Good'
        WHEN Campaign_Goal = 'Market Expansion' AND Customer_Segment = 'Fashion' 
            AND (Impressions < 60000 OR ROI < 1.5) THEN 'Bad'

        WHEN Campaign_Goal = 'Market Expansion' AND Customer_Segment = 'Food' 
            AND Impressions >= 90000 AND ROI >= 2 THEN 'Good'
        WHEN Campaign_Goal = 'Market Expansion' AND Customer_Segment = 'Food' 
            AND (Impressions < 50000 OR ROI < 1.3) THEN 'Bad'

        -- Product Launch
        WHEN Campaign_Goal = 'Product Launch' AND Customer_Segment = 'Fashion' 
            AND Conversion_Rate >= 0.08 AND ROI >= 2.2 THEN 'Good'
        WHEN Campaign_Goal = 'Product Launch' AND Customer_Segment = 'Fashion' 
            AND (Conversion_Rate < 0.05 OR ROI < 1.3) THEN 'Bad'

        WHEN Campaign_Goal = 'Product Launch' AND Customer_Segment = 'Food' 
            AND Conversion_Rate >= 0.10 AND ROI >= 2.5 THEN 'Good'
        WHEN Campaign_Goal = 'Product Launch' AND Customer_Segment = 'Food' 
            AND (Conversion_Rate < 0.06 OR ROI < 1.5) THEN 'Bad'

        -- Mặc định là Bad nếu không khớp điều kiện nào
        ELSE 'Bad'
    END
FROM marketing1

--2/ So sánh hiệu quả giữa các kênh khác nhau 
SELECT
[Channel_Used],
AVG([Conversion_Rate]) as Avg_Conversion_Rate,
AVG([Spend]) as Avg_Spend,
AVG([ROI]) as Avg_ROI,
AVG([Clicks]) as Avg_Clicks,
AVG([Impressions]) as Avg_Impressions,
AVG([CTR]) as Avg_CTR
FROM Marketing1
group by [Channel_Used]
--Nhận xét: 
-- Instagram là kênh hiệu quả nhất với ROI cao nhất (4.03), lượt click nhiều nhất (20,296) và CTR tốt (0.3212).
-- Facebook có tỷ lệ chuyển đổi cao nhất (7.35%) nhưng ROI thấp hơn (3.97).
-- Pinterest có ROI thấp nhất (0.73) dù chi phí cao (7,829.96) → cần cân nhắc lại hiệu quả đầu tư.

-- 3/ Đánh giá kênh nào hiện đang phù hợp với các ngành hàng
SELECT
[Channel_Used],
[Customer_Segment],
AVG([Conversion_Rate]) as Avg_Conversion_Rate,
AVG([Spend]) as Avg_Spend,
AVG([ROI]) as Avg_ROI,
AVG([Clicks]) as Avg_Clicks,
AVG([Impressions]) as Avg_Impressions,
AVG([CTR]) as Avg_CTR
FROM Marketing1
group by [Channel_Used], [Customer_Segment]
-- Nhận xét:
-- Instagram (Fashion) có ROI cao nhất (4.03) và tỷ lệ chuyển đổi tốt (7.41%), CTR ổn định (0.3210).
-- Facebook (Food) có tỷ lệ chuyển đổi cao nhất (7.52%) và ROI cao (3.98).
-- Pinterest (Food) có ROI thấp nhất (0.71) dù chi tiêu cao (8001.36) → cần xem xét lại hiệu quả.
-- Twitter (Fashion) đạt lượt click cao nhất (20,247) với CTR tốt (0.3216).
-- Đánh giá: Instagram phù hợp với ngành Fashion, Facebook phù hợp với ngành Food.

--3/ Kênh nào hiệu quả cho mục tiêu Brand Awareness ?
SELECT
[Campaign_Goal],
[Channel_Used],
[Customer_Segment],
AVG([Clicks]) as Avg_Clicks,
AVG([Impressions]) as Avg_Impressions,
AVG([CTR]) as Avg_CTR
FROM Marketing1
where [Campaign_Goal] = 'Brand Awareness'
group by [Channel_Used], [Customer_Segment], [Campaign_Goal]
order by [Customer_Segment], Avg_CTR desc
-- Nhận xét:
-- - Twitter (Fashion) có lượt click cao nhất (21,850) và CTR cao nhất (0.3238), hiệu quả cho mục tiêu Brand Awareness.
-- - Facebook (Fashion) cũng đạt click cao (21,075) và CTR tốt (0.3228), phù hợp với ngành thời trang.
-- - Pinterest (Fashion) có hiệu quả thấp nhất với lượt click thấp (12,150) và CTR thấp (0.2932).
-- - Đối với ngành Food, Twitter (20,293 click, CTR 0.3228) và Facebook (20,848 click, CTR 0.3229) tiếp tục là lựa chọn hiệu quả.
-- → Đề xuất:
-- - Sử dụng **Twitter và Facebook** cho chiến dịch Brand Awareness ở cả **Fashion** và **Food**.
-- - Hạn chế dùng **Pinterest** cho Brand Awareness do hiệu suất thấp.

--4/ Kênh nào hiệu quả cho mục tiêu Increase Sales
SELECT
[Channel_Used],
[Customer_Segment],
AVG([Conversion_Rate]) as Avg_Conversion_Rate,
AVG([ROI]) as Avg_ROI,
AVG([CTR]) as Avg_CTR
FROM Marketing1
where [Campaign_Goal] = 'Increase Sales'
group by [Channel_Used], [Customer_Segment], [Campaign_Goal]
order by [Customer_Segment]
-- Nhận xét:
-- - Facebook (Fashion) có ROI cao nhất (4.08) và tỷ lệ chuyển đổi tốt (7.11%), phù hợp với mục tiêu tăng doanh số.
-- - Instagram (Fashion) có ROI gần cao nhất (4.06), nhưng tỷ lệ chuyển đổi thấp hơn (6.99%).
-- - Pinterest (Fashion) có tỷ lệ chuyển đổi cao nhất (7.43%) nhưng ROI thấp (0.75) → không hiệu quả về chi phí.
-- - Trong ngành Food, Twitter có ROI cao nhất (4.15), còn Facebook và Instagram có tỷ lệ chuyển đổi cao (7.35% và 7.35%) cùng ROI tốt (~3.96).
-- → Đề xuất:
-- - **Facebook và Instagram** phù hợp cho cả hai ngành trong chiến dịch **Increase Sales**.
-- - **Twitter** là lựa chọn tốt cho **Food** nhờ ROI cao.
-- - **Hạn chế dùng Pinterest** do ROI thấp dù tỷ lệ chuyển đổi cao.

--5/ Kênh nào hiệu quả cho mục tiêu Market Expansion
SELECT
[Channel_Used],
[Customer_Segment],
AVG([Conversion_Rate]) as Avg_Conversion_Rate,
AVG([Impressions]) as Avg_Impressions,
AVG([CTR]) as Avg_CTR
FROM Marketing1
where [Campaign_Goal] = 'Market Expansion'
group by [Channel_Used], [Customer_Segment], [Campaign_Goal]
order by [Customer_Segment]
-- Nhận xét:
-- - Instagram (Fashion) có tỷ lệ chuyển đổi cao nhất (7.71%) và CTR tốt (0.3201) → hiệu quả cho mở rộng thị trường ngành thời trang.
-- - Pinterest (Food) có tỷ lệ chuyển đổi cao nhất (7.80%) nhưng CTR thấp (0.2928) → cần cải thiện khả năng thu hút tương tác.
-- - Facebook (Fashion & Food) có CTR cao nhất (lần lượt 0.3224 và 0.3227) và tỷ lệ chuyển đổi tốt (~7.11–7.56%) → đáng tin cậy.
-- - Twitter ổn định ở cả hai ngành với conversion rate ~7.49% và CTR ~0.319–0.321.
-- → Đề xuất:
-- - Ưu tiên **Instagram** cho **Fashion** và **Pinterest** cho **Food** khi cần mở rộng thị trường.
-- - **Facebook** là lựa chọn an toàn cho cả hai ngành nhờ hiệu suất ổn định và tương tác cao.
-- - **Twitter** có thể dùng bổ trợ nếu cần thêm kênh phân phối.

--6/ Kênh nào hiệu quả cho mục tiêu Product Launch
SELECT
[Channel_Used],
[Customer_Segment],
AVG([Conversion_Rate]) as Avg_Conversion_Rate,
AVG([Impressions]) as Avg_Impressions,
AVG([CTR]) as Avg_CTR
FROM Marketing1
where [Campaign_Goal] = 'Product Launch'
group by [Channel_Used], [Customer_Segment], [Campaign_Goal]
order by [Customer_Segment]
-- Nhận xét:
-- - Twitter (Fashion) có tỷ lệ chuyển đổi cao nhất (7.76%) và CTR tốt (0.323), rất hiệu quả cho chiến dịch Product Launch ngành thời trang.
-- - Instagram (Food) có CTR cao nhất (0.323) và tỷ lệ chuyển đổi tốt (7.29%), phù hợp với ngành thực phẩm.
-- - Pinterest có tỷ lệ chuyển đổi và CTR thấp nhất ở cả hai ngành, cần xem xét lại hiệu quả đầu tư.
-- - Facebook ổn định với tỷ lệ chuyển đổi khoảng 7.22% và CTR ~0.321 ở Fashion.
-- → Đề xuất:
-- - Ưu tiên sử dụng **Twitter** cho ngành Fashion và **Instagram** cho ngành Food trong chiến dịch Product Launch.
-- - Giảm đầu tư vào **Pinterest** do hiệu quả thấp.

--7/ So sánh số lượng nam và nữ trong 2 ngành hàng giữa quảng cáo Good và Bad
WITH G_Bad AS (
    SELECT
        [Customer_Segment],
        [Gender],
        COUNT(*) AS N_Gender_Bad
    FROM Marketing1
    WHERE [Performance_Rating] = 'Bad'
    GROUP BY [Customer_Segment], [Gender]
)

SELECT
    g.[Customer_Segment],
    g.[Gender],
    COUNT(*) AS N_Gender_Good,
    b.N_Gender_Bad
FROM Marketing1 g
INNER JOIN G_Bad b
    ON g.[Customer_Segment] = b.[Customer_Segment]
    AND g.[Gender] = b.[Gender]
WHERE g.[Performance_Rating] = 'Good'
GROUP BY g.[Customer_Segment], g.[Gender], b.N_Gender_Bad

--7/ So sánh số lượng nhóm tuổi trong 2 ngành hàng giữa quảng cáo Good và Bad
WITH G_Bad AS (
    SELECT
        [Customer_Segment],
        [Age_Range],
        COUNT(*) AS N_Age_Range_Bad
    FROM Marketing1
    WHERE [Performance_Rating] = 'Bad'
    GROUP BY [Customer_Segment], [Age_Range]
)

SELECT
    g.[Customer_Segment],
    g.[Age_Range],
    COUNT(*) AS N_Age_Range_Good,
    b.N_Age_Range_Bad
FROM Marketing1 g
INNER JOIN G_Bad b
    ON g.[Customer_Segment] = b.[Customer_Segment]
    AND g.[Age_Range] = b.[Age_Range]
WHERE g.[Performance_Rating] = 'Good'
GROUP BY g.[Customer_Segment], g.[Age_Range], b.N_Age_Range_Bad
order by [Customer_Segment]

