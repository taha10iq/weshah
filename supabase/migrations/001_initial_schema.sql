-- ============================================================
-- وشاح - نظام أرشفة وإدارة طلبات محل المشالح والأوشحة
-- Supabase Migration: 001_initial_schema.sql
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- جدول العملاء
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS customers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name   TEXT NOT NULL,
  phone       TEXT,
  address     TEXT,
  notes       TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_full_name ON customers (full_name);
CREATE INDEX IF NOT EXISTS idx_customers_phone     ON customers (phone);

-- ─────────────────────────────────────────────────────────────
-- جدول الطلبات
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number  SERIAL UNIQUE,
  customer_id   UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
  order_date    DATE NOT NULL DEFAULT CURRENT_DATE,
  status        TEXT NOT NULL DEFAULT 'new'
                  CHECK (status IN ('new','in_progress','ready','delivered','cancelled')),
  total_price   NUMERIC(10,2) NOT NULL DEFAULT 0,
  amount_paid   NUMERIC(10,2) NOT NULL DEFAULT 0,
  notes         TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id  ON orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status       ON orders (status);
CREATE INDEX IF NOT EXISTS idx_orders_order_date   ON orders (order_date);
CREATE INDEX IF NOT EXISTS idx_orders_order_number ON orders (order_number);

-- ─────────────────────────────────────────────────────────────
-- جدول تفاصيل الطلب (مواصفات المشلح/الوشاح)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_details (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id             UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,

  -- نوع المشلح
  sleeve_style         TEXT CHECK (sleeve_style IN (
                         'full_pleats','no_pleats','shoulder_only','other_model'
                       )),
  custom_model_note    TEXT,
  add_american_cap     BOOLEAN NOT NULL DEFAULT FALSE,

  -- المقاسات (بالسنتيمتر)
  shoulder_width_cm    NUMERIC(5,1),
  robe_length_cm       NUMERIC(5,1),
  sleeve_length_cm     NUMERIC(5,1),
  head_circumference_cm NUMERIC(5,1),

  -- الألوان
  robe_color           TEXT,
  embroidery_color     TEXT,
  cap_color            TEXT,

  -- النصوص
  right_side_text      TEXT,
  left_side_text       TEXT,
  chest_text           TEXT,
  sash_text            TEXT,

  -- معلومات إضافية
  graduation_year      TEXT,
  quantity             INTEGER NOT NULL DEFAULT 1,
  unit_price           NUMERIC(10,2) NOT NULL DEFAULT 0,
  design_notes         TEXT,

  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_details_order_id ON order_details (order_id);

-- ─────────────────────────────────────────────────────────────
-- جدول مرفقات الطلب (صور وملفات)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_attachments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  file_name   TEXT NOT NULL,
  file_path   TEXT NOT NULL,
  file_url    TEXT,
  file_type   TEXT,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_attachments_order_id ON order_attachments (order_id);

-- ─────────────────────────────────────────────────────────────
-- جدول سجل حالات الطلب (اختياري - للتتبع الزمني)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_status_history (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  old_status  TEXT,
  new_status  TEXT NOT NULL,
  notes       TEXT,
  changed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_status_history_order_id ON order_status_history (order_id);

-- ─────────────────────────────────────────────────────────────
-- دالة تحديث updated_at تلقائياً
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_customers_updated_at
  BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE OR REPLACE TRIGGER trg_order_details_updated_at
  BEFORE UPDATE ON order_details
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─────────────────────────────────────────────────────────────
-- دالة تسجيل تغييرات الحالة تلقائياً
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION log_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO order_status_history (order_id, old_status, new_status)
    VALUES (NEW.id, OLD.status, NEW.status);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_order_status_history
  AFTER UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION log_order_status_change();

-- ─────────────────────────────────────────────────────────────
-- Supabase Storage: bucket للمرفقات
-- (نفّذ هذا الأمر من لوحة Supabase > Storage > New bucket)
-- Bucket name: order-attachments
-- Public: false (أو true إذا أردت روابط عامة)
-- ─────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────
-- Row Level Security (RLS) — اختياري للبيئات متعددة المستخدمين
-- قم بتفعيله إذا احتجت صلاحيات منفصلة لكل مستخدم
-- ─────────────────────────────────────────────────────────────
-- ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE order_details ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE order_attachments ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE order_status_history ENABLE ROW LEVEL SECURITY;
