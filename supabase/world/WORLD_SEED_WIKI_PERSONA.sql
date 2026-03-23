-- World seed: wiki pages for additional persona-covered cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_meiling',
    'gensokyo_main',
    'characters/hong-meiling',
    'Hong Meiling',
    'character',
    'character',
    'meiling',
    'Gatekeeper of the Scarlet Devil Mansion and a strong fit for threshold and interruption scenes.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_satori',
    'gensokyo_main',
    'characters/satori-komeiji',
    'Satori Komeiji',
    'character',
    'character',
    'satori',
    'Master of Chireiden, associated with direct insight, psychological tension, and underground authority.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_rin',
    'gensokyo_main',
    'characters/orin',
    'Orin',
    'character',
    'character',
    'rin',
    'An underground mover and errand-runner whose social role is tied to circulation and informal information flow.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_chireiden',
    'gensokyo_main',
    'locations/chireiden',
    'Chireiden',
    'location',
    'location',
    'chireiden',
    'An underground palace where insight, discomfort, and household authority sit unusually close together.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
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
  (
    'wiki_character_meiling:section:overview',
    'wiki_character_meiling',
    'overview',
    1,
    'Overview',
    'Meiling as threshold guard and household edge.',
    'Hong Meiling functions most naturally at the visible edge of the Scarlet Devil Mansion, where entry, interruption, and household presentation all meet in one place.',
    '["claim_meiling_gatekeeper","lore_meiling_gatekeeping"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_satori:section:overview',
    'wiki_character_satori',
    'overview',
    1,
    'Overview',
    'Satori as an actor of uncomfortable clarity.',
    'Satori Komeiji should not be treated as a shallow background presence. Her role naturally pulls scenes toward motive, thought, and psychological pressure.',
    '["claim_satori_chireiden","lore_satori_insight"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_rin:section:overview',
    'wiki_character_rin',
    'overview',
    1,
    'Overview',
    'Rin as movement and social circulation.',
    'Orin is especially suited to stories that depend on transport, rumor flow, and the lived social rhythm of the underground.',
    '["claim_rin_underground_flow","lore_rin_social_flow"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_chireiden:section:profile',
    'wiki_location_chireiden',
    'profile',
    1,
    'Profile',
    'Chireiden as underground palace and psychological setting.',
    'Chireiden is not simply another underground building. Its atmosphere and ruler push scenes toward directness, discomfort, and deeper interior reading than many other locations support.',
    '["claim_chireiden_setting","lore_chireiden_profile"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
