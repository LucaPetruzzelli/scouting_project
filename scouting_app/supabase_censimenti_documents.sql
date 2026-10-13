-- =================================================================================
-- FASE 5 (AGGIORNAMENTO): DOCUMENTI CENSIMENTO MULTIPLI
-- DA ESEGUIRE SU SUPABASE SQL EDITOR
-- =================================================================================

-- 1. Rimuoviamo la vecchia tabella (se avevi caricato dei test andranno persi)
DROP TABLE IF EXISTS public.censimenti CASCADE;

-- 2. Creiamo la nuova tabella per i documenti
CREATE TABLE IF NOT EXISTS public.censimenti_documents (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  anno integer NOT NULL,
  document_type text NOT NULL, -- es. 'Ricevuta Bonifico', 'Scheda Medica', 'Privacy', etc.
  file_url text NOT NULL,
  status text NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
  validated_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Abilitiamo RLS
ALTER TABLE public.censimenti_documents ENABLE ROW LEVEL SECURITY;

-- 3. Policy per censimenti_documents

-- I capi possono leggere tutti i documenti di tutti i soci
CREATE POLICY "Lettura documenti capi" 
ON public.censimenti_documents FOR SELECT 
TO authenticated 
USING ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') );

-- L'utente può leggere solo i propri documenti
CREATE POLICY "Lettura documenti personale" 
ON public.censimenti_documents FOR SELECT 
TO authenticated 
USING ( auth.uid() = profile_id );

-- L'utente può inserire un proprio documento
CREATE POLICY "Inserimento documenti" 
ON public.censimenti_documents FOR INSERT 
TO authenticated 
WITH CHECK ( auth.uid() = profile_id );

-- I capi possono approvare/rifiutare i documenti (update status/validated_by)
CREATE POLICY "Approvazione documenti" 
ON public.censimenti_documents FOR UPDATE 
TO authenticated 
USING ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') )
WITH CHECK ( public.get_user_role(auth.uid()) IN ('capo', 'capo gruppo') );

-- L'utente può aggiornare/eliminare un documento SE è in stato 'pending' o 'rejected'
CREATE POLICY "Update documenti propri non approvati" 
ON public.censimenti_documents FOR UPDATE 
TO authenticated 
USING ( auth.uid() = profile_id AND status != 'approved' )
WITH CHECK ( auth.uid() = profile_id AND status != 'approved' );

CREATE POLICY "Eliminazione documenti propri non approvati" 
ON public.censimenti_documents FOR DELETE 
TO authenticated 
USING ( auth.uid() = profile_id AND status != 'approved' );
