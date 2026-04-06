-- World seed: wiki pages for small-scale world texture

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_minor_incidents','gensokyo_main','terms/minor-incidents','Minor Incidents','glossary','term','minor_incidents','A glossary page for recurring local disturbances that fall below full incident scale.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_night_detours','gensokyo_main','terms/night-detours','Night Detours','glossary','term','night_detours','A glossary page for the songs, stalls, darkness, and luck-based trouble that shape Gensokyo after dark.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_text_circulation','gensokyo_main','terms/text-circulation','Text Circulation','glossary','term','text_circulation','A glossary page for books, reports, and records as causes of small-scale disturbance.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_term_minor_incidents:section:definition','wiki_term_minor_incidents','definition',1,'Definition','Minor incidents as world texture.','Minor incidents are recurring disruptions that never become full-scale crises but still shape memory, habit, and local caution.', '["lore_minor_incident_fairy_pranks","history_minor_fairy_pranks"]'::jsonb,'{}'::jsonb),
  ('wiki_term_night_detours:section:definition','wiki_term_night_detours','definition',1,'Definition','Night detours as lived after-dark structure.','Night detours are created by song, darkness, trade, rumor, and luck; they make after-dark Gensokyo a space of managed uncertainty rather than emptiness.', '["lore_minor_incident_night_detours","history_minor_night_detours"]'::jsonb,'{}'::jsonb),
  ('wiki_term_text_circulation:section:definition','wiki_term_text_circulation','definition',1,'Definition','Text circulation as disturbance.','Texts, records, and articles create disturbance by changing what people know and what they think is worth testing, fearing, or retelling.', '["lore_minor_incident_text_circulation","history_minor_text_circulation"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
