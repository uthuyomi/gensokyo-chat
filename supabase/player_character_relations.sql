-- Project Sigmaris - Player ↔ Character relations (Touhou-talk)
-- ============================================================
-- Additive migration (safe to run multiple times).
-- Intended to be run in Supabase SQL Editor.
--
-- Purpose:
-- - Persist user-specific relationship state per character.
-- - Used by:
--   - touhou-talk-ui (persona prompt injection)
--   - gensokyo-world-engine (planner context + updates)
--
-- NOTE:
-- - Keep this table in public schema for now (RLS can be added later).

create extension if not exists pgcrypto;

create table if not exists public.player_character_relations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  character_id text not null,

  affinity double precision not null default 0,
  trust double precision not null default 0,
  friendship double precision not null default 0,
  role text,

  last_updated timestamptz not null default now(),

  unique (user_id, character_id)
);

create index if not exists idx_player_character_relations_user
  on public.player_character_relations (user_id, last_updated desc);

-- RLS (align with existing "common_*" tables: users can only read/write their own rows).
alter table public.player_character_relations enable row level security;

drop policy if exists player_character_relations_select_own on public.player_character_relations;
create policy player_character_relations_select_own
  on public.player_character_relations for select
  using (auth.uid() = user_id);

drop policy if exists player_character_relations_insert_own on public.player_character_relations;
create policy player_character_relations_insert_own
  on public.player_character_relations for insert
  with check (auth.uid() = user_id);

drop policy if exists player_character_relations_update_own on public.player_character_relations;
create policy player_character_relations_update_own
  on public.player_character_relations for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists player_character_relations_delete_own on public.player_character_relations;
create policy player_character_relations_delete_own
  on public.player_character_relations for delete
  using (auth.uid() = user_id);
