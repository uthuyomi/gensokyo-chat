-- World seed: lunar and late print-work support relationships

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','toyohime','yorihime','lunar_sibling_rule','Toyohime and Yorihime together make lunar rule feel aristocratic, coordinated, and difficult to casually breach.',0.86,'{}'::jsonb),
  ('gensokyo_main','toyohime','sagume','lunar_high_command','Toyohime and Sagume occupy the same upper air of lunar political seriousness from different angles.',0.49,'{}'::jsonb),
  ('gensokyo_main','yorihime','eirin','lunar_old_order','Yorihime and Eirin help make lunar history feel like a living political continuity.',0.52,'{}'::jsonb),
  ('gensokyo_main','miyoi','mystia','night_hospitality_overlap','Miyoi and Mystia both help make Gensokyo night life feel social, but through different kinds of invitation.',0.38,'{}'::jsonb),
  ('gensokyo_main','miyoi','suika','drinking_scene_overlap','Miyoi and Suika naturally overlap in scenes where drinking turns into revelation, looseness, or trouble.',0.44,'{}'::jsonb),
  ('gensokyo_main','mizuchi','satori','mystery_investigation_axis','Mizuchi and Satori create later-era mystery structure through hidden motive, possession, and mental pressure.',0.55,'{}'::jsonb),
  ('gensokyo_main','mizuchi','reimu','hidden_incident_target','Mizuchi belongs in the class of hidden trouble that forces even familiar protectors to re-evaluate ordinary surfaces.',0.41,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();
