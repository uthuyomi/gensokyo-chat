-- World seed: flower, celestial, dream, and seasonally important locations

insert into public.world_locations (
  world_id, id, name, kind, parent_location_id, title, summary, description, tags, default_mood, neighbors, metadata
)
values
  (
    'gensokyo_main',
    'heaven',
    'Heaven',
    'major_location',
    null,
    'Celestial Realm',
    'A lofty realm associated with celestials, privilege, weather disturbance, and detached superiority.',
    'A place where comfort, hauteur, and broad-scale consequences sit too close together.',
    '["celestial","weather","aloof"]'::jsonb,
    'aloof',
    '["hakurei_shrine","human_village"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'bhavaagra',
    'Bhavaagra',
    'sub_location',
    'heaven',
    'Seat of the Celestials',
    'A more elevated celestial seat associated with refined isolation and heavenly authority.',
    'A place that feels insulated enough to misjudge the urgency of the ground below.',
    '["celestial","seat","authority"]'::jsonb,
    'remote',
    '["heaven"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'dream_world',
    'Dream World',
    'major_location',
    null,
    'Dream Realm',
    'A dream-space where indirect access, symbolic encounter, and unstable personal logic become usable story ground.',
    'A place that can mirror, distort, or stage conflict without behaving like ordinary geography.',
    '["dream","symbolic","unstable"]'::jsonb,
    'surreal',
    '["lunar_capital","hakurei_shrine"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'nameless_hill',
    'Nameless Hill',
    'major_location',
    null,
    'Hill of Wild Flowers',
    'A flower-heavy field tied to poison, dolls, and lonely or dangerous natural beauty.',
    'A place where lovely scenery and hazardous neglect can coexist without contradiction.',
    '["flowers","poison","field"]'::jsonb,
    'beautiful',
    '["human_village","muenzuka"]'::jsonb,
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
