-- World seed: recent-realm claims and lore

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_blood_pool_greed','location_trait','Blood Pool Hell Greed Logic','Blood Pool Hell scenes work best when greed, appetite, and punishment all feel materially entangled.',jsonb_build_object('location_id','blood_pool_hell'),'["17.5","greed","hell"]'::jsonb,80),
  ('gensokyo_main','lore_sanzu_crossing','location_trait','Sanzu Crossing Logic','Sanzu River should be framed as a managed crossing, not a random stretch of water.',jsonb_build_object('location_id','sanzu_river'),'["crossing","afterlife","river"]'::jsonb,78),
  ('gensokyo_main','lore_recent_underworld_power','world_rule','Recent Underworld Power Scale','Recent underworld and beast-realm actors should not be flattened into ordinary local troublemakers; many belong to higher-pressure power structures.',jsonb_build_object('focus',array['yuuma','zanmu','yachie','enoko']),'["19","17.5","underworld"]'::jsonb,82)
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
  ('claim_suika_old_power','gensokyo_main','character','suika','role','Suika should be framed as revelry-backed oni force and old underworld perspective, not a tidy public official.',jsonb_build_object('role','old_power'),'src_swl','official',79,'["suika","oni","underworld"]'::jsonb),
  ('claim_yuuma_greed_power','gensokyo_main','character','yuuma','role','Yuuma is a greed-shaped underworld power best used where appetite behaves like structure and threat.',jsonb_build_object('role','predatory_power'),'src_17_5','official',83,'["yuuma","17.5","greed"]'::jsonb),
  ('claim_eika_fragile_resistance','gensokyo_main','character','eika','role','Eika belongs to stories of fragile persistence and interrupted small effort at the river''s edge.',jsonb_build_object('role','fragile_actor'),'src_wbawc','official',68,'["eika","wbawc","river"]'::jsonb),
  ('claim_kutaka_checkpoint_goddess','gensokyo_main','character','kutaka','role','Kutaka is a checkpoint goddess whose scenes should foreground structured permission and passage.',jsonb_build_object('role','gatekeeper'),'src_wbawc','official',72,'["kutaka","wbawc","checkpoint"]'::jsonb),
  ('claim_biten_mountain_fighter','gensokyo_main','character','biten','role','Biten is best used as a brash mountain fighter with agile challenge energy rather than as a bureaucratic actor.',jsonb_build_object('role','fighter'),'src_uDoALG','official',69,'["biten","19","mountain"]'::jsonb),
  ('claim_enoko_pack_order','gensokyo_main','character','enoko','role','Enoko belongs to disciplined pursuit and organized predatory hierarchy in beast-realm contexts.',jsonb_build_object('role','faction_leader'),'src_uDoALG','official',74,'["enoko","19","beast_realm"]'::jsonb),
  ('claim_chiyari_underworld_operator','gensokyo_main','character','chiyari','role','Chiyari is useful in blood-pool and underworld politics where force and affiliation are both socialized.',jsonb_build_object('role','underworld_operator'),'src_uDoALG','official',71,'["chiyari","19","underworld"]'::jsonb),
  ('claim_hisami_loyal_retainer','gensokyo_main','character','hisami','role','Hisami should be framed through dangerous loyalty and attached followership rather than independent grand ambition.',jsonb_build_object('role','retainer'),'src_uDoALG','official',70,'["hisami","19","loyalty"]'::jsonb),
  ('claim_zanmu_structural_actor','gensokyo_main','character','zanmu','role','Zanmu belongs to high-order underworld authority and should be treated as structural pressure.',jsonb_build_object('role','structural_actor'),'src_uDoALG','official',84,'["zanmu","19","high_impact"]'::jsonb),
  ('claim_blood_pool_hell_profile','gensokyo_main','location','blood_pool_hell','profile','Blood Pool Hell should feel like a greed-soaked underworld economy of suffering and appetite.',jsonb_build_object('role','greed_hell'),'src_17_5','official',80,'["location","17.5","hell"]'::jsonb),
  ('claim_sanzu_river_profile','gensokyo_main','location','sanzu_river','profile','Sanzu River is a formal crossing governed by ferries, checkpoints, and judgment-side order.',jsonb_build_object('role','afterlife_crossing'),'src_poFV','official',81,'["location","sanzu","crossing"]'::jsonb)
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
