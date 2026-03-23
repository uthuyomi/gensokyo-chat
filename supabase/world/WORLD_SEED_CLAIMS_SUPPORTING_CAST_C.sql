-- World seed: third supporting-cast claims and lore

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_supporting_cast_night_life','daily_life_texture','Night-Life Supporting Texture','Night in Gensokyo should feel occupied by singers, small predators, insects, and local trouble rather than becoming empty stage space.',jsonb_build_object('focus','nighttime_local_life'),'["supporting_cast","night","daily_life"]'::jsonb,73)
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
  ('claim_rumia_minor_night_threat','gensokyo_main','character','rumia','role','Rumia is best used as a small but recurring night-route threat, not a structural-scale planner.',jsonb_build_object('role','night_local'),'src_eosd','official',63,'["rumia","eosd","night"]'::jsonb),
  ('claim_mystia_night_vendor','gensokyo_main','character','mystia','role','Mystia is especially valuable where song, food, and dangerous charm make the night socially active.',jsonb_build_object('role','night_vendor'),'src_imperishable_night','official',69,'["mystia","in","night"]'::jsonb),
  ('claim_wriggle_small_collective_night','gensokyo_main','character','wriggle','role','Wriggle gives summer-night scenes a smaller-scale collective pressure tied to insects and overlooked life.',jsonb_build_object('role','night_local'),'src_imperishable_night','official',67,'["wriggle","in","summer"]'::jsonb)
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
