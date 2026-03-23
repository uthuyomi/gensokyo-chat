-- World seed: performer and media-side ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_lunasa','gensokyo_main','character','lunasa','ability','Lunasa is associated with melancholy performance, atmosphere control, and the deeper tonal weight of ensemble music.',jsonb_build_object('ability_theme','melancholic_mood_music'),'src_pcb','official',71,'["ability","lunasa","music"]'::jsonb),
  ('claim_ability_merlin','gensokyo_main','character','merlin','ability','Merlin is associated with energetic performance that pushes a scene outward through noise, spirit, and uplift.',jsonb_build_object('ability_theme','energetic_sound_projection'),'src_pcb','official',71,'["ability","merlin","music"]'::jsonb),
  ('claim_ability_lyrica','gensokyo_main','character','lyrica','ability','Lyrica is associated with tactical arrangement, quick musical shifts, and lighter-footed stage control.',jsonb_build_object('ability_theme','quick_arrangement'),'src_pcb','official',70,'["ability","lyrica","music"]'::jsonb),
  ('claim_ability_hatate','gensokyo_main','character','hatate','ability','Hatate is associated with delayed capture, trend-reading, and a more personal style of media observation than Aya.',jsonb_build_object('ability_theme','trend_sensitive_reporting'),'src_ds','official',72,'["ability","hatate","media"]'::jsonb),
  ('claim_ability_lily_white','gensokyo_main','character','lily_white','ability','Lily White is associated with announcing spring and making seasonal transition publicly audible.',jsonb_build_object('ability_theme','spring_announcement'),'src_pcb','official',66,'["ability","lily_white","season"]'::jsonb),
  ('claim_ability_letty','gensokyo_main','character','letty','ability','Letty is associated with winter presence itself, making cold and seasonality feel like a local actor.',jsonb_build_object('ability_theme','winter_presence'),'src_pcb','official',68,'["ability","letty","winter"]'::jsonb)
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
