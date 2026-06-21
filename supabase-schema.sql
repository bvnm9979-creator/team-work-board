-- ================================================================
-- 팀 업무 공유 보드 — Supabase 스키마 초기화 SQL
-- ================================================================
-- 사용법: Supabase 대시보드 → SQL Editor → 이 파일 전체 붙여넣기 → RUN
-- 주의: 이미 동일 이름의 테이블이 있으면 DROP 후 재생성됩니다.
-- ================================================================


-- ────────────────────────────────────────────────────────────────
-- 1. 확장 기능 활성화
-- ────────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ────────────────────────────────────────────────────────────────
-- 2. 업무 기록 테이블 (work_entries)
-- ────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS work_entries CASCADE;

CREATE TABLE work_entries (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  work_date   DATE        NOT NULL,
  name        TEXT        NOT NULL CHECK (char_length(name) BETWEEN 1 AND 100),
  task        TEXT        NOT NULL CHECK (char_length(task) BETWEEN 1 AND 2000),
  status      TEXT        NOT NULL DEFAULT '예정'
                          CHECK (status IN ('예정', '진행중', '완료', '보류')),
  category    TEXT        CHECK (char_length(category) <= 100),
  link        TEXT        CHECK (link IS NULL OR link ~ '^https?://'),
  image_url   TEXT,
  channel     TEXT        CHECK (channel IS NULL OR channel IN
                            ('youtube','fb_page','fb_group','instagram','twitter','threads')),
  stage       TEXT        CHECK (stage IS NULL OR stage IN ('예정','기획','진행 중','제작완료','검수','게시')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 날짜별 조회 성능 인덱스
CREATE INDEX idx_work_entries_work_date ON work_entries(work_date DESC);
-- 담당자별 조회 인덱스
CREATE INDEX idx_work_entries_name ON work_entries(name);
-- 카테고리 인덱스
CREATE INDEX idx_work_entries_category ON work_entries(category);

-- updated_at 자동 갱신 트리거
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER work_entries_updated_at
  BEFORE UPDATE ON work_entries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ────────────────────────────────────────────────────────────────
-- 3. SNS 채널 수치 테이블 (sns_metrics)
-- ────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS sns_metrics CASCADE;

CREATE TABLE sns_metrics (
  platform_key TEXT        NOT NULL
                           CHECK (platform_key IN
                             ('youtube','fb_page','fb_group','instagram','twitter','threads')),
  metric_date  DATE        NOT NULL,
  count        INTEGER     NOT NULL CHECK (count >= 0),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (platform_key, metric_date)
);

CREATE INDEX idx_sns_metrics_platform ON sns_metrics(platform_key, metric_date DESC);

-- ────────────────────────────────────────────────────────────────
-- 4. Row Level Security (RLS) 활성화
-- ────────────────────────────────────────────────────────────────
ALTER TABLE work_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE sns_metrics  ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────────
-- 5. RLS 정책 — anon 사용자 전체 CRUD 허용
-- ────────────────────────────────────────────────────────────────
-- ⚠️ 보안 트레이드오프: anon key를 아는 사람은 Supabase API로 직접 접근 가능합니다.
--    추후 Supabase Auth(매직링크 등)를 도입하면 더 강하게 제한할 수 있습니다.

-- work_entries 정책
CREATE POLICY "anon_select_work_entries"
  ON work_entries FOR SELECT
  TO anon USING (true);

CREATE POLICY "anon_insert_work_entries"
  ON work_entries FOR INSERT
  TO anon WITH CHECK (true);

CREATE POLICY "anon_update_work_entries"
  ON work_entries FOR UPDATE
  TO anon USING (true) WITH CHECK (true);

CREATE POLICY "anon_delete_work_entries"
  ON work_entries FOR DELETE
  TO anon USING (true);

-- sns_metrics 정책
CREATE POLICY "anon_select_sns_metrics"
  ON sns_metrics FOR SELECT
  TO anon USING (true);

CREATE POLICY "anon_insert_sns_metrics"
  ON sns_metrics FOR INSERT
  TO anon WITH CHECK (true);

CREATE POLICY "anon_update_sns_metrics"
  ON sns_metrics FOR UPDATE
  TO anon USING (true) WITH CHECK (true);

CREATE POLICY "anon_delete_sns_metrics"
  ON sns_metrics FOR DELETE
  TO anon USING (true);

-- ────────────────────────────────────────────────────────────────
-- 6. Realtime 게시 설정
-- ────────────────────────────────────────────────────────────────
-- Supabase Realtime이 변경사항을 구독자에게 전송할 수 있도록 설정
ALTER PUBLICATION supabase_realtime ADD TABLE work_entries;
ALTER PUBLICATION supabase_realtime ADD TABLE sns_metrics;

-- ────────────────────────────────────────────────────────────────
-- 7. Storage 버킷 — work-images
-- ────────────────────────────────────────────────────────────────
-- 방법 A: SQL로 생성 (supabase_storage_admin 역할 필요)
-- 버킷 생성이 SQL Editor에서 되지 않는 경우 방법 B를 사용하세요.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'work-images',
  'work-images',
  true,           -- 공개 버킷 (이미지 URL 공개 접근 허용)
  5242880,        -- 5MB 제한
  ARRAY['image/jpeg','image/png','image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- Storage RLS 정책 (anon 업로드/조회 허용)
CREATE POLICY "anon_upload_work_images"
  ON storage.objects FOR INSERT
  TO anon WITH CHECK (bucket_id = 'work-images');

CREATE POLICY "anon_select_work_images"
  ON storage.objects FOR SELECT
  TO anon USING (bucket_id = 'work-images');

CREATE POLICY "anon_delete_work_images"
  ON storage.objects FOR DELETE
  TO anon USING (bucket_id = 'work-images');

-- ────────────────────────────────────────────────────────────────
-- 8. 초기 데이터 확인 쿼리 (선택사항 — 실행 후 확인용)
-- ────────────────────────────────────────────────────────────────
-- 아래 주석을 해제하면 설정이 제대로 됐는지 확인할 수 있습니다.
--
-- SELECT tablename, rowsecurity FROM pg_tables
--   WHERE schemaname = 'public' AND tablename IN ('work_entries','sns_metrics');
--
-- SELECT schemaname, tablename, policyname, roles, cmd
--   FROM pg_policies
--   WHERE tablename IN ('work_entries','sns_metrics');
--
-- SELECT id, name, public FROM storage.buckets WHERE id = 'work-images';

-- ================================================================
-- 완료! 이제 index.html 상단의 SUPABASE_URL과 SUPABASE_ANON_KEY를
-- 본인 프로젝트 값으로 교체하면 됩니다.
-- ================================================================
