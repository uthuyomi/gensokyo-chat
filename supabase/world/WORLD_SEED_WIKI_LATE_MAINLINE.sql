-- World seed: wiki pages for late-mainline cast and locations

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_miko',
    'gensokyo_main',
    'characters/toyosatomimi-no-miko',
    'Toyosatomimi no Miko',
    'character',
    'character',
    'miko',
    'A saintly leader whose stories naturally involve rhetoric, legitimacy, and public authority.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_seija',
    'gensokyo_main',
    'characters/seija-kijin',
    'Seija Kijin',
    'character',
    'character',
    'seija',
    'A contrarian rebel best understood through inversion, sabotage, and corrosive pressure against settled order.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_junko',
    'gensokyo_main',
    'characters/junko',
    'Junko',
    'character',
    'character',
    'junko',
    'A high-impact actor of purified hostility whose use should be deliberate and consequential.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_okina',
    'gensokyo_main',
    'characters/okina-matara',
    'Okina Matara',
    'character',
    'character',
    'okina',
    'A hidden god of access, backstage control, and selective empowerment.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_yachie',
    'gensokyo_main',
    'characters/yachie-kicchou',
    'Yachie Kicchou',
    'character',
    'character',
    'yachie',
    'A calculating beast-realm leader whose strength lies in leverage and indirect control.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_takane',
    'gensokyo_main',
    'characters/takane-yamashiro',
    'Takane Yamashiro',
    'character',
    'character',
    'takane',
    'A mountain broker whose scenes revolve around trade, opportunity, and practical exchange.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_lunar_capital',
    'gensokyo_main',
    'locations/lunar-capital',
    'Lunar Capital',
    'location',
    'location',
    'lunar_capital',
    'A remote center of purity, order, and lunar political distance from ordinary Gensokyo life.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_beast_realm',
    'gensokyo_main',
    'locations/beast-realm',
    'Beast Realm',
    'location',
    'location',
    'beast_realm',
    'A factional realm where strategic predation and power blocs are part of the landscape itself.',
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
    'wiki_character_miko:section:overview',
    'wiki_character_miko',
    'overview',
    1,
    'Overview',
    'Miko as saintly authority and rhetorical center.',
    'Toyosatomimi no Miko should be framed less as a casual participant and more as a figure who can gather, redirect, and organize an audience through authority and presentation.',
    '["claim_miko_saint_leadership","lore_miko_public_authority"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_seija:section:overview',
    'wiki_character_seija',
    'overview',
    1,
    'Overview',
    'Seija as corrosive inversion pressure.',
    'Seija Kijin is not generic chaos. She works best when she actively reverses expectations, encourages grievance, and puts pressure on settled legitimacy.',
    '["claim_seija_rebel","lore_seija_contrarian_pressure"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_junko:section:overview',
    'wiki_character_junko',
    'overview',
    1,
    'Overview',
    'Junko as high-impact purity and hostility.',
    'Junko should appear where the story can sustain concentrated hostility and thematic purity. She is not ordinary background traffic.',
    '["claim_junko_pure_hostility","lore_junko_high_impact"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_okina:section:overview',
    'wiki_character_okina',
    'overview',
    1,
    'Overview',
    'Okina as hidden access and backstage control.',
    'Okina Matara belongs to stories about doors, backstage staging, and the quiet distribution of access or empowerment.',
    '["claim_okina_hidden_doors","lore_okina_hidden_access"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_yachie:section:overview',
    'wiki_character_yachie',
    'overview',
    1,
    'Overview',
    'Yachie as strategic faction leader.',
    'Yachie Kicchou is strongest in political or coercive contexts where a gentle surface hides structural leverage.',
    '["claim_yachie_faction_leader","lore_beast_realm_factions"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_takane:section:overview',
    'wiki_character_takane',
    'overview',
    1,
    'Overview',
    'Takane as mountain broker.',
    'Takane Yamashiro should be used where trade, brokerage, and practical market opportunity matter more than theatrical conflict.',
    '["claim_takane_broker","lore_takane_trade_frame"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_lunar_capital:section:profile',
    'wiki_location_lunar_capital',
    'profile',
    1,
    'Profile',
    'The Lunar Capital as ordered distance.',
    'The Lunar Capital should feel clean, remote, and culturally distinct from ordinary Gensokyo circulation. Its scenes carry high standards and political distance.',
    '["claim_lunar_capital_profile","lore_lunar_distance"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_beast_realm:section:profile',
    'wiki_location_beast_realm',
    'profile',
    1,
    'Profile',
    'The Beast Realm as factional pressure field.',
    'The Beast Realm is a power-structured realm of predatory factions, coercive alignment, and open strategic pressure rather than everyday social ease.',
    '["claim_beast_realm_profile","lore_beast_realm_factions"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
