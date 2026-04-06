-- World seed: second supporting-cast relationship layer

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','kisume','yamame','underground_neighbor','Kisume and Yamame help former-hell routes feel locally inhabited rather than empty connectors.',0.37,'{}'::jsonb),
  ('gensokyo_main','yamame','parsee','underground_social_overlap','Yamame and Parsee occupy adjacent social territory where rumor and resentment travel together.',0.42,'{}'::jsonb),
  ('gensokyo_main','parsee','yuugi','bridge_to_capital','Parsee and Yuugi connect the bridge threshold to the heavier social life of the old capital.',0.39,'{}'::jsonb),
  ('gensokyo_main','yuugi','suika','oni_peer','Yuugi and Suika make oni culture feel older and broader than one personality can carry.',0.58,'{}'::jsonb),
  ('gensokyo_main','kyouko','byakuren','temple_disciple','Kyouko gives Myouren Temple an everyday disciple perspective under Byakuren''s larger leadership.',0.61,'{}'::jsonb),
  ('gensokyo_main','shou','byakuren','temple_leadership','Shou and Byakuren together make temple authority feel distributed rather than singular.',0.67,'{}'::jsonb),
  ('gensokyo_main','yoshika','seiga','servant_bond','Yoshika''s usefulness is easiest to read through Seiga''s manipulative direction.',0.74,'{}'::jsonb),
  ('gensokyo_main','yoshika','miko','mausoleum_service','Yoshika helps make the mausoleum faction feel staffed rather than abstract.',0.34,'{}'::jsonb),
  ('gensokyo_main','sunny_milk','luna_child','fairy_trio','Sunny and Luna work best as part of a recurring fairy trio rhythm.',0.84,'{}'::jsonb),
  ('gensokyo_main','luna_child','star_sapphire','fairy_trio','Luna and Star balance stealth with perception in trio scenes.',0.84,'{}'::jsonb),
  ('gensokyo_main','star_sapphire','sunny_milk','fairy_trio','Star and Sunny keep fairy scenes quick, observant, and lightly troublesome.',0.84,'{}'::jsonb),
  ('gensokyo_main','sunny_milk','reimu','shrine_mischief','Sunny Milk belongs naturally in shrine-side daily mischief that annoys Reimu without overturning the world.',0.29,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();
