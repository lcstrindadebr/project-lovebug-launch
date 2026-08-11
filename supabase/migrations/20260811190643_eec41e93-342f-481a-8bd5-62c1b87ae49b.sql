-- 012_eisenhower_matrix_and_departments.sql
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS is_important boolean NOT NULL DEFAULT true;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS is_urgent boolean NOT NULL DEFAULT false;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS department text;

-- Backfill based on current priority
UPDATE public.tasks SET 
  is_important = CASE WHEN priority IN ('high', 'medium') THEN true ELSE false END,
  is_urgent = CASE WHEN priority = 'high' THEN true ELSE false END
WHERE is_important = true AND is_urgent = false; -- only apply if defaults haven't been changed manually

GRANT SELECT, INSERT, UPDATE, DELETE ON public.tasks TO authenticated;
GRANT ALL ON public.tasks TO service_role;
