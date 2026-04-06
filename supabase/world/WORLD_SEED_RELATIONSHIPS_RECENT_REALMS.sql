-- World seed: recent realm relationship edges

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','suika','yuuma','underworld_power_overlap','Suika and Yuuma overlap most naturally where underworld appetite and force become social or political pressure.',0.42,'{}'::jsonb),
  ('gensokyo_main','komachi','eika','crossing_proximity','Komachi''s ferry logic and Eika''s riverbank futility naturally coexist around the Sanzu frontier.',0.34,'{}'::jsonb),
  ('gensokyo_main','kutaka','komachi','checkpoint_crossing_overlap','Kutaka''s checkpoint logic complements Komachi''s ferry-crossing domain from a different angle.',0.48,'{}'::jsonb),
  ('gensokyo_main','yachie','enoko','factional_use','Yachie and Enoko fit beast-realm hierarchy scenes where pursuit and faction discipline matter.',0.45,'{}'::jsonb),
  ('gensokyo_main','chiyari','yuuma','underworld_alignment','Chiyari naturally overlaps with Yuuma through blood-pool and underworld power currents.',0.57,'{}'::jsonb),
  ('gensokyo_main','hisami','zanmu','loyal_retainer','Hisami''s strongest role is as intense devotion around a larger underworld authority.',0.73,'{}'::jsonb),
  ('gensokyo_main','zanmu','yachie','higher_order_pressure','Zanmu should feel like a higher-order pressure relative to ordinary beast-realm faction leadership.',0.58,'{}'::jsonb),
  ('gensokyo_main','biten','momiji','mountain_patrol_friction','Biten and Momiji fit mountain scenes where challenge and patrol order can clash.',0.39,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();
