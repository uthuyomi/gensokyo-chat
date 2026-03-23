-- World seed: wiki pages for records, books, and boundary spots

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_record_culture','gensokyo_main','terms/record-culture','Record Culture','glossary','term','record_culture','A glossary page for records as active social infrastructure in Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_book_circulation','gensokyo_main','terms/book-circulation','Book Circulation','glossary','term','book_circulation','A glossary page for books as both education and recurring disturbance.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_boundary_spots','gensokyo_main','terms/boundary-spots','Boundary Spots','glossary','term','boundary_spots','A glossary page for leakage-prone places where outside influence and narrative slippage enter Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_term_record_culture:section:definition','wiki_term_record_culture','definition',1,'Definition','Records as social infrastructure.','Record culture in Gensokyo supports memory, correction, authority, and the ability to argue about what actually happened.', '["claim_term_record_culture","lore_term_record_culture"]'::jsonb,'{}'::jsonb),
  ('wiki_term_book_circulation:section:definition','wiki_term_book_circulation','definition',1,'Definition','Books as circulation and hazard.','Book circulation educates people, tempts them, and repeatedly creates low-scale incidents by moving half-understood knowledge between hands.', '["claim_term_book_circulation","lore_term_book_circulation"]'::jsonb,'{}'::jsonb),
  ('wiki_term_boundary_spots:section:definition','wiki_term_boundary_spots','definition',1,'Definition','Boundary spots as leakage points.','Boundary spots should feel porous, imperfect, and narratively unstable rather than functioning like tidy doors.', '["claim_term_boundary_spots","lore_term_boundary_spots"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
