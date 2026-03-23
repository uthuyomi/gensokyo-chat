-- World seed: print-work, reportage, and urban-legend relevant cast

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','rinnosuke','Rinnosuke Morichika','Curio Shopkeeper','half-youkai','independent',
    'kourindou','kourindou',
    'A curio merchant and interpreter of objects whose scenes fit explanation, detachment, and material curiosity.',
    'Very useful when a story needs thoughtful interpretation of tools, goods, or outside-world remnants.',
    'calm, reflective, dry',
    'Objects reveal habits and worlds if you bother to examine them.',
    'interpreter',
    '["cola","objects","merchant"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['objects','outside_world_artifacts'], 'temperament', 'reflective')
  ),
  (
    'gensokyo_main','akyuu','Hieda no Akyuu','Child of Miare','human','human_village',
    'human_village','human_village',
    'A chronicler tied to memory, records, and formalized understanding of Gensokyo''s people and history.',
    'Essential whenever a scene needs explicit historical framing or documentary intelligence.',
    'polite, observant, composed',
    'A world without records becomes easier to misunderstand.',
    'historian',
    '["pmiss","records","history"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['village_history','public_records'], 'temperament', 'composed')
  ),
  (
    'gensokyo_main','kosuzu','Kosuzu Motoori','Book Curator','human','human_village',
    'suzunaan','suzunaan',
    'A village bookseller-curator whose curiosity makes written material active rather than inert.',
    'Useful in stories where texts, records, and dangerous reading habits cause movement.',
    'curious, earnest, bright',
    'Books are safer if understood, but more interesting if opened.',
    'librarian',
    '["fs","books","village"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['books','village_readers'], 'temperament', 'curious')
  ),
  (
    'gensokyo_main','hatate','Hatate Himekaidou','Tengu Trend Watcher','tengu','mountain',
    'youkai_mountain_foot','youkai_mountain_foot',
    'A crow tengu whose scenes fit trend-sensitive observation, delayed reporting, and self-directed information work.',
    'Best used when public narrative is fragmented, personal, or mediated through modern-ish habits.',
    'casual, skeptical, media-savvy',
    'Information changes shape depending on how and when you catch it.',
    'observer',
    '["ds","reportage","tengu"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['news','trends','mountain_media'], 'temperament', 'skeptical')
  ),
  (
    'gensokyo_main','kasen','Kasen Ibaraki','Hermit Advisor','hermit','independent',
    'hakurei_shrine','hakurei_shrine',
    'A hermit advisor whose scenes fit correction, guidance, and restrained criticism around shrine-side life.',
    'Useful when daily Gensokyo needs moral pressure without losing warmth.',
    'firm, caring, critical',
    'Helping someone often includes telling them what they would rather ignore.',
    'advisor',
    '["wahh","hermit","advisor"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['shrine_life','training','daily_gensokyo'], 'temperament', 'critical')
  ),
  (
    'gensokyo_main','sumireko','Sumireko Usami','Occult Outsider','human','independent',
    'muenzuka','human_village',
    'An outside-world psychic whose scenes naturally emphasize urban legends, leakage across boundaries, and youthful overreach.',
    'Strong when a story wants outside-world framing without replacing Gensokyo''s logic entirely.',
    'smart, excited, overconfident',
    'A rumor gets more interesting once it crosses a boundary.',
    'outsider',
    '["ulil","outside_world","urban_legend"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['urban_legends','outside_world'], 'temperament', 'overconfident')
  ),
  (
    'gensokyo_main','joon','Joon Yorigami','Pestilence Goddess','goddess','independent',
    'human_village','human_village',
    'A goddess of wasting fortune whose scenes fit glamour, exploitation, and social drain under bright presentation.',
    'Good for flashy social trouble with real cost underneath it.',
    'showy, greedy, breezy',
    'If someone is willing to spend, why stop them early?',
    'social_drain',
    '["aocf","poverty","glamour"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['social_desire','fortune_shifts'], 'temperament', 'showy')
  ),
  (
    'gensokyo_main','shion','Shion Yorigami','Goddess of Poverty','goddess','independent',
    'human_village','human_village',
    'A poverty goddess whose scenes emphasize depletion, misfortune, and the weight of being avoided.',
    'Useful when a story needs visible social bad luck without cartoon villainy.',
    'weak, resigned, plain',
    'Misfortune does not need to announce itself loudly to spread.',
    'misfortune_actor',
    '["aocf","poverty","misfortune"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['misfortune','social_avoidance'], 'temperament', 'resigned')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();
