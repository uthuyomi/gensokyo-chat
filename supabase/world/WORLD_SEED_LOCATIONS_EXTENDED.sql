-- World seed: extended locations for broader canon/runtime coverage

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'chireiden',
    'Chireiden',
    'major_location',
    'former_hell',
    'Palace of the Earth Spirits',
    'An underground palace associated with satori, pets, and unusually direct knowledge of minds.',
    'A controlled but emotionally difficult place where insight and discomfort coexist.',
    '["underground","palace","satori"]'::jsonb,
    'pressured',
    '["old_capital","former_hell"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'scarlet_gate',
    'Scarlet Mansion Gate',
    'sub_location',
    'scarlet_devil_mansion',
    'Front Gate',
    'The public-facing gate area of the Scarlet Devil Mansion.',
    'A threshold where hospitality, suspicion, and gatekeeping meet.',
    '["gate","mansion","threshold"]'::jsonb,
    'guarded',
    '["misty_lake","scarlet_devil_mansion"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'mansion_library',
    'Scarlet Library',
    'sub_location',
    'scarlet_devil_mansion',
    'Library',
    'A vast, quiet library associated with Patchouli and sustained magical study.',
    'A place of accumulated knowledge, controlled atmosphere, and low tolerance for pointless noise.',
    '["library","magic","indoors"]'::jsonb,
    'quiet',
    '["scarlet_devil_mansion"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'moriya_upper_precinct',
    'Moriya Upper Precinct',
    'sub_location',
    'moriya_shrine',
    'Upper Precinct',
    'The more elevated and formal side of Moriya Shrine operations.',
    'A place where divine authority and practical planning mix more openly than at many shrines.',
    '["shrine","mountain","formal"]'::jsonb,
    'driven',
    '["moriya_shrine","youkai_mountain_foot"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'bamboo_path',
    'Bamboo Path',
    'sub_location',
    'bamboo_forest',
    'Forest Path',
    'A shifting route through the Bamboo Forest of the Lost.',
    'A route that only feels stable until it suddenly is not.',
    '["forest","path","maze"]'::jsonb,
    'uneasy',
    '["bamboo_forest","eientei"]'::jsonb,
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
