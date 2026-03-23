-- World seed: print-work and reportage relationship edges

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','akyuu','keine','historical_collaboration','Akyuu and Keine are naturally linked through continuity, teaching, and the maintenance of village memory.',0.78,'{}'::jsonb),
  ('gensokyo_main','kosuzu','akyuu','record_affinity','Kosuzu''s book-centered curiosity overlaps strongly with Akyuu''s record-centered understanding.',0.63,'{}'::jsonb),
  ('gensokyo_main','rinnosuke','marisa','object_familiarity','Rinnosuke and Marisa are naturally linked through objects, tools, and opportunistic acquisition.',0.57,'{}'::jsonb),
  ('gensokyo_main','rinnosuke','reimu','dry_familiarity','Rinnosuke works best with shrine-side actors through detached familiarity rather than emotional intensity.',0.44,'{}'::jsonb),
  ('gensokyo_main','hatate','aya','media_peer','Hatate and Aya overlap as tengu information actors with different styles of timing and framing.',0.69,'{}'::jsonb),
  ('gensokyo_main','kasen','reimu','corrective_guidance','Kasen''s shrine-side role is naturally advisory and corrective toward Reimu.',0.76,'{}'::jsonb),
  ('gensokyo_main','sumireko','yukari','boundary_attention','Sumireko''s boundary-crossing significance puts her naturally into Yukari-adjacent territory.',0.41,'{}'::jsonb),
  ('gensokyo_main','joon','shion','sibling_asymmetry','The Yorigami sisters function most naturally as an uneven pair of glamour and deprivation.',0.88,'{}'::jsonb),
  ('gensokyo_main','shion','joon','sibling_dependency','Shion and Joon are structurally tied even when their social effects differ sharply.',0.88,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();
