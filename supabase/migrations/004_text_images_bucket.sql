-- ================================================================
-- Migration 004: إنشاء bucket للصور المرتبطة بحقول النصوص
-- ================================================================

-- إنشاء bucket text-images إذا لم يكن موجوداً
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'text-images',
  'text-images',
  true,           -- public bucket بدون توقيع
  5242880,        -- 5 MB حد أقصى للملف
  ARRAY['image/jpeg','image/jpg','image/png','image/webp','image/gif']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg','image/jpg','image/png','image/webp','image/gif'];

-- السماح لأي مستخدم بالرفع (anon + authenticated)
CREATE POLICY "Allow public uploads to text-images"
  ON storage.objects
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (bucket_id = 'text-images');

-- السماح لأي شخص بقراءة الصور (public bucket)
CREATE POLICY "Allow public read of text-images"
  ON storage.objects
  FOR SELECT
  TO anon, authenticated
  USING (bucket_id = 'text-images');

-- السماح بالتحديث والحذف
CREATE POLICY "Allow public update of text-images"
  ON storage.objects
  FOR UPDATE
  TO anon, authenticated
  USING (bucket_id = 'text-images');

CREATE POLICY "Allow public delete of text-images"
  ON storage.objects
  FOR DELETE
  TO anon, authenticated
  USING (bucket_id = 'text-images');
