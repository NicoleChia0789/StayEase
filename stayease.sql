-- =====================================================================
--  StayEase  |  AMCS2194 Mini Project  |  Shared database (v1 DRAFT)
--  Target: MariaDB 10.4+ (XAMPP) / MySQL 8.0+
--  Import:  phpMyAdmin > Import, or:  mysql -u root < stayease.sql
--
--  Naming rules
--    tables   : plural snake_case            (homestays, promo_codes)
--    columns  : snake_case                   (check_in, base_price)
--    PK       : <singular_table>_id          (homestay_id)
--    FK       : same name as the PK it points to (user_id, homestay_id)
--    status   : ENUM, Title Case, EXACTLY as listed below (do not invent new values)
--    delete   : "soft delete" = change status, never DELETE rows that have history
-- =====================================================================

CREATE DATABASE IF NOT EXISTS stayease
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE stayease;

SET FOREIGN_KEY_CHECKS = 0;
DROP VIEW  IF EXISTS v_homestay_ratings;
DROP TABLE IF EXISTS reviews, payments, bookings, blocked_dates, pricing_rules,
                     promo_codes, homestay_images, homestay_tags, tags,
                     homestays, users;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- 1. users                                        (Member A - Customer)
--    One table for both roles. role: User = customer, Staff = staff/admin
-- ---------------------------------------------------------------------
CREATE TABLE users (
  user_id        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  full_name      VARCHAR(100)  NOT NULL,
  email          VARCHAR(100)  NOT NULL,
  password_hash  VARCHAR(255)  NOT NULL,          -- password_hash() output, never plain text
  phone          VARCHAR(20)   NOT NULL,
  role           ENUM('User','Staff')      NOT NULL DEFAULT 'User',
  status         ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',   -- Inactive = soft delete / banned
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 2. homestays                                    (Member A - Homestay)
-- ---------------------------------------------------------------------
CREATE TABLE homestays (
  homestay_id  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  name         VARCHAR(100)  NOT NULL,
  state        VARCHAR(50)   NOT NULL,            -- e.g. Kedah, Penang  (used by filter + recommendation)
  city         VARCHAR(50)   NOT NULL,
  address      VARCHAR(255)  NOT NULL,
  description  TEXT          NULL,                -- written by AI Description Generator, edited by staff
  bedrooms     TINYINT UNSIGNED NOT NULL,
  bathrooms    TINYINT UNSIGNED NOT NULL,
  capacity     TINYINT UNSIGNED NOT NULL,         -- max guests
  base_price   DECIMAL(10,2) NOT NULL,            -- RM per night before any pricing rule
  status       ENUM('Active','Maintenance','Inactive') NOT NULL DEFAULT 'Active',  -- Inactive = soft delete
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (homestay_id),
  KEY idx_homestays_location (state, city),
  KEY idx_homestays_status (status),
  CONSTRAINT chk_homestays_capacity CHECK (capacity > 0),
  CONSTRAINT chk_homestays_price    CHECK (base_price > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE homestay_images (
  image_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  homestay_id  INT UNSIGNED NOT NULL,
  image_path   VARCHAR(255) NOT NULL,             -- relative path under /uploads, file itself is NOT in the DB
  is_cover     TINYINT(1)   NOT NULL DEFAULT 0,
  sort_order   TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (image_id),
  KEY idx_images_homestay (homestay_id),
  CONSTRAINT fk_images_homestay FOREIGN KEY (homestay_id)
    REFERENCES homestays (homestay_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tags are a fixed vocabulary shared by: homestay filter, AI recommendation, AI description prompt
CREATE TABLE tags (
  tag_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  tag_name  VARCHAR(30)  NOT NULL,
  PRIMARY KEY (tag_id),
  UNIQUE KEY uq_tags_name (tag_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE homestay_tags (
  homestay_id  INT UNSIGNED NOT NULL,
  tag_id       INT UNSIGNED NOT NULL,
  PRIMARY KEY (homestay_id, tag_id),              -- composite key (many-to-many link table)
  CONSTRAINT fk_htags_homestay FOREIGN KEY (homestay_id) REFERENCES homestays (homestay_id) ON DELETE CASCADE,
  CONSTRAINT fk_htags_tag      FOREIGN KEY (tag_id)      REFERENCES tags (tag_id)           ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 3. promo_codes + pricing_rules                  (Member B - Promotion)
-- ---------------------------------------------------------------------
CREATE TABLE promo_codes (
  promo_id        INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  code            VARCHAR(30)   NOT NULL,
  description     VARCHAR(255)  NULL,
  discount_type   ENUM('Percent','Fixed') NOT NULL,
  discount_value  DECIMAL(10,2) NOT NULL,         -- 10 = 10%  (Percent)  or  RM 50  (Fixed)
  min_nights      TINYINT UNSIGNED NOT NULL DEFAULT 1,
  min_amount      DECIMAL(10,2) NOT NULL DEFAULT 0,   -- minimum spend, checked AFTER pricing rules
  valid_from      DATE NOT NULL,
  valid_to        DATE NOT NULL,
  usage_limit     INT UNSIGNED NOT NULL,          -- usage count = COUNT of non-cancelled bookings with this promo_id
  status          ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',   -- Inactive = soft delete
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (promo_id),
  UNIQUE KEY uq_promo_code (code),
  CONSTRAINT chk_promo_value   CHECK (discount_value > 0),
  CONSTRAINT chk_promo_percent CHECK (discount_type <> 'Percent' OR discount_value <= 100),
  CONSTRAINT chk_promo_dates   CHECK (valid_to >= valid_from)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE pricing_rules (
  rule_id         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  homestay_id     INT UNSIGNED  NULL,             -- NULL = applies to every homestay
  rule_name       VARCHAR(100)  NOT NULL,
  rule_type       ENUM('Seasonal','Weekend','Long Stay') NOT NULL,
  start_date      DATE NULL,                      -- Seasonal only (inclusive)
  end_date        DATE NULL,                      -- Seasonal only (inclusive)
  min_nights      TINYINT UNSIGNED NULL,          -- Long Stay only
  adjust_percent  DECIMAL(5,2) NOT NULL,          -- +30 = surcharge 30%,  -10 = discount 10%
  status          ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',   -- Inactive = soft delete
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (rule_id),
  KEY idx_rules_homestay (homestay_id),
  CONSTRAINT fk_rules_homestay FOREIGN KEY (homestay_id) REFERENCES homestays (homestay_id),
  CONSTRAINT chk_rules_percent  CHECK (adjust_percent BETWEEN -100 AND 300),
  CONSTRAINT chk_rules_seasonal CHECK (rule_type <> 'Seasonal'  OR (start_date IS NOT NULL AND end_date IS NOT NULL AND end_date >= start_date)),
  CONSTRAINT chk_rules_longstay CHECK (rule_type <> 'Long Stay' OR min_nights IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 4. bookings + blocked_dates                     (Member B - Booking & Availability)
--    A date is UNAVAILABLE when an active booking OR an active block covers it.
--    Active booking  = status IN ('Pending','Confirmed','Checked-in')
--    Overlap test (bookings): new.check_in < old.check_out AND new.check_out > old.check_in
--    Overlap test (blocks)  : new.check_in <= block.end_date AND new.check_out > block.start_date
--      (block start_date and end_date are BOTH blocked nights)
--    Nights are not stored: nights = DATEDIFF(check_out, check_in)
-- ---------------------------------------------------------------------
CREATE TABLE bookings (
  booking_id      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  user_id         INT UNSIGNED  NOT NULL,         -- the guest
  homestay_id     INT UNSIGNED  NOT NULL,
  promo_id        INT UNSIGNED  NULL,
  created_by      INT UNSIGNED  NULL,             -- staff user_id if Walk-in / Phone, else NULL
  check_in        DATE NOT NULL,
  check_out       DATE NOT NULL,
  guests          TINYINT UNSIGNED NOT NULL,
  -- price snapshot (saved at booking time so later rule changes do not rewrite history)
  room_total      DECIMAL(10,2) NOT NULL,         -- sum of nightly prices after Seasonal/Weekend rules
  rule_discount   DECIMAL(10,2) NOT NULL DEFAULT 0,   -- Long Stay discount
  promo_discount  DECIMAL(10,2) NOT NULL DEFAULT 0,   -- promo code discount
  total_price     DECIMAL(10,2) NOT NULL,         -- = room_total - rule_discount - promo_discount
  status          ENUM('Pending','Confirmed','Checked-in','Checked-out','Cancelled') NOT NULL DEFAULT 'Pending',
  booking_source  ENUM('Online','Walk-in','Phone') NOT NULL DEFAULT 'Online',
  cancel_reason   VARCHAR(255) NULL,
  cancelled_at    DATETIME NULL,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (booking_id),
  KEY idx_bookings_availability (homestay_id, check_in, check_out),
  KEY idx_bookings_user (user_id),
  KEY idx_bookings_status (status),
  CONSTRAINT fk_bookings_user     FOREIGN KEY (user_id)     REFERENCES users (user_id),
  CONSTRAINT fk_bookings_homestay FOREIGN KEY (homestay_id) REFERENCES homestays (homestay_id),
  CONSTRAINT fk_bookings_promo    FOREIGN KEY (promo_id)    REFERENCES promo_codes (promo_id),
  CONSTRAINT fk_bookings_creator  FOREIGN KEY (created_by)  REFERENCES users (user_id),
  CONSTRAINT chk_bookings_dates   CHECK (check_out > check_in),
  CONSTRAINT chk_bookings_guests  CHECK (guests > 0),
  CONSTRAINT chk_bookings_total   CHECK (total_price >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE blocked_dates (
  block_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  homestay_id  INT UNSIGNED NOT NULL,
  created_by   INT UNSIGNED NOT NULL,             -- staff user_id
  start_date   DATE NOT NULL,                     -- inclusive
  end_date     DATE NOT NULL,                     -- inclusive
  reason       ENUM('Maintenance','Company Use','Other') NOT NULL,
  note         VARCHAR(255) NULL,
  status       ENUM('Active','Removed') NOT NULL DEFAULT 'Active',   -- Removed = soft delete
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (block_id),
  KEY idx_blocks_availability (homestay_id, start_date, end_date),
  CONSTRAINT fk_blocks_homestay FOREIGN KEY (homestay_id) REFERENCES homestays (homestay_id),
  CONSTRAINT fk_blocks_creator  FOREIGN KEY (created_by)  REFERENCES users (user_id),
  CONSTRAINT chk_blocks_dates   CHECK (end_date >= start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 5. payments                                     (Member C - Payment)
--    Payments are SIMULATED. Never store card numbers.
-- ---------------------------------------------------------------------
CREATE TABLE payments (
  payment_id      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  booking_id      INT UNSIGNED  NOT NULL,
  verified_by     INT UNSIGNED  NULL,             -- staff who approved / rejected
  amount          DECIMAL(10,2) NOT NULL,
  payment_type    ENUM('Deposit','Full','Balance') NOT NULL,
  payment_method  ENUM('Online Banking','E-Wallet','Bank Transfer','Cash') NOT NULL,
  reference_no    VARCHAR(50)   NULL,
  proof_path      VARCHAR(255)  NULL,             -- uploaded transfer slip (path only)
  status          ENUM('Pending','Paid','Rejected','Void','Refunded') NOT NULL DEFAULT 'Pending',
  refund_amount   DECIMAL(10,2) NOT NULL DEFAULT 0,
  remarks         VARCHAR(255)  NULL,
  paid_at         DATETIME NULL,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (payment_id),
  KEY idx_payments_booking (booking_id),
  KEY idx_payments_status (status),
  CONSTRAINT fk_payments_booking  FOREIGN KEY (booking_id)  REFERENCES bookings (booking_id),
  CONSTRAINT fk_payments_verifier FOREIGN KEY (verified_by) REFERENCES users (user_id),
  CONSTRAINT chk_payments_amount  CHECK (amount > 0),
  CONSTRAINT chk_payments_refund  CHECK (refund_amount >= 0 AND refund_amount <= amount)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------
-- 6. reviews                                      (Member C - Review)
--    One review per booking (UNIQUE booking_id). Guest and homestay are
--    reached through bookings, so they are NOT repeated here (3NF).
-- ---------------------------------------------------------------------
CREATE TABLE reviews (
  review_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  booking_id   INT UNSIGNED NOT NULL,
  replied_by   INT UNSIGNED NULL,
  rating       TINYINT UNSIGNED NOT NULL,
  comment      TEXT NULL,
  status       ENUM('Visible','Hidden') NOT NULL DEFAULT 'Visible',    -- Hidden = deleted by staff (moderation)
  staff_reply  TEXT NULL,
  replied_at   DATETIME NULL,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (review_id),
  UNIQUE KEY uq_reviews_booking (booking_id),
  CONSTRAINT fk_reviews_booking FOREIGN KEY (booking_id) REFERENCES bookings (booking_id),
  CONSTRAINT fk_reviews_replier FOREIGN KEY (replied_by) REFERENCES users (user_id),
  CONSTRAINT chk_reviews_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Helper view: average rating per homestay (used by homestay list, AI recommendation, PDF report)
CREATE VIEW v_homestay_ratings AS
SELECT b.homestay_id,
       ROUND(AVG(r.rating), 2) AS avg_rating,
       COUNT(*)                AS review_count
FROM reviews r
JOIN bookings b ON b.booking_id = r.booking_id
WHERE r.status = 'Visible'
GROUP BY b.homestay_id;

-- =====================================================================
--  SAMPLE DATA (demo only)   all demo accounts use password:  Password123
--    Staff : admin@stayease.my , hafiz@stayease.my
--    User  : alya@example.com , daniel@example.com , siti@example.com ...
--  Dates are around 6 Nov 2026 so there are past, current and future bookings.
-- =====================================================================
USE stayease;
SET NAMES utf8mb4;

INSERT INTO users (user_id, full_name, email, password_hash, phone, role, status) VALUES
(1, 'Aisyah Rahman', 'admin@stayease.my', '$2y$10$9sNlyfcpBfyaCUMGWvtQzO.UPtiW5WTeJQhv/Qytukx7pznSOKQuy', '012-3456789', 'Staff', 'Active'),
(2, 'Hafiz Ismail', 'hafiz@stayease.my', '$2y$10$9sNlyfcpBfyaCUMGWvtQzO.UPtiW5WTeJQhv/Qytukx7pznSOKQuy', '013-2223344', 'Staff', 'Active'),
(3, 'Nur Alya Nordin', 'alya@example.com', '$2y$10$9sNlyfcpBfyaCUMGWvtQzO.UPtiW5WTeJQhv/Qytukx7pznSOKQuy', '011-11112222', 'User', 'Active'),
(4, 'Daniel Lee', 'daniel@example.com', '$2y$10$9sNlyfcpBfyaCUMGWvtQzO.UPtiW5WTeJQhv/Qytukx7pznSOKQuy', '016-5557788', 'User', 'Active'),
(5, 'Siti Hajar', 'siti@example.com', '$2y$10$9sNlyfcpBfyaCUMGWvtQzO.UPtiW5WTeJQhv/Qytukx7pznSOKQuy', '019-8889900', 'User', 'Active'),
(6, 'Tan Wei Jie', 'weijie@example.com', '$2y$10$9sNlyfcpBfyaCUMGWvtQzO.UPtiW5WTeJQhv/Qytukx7pznSOKQuy', '017-4443322', 'User', 'Active'),
(7, 'Priya Nair', 'priya@example.com', '$2y$10$9sNlyfcpBfyaCUMGWvtQzO.UPtiW5WTeJQhv/Qytukx7pznSOKQuy', '012-9998877', 'User', 'Active'),
(8, 'Kevin Ong', 'kevin@example.com', '$2y$10$9sNlyfcpBfyaCUMGWvtQzO.UPtiW5WTeJQhv/Qytukx7pznSOKQuy', '014-6667788', 'User', 'Inactive');

INSERT INTO homestays (homestay_id, name, state, city, address, description, bedrooms, bathrooms, capacity, base_price, status) VALUES
(1, 'The Tides Langkawi', 'Kedah', 'Langkawi', 'Jalan Pantai Cenang, 07000 Langkawi', NULL, 3, 3, 6, 450.00, 'Active'),
(2, 'Sawah Padi Cottage', 'Kedah', 'Alor Setar', 'Kampung Gunung, 05150 Alor Setar', NULL, 2, 1, 4, 280.00, 'Active'),
(3, 'Kasih Heritage Loft', 'Penang', 'George Town', 'Lebuh Armenian, 10200 George Town', NULL, 2, 2, 4, 320.00, 'Active'),
(4, 'Bukit Hijau Hillside House', 'Penang', 'Balik Pulau', 'Jalan Bukit Genting, 11000 Balik Pulau', NULL, 3, 2, 5, 380.00, 'Active'),
(5, 'Sora Glasshouse', 'Pahang', 'Cameron Highlands', 'Jalan Tringkap, 39000 Brinchang', NULL, 2, 1, 4, 350.00, 'Active'),
(6, 'Awan Rainforest House', 'Pahang', 'Janda Baik', 'Kampung Cherok Paku, 28750 Bentong', NULL, 3, 2, 6, 420.00, 'Active'),
(7, 'Gua Villa Ipoh', 'Perak', 'Ipoh', 'Jalan Gunung Rapat, 31350 Ipoh', NULL, 3, 2, 5, 300.00, 'Active'),
(8, 'Sekinchan Paddy Cabin', 'Selangor', 'Sekinchan', 'Jalan Sawah Sempadan, 45400 Sekinchan', NULL, 2, 1, 4, 260.00, 'Active'),
(9, 'Riverside Melaka Townhouse', 'Melaka', 'Melaka City', 'Jalan Kampung Hulu, 75200 Melaka', NULL, 3, 2, 6, 340.00, 'Active'),
(10, 'Desaru Beach House', 'Johor', 'Desaru', 'Jalan Pantai Desaru, 81930 Kota Tinggi', NULL, 4, 3, 8, 400.00, 'Active'),
(11, 'Kinabalu Seaview Suite', 'Sabah', 'Kota Kinabalu', 'Jalan Tun Fuad Stephens, 88000 Kota Kinabalu', NULL, 1, 1, 3, 360.00, 'Active'),
(12, 'Semporna Island Cabin', 'Sabah', 'Semporna', 'Jalan Bandar Baru, 91300 Semporna', NULL, 2, 1, 4, 500.00, 'Maintenance');

INSERT INTO homestay_images (homestay_id, image_path, is_cover, sort_order) VALUES
(1, 'uploads/homestays/1/cover.jpg', 1, 0),
(2, 'uploads/homestays/2/cover.jpg', 1, 0),
(3, 'uploads/homestays/3/cover.jpg', 1, 0),
(4, 'uploads/homestays/4/cover.jpg', 1, 0),
(5, 'uploads/homestays/5/cover.jpg', 1, 0),
(6, 'uploads/homestays/6/cover.jpg', 1, 0),
(7, 'uploads/homestays/7/cover.jpg', 1, 0),
(8, 'uploads/homestays/8/cover.jpg', 1, 0),
(9, 'uploads/homestays/9/cover.jpg', 1, 0),
(10, 'uploads/homestays/10/cover.jpg', 1, 0),
(11, 'uploads/homestays/11/cover.jpg', 1, 0),
(12, 'uploads/homestays/12/cover.jpg', 1, 0);

INSERT INTO tags (tag_id, tag_name) VALUES
(1, 'beachfront'),
(2, 'quiet'),
(3, 'family_friendly'),
(4, 'pet_friendly'),
(5, 'pool'),
(6, 'city_center'),
(7, 'nature'),
(8, 'wifi'),
(9, 'kitchen'),
(10, 'romantic');

INSERT INTO homestay_tags (homestay_id, tag_id) VALUES
(1, 1),
(1, 5),
(1, 3),
(1, 8),
(2, 2),
(2, 7),
(2, 9),
(3, 6),
(3, 8),
(3, 9),
(3, 10),
(4, 2),
(4, 7),
(4, 3),
(4, 4),
(5, 10),
(5, 7),
(5, 2),
(6, 7),
(6, 5),
(6, 3),
(6, 4),
(7, 2),
(7, 9),
(7, 3),
(7, 8),
(8, 2),
(8, 7),
(8, 4),
(9, 6),
(9, 3),
(9, 8),
(9, 9),
(10, 1),
(10, 5),
(10, 3),
(11, 6),
(11, 10),
(11, 8),
(12, 1),
(12, 10),
(12, 2);

INSERT INTO promo_codes (promo_id, code, description, discount_type, discount_value, min_nights, min_amount, valid_from, valid_to, usage_limit, status) VALUES
(1, 'WELCOME10', '10% off for any stay', 'Percent', 10.00, 1, 200.00, '2026-01-01', '2026-12-31', 100, 'Active'),
(2, 'FIXED50', 'RM50 off stays above RM400', 'Fixed', 50.00, 1, 400.00, '2026-10-01', '2027-03-31', 50, 'Active'),
(3, 'MERDEKA25', 'Merdeka special 25% off (expired)', 'Percent', 25.00, 2, 300.00, '2026-08-25', '2026-09-05', 30, 'Inactive');

INSERT INTO pricing_rules (rule_id, homestay_id, rule_name, rule_type, start_date, end_date, min_nights, adjust_percent, status) VALUES
(1, NULL, 'Weekend Rate (Fri & Sat nights)', 'Weekend', NULL, NULL, NULL, 15.00, 'Active'),
(2, NULL, 'Year-End School Holiday', 'Seasonal', '2026-12-12', '2027-01-03', NULL, 25.00, 'Active'),
(3, NULL, 'Chinese New Year 2027', 'Seasonal', '2027-02-05', '2027-02-09', NULL, 30.00, 'Active'),
(4, NULL, 'Long Stay 3+ nights', 'Long Stay', NULL, NULL, 3, -10.00, 'Active'),
(5, 10, 'Desaru Peak Season (Dec)', 'Seasonal', '2026-12-01', '2026-12-31', NULL, 10.00, 'Inactive');

INSERT INTO bookings (booking_id, user_id, homestay_id, promo_id, created_by, check_in, check_out, guests, room_total, rule_discount, promo_discount, total_price, status, booking_source, cancel_reason, cancelled_at) VALUES
(1, 3, 1, NULL, NULL, '2026-09-04', '2026-09-07', 4, 1485.00, 148.50, 0, 1336.50, 'Checked-out', 'Online', NULL, NULL),
(2, 4, 6, 1, NULL, '2026-09-18', '2026-09-20', 2, 966.00, 0, 96.60, 869.40, 'Checked-out', 'Online', NULL, NULL),
(3, 5, 3, NULL, NULL, '2026-10-09', '2026-10-12', 2, 1056.00, 105.60, 0, 950.40, 'Checked-out', 'Online', NULL, NULL),
(4, 3, 10, 2, NULL, '2026-10-23', '2026-10-25', 6, 920.00, 0, 50, 870.00, 'Checked-out', 'Online', NULL, NULL),
(5, 6, 2, NULL, NULL, '2026-10-30', '2026-11-02', 3, 924.00, 92.40, 0, 831.60, 'Checked-out', 'Online', NULL, NULL),
(6, 7, 4, 1, NULL, '2026-11-13', '2026-11-15', 4, 874.00, 0, 87.40, 786.60, 'Confirmed', 'Online', NULL, NULL),
(7, 4, 1, 1, NULL, '2026-11-20', '2026-11-23', 5, 1485.00, 148.50, 133.65, 1202.85, 'Pending', 'Online', NULL, NULL),
(8, 5, 5, NULL, NULL, '2026-12-18', '2026-12-21', 2, 1417.50, 141.75, 0, 1275.75, 'Confirmed', 'Online', NULL, NULL),
(9, 6, 9, 2, NULL, '2026-12-26', '2026-12-28', 4, 901.00, 0, 50, 851.00, 'Cancelled', 'Online', 'Change of travel plan', '2026-12-01 10:00:00'),
(10, 7, 7, NULL, 2, '2026-11-27', '2026-11-29', 4, 690.00, 0, 0, 690.00, 'Confirmed', 'Phone', NULL, NULL),
(11, 3, 11, NULL, NULL, '2027-02-05', '2027-02-08', 2, 1512.00, 151.20, 0, 1360.80, 'Pending', 'Online', NULL, NULL),
(12, 4, 8, NULL, NULL, '2026-09-25', '2026-09-27', 3, 598.00, 0, 0, 598.00, 'Checked-out', 'Online', NULL, NULL);

INSERT INTO blocked_dates (homestay_id, created_by, start_date, end_date, reason, note, status) VALUES
(11, 1, '2026-11-16', '2026-11-18', 'Maintenance', 'Aircond servicing', 'Active'),
(1, 1, '2026-12-24', '2026-12-26', 'Company Use', 'Staff retreat', 'Active'),
(9, 2, '2026-10-05', '2026-10-06', 'Maintenance', 'Roof repair (completed early)', 'Removed');

INSERT INTO payments (booking_id, verified_by, amount, payment_type, payment_method, reference_no, status, refund_amount, remarks, paid_at) VALUES
(1, 1, 1336.50, 'Full', 'Online Banking', 'FPX-0001', 'Paid', 0, NULL, '2026-08-30 14:05:00'),
(2, 1, 869.40, 'Full', 'E-Wallet', 'TNG-0002', 'Paid', 0, NULL, '2026-09-10 09:20:00'),
(3, 2, 950.40, 'Full', 'Bank Transfer', 'TRF-0003', 'Paid', 0, NULL, '2026-10-02 18:40:00'),
(4, 1, 870.00, 'Full', 'Online Banking', 'FPX-0004', 'Paid', 0, NULL, '2026-10-15 11:00:00'),
(5, 2, 831.60, 'Full', 'E-Wallet', 'TNG-0005', 'Paid', 0, NULL, '2026-10-25 20:15:00'),
(6, 1, 235.98, 'Deposit', 'Online Banking', 'FPX-0006', 'Paid', 0, '30% deposit', '2026-11-01 10:30:00'),
(7, NULL, 1202.85, 'Full', 'Bank Transfer', 'TRF-0007', 'Pending', 0, 'Awaiting staff verification', NULL),
(8, 1, 1275.75, 'Full', 'Online Banking', 'FPX-0008', 'Paid', 0, NULL, '2026-11-03 16:45:00'),
(9, 2, 851.00, 'Full', 'E-Wallet', 'TNG-0009', 'Refunded', 425.50, '50% refund per cancellation policy', '2026-11-04 13:10:00'),
(10, 2, 690.00, 'Full', 'Cash', NULL, 'Paid', 0, 'Paid at office', '2026-11-04 15:00:00'),
(12, 1, 598.00, 'Full', 'Online Banking', 'FPX-0012', 'Paid', 0, NULL, '2026-09-12 08:55:00'),
(12, 1, 30.00, 'Balance', 'Cash', NULL, 'Void', 0, 'Entered by mistake', NULL);

INSERT INTO reviews (booking_id, replied_by, rating, comment, status, staff_reply, replied_at) VALUES
(1, 1, 5, 'Beautiful villa, the pool was amazing and the kids loved it. Very clean.', 'Visible', 'Thank you for staying with us, Alya!', NOW()),
(2, NULL, 4, 'Peaceful rainforest setting. A bit far from town but worth it.', 'Visible', NULL, NULL),
(3, 2, 5, 'Great location in the heart of George Town. Easy walking to the food stalls.', 'Visible', 'Glad you enjoyed it!', NOW()),
(4, 1, 2, 'House was nice but the air conditioner in the master room was not cold and the check-in was late.', 'Visible', 'We are sorry about the aircond issue. It has been serviced.', NOW()),
(5, NULL, 4, 'Quiet and relaxing, good for a short break.', 'Visible', NULL, NULL),
(12, NULL, 1, 'Rude comment removed by staff.', 'Hidden', NULL, NULL);
