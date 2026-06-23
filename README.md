# Fuzzy Factory — E-commerce Analytics Project

Phân tích dữ liệu kinh doanh cho **Fuzzy Factory**, một sàn thương mại điện tử B2C bán gấu bông trực tuyến, hoạt động từ **19/03/2012 đến 19/03/2015**.

Pipeline: **CSV (raw data) → SQL Server (tạo bảng) → Python (ETL: clean & load) → SQL (EDA) → Power BI (Dashboard)**

---

## 1. Bối cảnh dữ liệu

- Mô hình kinh doanh: B2C, bán 4 dòng sản phẩm gấu bông.
- ~31,696 khách hàng, 32,313 đơn hàng, 40,025 sản phẩm đã bán, 1,731 yêu cầu hoàn tiền.
- Hành trình khách hàng trên web: `/home → /products → /<product-detail> → /cart → /shipping → /billing (hoặc /billing-2) → /thank-you-for-your-order`.
- Nguồn traffic: `gsearch`, `bsearch`, `socialbook`; chiến dịch: `brand`, `nonbrand`, `desktop_targeted`, `pilot`.

Chi tiết đầy đủ về bối cảnh và phát hiện phân tích: xem [`docs/Project_Brief.pdf`](docs/Project_Brief.pdf).

---

## 2. Cấu trúc repo

```
fuzzy-factory-analytics/
├── data/
│   ├── raw/                # 6 file CSV nguồn
│   │                     
│   └── processed/          # Output đã làm sạch 
├── etl/
│   └── etl.py              # Script ETL: đọc CSV -> làm sạch -> load vào SQL Server
├── sql/
│   ├── 01_create_tables.sql   # DDL: tạo database + 6 bảng + khóa ngoại
│   └── 02_eda_queries.sql     # Các query EDA: doanh thu, funnel, traffic, retention, cross-sell...
├── dashboard/
│   └── Dashboard_Fuzzy_Factory.pbix   # Dashboard Power BI
├── docs/
│   └── Project_Brief.pdf      # Báo cáo phân tích đầy đủ (bối cảnh + insight + action)
│   
│   
├── requirements.txt
├── .gitignore
└── README.md
```

---

## 3. Stage 1 — Database (SQL Server)

Chạy `sql/01_create_tables.sql` trên SQL Server để tạo database `FUZZY_FACTORY` và 6 bảng:

`products → website_sessions → website_pageviews → orders → order_items → order_item_refunds`

(thứ tự này cũng là thứ tự khóa ngoại: bảng cha phải tồn tại trước bảng con tham chiếu tới nó).

## 4. Stage 2 — ETL (Python)

```bash
pip install -r requirements.txt
```

Cấu hình kết nối qua biến môi trường:

```powershell
$env:SQL_SERVER_CONN = "mssql+pyodbc://@<TEN_SERVER>/FUZZY_FACTORY?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
python etl/etl.py
```

Script sẽ:
1. Kết nối SQL Server , lưu CSV đã làm sạch vào `data/processed/`.
2. Đọc từng CSV trong `data/raw/`, loại trùng, chuẩn hoá chuỗi, xử lý NULL theo từng bảng cụ thể, ép kiểu ngày.
3. Xoá dữ liệu cũ bằng `DELETE`, rồi nạp dữ liệu mới.

## 5. Stage 3 — EDA (SQL)

Chạy từng block trong `sql/02_eda_queries.sql` trên SQL Server để lấy các chỉ số: doanh thu theo thời gian, AOV/AUP/UPT, refund rate theo sản phẩm, traffic & conversion theo nguồn, funnel theo thiết bị, cross-sell, retention...


## 6. Stage 4 — Dashboard (Power BI)

Mở `dashboard/Dashboard_Fuzzy_Factory.pbix` bằng Power BI Desktop, trỏ lại nguồn dữ liệu về SQL Server instance (Power BI → Transform Data → Data source settings).

---

## 7. Tóm tắt phát hiện chính

- Tổng doanh thu 3 năm: ~1.9 triệu USD, lợi nhuận gộp (chưa trừ marketing): ~1.2 triệu USD.
- Năm 2014 đạt đỉnh doanh thu; Q1 hàng năm thường chững lại theo mùa.
- `The Original Mr. Fuzzy` là sản phẩm "mồi" thu khách chính; `The Hudson River Mini Bear` là sản phẩm bán chéo (cross-sell) tốt nhất.
- Desktop chuyển đổi gấp ~3 lần Mobile (8.5% vs ~3.09%) → mobile UX là điểm nghẽn lớn.
- `bsearch` (Bing) có CVR cao nhất hệ thống dù traffic thấp hơn Google nhiều; `socialbook` hiệu quả thấp nhất.

Chi tiết đầy đủ + action đề xuất: xem `docs/Project_Brief.pdf`.


## 8. Tech stack

- **Database:** Microsoft SQL Server
- **ETL:** Python (pandas, SQLAlchemy, pyodbc)
- **BI:** Power BI
