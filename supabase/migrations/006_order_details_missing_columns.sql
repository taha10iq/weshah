-- ============================================================
-- Migration 006: إضافة الأعمدة الناقصة في order_details
-- ============================================================
-- شغّل هذا الملف كاملاً في Supabase SQL Editor

ALTER TABLE public.order_details
  ADD COLUMN IF NOT EXISTS cap_text                TEXT,
  ADD COLUMN IF NOT EXISTS cap_text_image_url      TEXT,
  ADD COLUMN IF NOT EXISTS right_text_image_url    TEXT,
  ADD COLUMN IF NOT EXISTS left_text_image_url     TEXT,
  ADD COLUMN IF NOT EXISTS chest_text_image_url    TEXT,
  ADD COLUMN IF NOT EXISTS sash_text_image_url     TEXT,
  ADD COLUMN IF NOT EXISTS design_notes_image_url  TEXT;
