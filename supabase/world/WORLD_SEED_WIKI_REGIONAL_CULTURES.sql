-- World seed: wiki and chat support for regional cultures

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_region_old_capital_culture','gensokyo_main','regions/old-capital-culture','Old Capital Culture','glossary','location','old_capital','A culture page for oni public life, drinking, and challenge in the Old Capital.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_region_myouren_daily_life','gensokyo_main','regions/myouren-daily-life','Myouren Temple Daily Life','glossary','location','myouren_temple','A culture page for routine temple life, coexistence, and lived religious practice.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_region_village_night_life','gensokyo_main','regions/village-night-life','Village-Edge Night Life','glossary','location','human_village','A culture page for song, food, rumor, and danger at the night edge of the village.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_region_old_capital_culture:section:overview','wiki_region_old_capital_culture','overview',1,'Overview','Old Capital as sociable oni sphere.','The Old Capital should feel loud, public, and convivial, with power displayed through social life rather than hidden behind it.','["claim_regional_old_capital_culture","lore_regional_old_capital"]'::jsonb,'{}'::jsonb),
  ('wiki_region_myouren_daily_life:section:overview','wiki_region_myouren_daily_life','overview',1,'Overview','Myouren Temple as lived institution.','Myouren Temple is strongest as a setting when discipline, routine, care, and coexistence all feel present beneath larger doctrinal conflict.','["claim_regional_myouren_daily_life","lore_regional_myouren_temple"]'::jsonb,'{}'::jsonb),
  ('wiki_region_village_night_life:section:overview','wiki_region_village_night_life','overview',1,'Overview','Night culture at the village edge.','The village at night should read as a space of food, song, rumor, and manageable danger rather than becoming empty after dark.','["claim_regional_village_night_life","lore_regional_night_village_edges"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_old_capital_culture',
    'gensokyo_main',
    'global',
    null,
    'old_capital',
    null,
    'location_mood',
    'Old Capital scenes should feel public, strong, and convivial rather than merely hazardous.',
    jsonb_build_object(
      'default_mood', 'boisterous',
      'claim_ids', array['claim_regional_old_capital_culture']
    ),
    0.84,
    now()
  ),
  (
    'chat_location_myouren_daily_life',
    'gensokyo_main',
    'global',
    null,
    'myouren_temple',
    null,
    'location_mood',
    'Myouren Temple scenes should feel lived in by routine, discipline, and coexistence-minded order.',
    jsonb_build_object(
      'default_mood', 'orderly',
      'claim_ids', array['claim_regional_myouren_daily_life']
    ),
    0.85,
    now()
  ),
  (
    'chat_location_village_night_life',
    'gensokyo_main',
    'global',
    null,
    'human_village',
    null,
    'location_mood',
    'At night, the village edge should feel social and slightly risky rather than empty.',
    jsonb_build_object(
      'default_mood', 'lively_after_dark',
      'claim_ids', array['claim_regional_village_night_life']
    ),
    0.83,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();
