-- World DB manager support schema
-- Multi-layer knowledge management support for gensokyo-db-manager.

create extension if not exists pgcrypto;

create table if not exists public.world_admin_signals (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  signal_type text not null,
  entity_kind text not null default '',
  entity_id text,
  entity_name text,
  source_text text,
  source_url text,
  observed_in text not null default 'user_interaction',
  reason text,
  user_message text,
  assistant_message text,
  proposed_fields jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create table if not exists public.world_schema_proposals (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  need text,
  candidate_name text,
  observed_fields jsonb not null default '[]'::jsonb,
  expected_rows integer not null default 0,
  repeats_per_entity integer not null default 0,
  requires_history boolean not null default false,
  context jsonb not null default '{}'::jsonb,
  decision text not null,
  reason text not null,
  suggested_table text,
  suggested_columns jsonb not null default '[]'::jsonb,
  status text not null default 'proposed',
  created_at timestamptz not null default now()
);

create table if not exists public.world_manager_policies (
  policy_key text primary key,
  policy_value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.world_knowledge_sources (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  source_kind text not null,
  title text not null,
  source_url text,
  canonical_url text,
  citation text,
  origin text,
  authority_score numeric(5,4) not null default 0.5000,
  published_at timestamptz,
  retrieved_at timestamptz not null default now(),
  quote_excerpt text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.world_knowledge_claims (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  entity_kind text not null,
  entity_id text,
  topic text,
  claim_type text not null default 'fact',
  claim_fingerprint text,
  layer text not null,
  claim_text text not null,
  confidence numeric(5,4) not null default 0.8000,
  temporal_scope text,
  status text not null default 'pending',
  review_note text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.world_knowledge_claim_sources (
  claim_id uuid not null references public.world_knowledge_claims(id) on delete cascade,
  source_id uuid not null references public.world_knowledge_sources(id) on delete cascade,
  support_type text not null default 'supports',
  quote_excerpt text,
  created_at timestamptz not null default now(),
  primary key (claim_id, source_id)
);

create table if not exists public.world_knowledge_conflicts (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  entity_kind text not null,
  entity_id text,
  topic text,
  resolution_status text not null default 'open',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.world_knowledge_conflict_members (
  conflict_id uuid not null references public.world_knowledge_conflicts(id) on delete cascade,
  claim_id uuid not null references public.world_knowledge_claims(id) on delete cascade,
  stance text not null default 'competing',
  created_at timestamptz not null default now(),
  primary key (conflict_id, claim_id)
);

create table if not exists public.world_discovery_sources (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  source_name text not null,
  source_kind text not null,
  start_url text not null,
  entity_kind text,
  entity_id text,
  topic text,
  claim_type text not null default 'fact',
  layer text not null default 'official_secondary',
  include_patterns jsonb not null default '[]'::jsonb,
  exclude_patterns jsonb not null default '[]'::jsonb,
  max_urls_per_run integer not null default 20,
  metadata jsonb not null default '{}'::jsonb,
  status text not null default 'active',
  last_discovered_at timestamptz,
  last_discovery_note text,
  created_at timestamptz not null default now()
);

create table if not exists public.world_web_ingest_queue (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  url text not null,
  canonical_url text,
  source_kind text not null,
  entity_kind text,
  entity_id text,
  topic text,
  claim_type text not null default 'fact',
  layer text not null default 'official_secondary',
  extract_as_claim boolean not null default true,
  title text,
  summary text,
  note text,
  status text not null default 'queued',
  created_at timestamptz not null default now()
);

alter table public.world_web_ingest_queue add column if not exists topic text;
alter table public.world_web_ingest_queue add column if not exists claim_type text not null default 'fact';
alter table public.world_web_ingest_queue add column if not exists layer text not null default 'official_secondary';
alter table public.world_web_ingest_queue add column if not exists extract_as_claim boolean not null default true;
alter table public.world_web_ingest_queue add column if not exists canonical_url text;
alter table public.world_knowledge_sources add column if not exists canonical_url text;
alter table public.world_knowledge_claims add column if not exists claim_fingerprint text;

create table if not exists public.world_approval_actions (
  id uuid primary key default gen_random_uuid(),
  target_type text not null,
  target_id text not null,
  action text not null,
  reviewer text not null default 'system',
  note text,
  created_at timestamptz not null default now()
);

create table if not exists public.world_manager_job_runs (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  job_type text not null,
  status text not null default 'running',
  success_count integer not null default 0,
  error_count integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.world_manager_job_items (
  id uuid primary key default gen_random_uuid(),
  run_id uuid not null references public.world_manager_job_runs(id) on delete cascade,
  item_key text not null,
  status text not null,
  category text,
  message text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.world_harvest_plans (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  task_type text not null,
  entity_kind text,
  entity_id text,
  topic text,
  priority numeric(5,4) not null default 0.5000,
  reason text not null,
  suggested_source_name text,
  suggested_start_url text,
  status text not null default 'planned',
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_world_admin_signals_world_created
  on public.world_admin_signals(world_id, created_at desc);
create index if not exists idx_world_admin_signals_status
  on public.world_admin_signals(status, created_at desc);
create index if not exists idx_world_schema_proposals_world_created
  on public.world_schema_proposals(world_id, created_at desc);
create index if not exists idx_world_schema_proposals_status
  on public.world_schema_proposals(status, created_at desc);
create index if not exists idx_world_manager_job_runs_world_created
  on public.world_manager_job_runs(world_id, created_at desc);
create index if not exists idx_world_manager_job_runs_type_created
  on public.world_manager_job_runs(job_type, created_at desc);
create index if not exists idx_world_manager_job_items_run_created
  on public.world_manager_job_items(run_id, created_at asc);
create index if not exists idx_world_harvest_plans_world_created
  on public.world_harvest_plans(world_id, created_at desc);
create index if not exists idx_world_knowledge_sources_world_created
  on public.world_knowledge_sources(world_id, created_at desc);
create unique index if not exists idx_world_knowledge_sources_world_canonical
  on public.world_knowledge_sources(world_id, canonical_url)
  where canonical_url is not null;
create index if not exists idx_world_knowledge_claims_world_status
  on public.world_knowledge_claims(world_id, status, created_at desc);
create index if not exists idx_world_knowledge_claims_entity
  on public.world_knowledge_claims(world_id, entity_kind, entity_id, claim_type);
create unique index if not exists idx_world_knowledge_claims_world_fingerprint
  on public.world_knowledge_claims(world_id, claim_fingerprint)
  where claim_fingerprint is not null;
create index if not exists idx_world_knowledge_conflicts_world_created
  on public.world_knowledge_conflicts(world_id, created_at desc);
create index if not exists idx_world_discovery_sources_world_status
  on public.world_discovery_sources(world_id, status, created_at desc);
create index if not exists idx_world_web_ingest_queue_world_status
  on public.world_web_ingest_queue(world_id, status, created_at desc);
create unique index if not exists idx_world_web_ingest_queue_canonical
  on public.world_web_ingest_queue(canonical_url)
  where canonical_url is not null;
