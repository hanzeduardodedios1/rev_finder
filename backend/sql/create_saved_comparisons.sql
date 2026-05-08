-- Run in Supabase SQL editor (or via migration tooling).
-- Enables POST /api/favorites/comparison inserts.

CREATE TABLE IF NOT EXISTS public.saved_comparisons (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
    bike_a_id text NOT NULL,
    bike_b_id text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    summary text
);

CREATE INDEX IF NOT EXISTS saved_comparisons_user_id_idx
    ON public.saved_comparisons (user_id);

ALTER TABLE public.saved_comparisons ENABLE ROW LEVEL SECURITY;
