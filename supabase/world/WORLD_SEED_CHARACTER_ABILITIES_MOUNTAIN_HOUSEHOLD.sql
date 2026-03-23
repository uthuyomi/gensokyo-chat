-- World seed: ability claims for mountain and household recurring cast

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_meiling','gensokyo_main','character','meiling','ability','Meiling is associated with martial force, bodily discipline, and threshold defense rather than abstract household planning.',jsonb_build_object('ability_theme','martial_gatekeeping'),'src_eosd','official',73,'["ability","meiling","sdm"]'::jsonb),
  ('claim_ability_momiji','gensokyo_main','character','momiji','ability','Momiji is associated with mountain patrol competence, disciplined response, and practical vigilance.',jsonb_build_object('ability_theme','patrol_and_detection'),'src_mofa','official',71,'["ability","momiji","mountain"]'::jsonb),
  ('claim_ability_hina','gensokyo_main','character','hina','ability','Hina is associated with misfortune redirection and with dangerous flow being turned aside rather than erased.',jsonb_build_object('ability_theme','misfortune_redirection'),'src_mofa','official',74,'["ability","hina","misfortune"]'::jsonb),
  ('claim_ability_minoriko','gensokyo_main','character','minoriko','ability','Minoriko is associated with harvest abundance, food, and the public enjoyment of autumn plenty.',jsonb_build_object('ability_theme','harvest_abundance'),'src_mofa','official',70,'["ability","minoriko","harvest"]'::jsonb),
  ('claim_ability_shizuha','gensokyo_main','character','shizuha','ability','Shizuha is associated with autumn leaves, decline, and the visual transition of season rather than overt command.',jsonb_build_object('ability_theme','autumn_transience'),'src_mofa','official',69,'["ability","shizuha","autumn"]'::jsonb)
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
