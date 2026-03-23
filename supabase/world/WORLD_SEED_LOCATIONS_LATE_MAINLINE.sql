-- World seed: major late-mainline locations for expanded canon coverage

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'divine_spirit_mausoleum',
    'Divine Spirit Mausoleum',
    'major_location',
    null,
    'Ancient Mausoleum',
    'A mausoleum tied to resurrection politics, hermit logic, and old authority returning to the present.',
    'A place where old legitimacy, ritual order, and strategic self-presentation gather in one frame.',
    '["mausoleum","ritual","authority"]'::jsonb,
    'formal',
    '["human_village","senkai"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'senkai',
    'Senkai',
    'major_location',
    null,
    'Hermit Realm',
    'A hidden hermit realm tied to seclusion, cultivation, and selective access.',
    'A detached space where withdrawal from ordinary circulation becomes part of the point.',
    '["realm","hermit","hidden"]'::jsonb,
    'detached',
    '["divine_spirit_mausoleum"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'shining_needle_castle',
    'Shining Needle Castle',
    'major_location',
    null,
    'Inchling Castle',
    'A castle associated with reversal, small-rule upheaval, and pride sharpened by imbalance.',
    'A setting that naturally supports insurrection, inversion, and unstable hierarchy.',
    '["castle","reversal","inchling"]'::jsonb,
    'tense',
    '["human_village","hakurei_shrine"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'lunar_capital',
    'Lunar Capital',
    'major_location',
    null,
    'Moon Capital',
    'A lunar seat of order, purity, and distance from ordinary Gensokyo life.',
    'A remote, disciplined center whose priorities and standards differ sharply from Gensokyo''s daily balance.',
    '["moon","capital","purity"]'::jsonb,
    'distant',
    '["eientei"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'backdoor_realm',
    'Backdoor Realm',
    'major_location',
    null,
    'Backdoor Space',
    'A realm tied to hidden doors, seasonal manipulation, and selective access controlled from behind the visible scene.',
    'A place where staging, access, and off-angle intervention are inseparable.',
    '["realm","backdoor","hidden"]'::jsonb,
    'uncanny',
    '["forest_of_magic","hakurei_shrine","youkai_mountain_foot"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'beast_realm',
    'Beast Realm',
    'major_location',
    null,
    'Beast Realm',
    'A violent realm of competing animal spirit powers, factional leadership, and strategic coercion.',
    'Power blocs and tactical pressure matter here more openly than in ordinary Gensokyo public life.',
    '["realm","beast","factional"]'::jsonb,
    'predatory',
    '["former_hell","old_capital"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'rainbow_dragon_cave',
    'Rainbow Dragon Cave',
    'major_location',
    null,
    'Rainbow Cave',
    'A cave region associated with mining, cards, hidden commerce, and mountain-adjacent opportunism.',
    'A place where resources, trade, and unusual market currents become tangible.',
    '["cave","market","mountain"]'::jsonb,
    'restless',
    '["youkai_mountain_foot","human_village"]'::jsonb,
    '{}'::jsonb
  )
on conflict (world_id, id) do update
set name = excluded.name,
    kind = excluded.kind,
    parent_location_id = excluded.parent_location_id,
    title = excluded.title,
    summary = excluded.summary,
    description = excluded.description,
    tags = excluded.tags,
    default_mood = excluded.default_mood,
    neighbors = excluded.neighbors,
    metadata = excluded.metadata,
    updated_at = now();
