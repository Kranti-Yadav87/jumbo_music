-- Shared lyrics cache. Only the edge function (service role) can read/write:
-- RLS is enabled and there are intentionally NO policies for anon/authenticated.
create table if not exists public.lyrics_cache (
  key        text primary key,
  lyrics     text,
  found      boolean not null default true,
  updated_at timestamptz not null default now()
);

alter table public.lyrics_cache enable row level security;
