-- 1. Creazione Enum per lo stato dei campetti
DO $$ BEGIN
    CREATE TYPE campetto_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Creazione della tabella campetti
CREATE TABLE IF NOT EXISTS public.campetti (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  titolo text NOT NULL,
  tipo text NOT NULL,
  data_inizio date NOT NULL,
  data_fine date NOT NULL,
  
  status campetto_status NOT NULL DEFAULT 'pending',
  validated_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Abilitiamo la Row Level Security (RLS)
ALTER TABLE public.campetti ENABLE ROW LEVEL SECURITY;

-- 3. Funzione Helper Sicura per leggere la Branca
CREATE OR REPLACE FUNCTION public.get_user_branch(user_id uuid)
RETURNS text AS $$
DECLARE
  user_branch_val text;
BEGIN
  SELECT branch::text INTO user_branch_val FROM public.profiles WHERE id = user_id;
  RETURN user_branch_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Creazione Policy RLS
DROP POLICY IF EXISTS "Utenti possono inserire i propri campetti" ON public.campetti;
DROP POLICY IF EXISTS "Lettura campetti in base a privacy" ON public.campetti;
DROP POLICY IF EXISTS "Approvazione campetti (Update)" ON public.campetti;
DROP POLICY IF EXISTS "Utenti possono eliminare propri campetti se pending" ON public.campetti;
DROP POLICY IF EXISTS "Capi gruppo possono eliminare campetti" ON public.campetti;

-- POLICY INSERT: Ognuno può inserire un campetto per se stesso
CREATE POLICY "Utenti possono inserire i propri campetti" 
ON public.campetti FOR INSERT 
TO authenticated 
WITH CHECK ( auth.uid() = profile_id );

-- POLICY SELECT:
CREATE POLICY "Lettura campetti in base a privacy" 
ON public.campetti FOR SELECT 
TO authenticated 
USING (
  auth.uid() = profile_id 
  OR 
  ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') AND LOWER(public.get_user_branch(auth.uid())) IN ('co.ca.', 'gruppo') )
  OR
  ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') AND public.get_user_role(profile_id) IN ('capo', 'capo gruppo') )
  OR
  ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') 
    AND public.get_user_role(profile_id) NOT IN ('capo', 'capo gruppo') 
    AND LOWER(public.get_user_branch(auth.uid())) = LOWER(public.get_user_branch(profile_id)) )
);

-- POLICY UPDATE (Per la Validazione):
CREATE POLICY "Approvazione campetti (Update)" 
ON public.campetti FOR UPDATE 
TO authenticated 
USING (
  ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') AND LOWER(public.get_user_branch(auth.uid())) IN ('co.ca.', 'gruppo') )
  OR
  ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') 
    AND public.get_user_role(profile_id) NOT IN ('capo', 'capo gruppo') 
    AND LOWER(public.get_user_branch(auth.uid())) = LOWER(public.get_user_branch(profile_id)) )
)
WITH CHECK (
  ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') AND LOWER(public.get_user_branch(auth.uid())) IN ('co.ca.', 'gruppo') )
  OR
  ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') 
    AND public.get_user_role(profile_id) NOT IN ('capo', 'capo gruppo') 
    AND LOWER(public.get_user_branch(auth.uid())) = LOWER(public.get_user_branch(profile_id)) )
);

-- POLICY DELETE:
-- L'utente può eliminare il proprio campetto finché è pending
CREATE POLICY "Utenti possono eliminare propri campetti se pending" 
ON public.campetti FOR DELETE 
TO authenticated 
USING ( auth.uid() = profile_id AND status = 'pending' );

-- Capi Gruppo possono eliminare qualsiasi campetto (opzionale per pulizia)
CREATE POLICY "Capi gruppo possono eliminare campetti"
ON public.campetti FOR DELETE
TO authenticated
USING ( public.get_user_role(auth.uid()) = 'capo' AND public.get_user_branch(auth.uid()) = 'Co.Ca.' );
