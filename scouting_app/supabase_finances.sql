-- =================================================================================
-- FASE 5: GESTIONE FINANZIARIA (Censimenti e Quote Eventi)
-- DA ESEGUIRE SU SUPABASE SQL EDITOR
-- =================================================================================

-- 1. Tabelle
CREATE TABLE IF NOT EXISTS public.censimenti (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  anno integer NOT NULL,
  status text NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
  ricevuta_url text NOT NULL,
  validated_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(profile_id, anno) -- Un solo caricamento valido per anno
);

CREATE TABLE IF NOT EXISTS public.event_payments (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id uuid NOT NULL, -- references events (if exists, but we don't have events explicitly defined in SQL here, so we assume it exists or just UUID)
  profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  has_paid boolean DEFAULT false NOT NULL,
  verified_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(event_id, profile_id)
);

-- Abilitiamo RLS
ALTER TABLE public.censimenti ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_payments ENABLE ROW LEVEL SECURITY;

-- 2. Policy Censimenti
-- I capi (e in futuro logistica) possono leggere tutto
CREATE POLICY "Lettura censimenti capi" 
ON public.censimenti FOR SELECT 
TO authenticated 
USING ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') );

-- L'utente può leggere il suo censimento
CREATE POLICY "Lettura censimento personale" 
ON public.censimenti FOR SELECT 
TO authenticated 
USING ( auth.uid() = profile_id );

-- L'utente può inserire il suo censimento
CREATE POLICY "Inserimento censimento" 
ON public.censimenti FOR INSERT 
TO authenticated 
WITH CHECK ( auth.uid() = profile_id );

-- I capi possono approvare/rifiutare censimenti (update)
CREATE POLICY "Approvazione censimenti" 
ON public.censimenti FOR UPDATE 
TO authenticated 
USING ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') )
WITH CHECK ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') );

-- L'utente può eliminare la propria richiesta (se pending) per reinviarla
CREATE POLICY "Eliminazione censimento pending" 
ON public.censimenti FOR DELETE 
TO authenticated 
USING ( auth.uid() = profile_id AND status = 'pending' );

-- 3. Policy Quote Eventi (event_payments)
-- Chiunque (autenticato) può leggere (in quanto i partecipanti devono sapere se hanno pagato)
-- Però per privacy limitiamo a: se stessi, capi, o se abilitati logistica (ma lo facciamo leggere ai soci per i loro)
CREATE POLICY "Lettura quote proprie" 
ON public.event_payments FOR SELECT 
TO authenticated 
USING ( auth.uid() = profile_id );

CREATE POLICY "Lettura quote per capi" 
ON public.event_payments FOR SELECT 
TO authenticated 
USING ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') );

-- Inserimento e Modifica (solo capi)
CREATE POLICY "Inserimento quote capi" 
ON public.event_payments FOR INSERT 
TO authenticated 
WITH CHECK ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') );

CREATE POLICY "Modifica quote capi" 
ON public.event_payments FOR UPDATE 
TO authenticated 
USING ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') );


-- 4. Storage Bucket
-- Creazione del bucket se non esiste. Usa l'interfaccia SQL (richiede permessi superuser, se fallisce creare da UI Supabase)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('private_documents', 'private_documents', false)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies
-- SELECT: proprietario del file o capi
CREATE POLICY "Accesso documenti privati personale"
ON storage.objects FOR SELECT
TO authenticated
USING ( bucket_id = 'private_documents' AND (storage.foldername(name))[1] = auth.uid()::text );

CREATE POLICY "Accesso documenti privati capi"
ON storage.objects FOR SELECT
TO authenticated
USING ( bucket_id = 'private_documents' AND public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') );

-- INSERT: proprietario del file (deve caricare nella propria cartella, es: "uuid_utente/ricevuta.pdf")
CREATE POLICY "Caricamento documenti privati"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'private_documents' AND (storage.foldername(name))[1] = auth.uid()::text );

-- DELETE: proprietario del file o capi
CREATE POLICY "Eliminazione documenti privati"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'private_documents' AND ( (storage.foldername(name))[1] = auth.uid()::text OR public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') ) );
