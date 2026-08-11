-- Migration 012: Eisenhower Matrix and Departments
-- Added to public.tasks: is_important, is_urgent, department

ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS is_important boolean NOT NULL DEFAULT true;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS is_urgent boolean NOT NULL DEFAULT false;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS department text;

-- Backfill based on existing priority
UPDATE public.tasks SET 
  is_important = CASE WHEN priority = 'low' THEN false ELSE true END,
  is_urgent = CASE WHEN priority = 'high' THEN true ELSE false END
WHERE is_important = true AND is_urgent = false; -- only if defaults are still there

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_tasks_department ON public.tasks(department);
CREATE INDEX IF NOT EXISTS idx_tasks_eisenhower ON public.tasks(is_important, is_urgent);
