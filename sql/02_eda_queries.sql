Use FUZZY_FACTORY;

select *
from products

-- Orders
select *
from orders;

-- số đơn hàng đã bán
select count(*) as So_don_hang
from orders; 

-- số khách hàng
Select Count(distinct user_id) as So_khach_hang
from orders;

-- số lượng sản phẩm trong 1 đơn hàng
select distinct items_purchased
from orders;

-- ngày bắt đầu kinh doanh
select min(created_at) as stard_day
from orders;

-- ngày mới nhất ghi nhận đơn hàng
select max(created_at) as lasted_day
from orders;

--------------------------------------------
-------- Sản phẩm trong 1 đơn hàng ---------
--------------------------------------------
select *
from order_items

-- Tổng số sản phẩm đã bán
select count(*) as Tong_san_pham
from order_items;

-- Số lượng bán theo từng sản phẩm
select p.product_name, count(*) as so_luong_san_pham
From order_items o
join products p on o.product_id = p.product_id
group by o.product_id,p.product_name; 

-- Giá bán theo từng sản phẩm
select p.product_name, o.price_usd,o.cogs_usd
From order_items o
join products p on o.product_id = p.product_id
group by p.product_name,o.price_usd,o.cogs_usd; 

--------------------------------------------
-------- Sản phẩm bị trả hàng --------------
--------------------------------------------
select *
from order_item_refunds

--------------------------------------------
-------- luồng hoạt động --------------
--------------------------------------------
select *
from website_pageviews

-- các pageview
select distinct pageview_url
from website_pageviews;


--------------------------------------------
-------- Session hoạt động -----------------
--------------------------------------------
select * 
from website_sessions

-- các chiến dịch quảng cáo
select distinct utm_campaign
from website_sessions

-- các nguồn lưu lượng truy cập
select distinct utm_source
from website_sessions

-- các loại nội dung quảng cáo
select distinct utm_content
from website_sessions



--------------------------------------------
------------------- EDA --------------------
--------------------------------------------

-- Tổng doanh thu sau 3 năm hoạt động 
select sum(price_usd) as Total_revenue, (Sum(price_usd) - Sum(cogs_usd)) as Total_profit
from orders;

-- Doanh thu theo từng năm
SELECT 
    YEAR(o.created_at) AS revenue_year,
    SUM(o.price_usd) AS Total_revenue_per_year
FROM orders o
GROUP BY YEAR(o.created_at)
ORDER BY revenue_year ;

-- doanh thu theo tháng qua từng năm
SELECT 
	YEAR(o.created_at) AS revenue_year,
    Month(o.created_at) AS revenue_month,
    SUM(o.price_usd) AS Total_revenue_per_year
FROM orders o
GROUP BY Month(o.created_at),Year(o.created_at)
ORDER BY revenue_year,revenue_month ;

-- doanh thu theo quý qua từng năm
SELECT 
    YEAR(o.created_at) AS revenue_year,
    DATEPART(quarter, o.created_at) AS revenue_quarter,
    SUM(o.price_usd) AS Total_revenue_per_quarter
FROM orders o
GROUP BY YEAR(o.created_at), DATEPART(quarter, o.created_at) 
ORDER BY revenue_year, revenue_quarter;

-- So sánh tăng trưởng theo năm 
WITH RevenueByYear AS (
    SELECT 
        YEAR(o.created_at) AS revenue_year,
        SUM(o.price_usd) AS total_revenue_per_year
    FROM orders o
    GROUP BY YEAR(o.created_at)
)
SELECT 
    revenue_year,
    total_revenue_per_year,
    (total_revenue_per_year - LAG(total_revenue_per_year, 1) OVER (ORDER BY revenue_year)) AS revenue_growth,
    ROUND(
        (total_revenue_per_year - LAG(total_revenue_per_year, 1) OVER (ORDER BY revenue_year)) 
        / LAG(total_revenue_per_year, 1) OVER (ORDER BY revenue_year) * 100, 2
    ) AS growth_percentage
FROM RevenueByYear
ORDER BY revenue_year;


-- số lượng đơn hàng theo quý
SELECT 
    YEAR(o.created_at) AS revenue_year,
    DATEPART(quarter, o.created_at) AS revenue_quarter,
    count(*) AS Total_orders_per_quarter
FROM orders o
GROUP BY YEAR(o.created_at), DATEPART(quarter, o.created_at) 
ORDER BY revenue_year, revenue_quarter;

-- doanh thu theo tháng qua từng năm

SELECT 
    YEAR(created_at) AS r_year,
    MONTH(created_at) AS r_month,
    SUM(price_usd) AS total_revenue,                       -- Tổng doanh thu
    COUNT(DISTINCT order_id) AS total_orders,              -- Tổng số đơn hàng
    SUM(items_purchased) AS total_items_sold,               -- Tổng số sản phẩm bán ra
    SUM(price_usd) / COUNT(DISTINCT order_id) AS AOV,     -- Giá trị đơn hàng trung bình
    SUM(items_purchased) * 1.0/ COUNT(DISTINCT order_id) AS UPT  -- Số sản phẩm trung bình/đơn
FROM orders
WHERE created_at >= '2012-10-01' AND created_at < '2015-04-01'
GROUP BY YEAR(created_at), MONTH(created_at)
ORDER BY r_year, r_month;


-- EDA chuyên sâu --



-- DA SUA LAN 2 (dinh nghia lai "khach hang cu"): is_repeat_session chi cho biet
-- khach quay lai XEM WEB lan nua, KHONG dam bao ho da MUA hang truoc do. "Khach hang"
-- dung nghia phai la nguoi da co don hang truoc day. Dung ROW_NUMBER theo user_id de
-- xac dinh don hang nay la lan mua thu may, tu do moi tinh dung "don hang tu khach cu".
WITH OrderSequenced AS (
    SELECT 
        order_id,
        user_id,
        created_at,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at) AS purchase_sequence
    FROM orders
)
SELECT 
    YEAR(created_at) AS r_year,
    MONTH(created_at) AS r_month,
    COUNT(*) AS repeat_customer_orders   -- don hang ma nguoi mua DA tung mua truoc do (purchase_sequence > 1)
FROM OrderSequenced
WHERE created_at >= '2014-10-01' AND created_at < '2015-04-01' 
    AND purchase_sequence > 1
GROUP BY YEAR(created_at), MONTH(created_at)
ORDER BY r_year, r_month


-- Doanh thu trung bình mỗi ngày
SELECT 
    YEAR(o.created_at) AS r_year,
    MONTH(o.created_at) AS r_month,
    SUM(oi.price_usd) AS Total_revenue,
    COUNT(DISTINCT o.order_id) AS Total_orders,
    COUNT(DISTINCT DAY(o.created_at)) AS active_days,
    SUM(oi.price_usd) / COUNT(DISTINCT DAY(o.created_at)) AS avg_daily_revenue
    
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.created_at >= '2014-10-01' AND o.created_at < '2015-04-01'
GROUP BY YEAR(o.created_at), MONTH(o.created_at)
ORDER BY r_year, r_month;

-- số lượng bán ra của từng product theo từng quý
Select p.product_name,YEAR(o.created_at) AS r_year,DATEPART(quarter, o.created_at) AS r_quarter, Count(o.product_id) as quantity,SUM(o.price_usd) AS Total_revenue_per_year
from order_items o
Join products p on o.product_id = p.product_id
WHERE o.created_at >= '2012-01-01' AND o.created_at < '2015-04-01'
group by p.product_name, YEAR(o.created_at),  DATEPART(quarter, o.created_at)
order by r_year,r_quarter


SELECT 
    p.product_name,
    YEAR(o.created_at) AS r_year,
    DATEPART(quarter, o.created_at) AS r_quarter, 
    COUNT(o.product_id) AS quantity,
    SUM(o.price_usd) AS Total_revenue_per_quarter,
    
    -- Cột mới: Tính % doanh thu của sản phẩm so với tổng doanh thu quý đó
    ROUND(
        SUM(o.price_usd) * 100.0 / 
        SUM(SUM(o.price_usd)) OVER(PARTITION BY YEAR(o.created_at), DATEPART(quarter, o.created_at))
    , 2) AS revenue_percentage

FROM order_items o
JOIN products p ON o.product_id = p.product_id
WHERE o.created_at >= '2012-01-01' AND o.created_at < '2015-04-01'
GROUP BY p.product_name, YEAR(o.created_at), DATEPART(quarter, o.created_at)
ORDER BY r_year, r_quarter, revenue_percentage DESC; -- Sắp xếp thêm % từ cao xuống thấp
--

-- DA SUA: SQL Server khong cho phep 2 menh de WITH tach roi nhau.
-- Gop OrderSummary, ProductPairs, MainProductTotal vao 1 WITH duy nhat, noi bang dau phay.
-- (Luu y: OrderSummary va MainProductTotal hien khong duoc dung trong SELECT cuoi cung ben duoi,
--  giu lai de tham khao/mo rong sau, khong gay loi vi CTE khong dung toi van hop le.)
WITH OrderSummary AS (
    SELECT 
        order_id,
        COUNT(product_id) AS total_items_in_order
    FROM order_items
    GROUP BY order_id
),
ProductPairs AS (
    -- Bước 1: Tìm các cặp sản phẩm xuất hiện cùng nhau trong một đơn hàng
    SELECT 
        oi1.product_id AS main_product_id,
        oi2.product_id AS cross_product_id,
        COUNT(DISTINCT oi1.order_id) AS joint_order_count
    FROM order_items oi1
    JOIN order_items oi2 ON oi1.order_id = oi2.order_id
    WHERE oi1.product_id <> oi2.product_id -- Loại trừ việc sản phẩm tự bắt cặp với chính nó
    GROUP BY oi1.product_id, oi2.product_id
),
MainProductTotal AS (
    -- Bước 2: Tính tổng số đơn hàng của riêng sản phẩm chính
    SELECT 
        product_id,
        COUNT(DISTINCT order_id) AS total_main_orders
    FROM order_items
    GROUP BY product_id
)
-- Bước 3: Ghép dữ liệu và tính tỷ lệ % cross-sell

SELECT 
    main.product_id AS primary_product_id,
    addon.product_id AS cross_sold_product_id,
    COUNT(DISTINCT main.order_id) AS times_bought_together
FROM order_items main
JOIN order_items addon ON main.order_id = addon.order_id
WHERE 
    main.is_primary_item = 1  
    AND addon.is_primary_item = 0 
GROUP BY 
    main.product_id, 
    addon.product_id
ORDER BY 
    times_bought_together DESC;


select *
from order_item_refunds

WITH MultipleItemOrders AS (
    SELECT order_id
    FROM order_items
    GROUP BY order_id
    HAVING COUNT(product_id) > 1
)
SELECT COUNT(*) AS total_multiple_item_orders
FROM MultipleItemOrders;


-- DA SUA: dung COUNT(oi.order_item_id) truc tiep sau LEFT JOIN se bi dem du total_sold
-- neu mot order_item co nhieu ban ghi refund (hoan tung phan). Tach total_sold ra dem
-- DISTINCT truoc, refund van dem nhu cu vi 1 item co the co > 1 lan refund la hop le.
SELECT 
    p.product_name,
    COUNT(DISTINCT oi.order_item_id) AS total_sold,                      
    COUNT(oir.order_item_refund_id) AS total_refunded,          
    ROUND(COUNT(oir.order_item_refund_id) * 100.0 / COUNT(DISTINCT oi.order_item_id), 2) AS refund_rate_percent,
    ROUND(AVG(CAST(DATEDIFF(day, oi.created_at, oir.created_at) AS FLOAT)), 1) AS avg_days_to_refund
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN order_item_refunds oir ON oi.order_item_id = oir.order_item_id
GROUP BY p.product_name
ORDER BY refund_rate_percent DESC;


-- Phân tích về traffic
	SELECT 
		ws.utm_source,
		ws.utm_campaign,
		COUNT(ws.website_session_id) AS total_sessions,
		COUNT(o.order_id) AS total_orders,
    
		-- Tính tỷ lệ chuyển đổi: Số đơn hàng / Số phiên truy cập
		ROUND(COUNT(o.order_id) * 100.0 / COUNT(ws.website_session_id), 2) AS conversion_rate_percent

	FROM website_sessions ws
	LEFT JOIN orders o ON ws.website_session_id = o.website_session_id
	WHERE ws.created_at >= '2012-01-01' AND ws.created_at < '2015-04-01'
	GROUP BY 
		ws.utm_source, 
		ws.utm_campaign
	ORDER BY 
		conversion_rate_percent DESC;

	SELECT 
		-- Xử lý các dòng NULL (Khách không qua quảng cáo mà tự gõ URL hoặc click link trực tiếp)
		COALESCE(utm_source, 'Direct / Organic') AS traffic_source,
    
		COUNT(website_session_id) AS total_sessions,
    
		-- Tính % tỷ trọng traffic của từng nguồn so với tổng toàn hệ thống
		ROUND(
			COUNT(website_session_id) * 100.0 / 
			SUM(COUNT(website_session_id)) OVER()
		, 2) AS traffic_percentage

	FROM website_sessions
	WHERE created_at >= '2012-01-01' AND created_at < '2015-04-01' -- Có thể thay đổi mốc thời gian tùy ý
	GROUP BY utm_source
	ORDER BY traffic_percentage DESC;

	

-- phân tích phễu
SELECT 
    pageview_url, 
    COUNT(website_pageview_id) AS total_views
FROM website_pageviews
GROUP BY pageview_url
ORDER BY total_views DESC;


WITH SessionLevelMadeIt AS (
    -- Bước 1: Gắn cờ hành trình và lấy thêm device_type từ bảng sessions
    SELECT 
        wp.website_session_id,
        ws.device_type,
        MAX(CASE WHEN wp.pageview_url IN ('/home', '/lander-1', '/lander-2', '/lander-3', '/lander-4', '/lander-5') THEN 1 ELSE 0 END) AS made_it_to_lander,
        MAX(CASE WHEN wp.pageview_url IN ('/products', '/the-original-mr-fuzzy', '/the-forever-love-bear', '/the-birthday-sugar-panda', '/the-hudson-river-mini-bear') THEN 1 ELSE 0 END) AS made_it_to_product,
        MAX(CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END) AS made_it_to_cart,
        MAX(CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END) AS made_it_to_shipping,
        MAX(CASE WHEN wp.pageview_url IN ('/billing', '/billing-2') THEN 1 ELSE 0 END) AS made_it_to_billing,
        MAX(CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS made_it_to_thankyou
    FROM website_pageviews wp
    JOIN website_sessions ws ON wp.website_session_id = ws.website_session_id
    WHERE wp.created_at >= '2014-10-01' AND wp.created_at < '2015-04-01' 
    GROUP BY wp.website_session_id, ws.device_type
)
-- Bước 2: Gom nhóm và tính toán tỷ lệ theo từng loại thiết bị
SELECT 
    device_type,
    COUNT(website_session_id) AS total_sessions,
    SUM(made_it_to_lander) AS to_lander_stage,
    SUM(made_it_to_product) AS to_product_stage,
    SUM(made_it_to_cart) AS to_cart_stage,
    SUM(made_it_to_shipping) AS to_shipping_stage,
    SUM(made_it_to_billing) AS to_billing_stage,
    SUM(made_it_to_thankyou) AS completed_orders,
    
    ROUND(SUM(made_it_to_product) * 100.0 / NULLIF(SUM(made_it_to_lander), 0), 2) AS lander_to_product_rt,
    ROUND(SUM(made_it_to_cart) * 100.0 / NULLIF(SUM(made_it_to_product), 0), 2) AS product_to_cart_rt,
    ROUND(SUM(made_it_to_shipping) * 100.0 / NULLIF(SUM(made_it_to_cart), 0), 2) AS cart_to_shipping_rt,
    ROUND(SUM(made_it_to_billing) * 100.0 / NULLIF(SUM(made_it_to_shipping), 0), 2) AS shipping_to_billing_rt,
    ROUND(SUM(made_it_to_thankyou) * 100.0 / NULLIF(SUM(made_it_to_billing), 0), 2) AS billing_to_order_rt
FROM SessionLevelMadeIt
GROUP BY device_type;



SELECT 
    -- Tính CVR cho Desktop
    ROUND(
        COUNT(DISTINCT CASE WHEN ws.device_type = 'desktop' AND o.order_id IS NOT NULL THEN o.order_id END) * 100.0 
        / COUNT(DISTINCT CASE WHEN ws.device_type = 'desktop' THEN ws.website_session_id END), 
        2
    ) AS desktop_cvr_percentage,

    -- Tính CVR cho Mobile
    ROUND(
        COUNT(DISTINCT CASE WHEN ws.device_type = 'mobile' AND o.order_id IS NOT NULL THEN o.order_id END) * 100.0 
        / COUNT(DISTINCT CASE WHEN ws.device_type = 'mobile' THEN ws.website_session_id END), 
        2
    ) AS mobile_cvr_percentage
FROM website_sessions ws
LEFT JOIN orders o ON ws.website_session_id = o.website_session_id;

-- tỉ lệ khách hàng rời bỏ
WITH UserOrderCounts AS (
    SELECT 
        user_id,
        COUNT(order_id) AS total_orders
    FROM orders
    -- Nếu bảng orders không có user_id, hãy dùng: JOIN website_sessions ws ON orders.website_session_id = ws.website_session_id
    GROUP BY user_id
)
SELECT 
    total_orders AS number_of_purchases,
    COUNT(user_id) AS total_customers,
    
    -- Quy đổi ra % để thấy rõ tỷ lệ rời bỏ
    ROUND(COUNT(user_id) * 100.0 / SUM(COUNT(user_id)) OVER(), 2) AS percentage_of_customers
FROM UserOrderCounts
GROUP BY total_orders
ORDER BY total_orders;




WITH RankedOrders AS (
    SELECT 
        o.user_id,
        o.order_id,
        oi.product_id,
        ROW_NUMBER() OVER(PARTITION BY o.user_id ORDER BY o.created_at) AS order_sequence
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
)
SELECT 
    p1.product_name AS first_purchase,
    p2.product_name AS second_purchase,
    COUNT(r1.user_id) AS total_customers_bought_both
FROM RankedOrders r1
-- Nối chính nó để bắt cặp Đơn lần 1 và Đơn lần 2
JOIN RankedOrders r2 ON r1.user_id = r2.user_id 
    AND r1.order_sequence = 1 
    AND r2.order_sequence = 2
JOIN products p1 ON r1.product_id = p1.product_id
JOIN products p2 ON r2.product_id = p2.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY total_customers_bought_both DESC;


-- BO SUNG (theo muc 3 trong REVIEW.md): kiem chung claim "Mini Bear la vua ban cheo".
-- So sanh ty trong cua Mini Bear trong TAT CA lan mua thu 2 (baseline khong dieu kien)
-- voi ty trong cua no trong TAT CA don hang noi chung (do pho bien tu nhien cua san pham).
-- Neu ty trong trong "lan mua thu 2" > han ty trong "tat ca don hang" -> co tin hieu uu tien
-- thuc su khi mua lai. Neu xap xi nhau -> nhieu kha nang chi vi gia re/de mua, khong phai uu tien dac biet.
WITH RankedOrders2 AS (
    SELECT 
        o.user_id,
        oi.product_id,
        ROW_NUMBER() OVER (PARTITION BY o.user_id ORDER BY o.created_at) AS order_sequence
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
),
SecondPurchaseShare AS (
    -- Ty trong cua tung san pham trong TAT CA lan mua thu 2
    SELECT 
        p.product_name,
        COUNT(*) AS second_purchase_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS second_purchase_share_pct
    FROM RankedOrders2 r
    JOIN products p ON r.product_id = p.product_id
    WHERE r.order_sequence = 2
    GROUP BY p.product_name
),
OverallShare AS (
    -- Ty trong cua tung san pham trong TAT CA don hang (do pho bien tu nhien)
    SELECT 
        p.product_name,
        COUNT(*) AS overall_order_item_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS overall_share_pct
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_name
)
SELECT 
    s.product_name,
    s.second_purchase_share_pct,
    o.overall_share_pct,
    ROUND(s.second_purchase_share_pct - o.overall_share_pct, 2) AS uplift_pct_points  -- > 0 nghia la duoc "uu tien" hon khi mua lai
FROM SecondPurchaseShare s
JOIN OverallShare o ON s.product_name = o.product_name
ORDER BY uplift_pct_points DESC;


-- BO SUNG (theo muc 3 trong REVIEW.md): cong thuc ADR (Average Daily Revenue) day du,
-- chuan hoa doanh thu theo so ngay hoat dong thuc te de tranh hieu lam "sut giam" do
-- du lieu bi cat cut (he thong ket thuc dot ngot 19/03/2015) chu khong phai do khung hoang.
-- ADR = Tong doanh thu trong ky / So ngay co ghi nhan doanh thu trong ky
SELECT
    YEAR(created_at) AS r_year,
    DATEPART(quarter, created_at) AS r_quarter,
    SUM(price_usd) AS total_revenue,
    COUNT(DISTINCT CAST(created_at AS DATE)) AS active_days,
    ROUND(SUM(price_usd) / COUNT(DISTINCT CAST(created_at AS DATE)), 2) AS ADR
FROM orders
GROUP BY YEAR(created_at), DATEPART(quarter, created_at)
ORDER BY r_year, r_quarter;