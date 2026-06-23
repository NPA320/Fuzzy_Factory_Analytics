
CREATE DATABASE FUZZY_FACTORY;
Use FUZZY_FACTORY;
CREATE TABLE products (
    product_id INT NOT NULL,
    created_at DATETIME NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    
    CONSTRAINT PK_products PRIMARY KEY (product_id)
);


CREATE TABLE website_sessions (
    website_session_id INT NOT NULL,
    created_at DATETIME NOT NULL,
    user_id INT NOT NULL,
    is_repeat_session BIT NOT NULL, -- Cờ nhị phân (0 hoặc 1)
    utm_source VARCHAR(50) NULL,
    utm_campaign VARCHAR(50) NULL,
    utm_content VARCHAR(50) NULL,
    device_type VARCHAR(20) NULL,
    http_referer VARCHAR(255) NULL,
    
    CONSTRAINT PK_website_sessions PRIMARY KEY (website_session_id)
);


CREATE TABLE website_pageviews (
    website_pageview_id INT NOT NULL,
    created_at DATETIME NOT NULL,
    website_session_id INT NOT NULL,
    pageview_url VARCHAR(100) NOT NULL,
    
    CONSTRAINT PK_website_pageviews PRIMARY KEY (website_pageview_id),
    CONSTRAINT FK_pageviews_sessions FOREIGN KEY (website_session_id) 
        REFERENCES website_sessions(website_session_id)
);


CREATE TABLE orders (
    order_id INT NOT NULL,
    created_at DATETIME NOT NULL,
    website_session_id INT NOT NULL,
    user_id INT NOT NULL,
    primary_product_id INT NOT NULL,
    items_purchased INT NOT NULL,
    price_usd DECIMAL(10, 2) NOT NULL, -- Kiểu số thực cho tiền tệ
    cogs_usd DECIMAL(10, 2) NOT NULL,
    
    CONSTRAINT PK_orders PRIMARY KEY (order_id),
    CONSTRAINT FK_orders_sessions FOREIGN KEY (website_session_id) 
        REFERENCES website_sessions(website_session_id),
    CONSTRAINT FK_orders_products FOREIGN KEY (primary_product_id) 
        REFERENCES products(product_id)
);


CREATE TABLE order_items (
    order_item_id INT NOT NULL,
    created_at DATETIME NOT NULL,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    is_primary_item BIT NOT NULL,
    price_usd DECIMAL(10, 2) NOT NULL,
    cogs_usd DECIMAL(10, 2) NOT NULL,
    
    CONSTRAINT PK_order_items PRIMARY KEY (order_item_id),
    CONSTRAINT FK_items_orders FOREIGN KEY (order_id) 
        REFERENCES orders(order_id),
    CONSTRAINT FK_items_products FOREIGN KEY (product_id) 
        REFERENCES products(product_id)
);


CREATE TABLE order_item_refunds (
    order_item_refund_id INT NOT NULL,
    created_at DATETIME NOT NULL,
    order_item_id INT NOT NULL,
    order_id INT NOT NULL,
    refund_amount_usd DECIMAL(10, 2) NOT NULL,
    
    CONSTRAINT PK_order_item_refunds PRIMARY KEY (order_item_refund_id),
    CONSTRAINT FK_refunds_items FOREIGN KEY (order_item_id) 
        REFERENCES order_items(order_item_id),
    CONSTRAINT FK_refunds_orders FOREIGN KEY (order_id) 
        REFERENCES orders(order_id)
);


