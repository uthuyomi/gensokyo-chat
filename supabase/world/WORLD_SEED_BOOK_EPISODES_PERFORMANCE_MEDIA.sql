-- World seed: performance and media-side printwork patterns

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_book_public_performance_pattern','printwork_pattern','Public Performance Pattern','Festival and performance scenes work best when music changes public mood rather than appearing as isolated ornament.',jsonb_build_object('source_cluster',array['src_pcb','src_poFV']),'["printwork","performance","public_mood"]'::jsonb,76),
  ('gensokyo_main','lore_book_split_media_pattern','printwork_pattern','Split Media Pattern','Tengu media should preserve the difference between Aya''s frontal publication logic and Hatate''s more selective, trend-sensitive angle.',jsonb_build_object('source_cluster',array['src_boaFW','src_ds','src_alt_truth']),'["printwork","media","tengu"]'::jsonb,78)
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
  ('claim_book_public_performance_pattern','gensokyo_main','printwork','public_performance_cluster','summary','Performance scenes are strongest when they shape gathering mood, social memory, and event atmosphere.',jsonb_build_object('linked_characters',array['lunasa','merlin','lyrica','mystia']),'src_pcb','official',75,'["printwork","performance","summary"]'::jsonb),
  ('claim_book_split_media_pattern','gensokyo_main','printwork','split_media_cluster','summary','Tengu media should preserve the contrast between immediate public framing and slower trend-sensitive interpretation.',jsonb_build_object('linked_characters',array['aya','hatate']),'src_ds','official',77,'["printwork","media","summary"]'::jsonb)
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
