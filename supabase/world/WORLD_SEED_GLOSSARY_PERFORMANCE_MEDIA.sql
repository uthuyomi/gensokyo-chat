-- World seed: performance and media culture glossary

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_regional_public_performance','regional_culture','Public Performance Culture','Public performance in Gensokyo should feel like a real social function that shapes festivals, memory, and mood.',jsonb_build_object('focus','performance_and_festivals'),'["performance","festival","culture"]'::jsonb,77),
  ('gensokyo_main','lore_regional_tengu_media','regional_culture','Tengu Media Culture','Tengu media should be treated as a living information layer shaped by timing, angle, competition, and selective publication.',jsonb_build_object('focus','tengu_media'),'["media","tengu","culture"]'::jsonb,79)
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
  ('claim_regional_public_performance','gensokyo_main','world','gensokyo_main','world_rule','Performance should be treated as a social technology for mood, memory, and public gathering rather than decorative filler.',jsonb_build_object('related_characters',array['lunasa','merlin','lyrica','mystia']),'src_pcb','official',76,'["performance","culture","world_rule"]'::jsonb),
  ('claim_regional_tengu_media','gensokyo_main','faction','tengu','glossary','Tengu media culture includes both frontal reportage and more delayed, trend-sensitive observation.',jsonb_build_object('related_characters',array['aya','hatate']),'src_ds','official',78,'["media","tengu","glossary"]'::jsonb)
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
