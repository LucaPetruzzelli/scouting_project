-- RUN THIS SCRIPT IN SUPABASE SQL EDITOR

-- 1. Create Enums
CREATE TYPE user_role AS ENUM ('socio', 'capo', 'genitore');
CREATE TYPE user_branch AS ENUM ('branco', 'reparto', 'clan', 'gruppo');
CREATE TYPE user_status AS ENUM ('pending', 'active', 'rejected');

-- 2. Create Profiles Table
CREATE TABLE public.profiles (
  id uuid REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  role user_role NOT NULL DEFAULT 'socio',
  branch user_branch,
  status user_status NOT NULL DEFAULT 'pending',
  
  -- Dati Anagrafici
  nome text NOT NULL,
  cognome text NOT NULL,
  genere text NOT NULL,
  data_di_nascita date NOT NULL,
  
  -- Contatti
  email text NOT NULL,
  telefono text,
  
  -- Indirizzo
  indirizzo text,
  civico text,
  cap text,
  comune text,
  provincia text,
  
  -- Audit
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Abilita RLS per Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy: I Capi possono leggere tutti i profili
CREATE POLICY "I capi possono leggere tutti i profili" 
ON public.profiles FOR SELECT 
TO authenticated 
USING ( (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'capo' );

-- Policy: Gli utenti possono leggere il proprio profilo
CREATE POLICY "Gli utenti possono leggere il proprio profilo" 
ON public.profiles FOR SELECT 
TO authenticated 
USING ( auth.uid() = id );

-- Policy: Permetti inserimento al momento della registrazione
CREATE POLICY "Inserimento profilo post-registrazione" 
ON public.profiles FOR INSERT 
TO authenticated 
WITH CHECK ( auth.uid() = id );

-- Policy: Permetti agli utenti di aggiornare il proprio profilo (limitato in futuro)
CREATE POLICY "Aggiornamento proprio profilo" 
ON public.profiles FOR UPDATE 
TO authenticated 
USING ( auth.uid() = id );


-- 3. Create Parents/Emergency Contacts Table
CREATE TABLE public.parents_contacts (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  
  nome text NOT NULL,
  cognome text,
  email text,
  telefono text NOT NULL,
  
  is_emergency_contact boolean DEFAULT false,
  
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Abilita RLS per Parents Contacts
ALTER TABLE public.parents_contacts ENABLE ROW LEVEL SECURITY;

-- Policy: I Capi possono leggere tutti i contatti
CREATE POLICY "I capi possono leggere tutti i contatti" 
ON public.parents_contacts FOR SELECT 
TO authenticated 
USING ( (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'capo' );

-- Policy: L'utente può leggere i contatti collegati al suo profilo
CREATE POLICY "Gli utenti possono leggere i contatti collegati" 
ON public.parents_contacts FOR SELECT 
TO authenticated 
USING ( auth.uid() = profile_id );

-- Policy: Inserimento consentito post-registrazione
CREATE POLICY "Inserimento contatti post-registrazione" 
ON public.parents_contacts FOR INSERT 
TO authenticated 
WITH CHECK ( auth.uid() = profile_id );
