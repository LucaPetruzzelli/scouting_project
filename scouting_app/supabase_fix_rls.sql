-- ESEGUI QUESTO SCRIPT NEL SQL EDITOR DI SUPABASE PER RISOLVERE L'ERRORE

-- 1. Eliminiamo le policy che causano la ricorsione infinita
DROP POLICY IF EXISTS "I capi possono leggere tutti i profili" ON public.profiles;
DROP POLICY IF EXISTS "I capi possono leggere tutti i contatti" ON public.parents_contacts;

-- 2. Creiamo una funzione "Security Definer" che bypassa RLS per leggere il ruolo
-- Questo evita la ricorsione perché la funzione gira come amministratore interno.
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text AS $$
DECLARE
  user_role_val text;
BEGIN
  SELECT role::text INTO user_role_val FROM public.profiles WHERE id = user_id;
  RETURN user_role_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Ricreiamo le policy usando la nuova funzione sicura
CREATE POLICY "I capi possono leggere tutti i profili" 
ON public.profiles FOR SELECT 
TO authenticated 
USING ( public.get_user_role(auth.uid()) = 'capo' );

CREATE POLICY "I capi possono leggere tutti i contatti" 
ON public.parents_contacts FOR SELECT 
TO authenticated 
USING ( public.get_user_role(auth.uid()) = 'capo' );
