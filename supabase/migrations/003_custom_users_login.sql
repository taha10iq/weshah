-- ============================================================
-- وشاح - جدول المستخدمين المخصص + دالة تسجيل الدخول
-- Supabase Migration: 003_custom_users_login.sql
-- ============================================================

-- تفعيل pgcrypto لاستخدام crypt()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ─────────────────────────────────────────────────────────────
-- جدول المستخدمين المخصص
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name     TEXT NOT NULL,
  username      TEXT NOT NULL UNIQUE,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role          TEXT NOT NULL DEFAULT 'employee'
                  CHECK (role IN ('admin', 'employee')),
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_users_email     ON public.users (email);
CREATE INDEX IF NOT EXISTS idx_users_username  ON public.users (username);
CREATE INDEX IF NOT EXISTS idx_users_role      ON public.users (role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users (is_active);

-- ─────────────────────────────────────────────────────────────
-- دالة تسجيل الدخول
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.login_user(
  p_email    TEXT,
  p_password TEXT
)
RETURNS TABLE (
  id        UUID,
  full_name TEXT,
  username  TEXT,
  email     TEXT,
  role      TEXT,
  is_active BOOLEAN
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    u.id,
    u.full_name,
    u.username,
    u.email,
    u.role,
    u.is_active
  FROM public.users u
  WHERE u.email         = p_email
    AND u.password_hash = crypt(p_password, u.password_hash)
    AND u.is_active     = true;
$$;

-- ─────────────────────────────────────────────────────────────
-- دالة إنشاء مستخدم مع تشفير كلمة المرور
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_user(
  p_full_name TEXT,
  p_username  TEXT,
  p_email     TEXT,
  p_password  TEXT,
  p_role      TEXT DEFAULT 'employee'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.users (full_name, username, email, password_hash, role)
  VALUES (
    p_full_name,
    p_username,
    p_email,
    crypt(p_password, gen_salt('bf')),
    p_role
  )
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

-- ─────────────────────────────────────────────────────────────
-- مستخدم Admin افتراضي (غيّر البيانات حسب الحاجة)
-- ─────────────────────────────────────────────────────────────
-- يمكنك تشغيل هذا السطر يدوياً من Supabase SQL Editor:
-- SELECT public.create_user('مدير النظام', 'admin', 'admin@weshah.com', 'Admin@123', 'admin');

-- ─────────────────────────────────────────────────────────────
-- RLS: السماح باستدعاء الدالة بدون مصادقة (anon)
-- ─────────────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION public.login_user(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_user(TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;
