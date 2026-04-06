-- World seed: supporting-cast relationships

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','wakasagihime','cirno','lake_proximity','Wakasagihime and Cirno both naturally occupy misty-lake scenes from different tones of presence.',0.28,'{}'::jsonb),
  ('gensokyo_main','sekibanki','kosuzu','village_text_unease','Sekibanki and Kosuzu both fit village-edge unease where the ordinary and uncanny meet.',0.24,'{}'::jsonb),
  ('gensokyo_main','kagerou','tewi','bamboo_overlap','Kagerou and Tewi naturally overlap in bamboo-forest local routes from very different social angles.',0.31,'{}'::jsonb),
  ('gensokyo_main','benben','yatsuhashi','sibling_ensemble','Benben and Yatsuhashi work best as a musical sibling pair rather than isolated entries.',0.83,'{}'::jsonb),
  ('gensokyo_main','seiran','ringo','lunar_peer','Seiran and Ringo help lunar settings feel staffed by actual peers rather than only top-level strategists.',0.64,'{}'::jsonb),
  ('gensokyo_main','mike','takane','trade_scale_difference','Mike and Takane connect through trade, but at very different scales of market life.',0.34,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();
