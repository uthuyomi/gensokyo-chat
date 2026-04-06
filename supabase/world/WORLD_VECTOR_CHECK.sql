-- World vector check
-- Run after WORLD_SEED_VECTOR_BOOTSTRAP.sql to confirm vector-ready documents were built.

select source_kind, count(*) as document_count
from public.world_embedding_documents
where world_id = 'gensokyo_main'
group by source_kind
order by source_kind;

select count(*) as pending_embedding_jobs
from public.world_embedding_jobs
where world_id = 'gensokyo_main'
  and status = 'pending';

select id, source_kind, source_ref_id, source_title
from public.world_embedding_documents
where world_id = 'gensokyo_main'
  and source_kind in ('canon_claim', 'wiki_page', 'chronicle_entry', 'chat_context')
order by source_kind, id
limit 20;
