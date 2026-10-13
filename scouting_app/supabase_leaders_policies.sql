-- ESEGUI QUESTO SCRIPT NEL SQL EDITOR DI SUPABASE PER ATTIVARE LE APPROVAZIONI

-- 1. Eliminiamo policy pre-esistenti se ci sono conflitti
DROP POLICY IF EXISTS "I capi possono aggiornare i profili" ON public.profiles;

-- 2. Creiamo la policy per permettere ai Capi di AGGIORNARE i profili degli altri
-- Nota: Usiamo la funzione sicura 'public.get_user_role' che abbiamo creato prima.
CREATE POLICY "I capi possono aggiornare i profili" 
ON public.profiles FOR UPDATE 
TO authenticated 
USING ( public.get_user_role(auth.uid()) = 'capo' )
WITH CHECK ( public.get_user_role(auth.uid()) = 'capo' );

-- Assicuriamoci anche di poter eliminare i profili (se il capo rifiuta una registrazione)
DROP POLICY IF EXISTS "I capi possono eliminare i profili" ON public.profiles;
CREATE POLICY "I capi possono eliminare i profili" 
ON public.profiles FOR DELETE 
TO authenticated 
USING ( public.get_user_role(auth.uid()) = 'capo' );
