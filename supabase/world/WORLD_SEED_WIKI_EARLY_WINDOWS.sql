-- World seed: wiki pages for early Windows-era additions

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_cirno',
    'gensokyo_main',
    'characters/cirno',
    'Cirno',
    'character',
    'character',
    'cirno',
    'A local fairy force around Misty Lake, loud, confident, and best treated as immediate rather than administrative.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_tewi',
    'gensokyo_main',
    'characters/tewi-inaba',
    'Tewi Inaba',
    'character',
    'character',
    'tewi',
    'A rabbit associated with luck, misdirection, and the side-routes of Eientei and the Bamboo Forest.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_group_prismriver',
    'gensokyo_main',
    'groups/prismriver-ensemble',
    'Prismriver Ensemble',
    'group',
    'group',
    'prismriver',
    'A musical ensemble whose members are most legible as a coordinated group presence.',
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
    'wiki_character_cirno:section:overview',
    'wiki_character_cirno',
    'overview',
    1,
    'Overview',
    'Cirno as local force rather than system-scale actor.',
    'Cirno is most useful to the world model as a local, immediate, highly visible fairy force. She changes atmosphere quickly, but she should not be mistaken for a stable organizer of large-scale public structure.',
    '["claim_cirno_fairy_local","lore_cirno_local_trouble"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_tewi:section:overview',
    'wiki_character_tewi',
    'overview',
    1,
    'Overview',
    'Tewi as luck and detour actor.',
    'Tewi belongs naturally in side routes, evasive guidance, and playful local disruption around Eientei and the Bamboo Forest, where a crooked path can still be the useful one.',
    '["claim_tewi_eientei_trickster","lore_tewi_detours"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_group_prismriver:section:overview',
    'wiki_group_prismriver',
    'overview',
    1,
    'Overview',
    'The ensemble logic of the Prismriver sisters.',
    'The Prismriver sisters should usually be framed as an ensemble first. Their individual tones matter, but their clearest public identity is coordinated performance and mood-shaping presence.',
    '["claim_prismriver_ensemble","lore_prismriver_ensemble"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
