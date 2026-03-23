-- World seed: claims and lore for persona-covered cast

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_meiling_gatekeeping','character_role','Meiling and Threshold Scenes','Meiling is especially suited to scenes involving entry, interruption, and visible household boundaries.',jsonb_build_object('character_id','meiling'),'["meiling","threshold","sdm"]'::jsonb,74),
  ('gensokyo_main','lore_momiji_patrols','character_role','Momiji and Mountain Patrol','Momiji is best treated as a practical mountain guard rather than a free-floating public actor.',jsonb_build_object('character_id','momiji'),'["momiji","mountain","guard"]'::jsonb,72),
  ('gensokyo_main','lore_satori_insight','character_role','Satori and Direct Insight','Satori is a poor fit for shallow scenes because her role naturally pulls toward motive, thought, and discomfort.',jsonb_build_object('character_id','satori'),'["satori","mind","insight"]'::jsonb,79),
  ('gensokyo_main','lore_rin_social_flow','character_role','Rin and Underground Movement','Rin fits the social and rumor circulation of the underground better than static ceremonial scenes.',jsonb_build_object('character_id','rin'),'["rin","underground","movement"]'::jsonb,70),
  ('gensokyo_main','lore_chireiden_profile','location_trait','Chireiden Profile','Chireiden is a psychologically loaded location where hidden thought is less secure than elsewhere.',jsonb_build_object('location_id','chireiden'),'["chireiden","mind","underground"]'::jsonb,78)
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
  ('claim_meiling_gatekeeper','gensokyo_main','character','meiling','role','Meiling is strongly tied to gatekeeping, threshold control, and the public-facing edge of the Scarlet Devil Mansion.',jsonb_build_object('role','gatekeeper'),'src_eosd','official',76,'["meiling","sdm","gate"]'::jsonb),
  ('claim_momiji_mountain_guard','gensokyo_main','character','momiji','role','Momiji belongs more naturally to mountain guard and patrol functions than to broad cross-Gensokyo social scenes.',jsonb_build_object('role','mountain_guard'),'src_mofa','official',72,'["momiji","guard","mountain"]'::jsonb),
  ('claim_satori_chireiden','gensokyo_main','character','satori','role','Satori''s role is inseparable from Chireiden, mind-reading implications, and underground household authority.',jsonb_build_object('role','palace_master'),'src_subterranean_animism','official',84,'["satori","chireiden","mind"]'::jsonb),
  ('claim_rin_underground_flow','gensokyo_main','character','rin','role','Rin is associated with movement, errands, and circulation in the underground social sphere.',jsonb_build_object('role','carrier'),'src_subterranean_animism','official',75,'["rin","underground","movement"]'::jsonb),
  ('claim_chireiden_setting','gensokyo_main','location','chireiden','setting','Chireiden is a core underground residence tied to Satori and household-scale management of unusual pets and power.',jsonb_build_object('location_id','chireiden'),'src_subterranean_animism','official',80,'["chireiden","setting"]'::jsonb)
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
