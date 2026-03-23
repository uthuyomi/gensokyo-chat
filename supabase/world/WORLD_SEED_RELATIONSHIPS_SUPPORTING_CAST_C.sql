-- World seed: third supporting-cast relationship layer

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','rumia','cirno','minor_chaos_overlap','Rumia and Cirno both help early Gensokyo feel dangerous in small, unserious, recurring ways.',0.26,'{}'::jsonb),
  ('gensokyo_main','mystia','keine','night_village_overlap','Mystia''s night-vendor role and Keine''s village-guardian role naturally intersect at the edge of human nighttime life.',0.41,'{}'::jsonb),
  ('gensokyo_main','mystia','wriggle','night_creature_peer','Mystia and Wriggle make summer-night scenes feel inhabited by more than one kind of local actor.',0.46,'{}'::jsonb),
  ('gensokyo_main','wriggle','cirno','seasonal_smallscale','Wriggle and Cirno connect through small-scale seasonal trouble rather than public incident leadership.',0.28,'{}'::jsonb),
  ('gensokyo_main','rumia','reimu','minor_incident_target','Rumia is the sort of small recurring night problem Reimu should be able to brush aside without escalating the world.',0.35,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();
