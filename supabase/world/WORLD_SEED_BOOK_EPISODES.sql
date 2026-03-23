-- World seed: print-work episode claims and chronicle fragments

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_book_forbidden_scrollery','printwork_pattern','Forbidden Scrollery Pattern','Forbidden Scrollery should be treated as village book-culture life repeatedly intersecting with dangerous texts and small incidents.',jsonb_build_object('source','fs'),'["printwork","fs","books"]'::jsonb,81),
  ('gensokyo_main','lore_book_wild_and_horned_hermit','printwork_pattern','Wild and Horned Hermit Pattern','Wild and Horned Hermit scenes combine shrine-side daily life, correction, and hidden depth behind apparently ordinary episodes.',jsonb_build_object('source','wahh'),'["printwork","wahh","daily_life"]'::jsonb,80),
  ('gensokyo_main','lore_book_lotus_asia','printwork_pattern','Curiosities of Lotus Asia Pattern','Curiosities of Lotus Asia works through objects, detached interpretation, and the slow exposure of hidden meanings in everyday goods.',jsonb_build_object('source','lotus_asia'),'["printwork","cola","objects"]'::jsonb,79),
  ('gensokyo_main','lore_book_bunbunmaru_reporting','printwork_pattern','Tengu Reporting Pattern','Aya-centered reporting works by converting local disturbance into mediated public narrative.',jsonb_build_object('source','boafw'),'["printwork","reporting","aya"]'::jsonb,78)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_book_forbidden_scrollery','gensokyo_main','printwork','forbidden_scrollery','summary','Forbidden Scrollery is a village-side book and incident pattern centered on dangerous texts entering ordinary circulation.',jsonb_build_object('linked_characters',array['kosuzu','akyuu','reimu']),'src_fs','official',82,'["printwork","fs","summary"]'::jsonb),
  ('claim_book_wild_and_horned_hermit','gensokyo_main','printwork','wild_and_horned_hermit','summary','Wild and Horned Hermit emphasizes shrine daily life, advice, discipline, and slowly exposed hidden depth.',jsonb_build_object('linked_characters',array['kasen','reimu','marisa']),'src_wahh','official',81,'["printwork","wahh","summary"]'::jsonb),
  ('claim_book_lotus_asia','gensokyo_main','printwork','lotus_asia','summary','Curiosities of Lotus Asia is centered on objects, interpretation, and the mundane surface of strange things.',jsonb_build_object('linked_characters',array['rinnosuke','marisa','reimu']),'src_lotus_asia','official',80,'["printwork","cola","summary"]'::jsonb),
  ('claim_book_bunbunmaru_reporting','gensokyo_main','printwork','bunbunmaru_reporting','summary','Aya-centered reporting turns local events into broader public narrative and selective visibility.',jsonb_build_object('linked_characters',array['aya','hatate']),'src_boaFW','official',79,'["printwork","reporting","summary"]'::jsonb)
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();

insert into public.world_chronicle_entries (
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body,
  subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values
  (
    'chronicle_entry_printwork_books',
    'chronicle_gensokyo_history',
    'chronicle_gensokyo_history:chapter:foundations',
    'printwork_patterns',
    2,
    'essay',
    'Books, Reports, and How Daily Life Enters History',
    'A note on how printed works preserve daily life, minor incidents, and public interpretation.',
    'Not all history in Gensokyo is written through formal crisis. Some of it survives through booksellers, curio merchants, tengu articles, and the repeated circulation of small episodes that reveal how the world functions when it is not exploding. These records are indispensable precisely because they preserve ordinary pressure, not only extraordinary disaster.',
    'world',
    'gensokyo_main',
    'keine',
    null,
    null,
    '["printwork","history","daily_life"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    narrator_character_id = excluded.narrator_character_id,
    event_id = excluded.event_id,
    history_id = excluded.history_id,
    tags = excluded.tags,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_entry_sources (
  id, entry_id, source_kind, source_ref_id, source_label, weight, notes
)
values
  ('chronicle_entry_printwork_books:src:fs','chronicle_entry_printwork_books','canon_claim','claim_book_forbidden_scrollery','Forbidden Scrollery Pattern',0.9,'Village-side book culture'),
  ('chronicle_entry_printwork_books:src:wahh','chronicle_entry_printwork_books','canon_claim','claim_book_wild_and_horned_hermit','Wild and Horned Hermit Pattern',0.9,'Shrine daily life and advice'),
  ('chronicle_entry_printwork_books:src:cola','chronicle_entry_printwork_books','canon_claim','claim_book_lotus_asia','Curiosities of Lotus Asia Pattern',0.85,'Objects and interpretation'),
  ('chronicle_entry_printwork_books:src:boafw','chronicle_entry_printwork_books','canon_claim','claim_book_bunbunmaru_reporting','Bunbunmaru Reporting Pattern',0.82,'Public narrative through reportage')
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_ref_id = excluded.source_ref_id,
    source_label = excluded.source_label,
    weight = excluded.weight,
    notes = excluded.notes;
