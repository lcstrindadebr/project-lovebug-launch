-- ==========================================================
-- BIVVO COMPLETE DATABASE SCHEMA (VPS/EXTERNAL DEPLOY)
-- Generated on: 2026-05-19
-- ==========================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_net";

-- 2. ENUMS
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'app_role') THEN
        CREATE TYPE public.app_role AS ENUM ('admin', 'affiliate');
    END IF;
END
$$;

-- 3. TABLES (Re-applying core tables with idempotency)

-- Customers
CREATE TABLE IF NOT EXISTS public.customers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    email text NOT NULL UNIQUE,
    phone text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- Users (Profiles)
CREATE TABLE IF NOT EXISTS public.users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    email text NOT NULL UNIQUE,
    whatsapp text,
    cpf text,
    billing_name text,
    cep text,
    endereco text,
    numero text,
    complemento text,
    bairro text,
    cidade text,
    estado text,
    plano_ativo text,
    data_expiracao timestamptz,
    asaas_customer_id text,
    status text DEFAULT 'pending',
    asaas_subscription_id text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Subscriptions
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    plan_slug text NOT NULL,
    users_count int NOT NULL DEFAULT 1,
    channels_config jsonb NOT NULL DEFAULT '{}',
    is_protagonista boolean NOT NULL DEFAULT false,
    has_telefonia boolean NOT NULL DEFAULT false,
    channels_discount int NOT NULL DEFAULT 0,
    status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'past_due', 'canceled')),
    account_created boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- User Roles
CREATE TABLE IF NOT EXISTS public.user_roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role public.app_role NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(user_id, role)
);

-- Payments
CREATE TABLE IF NOT EXISTS public.payments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
    plan text NOT NULL,
    amount numeric NOT NULL,
    status text DEFAULT 'pending',
    asaas_payment_id text,
    asaas_subscription_id text,
    paid_at timestamptz,
    created_at timestamptz DEFAULT now()
);

-- Plans
CREATE TABLE IF NOT EXISTS public.plans (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug text NOT NULL UNIQUE,
    name text NOT NULL,
    price numeric NOT NULL,
    price_recurring numeric NOT NULL DEFAULT 0,
    description text,
    features jsonb NOT NULL DEFAULT '[]',
    popular boolean DEFAULT false,
    sort_order integer DEFAULT 0,
    active boolean DEFAULT true,
    gradient text DEFAULT 'from-blue-500 to-indigo-500',
    icon text DEFAULT 'Package',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Settings
CREATE TABLE IF NOT EXISTS public.settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    key text NOT NULL UNIQUE,
    value text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Coupons
CREATE TABLE IF NOT EXISTS public.coupons (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text NOT NULL UNIQUE,
    discount_type text NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value numeric NOT NULL,
    active boolean DEFAULT true,
    expires_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Affiliates
CREATE TABLE IF NOT EXISTS public.affiliates (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    name text NOT NULL,
    email text NOT NULL UNIQUE,
    whatsapp text,
    document text,
    slug text NOT NULL UNIQUE,
    status text NOT NULL DEFAULT 'active',
    commission_percent numeric NOT NULL DEFAULT 20,
    commission_recurring boolean NOT NULL DEFAULT false,
    pix_key text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Grants
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT SELECT ON public.plans, public.settings, public.coupons TO anon;

-- Apply Missing Columns and features from migrations 003-009
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS person_type text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS company_name text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bivvo_config jsonb;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bivvo_tenant_id text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS overdue_since timestamptz;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS inactivated_at timestamptz;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bivvo_config_previous jsonb;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bivvo_config_updated_at timestamptz;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bivvo_config_synced_bivvo jsonb;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bivvo_config_synced_bivvo_at timestamptz;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bivvo_config_synced_asaas_value numeric;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS bivvo_config_synced_asaas_at timestamptz;

-- Tasks (Migration 003 + 005)
CREATE TABLE IF NOT EXISTS public.tasks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  description TEXT,
  status      TEXT NOT NULL DEFAULT 'todo',
  priority    TEXT NOT NULL DEFAULT 'medium',
  assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  due_date    TIMESTAMPTZ,
  completed_at timestamptz,
  subtasks    jsonb NOT NULL DEFAULT '[]'::jsonb,
  waiting_third_party boolean NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Admin Secrets (Migration 008 + 009)
CREATE TABLE IF NOT EXISTS public.admin_secrets (
  key        text PRIMARY KEY,
  value      text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Logs (Migration 007)
CREATE TABLE IF NOT EXISTS public.system_logs (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source     text NOT NULL,
  level      text NOT NULL DEFAULT 'info',
  message    text NOT NULL,
  context    jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid,
  action     text NOT NULL,
  table_name text,
  record_id  text,
  old_data   jsonb,
  new_data   jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Hardening RLS (Migration 004)
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_secrets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins manage tasks" ON public.tasks;
CREATE POLICY "Admins manage tasks" ON public.tasks FOR ALL USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "Admins manage admin_secrets" ON public.admin_secrets;
CREATE POLICY "Admins manage admin_secrets" ON public.admin_secrets FOR ALL USING (public.has_role(auth.uid(), 'admin'));
