-- World seed: wiki pages for recent-realm cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_yuuma','gensokyo_main','characters/yuuma-toutetsu','Yuuma Toutetsu','character','character','yuuma','An underworld greed-power best used where appetite behaves like structure and threat.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_zanmu','gensokyo_main','characters/zanmu-nippaku','Zanmu Nippaku','character','character','zanmu','A high-order underworld authority who should be treated as structural pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_suika','gensokyo_main','characters/suika-ibuki','Suika Ibuki','character','character','suika','An oni of revelry and force whose scenes expand gatherings into pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_location_blood_pool_hell','gensokyo_main','locations/blood-pool-hell','Blood Pool Hell','location','location','blood_pool_hell','A greed-soaked underworld region where appetite, punishment, and pressure are materially entangled.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_yuuma:section:overview','wiki_character_yuuma','overview',1,'Overview','Yuuma as greed-driven underworld power.','Yuuma Toutetsu belongs in scenes where appetite and acquisition become the actual logic of the underworld rather than just personality traits.','["claim_yuuma_greed_power","lore_blood_pool_greed"]'::jsonb,'{}'::jsonb),
  ('wiki_character_zanmu:section:overview','wiki_character_zanmu','overview',1,'Overview','Zanmu as structural underworld authority.','Zanmu should be handled as a large-scale underworld pressure point, not as casual local chatter or interchangeable threat.','["claim_zanmu_structural_actor","lore_recent_underworld_power"]'::jsonb,'{}'::jsonb),
  ('wiki_character_suika:section:overview','wiki_character_suika','overview',1,'Overview','Suika as revelry-backed old oni force.','Suika works best when feasting, compression, and blunt oni force all feel like the same social motion.','["claim_suika_old_power"]'::jsonb,'{}'::jsonb),
  ('wiki_location_blood_pool_hell:section:profile','wiki_location_blood_pool_hell','profile',1,'Profile','Blood Pool Hell as appetite and punishment engine.','Blood Pool Hell should feel like an underworld environment where greed, waste, pain, and power all accumulate into one pressure system.','["claim_blood_pool_hell_profile","lore_blood_pool_greed"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
