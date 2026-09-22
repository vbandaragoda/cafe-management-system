-- ============================================================================
-- Caffora Cafe Management System — Database Schema
-- ============================================================================
-- Target: MySQL 8.x (matches backend/docker-compose.yml's `mysql:8.4` image
-- and backend/src/main/resources/application.yml's MySQLDialect).
--
-- This file is the documentation-of-record for the schema described in
-- docs/database/erd.md. In normal development, Hibernate's `ddl-auto=update`
-- (see application.yml, driven by the DDL_AUTO env var) generates and
-- evolves the actual tables from the JPA entities in
-- backend/src/main/java/com/caffora/backend/model/. This script exists so
-- the schema can be read, reviewed, and (re)created independently of the
-- running application — e.g. for provisioning a fresh managed MySQL
-- instance, or for a reviewer who wants to see the DDL without running
-- Spring Boot.
--
-- No file named docs-schema-reference.sql existed in backend/ at the time
-- this was written, so this script was authored directly from the
-- authoritative entity spec (7 tables: users, categories, products,
-- cafe_tables, orders, order_items, payments).
-- ============================================================================

CREATE DATABASE IF NOT EXISTS caffora
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE caffora;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------------------------------------------------------
-- users
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(120)        NOT NULL,
    email           VARCHAR(190)        NOT NULL,
    password_hash   VARCHAR(255)        NOT NULL,           -- BCrypt hash, never plaintext
    role            ENUM('ADMIN','CUSTOMER') NOT NULL DEFAULT 'CUSTOMER',
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                             ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_users_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- categories
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS categories;
CREATE TABLE categories (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(80)         NOT NULL,
    description     VARCHAR(500)        NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                             ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_categories_name UNIQUE (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- products  (menu items; category-scoped, priced, image-linked, stock status)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150)        NOT NULL,
    description     VARCHAR(1000)       NULL,
    price           DECIMAL(10,2)       NOT NULL,
    category_id     BIGINT UNSIGNED     NOT NULL,
    image_url       VARCHAR(500)        NULL,
    status          ENUM('AVAILABLE','SOLD_OUT') NOT NULL DEFAULT 'AVAILABLE',
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                             ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES categories(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_products_price_nonneg CHECK (price >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_products_category_id ON products (category_id);
CREATE INDEX idx_products_status      ON products (status);

-- ----------------------------------------------------------------------------
-- cafe_tables  (physical tables, each with a unique printable QR value)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS cafe_tables;
CREATE TABLE cafe_tables (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    table_number    INT UNSIGNED        NOT NULL,
    qr_code_value   VARCHAR(255)        NOT NULL,          -- e.g. cafe://table/7
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_cafe_tables_number UNIQUE (table_number),
    CONSTRAINT uq_cafe_tables_qr_value UNIQUE (qr_code_value)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ----------------------------------------------------------------------------
-- orders
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_number    VARCHAR(40)         NOT NULL,          -- human-facing, e.g. CF-20260918-0042
    user_id         BIGINT UNSIGNED     NOT NULL,
    table_id        BIGINT UNSIGNED     NULL,               -- NULL = pickup order, no physical table
    status          ENUM('PENDING','PREPARING','READY','COMPLETED','CANCELLED')
                                        NOT NULL DEFAULT 'PENDING',
    subtotal        DECIMAL(10,2)       NOT NULL,
    tax             DECIMAL(10,2)       NOT NULL,
    pickup_fee      DECIMAL(10,2)       NOT NULL DEFAULT 0.00,
    total           DECIMAL(10,2)       NOT NULL,
    placed_at       DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                             ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_orders_order_number UNIQUE (order_number),
    CONSTRAINT fk_orders_user
        FOREIGN KEY (user_id) REFERENCES users(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orders_table
        FOREIGN KEY (table_id) REFERENCES cafe_tables(id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_orders_totals_nonneg
        CHECK (subtotal >= 0 AND tax >= 0 AND pickup_fee >= 0 AND total >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_orders_status   ON orders (status);
CREATE INDEX idx_orders_user_id  ON orders (user_id);
CREATE INDEX idx_orders_table_id ON orders (table_id);

-- ----------------------------------------------------------------------------
-- order_items  (line items; product name/price SNAPSHOTTED at order time)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id        BIGINT UNSIGNED     NOT NULL,
    product_id      BIGINT UNSIGNED     NOT NULL,
    product_name    VARCHAR(150)        NOT NULL,          -- snapshot, survives product renames
    unit_price      DECIMAL(10,2)       NOT NULL,          -- snapshot, survives price changes
    quantity        INT UNSIGNED        NOT NULL,
    note            VARCHAR(300)        NULL,
    line_total      DECIMAL(10,2)       NOT NULL,          -- quantity * unit_price
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders(id)
        ON UPDATE CASCADE ON DELETE CASCADE,               -- deleting an order removes its lines
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id) REFERENCES products(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,               -- a product can't be hard-deleted
                                                             -- while historical orders reference it
    CONSTRAINT chk_order_items_qty_positive CHECK (quantity > 0),
    CONSTRAINT chk_order_items_price_nonneg CHECK (unit_price >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_order_items_order_id   ON order_items (order_id);
CREATE INDEX idx_order_items_product_id ON order_items (product_id);

-- ----------------------------------------------------------------------------
-- payments  (strictly 1:1 with orders)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id        BIGINT UNSIGNED     NOT NULL,
    amount          DECIMAL(10,2)       NOT NULL,
    method          ENUM('CASH','CARD','MOBILE_WALLET') NOT NULL,
    status          ENUM('PENDING','PAID','FAILED','REFUNDED') NOT NULL DEFAULT 'PENDING',
    paid_at         DATETIME            NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_payments_order_id UNIQUE (order_id),      -- enforces 1:1 with orders
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES orders(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_payments_amount_nonneg CHECK (amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- Notes
-- ============================================================================
-- * All money columns use DECIMAL(10,2) — never FLOAT/DOUBLE — to avoid
--   binary floating-point rounding errors in prices and totals.
-- * created_at/updated_at use MySQL's DEFAULT CURRENT_TIMESTAMP /
--   ON UPDATE CURRENT_TIMESTAMP so timestamps are set by the database even
--   if application code forgets to set them explicitly.
-- * Indexes on orders.status, orders.user_id, order_items.order_id and
--   order_items.product_id back the hottest queries: the admin active-order
--   queue, a customer's own order history, and the GROUP BY aggregate
--   queries behind /admin/reports/sales, /admin/reports/top-products and
--   /admin/dashboard (see docs/database/erd.md for the full rationale).
-- * CHECK constraints are enforced by MySQL 8.0.16+ (the project targets
--   mysql:8.4 per backend/docker-compose.yml).
