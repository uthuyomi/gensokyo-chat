-- World seed: regional culture for mountain approach and mansion threshold

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_regional_mountain_approach_hazards','regional_culture','Mountain-Approach Hazard Culture','The approach to Youkai Mountain should feel like a managed danger zone shaped by warning, patrol, and uneven public access.',jsonb_build_object('location_id','youkai_mountain_foot'),'["region","mountain","hazard"]'::jsonb,77),
  ('gensokyo_main','lore_regional_scarlet_gate_threshold','regional_culture','Scarlet Gate Threshold Culture','The Scarlet Gate should read as a visible household threshold where entry becomes social performance and martial filtering at once.',jsonb_build_object('location_id','scarlet_gate'),'["region","sdm","threshold"]'::jsonb,78)
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
  ('claim_regional_mountain_approach_hazards','gensokyo_main','location','youkai_mountain_foot','setting','The mountain approach should be framed as managed danger through warning actors, patrols, and uneven permission.',jsonb_build_object('related_characters',array['hina','momiji','aya','nitori']),'src_mofa','official',77,'["mountain","approach","culture"]'::jsonb),
  ('claim_regional_scarlet_gate_threshold','gensokyo_main','location','scarlet_gate','setting','The Scarlet Gate is a public threshold where mansion order becomes visible through interruption, filtering, and presentation.',jsonb_build_object('related_characters',array['meiling','sakuya']),'src_eosd','official',78,'["scarlet_gate","threshold","culture"]'::jsonb)
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
