-- World seed: residual realm and late-system wiki pages

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_satono','gensokyo_main','characters/satono-nishida','Satono Nishida','character','character','satono','A hidden-stage attendant whose brightness is inseparable from selective service and access.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_mai','gensokyo_main','characters/mai-teireida','Mai Teireida','character','character','mai','A hidden-stage attendant whose energy and obedience are tied to backstage motion and chosen service.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_sannyo','gensokyo_main','characters/sannyo-komakusa','Sannyo Komakusa','character','character','sannyo','A smoke seller who helps market routes feel informal, local, and socially sustained.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_biten','gensokyo_main','characters/son-biten','Son Biten','character','character','biten','A brash mountain fighter whose value lies in challenge-energy more than formal authority.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_enoko','gensokyo_main','characters/enoko-mitsugashira','Enoko Mitsugashira','character','character','enoko','A Beast Realm pursuit leader whose order is expressed through pack discipline and organized hunting pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_chiyari','gensokyo_main','characters/chiyari-tenkajin','Chiyari Tenkajin','character','character','chiyari','An underworld operator whose force is socialized inside blood-pool and hell-side affiliations.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_hisami','gensokyo_main','characters/hisami-yomotsu','Hisami Yomotsu','character','character','hisami','A dangerous retainer whose loyalty itself creates pressure in the room.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_character_satono:section:overview','wiki_character_satono','overview',1,'Overview','Satono as chosen attendant.','Satono is strongest when hidden service and selective empowerment are visible just beneath a bright, obedient surface.', '["claim_term_hidden_seasons"]'::jsonb,'{}'::jsonb),
  ('wiki_character_mai:section:overview','wiki_character_mai','overview',1,'Overview','Mai as energetic backstage motion.','Mai turns hidden-stage service into movement, rhythm, and sharp obedience rather than passive attendance.', '["claim_term_hidden_seasons"]'::jsonb,'{}'::jsonb),
  ('wiki_character_sannyo:section:overview','wiki_character_sannyo','overview',1,'Overview','Sannyo as informal market life.','Sannyo makes market routes feel lived in through repeated contact, smoke, and ordinary exchange rather than grand abstractions of value.', '["claim_incident_market_cards"]'::jsonb,'{}'::jsonb),
  ('wiki_character_biten:section:overview','wiki_character_biten','overview',1,'Overview','Biten as mountain challenge energy.','Biten is best used when mountain scenes need reckless challenge and agile bravado rather than administrative order.', '["claim_biten_mountain_fighter"]'::jsonb,'{}'::jsonb),
  ('wiki_character_enoko:section:overview','wiki_character_enoko','overview',1,'Overview','Enoko as pack discipline.','Enoko gives Beast Realm pursuit logic a disciplined and socially organized face.', '["claim_enoko_pack_order"]'::jsonb,'{}'::jsonb),
  ('wiki_character_chiyari:section:overview','wiki_character_chiyari','overview',1,'Overview','Chiyari as socialized underworld force.','Chiyari matters because underworld power around her feels inhabited and affiliated, not merely violent.', '["claim_chiyari_underworld_operator"]'::jsonb,'{}'::jsonb),
  ('wiki_character_hisami:section:overview','wiki_character_hisami','overview',1,'Overview','Hisami as dangerous loyalty.','Hisami gives later underworld scenes a form of devotion that intensifies hierarchy instead of softening it.', '["claim_hisami_loyal_retainer"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
