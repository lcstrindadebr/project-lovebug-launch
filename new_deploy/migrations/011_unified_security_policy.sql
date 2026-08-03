-- Unified Security Policy for Bivvo
-- Ensures that Admins (via has_role) have full access to all relevant tables
-- and prevents RLS errors like the one encountered in 'tasks'.

-- 1. Hardening existing tables with unified 'authenticated' access for admins
DO $$
DECLARE
    t text;
    tables_to_harden text[] := ARRAY[
        'customers', 'users', 'subscriptions', 'user_roles', 'payments', 
        'plans', 'coupons', 'affiliates', 'affiliate_sales', 
        'affiliate_commissions', 'expenses', 'asaas_webhooks', 
        'settings', 'finance_events', 'system_logs', 'bivvo_config_change_logs',
        'finance_daily_snapshots', 'audit_logs', 'admin_secrets', 'channels', 'tasks'
    ];
BEGIN
    FOREACH t IN ARRAY tables_to_harden
    LOOP
        -- Grant permissions to authenticated users and service role
        EXECUTE format('GRANT ALL ON public.%I TO authenticated', t);
        EXECUTE format('GRANT ALL ON public.%I TO service_role', t);
        
        -- Remove loose policies and apply unified admin policy
        EXECUTE format('DROP POLICY IF EXISTS "Admins manage everything" ON public.%I', t);
        EXECUTE format('DROP POLICY IF EXISTS "Admins manage tasks" ON public.%I', t);
        EXECUTE format('DROP POLICY IF EXISTS "Admins manage secrets" ON public.%I', t);
        EXECUTE format('DROP POLICY IF EXISTS "Admins manage admin_secrets" ON public.%I', t);
        
        EXECUTE format('CREATE POLICY "Admins full access" ON public.%I FOR ALL TO authenticated USING (has_role(auth.uid(), ''admin'')) WITH CHECK (has_role(auth.uid(), ''admin''))', t);
    END LOOP;
END $$;

-- 2. Specific public access policies
-- Plans
DROP POLICY IF EXISTS "Plans are publicly readable" ON public.plans;
DROP POLICY IF EXISTS "Allow public select" ON public.plans;
CREATE POLICY "Public select plans" ON public.plans FOR SELECT TO public USING (true);
GRANT SELECT ON public.plans TO anon;

-- Channels
DROP POLICY IF EXISTS "Channels are publicly readable" ON public.channels;
CREATE POLICY "Public select channels" ON public.channels FOR SELECT TO public USING (true);
GRANT SELECT ON public.channels TO anon;

-- Settings (whitelisted)
DROP POLICY IF EXISTS "Public can read whitelisted settings" ON public.settings;
CREATE POLICY "Public read whitelisted settings" ON public.settings FOR SELECT TO public 
USING (key = ANY (ARRAY['site_url', 'site_name', 'support_email', 'support_whatsapp', 'cnpj', 'address', 'timezone', 'brand_logo_url', 'brand_logo_dark_url', 'favicon_url', 'brand_color_primary', 'brand_color_accent', 'brand_theme_default', 'ga_id', 'meta_pixel_id']));
GRANT SELECT ON public.settings TO anon;

-- 3. Ensure the admin user exists and has the role
INSERT INTO public.users (id, email, name, status, bivvo_status)
SELECT id, email, 'Admin Bivvo', 'active', 'active'
FROM auth.users
WHERE email = 'admin@bivvo.com.br'
ON CONFLICT (id) DO UPDATE SET bivvo_status = 'active';

INSERT INTO public.user_roles (user_id, role)
SELECT id, 'admin'::app_role
FROM auth.users
WHERE email = 'admin@bivvo.com.br'
ON CONFLICT (user_id, role) DO NOTHING;

-- 4. Audit & Logs
GRANT SELECT ON public.system_logs TO authenticated;
GRANT SELECT ON public.audit_logs TO authenticated;

COMMIT;
