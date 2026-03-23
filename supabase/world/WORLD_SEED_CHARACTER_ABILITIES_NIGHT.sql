-- World seed: night-life support cast ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_rumia','gensokyo_main','character','rumia','ability','Rumia is defined by darkness and by obstructing ordinary visibility in close-range scenes.',jsonb_build_object('ability_theme','darkness_manipulation'),'src_eosd','official',67,'["ability","rumia","eosd"]'::jsonb),
  ('claim_ability_mystia','gensokyo_main','character','mystia','ability','Mystia is associated with song, night-sparrow danger, and forms of confusion tied to nighttime travel.',jsonb_build_object('ability_theme','night_song_and_confusion'),'src_imperishable_night','official',71,'["ability","mystia","in"]'::jsonb),
  ('claim_ability_wriggle','gensokyo_main','character','wriggle','ability','Wriggle is associated with insects and the collective force of small life in summer-night scenes.',jsonb_build_object('ability_theme','insect_command'),'src_imperishable_night','official',69,'["ability","wriggle","in"]'::jsonb)
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
