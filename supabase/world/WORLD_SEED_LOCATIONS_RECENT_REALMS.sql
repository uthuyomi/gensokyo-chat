-- World seed: recent-realm locations for Gouyoku Ibun and UDoALG era coverage

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'blood_pool_hell',
    'Blood Pool Hell',
    'major_location',
    'former_hell',
    'Blood Pool Hell',
    'A harsh underworld region associated with greed, suffering, and thick accumulations of desire and sludge.',
    'A place where appetite, filth, and punishment gather into something almost economic.',
    '["hell","greed","underworld"]'::jsonb,
    'oppressive',
    '["former_hell","old_capital"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'sanzu_river',
    'Sanzu River',
    'major_location',
    null,
    'River of Crossing',
    'A river crossing tied to ferrymen, the dead, and formal transitions between states of being.',
    'A boundary where movement is structured, judged, and never entirely casual.',
    '["river","crossing","afterlife"]'::jsonb,
    'solemn',
    '["muenzuka"]'::jsonb,
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
