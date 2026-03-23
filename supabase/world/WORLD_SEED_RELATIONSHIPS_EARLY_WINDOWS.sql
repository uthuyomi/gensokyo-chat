-- World seed: relationships for early Windows-era cast

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','cirno','remilia','territorial_overlap','Cirno and the Scarlet Devil Mansion share the Misty Lake sphere, even if not on equal footing.',0.31,'{}'::jsonb),
  ('gensokyo_main','lily_white','reimu','seasonal_contact','Lily White''s role intersects naturally with shrine-centered seasonal awareness.',0.36,'{}'::jsonb),
  ('gensokyo_main','lunasa','merlin','ensemble_sibling','The Prismriver sisters are fundamentally shaped by ensemble performance together.',0.88,'{}'::jsonb),
  ('gensokyo_main','merlin','lyrica','ensemble_sibling','The Prismriver sisters are fundamentally shaped by ensemble performance together.',0.88,'{}'::jsonb),
  ('gensokyo_main','lunasa','lyrica','ensemble_sibling','The Prismriver sisters are fundamentally shaped by ensemble performance together.',0.88,'{}'::jsonb),
  ('gensokyo_main','minoriko','shizuha','seasonal_sibling','The Aki sisters are tied together through seasonal abundance and decline.',0.84,'{}'::jsonb),
  ('gensokyo_main','shizuha','minoriko','seasonal_sibling','The Aki sisters are tied together through seasonal abundance and decline.',0.84,'{}'::jsonb),
  ('gensokyo_main','tewi','reisen','eientei_local','Tewi and Reisen share Eientei space, but not the same discipline or priorities.',0.63,'{}'::jsonb),
  ('gensokyo_main','reisen','tewi','eientei_local','Reisen has to account for Tewi''s influence inside Eientei''s daily life.',0.63,'{}'::jsonb),
  ('gensokyo_main','hina','momiji','mountain_proximity','Hina and Momiji both fit mountain-side scenes, though from different functions.',0.41,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();
