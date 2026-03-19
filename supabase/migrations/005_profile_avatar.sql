-- ============================================================
-- Migration 005: Profile Avatar & Password Functions
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. إضافة عمود صورة الملف الشخصي لجدول المستخدمين
-- ─────────────────────────────────────────────────────────────
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS avatar_url TEXT DEFAULT NULL;

-- ─────────────────────────────────────────────────────────────
-- 2. إنشاء bucket الصور الشخصية
-- ─────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  3145728,  -- 3 MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET public = true;

-- ─────────────────────────────────────────────────────────────
-- 3. سياسات الوصول لـ bucket الصور الشخصية
-- ─────────────────────────────────────────────────────────────
DO $$
BEGIN
  -- رفع الصور
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'objects'
      AND policyname = 'Allow avatar uploads'
  ) THEN
    CREATE POLICY "Allow avatar uploads"
      ON storage.objects FOR INSERT
      TO anon, authenticated
      WITH CHECK (bucket_id = 'avatars');
  END IF;

  -- قراءة الصور
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'objects'
      AND policyname = 'Allow avatar reads'
  ) THEN
    CREATE POLICY "Allow avatar reads"
      ON storage.objects FOR SELECT
      TO anon, authenticated
      USING (bucket_id = 'avatars');
  END IF;

  -- تحديث الصور (upsert)
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'objects'
      AND policyname = 'Allow avatar updates'
  ) THEN
    CREATE POLICY "Allow avatar updates"
      ON storage.objects FOR UPDATE
      TO anon, authenticated
      USING (bucket_id = 'avatars');
  END IF;
END
$$;

-- ─────────────────────────────────────────────────────────────
-- 4. دوال تغيير كلمة المرور (إن لم تكن موجودة)
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.verify_user_password(
  p_user_id UUID,
  p_password TEXT
)
RETURNS TABLE (valid BOOLEAN)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT (password_hash = crypt(p_password, password_hash)) AS valid
  FROM public.users
  WHERE id = p_user_id;
$$;

CREATE OR REPLACE FUNCTION public.update_user_password(
  p_user_id UUID,
  p_new_password TEXT
)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.users
  SET password_hash = crypt(p_new_password, gen_salt('bf')),
      updated_at = NOW()
  WHERE id = p_user_id;
$$;

GRANT EXECUTE ON FUNCTION public.verify_user_password(UUID, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_password(UUID, TEXT) TO anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 5. تحديث دالة login_user لتُرجع avatar_url
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.login_user(
  p_username TEXT,
  p_password TEXT
)
RETURNS TABLE (
  id         UUID,
  full_name  TEXT,
  username   TEXT,
  email      TEXT,
  role       TEXT,
  is_active  BOOLEAN,
  avatar_url TEXT
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
    u.is_active,
    u.avatar_url
  FROM public.users u
  WHERE u.username      = p_username
    AND u.password_hash = crypt(p_password, u.password_hash)
    AND u.is_active     = true;
$$;

GRANT EXECUTE ON FUNCTION public.login_user(TEXT, TEXT) TO anon, authenticated;

-- ─────────────────────────────────────────────────────────────
-- 6. إضافة عمود صورة ملاحظات التصميم لجدول order_details
-- ─────────────────────────────────────────────────────────────
ALTER TABLE public.order_details
  ADD COLUMN IF NOT EXISTS design_notes_image_url TEXT DEFAULT NULL;
