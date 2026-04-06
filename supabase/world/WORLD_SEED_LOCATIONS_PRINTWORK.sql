-- World seed: print-work and urban-legend oriented locations

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'kourindou',
    'Kourindou',
    'major_location',
    'human_village',
    'Curio Shop',
    'A curio shop associated with objects from inside and outside Gensokyo, interpretation, and slightly detached commerce.',
    'A place where strange objects, soft expertise, and off-angle commentary naturally accumulate.',
    '["shop","objects","curio"]'::jsonb,
    'curious',
    '["human_village","hakurei_shrine"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'suzunaan',
    'Suzunaan',
    'major_location',
    'human_village',
    'Book Rental Shop',
    'A village bookshop-library tied to written circulation, curiosity, and dangerous textual accidents.',
    'A cultural node where stories, records, and unsafe reading habits can all become plot fuel.',
    '["books","village","records"]'::jsonb,
    'scholarly',
    '["human_village"]'::jsonb,
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
