-- World schema: vector-ready document and embedding layer
-- This layer keeps structured canon as the source of truth and adds
-- searchable document projections for vector indexing and later visualization.

create extension if not exists vector;

create table if not exists public.world_embedding_documents (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  source_kind text not null,
  source_ref_id text not null,
  source_title text not null,
  content text not null,
  source_updated_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (world_id, source_kind, source_ref_id)
);

create index if not exists idx_world_embedding_documents_lookup
  on public.world_embedding_documents(world_id, source_kind, source_ref_id);

create table if not exists public.world_embedding_jobs (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  document_id text references public.world_embedding_documents(id) on delete cascade,
  job_kind text not null default 'embed',
  status text not null default 'pending',
  embedding_model text,
  error_message text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_world_embedding_jobs_world_status
  on public.world_embedding_jobs(world_id, status, created_at desc);

create table if not exists public.world_embeddings (
  id text primary key,
  world_id text not null references public.worlds(id) on delete cascade,
  document_id text not null references public.world_embedding_documents(id) on delete cascade,
  embedding_model text not null,
  embedding_dimensions integer not null,
  embedding vector(1536),
  content_hash text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (document_id, embedding_model)
);

create index if not exists idx_world_embeddings_world_model
  on public.world_embeddings(world_id, embedding_model, updated_at desc);

create or replace view public.world_embedding_source_counts as
select world_id, source_kind, count(*) as document_count
from public.world_embedding_documents
group by world_id, source_kind;

create or replace function public.world_refresh_embedding_documents(
  p_world_id text default null
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_scope text;
  v_doc_count integer;
begin
  v_scope := coalesce(p_world_id, '');

  insert into public.world_embedding_documents (
    id,
    world_id,
    source_kind,
    source_ref_id,
    source_title,
    content,
    source_updated_at,
    metadata,
    updated_at
  )
  select
    'doc:canon_claim:' || c.id,
    c.world_id,
    'canon_claim',
    c.id,
    coalesce(c.summary, c.id),
    trim(
      both from concat_ws(
        E'\n\n',
        'Claim: ' || c.summary,
        'Subject: ' || c.subject_type || ' / ' || c.subject_id,
        'Claim Type: ' || c.claim_type,
        'Details: ' || coalesce(c.details::text, '{}')
      )
    ),
    c.updated_at,
    jsonb_build_object(
      'subject_type', c.subject_type,
      'subject_id', c.subject_id,
      'claim_type', c.claim_type,
      'source_id', c.source_id,
      'tags', c.tags,
      'confidence', c.confidence,
      'priority', c.priority
    ),
    now()
  from public.world_canon_claims c
  where p_world_id is null or c.world_id = p_world_id
  on conflict (id) do update
  set source_title = excluded.source_title,
      content = excluded.content,
      source_updated_at = excluded.source_updated_at,
      metadata = excluded.metadata,
      updated_at = excluded.updated_at;

  insert into public.world_embedding_documents (
    id,
    world_id,
    source_kind,
    source_ref_id,
    source_title,
    content,
    source_updated_at,
    metadata,
    updated_at
  )
  select
    'doc:lore:' || l.id,
    l.world_id,
    'lore_entry',
    l.id,
    l.title,
    trim(
      both from concat_ws(
        E'\n\n',
        l.title,
        l.summary,
        'Category: ' || l.category,
        'Details: ' || coalesce(l.details::text, '{}')
      )
    ),
    l.updated_at,
    jsonb_build_object(
      'category', l.category,
      'tags', l.tags,
      'priority', l.priority
    ),
    now()
  from public.world_lore_entries l
  where p_world_id is null or l.world_id = p_world_id
  on conflict (id) do update
  set source_title = excluded.source_title,
      content = excluded.content,
      source_updated_at = excluded.source_updated_at,
      metadata = excluded.metadata,
      updated_at = excluded.updated_at;

  insert into public.world_embedding_documents (
    id,
    world_id,
    source_kind,
    source_ref_id,
    source_title,
    content,
    source_updated_at,
    metadata,
    updated_at
  )
  select
    'doc:wiki_page:' || p.id,
    p.world_id,
    'wiki_page',
    p.id,
    p.title,
    trim(
      both from concat_ws(
        E'\n\n',
        p.title,
        p.summary,
        coalesce(
          string_agg(
            ws.heading || E'\n' || coalesce(ws.summary || E'\n', '') || ws.body,
            E'\n\n'
            order by ws.section_order
          ),
          ''
        )
      )
    ),
    greatest(
      p.updated_at,
      coalesce(max(ws.updated_at), p.updated_at)
    ),
    jsonb_build_object(
      'page_type', p.page_type,
      'subject_type', p.subject_type,
      'subject_id', p.subject_id,
      'status', p.status,
      'canonical_book_id', p.canonical_book_id
    ),
    now()
  from public.world_wiki_pages p
  left join public.world_wiki_page_sections ws
    on ws.page_id = p.id
  where p_world_id is null or p.world_id = p_world_id
  group by
    p.id,
    p.world_id,
    p.title,
    p.summary,
    p.page_type,
    p.subject_type,
    p.subject_id,
    p.status,
    p.canonical_book_id,
    p.updated_at
  on conflict (id) do update
  set source_title = excluded.source_title,
      content = excluded.content,
      source_updated_at = excluded.source_updated_at,
      metadata = excluded.metadata,
      updated_at = excluded.updated_at;

  insert into public.world_embedding_documents (
    id,
    world_id,
    source_kind,
    source_ref_id,
    source_title,
    content,
    source_updated_at,
    metadata,
    updated_at
  )
  select
    'doc:chronicle_entry:' || e.id,
    b.world_id,
    'chronicle_entry',
    e.id,
    e.title,
    trim(
      both from concat_ws(
        E'\n\n',
        e.title,
        e.summary,
        e.body
      )
    ),
    e.updated_at,
    jsonb_build_object(
      'book_id', e.book_id,
      'chapter_id', e.chapter_id,
      'entry_code', e.entry_code,
      'entry_type', e.entry_type,
      'subject_type', e.subject_type,
      'subject_id', e.subject_id,
      'tags', e.tags
    ),
    now()
  from public.world_chronicle_entries e
  join public.world_chronicle_books b
    on b.id = e.book_id
  where p_world_id is null or b.world_id = p_world_id
  on conflict (id) do update
  set source_title = excluded.source_title,
      content = excluded.content,
      source_updated_at = excluded.source_updated_at,
      metadata = excluded.metadata,
      updated_at = excluded.updated_at;

  insert into public.world_embedding_documents (
    id,
    world_id,
    source_kind,
    source_ref_id,
    source_title,
    content,
    source_updated_at,
    metadata,
    updated_at
  )
  select
    'doc:chat_context:' || c.id,
    c.world_id,
    'chat_context',
    c.id,
    c.context_type || ':' || coalesce(c.character_id, c.location_id, c.id),
    trim(
      both from concat_ws(
        E'\n\n',
        c.summary,
        'Context Type: ' || c.context_type,
        case when c.character_id is not null then 'Character: ' || c.character_id else null end,
        case when c.location_id is not null and c.location_id <> '' then 'Location: ' || c.location_id else null end,
        case when c.event_id is not null then 'Event: ' || c.event_id else null end,
        'Payload: ' || coalesce(c.payload::text, '{}')
      )
    ),
    c.updated_at,
    jsonb_build_object(
      'user_scope', c.user_scope,
      'character_id', c.character_id,
      'location_id', c.location_id,
      'event_id', c.event_id,
      'context_type', c.context_type,
      'freshness_score', c.freshness_score
    ),
    now()
  from public.world_chat_context_cache c
  where p_world_id is null or c.world_id = p_world_id
  on conflict (id) do update
  set source_title = excluded.source_title,
      content = excluded.content,
      source_updated_at = excluded.source_updated_at,
      metadata = excluded.metadata,
      updated_at = excluded.updated_at;

  delete from public.world_embedding_documents d
  where (p_world_id is null or d.world_id = p_world_id)
    and d.source_kind = 'canon_claim'
    and not exists (
      select 1 from public.world_canon_claims c
      where c.id = d.source_ref_id
        and c.world_id = d.world_id
    );

  delete from public.world_embedding_documents d
  where (p_world_id is null or d.world_id = p_world_id)
    and d.source_kind = 'lore_entry'
    and not exists (
      select 1 from public.world_lore_entries l
      where l.id = d.source_ref_id
        and l.world_id = d.world_id
    );

  delete from public.world_embedding_documents d
  where (p_world_id is null or d.world_id = p_world_id)
    and d.source_kind = 'wiki_page'
    and not exists (
      select 1 from public.world_wiki_pages p
      where p.id = d.source_ref_id
        and p.world_id = d.world_id
    );

  delete from public.world_embedding_documents d
  where (p_world_id is null or d.world_id = p_world_id)
    and d.source_kind = 'chronicle_entry'
    and not exists (
      select 1
      from public.world_chronicle_entries e
      join public.world_chronicle_books b on b.id = e.book_id
      where e.id = d.source_ref_id
        and b.world_id = d.world_id
    );

  delete from public.world_embedding_documents d
  where (p_world_id is null or d.world_id = p_world_id)
    and d.source_kind = 'chat_context'
    and not exists (
      select 1 from public.world_chat_context_cache c
      where c.id = d.source_ref_id
        and c.world_id = d.world_id
    );

  select count(*)
  into v_doc_count
  from public.world_embedding_documents d
  where p_world_id is null or d.world_id = p_world_id;

  return jsonb_build_object(
    'ok', true,
    'world_id', nullif(v_scope, ''),
    'document_count', v_doc_count
  );
end $$;

create or replace function public.world_queue_embedding_refresh(
  p_world_id text default null
) returns integer
language plpgsql
security definer
as $$
declare
  v_count integer;
begin
  insert into public.world_embedding_jobs (
    id,
    world_id,
    document_id,
    job_kind,
    status,
    embedding_model,
    metadata,
    updated_at
  )
  select
    'job:embed:' || d.id,
    d.world_id,
    d.id,
    'embed',
    'pending',
    null,
    jsonb_build_object('source_kind', d.source_kind, 'source_ref_id', d.source_ref_id),
    now()
  from public.world_embedding_documents d
  where p_world_id is null or d.world_id = p_world_id
  on conflict (id) do update
  set status = 'pending',
      error_message = null,
      metadata = excluded.metadata,
      updated_at = now();

  select count(*)
  into v_count
  from public.world_embedding_jobs j
  where j.status = 'pending'
    and (p_world_id is null or j.world_id = p_world_id);

  return v_count;
end $$;

create or replace function public.world_match_embeddings(
  p_world_id text,
  p_query_embedding vector(1536),
  p_match_count integer default 10,
  p_source_kind text default null,
  p_embedding_model text default null
) returns table (
  document_id text,
  source_kind text,
  source_ref_id text,
  source_title text,
  content text,
  metadata jsonb,
  distance double precision
)
language sql
stable
as $$
  select
    d.id as document_id,
    d.source_kind,
    d.source_ref_id,
    d.source_title,
    d.content,
    d.metadata,
    (e.embedding <=> p_query_embedding) as distance
  from public.world_embeddings e
  join public.world_embedding_documents d
    on d.id = e.document_id
  where d.world_id = p_world_id
    and e.embedding is not null
    and (p_source_kind is null or d.source_kind = p_source_kind)
    and (p_embedding_model is null or e.embedding_model = p_embedding_model)
  order by e.embedding <=> p_query_embedding
  limit greatest(p_match_count, 1);
$$;
