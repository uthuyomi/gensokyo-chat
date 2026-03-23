-- World seed: flower, celestial, dream, and season-edge relationships

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','komachi','eiki','subordinate_judge','Komachi''s border work is structurally subordinate to Eiki''s judgment.',0.86,'{}'::jsonb),
  ('gensokyo_main','eiki','komachi','supervisory_frustration','Eiki''s relation to Komachi naturally carries supervision and admonishment.',0.86,'{}'::jsonb),
  ('gensokyo_main','iku','tenshi','courteous_warning','Iku naturally fits as a heavenly messenger who warns around Tenshi''s disruptive excesses.',0.63,'{}'::jsonb),
  ('gensokyo_main','tenshi','reimu','incident_target','Tenshi is best linked to shrine-side response through caused disruption rather than quiet cooperation.',0.66,'{}'::jsonb),
  ('gensokyo_main','kokoro','mamizou','emotion_guidance','Kokoro and Mamizou fit scenes where social performance and emotional management intersect.',0.55,'{}'::jsonb),
  ('gensokyo_main','doremy','sagume','dream_lunar_overlap','Dream and lunar crisis logic meet naturally through Doremy and Sagume from different operational angles.',0.49,'{}'::jsonb),
  ('gensokyo_main','aunn','reimu','local_guardianship','Aunn''s natural place is protective and loyal around the Hakurei Shrine sphere.',0.78,'{}'::jsonb),
  ('gensokyo_main','eternity','lily_white','seasonal_affinity','Eternity and Lily White both function well as seasonal markers, though in different times of year.',0.39,'{}'::jsonb),
  ('gensokyo_main','nemuno','aya','mountain_distance','Nemuno fits mountain life outside the cleaner media-facing mountain institutions Aya navigates.',0.31,'{}'::jsonb),
  ('gensokyo_main','yuuka','medicine','flower_field_affinity','Yuuka and Medicine both belong to dangerous flower-heavy spaces, but not with the same scale or calm.',0.42,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();
