-- Project Sigmaris - Character-scoped episodic memory (Sigmaris Persona Core)
-- ============================================================
-- Additive migration (safe to run multiple times).
-- Intended to be run in Supabase SQL Editor.
--
-- Goal:
-- - Extend common_episodes to be scoped by (user_id, character_id) in queries.
-- - Keep backward compatibility: character_id is nullable.

alter table if exists public.common_episodes
  add column if not exists character_id text null;

create index if not exists idx_common_episodes_user_character_timestamp
  on public.common_episodes (user_id, character_id, timestamp desc);

