-- World seed: extended printwork-side ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_rinnosuke','gensokyo_main','character','rinnosuke','ability','Rinnosuke is associated with object reading, detached interpretation, and insight through material culture rather than force.',jsonb_build_object('ability_theme','object_interpretation'),'src_lotus_asia','official',79,'["ability","rinnosuke","objects"]'::jsonb),
  ('claim_ability_kosuzu','gensokyo_main','character','kosuzu','ability','Kosuzu is associated with dangerous reading, textual curiosity, and the way books can activate trouble by being handled.',jsonb_build_object('ability_theme','dangerous_reading'),'src_fs','official',77,'["ability","kosuzu","books"]'::jsonb),
  ('claim_ability_sumireko','gensokyo_main','character','sumireko','ability','Sumireko is associated with psychic force, occult framing, and youthful overreach linked to outside-world rumors.',jsonb_build_object('ability_theme','psychic_occult_pressure'),'src_ulil','official',76,'["ability","sumireko","occult"]'::jsonb),
  ('claim_ability_joon','gensokyo_main','character','joon','ability','Joon is associated with conspicuous appetite, glamour, and extractive social movement.',jsonb_build_object('ability_theme','glamour_and_extraction'),'src_aocf','official',73,'["ability","joon","glamour"]'::jsonb),
  ('claim_ability_shion','gensokyo_main','character','shion','ability','Shion is associated with visible depletion, misfortune, and the social atmosphere of things going wrong by contact.',jsonb_build_object('ability_theme','misfortune_contagion'),'src_aocf','official',74,'["ability","shion","misfortune"]'::jsonb)
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
