-- ============================================================================
-- Caffora / Cafe Management System — reference schema
--
-- This file is NOT executed by the application. Hibernate (ddl-auto=update, see
-- src/main/resources/application.yml) creates and evolves the real schema from the
-- JPA entities under src/main/java/com/caffora/backend/model/. This file exists purely
-- as human-readable documentation of the resulting schema, for the docs/database folder.
-- Dialect: MySQL 8.
-- ============================================================================

CREATE TABLE users (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(120)  NOT NULL,
    email           VARCHAR(180)  NOT NULL,
    password_hash   VARCHAR(255)  NOT NULL,
    role            VARCHAR(20)   NOT NULL,               -- CUSTOMER | ADMIN
    loyalty_status  VARCHAR(60),
    enabled         BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY idx_users_email (email)
);

CREATE TABLE categories (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(100)  NOT NULL,
    description     VARCHAR(500),
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY idx_categories_name (name)
);

CREATE TABLE products (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150)  NOT NULL,
    description     VARCHAR(500)  NOT NULL,
    price           DECIMAL(10,2) NOT NULL,
    category_id     BIGINT,                                -- nullable: legacy/uncategorised rows only
    calories        INT           DEFAULT 0,
    image_url       VARCHAR(500),
    status          VARCHAR(20)   NOT NULL,               -- AVAILABLE | SOLD_OUT
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(id),
    KEY idx_products_category_id (category_id)
);

CREATE TABLE cafe_tables (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_number    VARCHAR(20)   NOT NULL,               -- e.g. "T-01"
    qr_code_value   VARCHAR(255)  NOT NULL,               -- e.g. "cafe://table/T-01"
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY idx_cafe_tables_table_number (table_number),
    UNIQUE KEY idx_cafe_tables_qr_code_value (qr_code_value)
);

CREATE TABLE orders (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_number    VARCHAR(20)   NOT NULL,               -- e.g. "C408"
    user_id         BIGINT        NOT NULL,
    table_id        BIGINT,                                -- nullable: null for counter/pickup orders
    status          VARCHAR(20)   NOT NULL,               -- PENDING|PREPARING|READY|COMPLETED|CANCELLED
    pickup_type     VARCHAR(20)   NOT NULL,               -- COUNTER | TABLE
    subtotal        DECIMAL(10,2) NOT NULL,
    pickup_fee      DECIMAL(10,2) NOT NULL,
    tax             DECIMAL(10,2) NOT NULL,
    total           DECIMAL(10,2) NOT NULL,
    placed_at       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    ready_at        TIMESTAMP     NULL,
    completed_at    TIMESTAMP     NULL,
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_orders_table FOREIGN KEY (table_id) REFERENCES cafe_tables(id),
    UNIQUE KEY idx_orders_order_number (order_number),
    KEY idx_orders_status (status),
    KEY idx_orders_user_id (user_id)
);

CREATE TABLE order_items (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id        BIGINT        NOT NULL,
    product_id      BIGINT,                                -- nullable: preserved even if the product is later deleted
    item_name       VARCHAR(150)  NOT NULL,               -- snapshot of product name at order time
    unit_price      DECIMAL(10,2) NOT NULL,               -- snapshot of product price at order time
    quantity        INT           NOT NULL,
    note            VARCHAR(250),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(id),
    KEY idx_order_items_order_id (order_id),
    KEY idx_order_items_product_id (product_id)
);

CREATE TABLE payments (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id        BIGINT        NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    method          VARCHAR(20)   NOT NULL,               -- CASH | CARD | MOBILE_WALLET
    status          VARCHAR(20)   NOT NULL,               -- PENDING|PAID|FAILED|REFUNDED
    paid_at         TIMESTAMP     NULL,
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(id),
    UNIQUE KEY idx_payments_order_id (order_id)             -- one payment per order (OneToOne)
);
