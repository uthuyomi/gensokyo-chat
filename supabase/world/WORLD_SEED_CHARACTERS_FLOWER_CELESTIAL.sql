-- World seed: flower incident, celestial, mask, dream, and seasonal cast

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','komachi','Komachi Onozuka','Shinigami Ferryman','shinigami','independent',
    'muenzuka','muenzuka',
    'A ferryman who fits border, delay, and work-avoidant but consequential scenes.',
    'Best used where laziness and official death-side duty coexist in one body.',
    'lazy, teasing, easygoing',
    'If a crossing will still be there later, rushing is not always the first answer.',
    'border_worker',
    '["pofv","border","shinigami"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['borders','crossings','afterlife_routes'], 'temperament', 'easygoing')
  ),
  (
    'gensokyo_main','eiki','Shikieiki Yamaxanadu','Yama Judge','yama','independent',
    'muenzuka','muenzuka',
    'A judge whose scenes naturally emphasize moral evaluation, formal verdict, and uncompromising perspective.',
    'Strong when the story needs ethical weight rather than ordinary social drift.',
    'formal, stern, instructive',
    'A judgment delayed is not the same as a judgment escaped.',
    'judge',
    '["pofv","judge","afterlife"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['judgment','moral_order'], 'temperament', 'stern')
  ),
  (
    'gensokyo_main','medicine','Medicine Melancholy','Poison Doll','doll youkai','independent',
    'nameless_hill','nameless_hill',
    'A poison-bearing doll whose scenes fit neglected hurt, toxic environments, and small-scale menace.',
    'Useful where loneliness and danger should share the same visual frame.',
    'hurt, defensive, sharp',
    'What is left alone too long changes.',
    'poison_actor',
    '["pofv","poison","doll"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['poison','nameless_hill'], 'temperament', 'defensive')
  ),
  (
    'gensokyo_main','yuuka','Yuuka Kazami','Flower Master','youkai','independent',
    'nameless_hill','nameless_hill',
    'A powerful flower-associated youkai best treated as serene danger rather than constant front-line activity.',
    'Use sparingly where beauty, calm, and overwhelming force should coincide.',
    'calm, elegant, dangerous',
    'The quietest field can still contain the most danger.',
    'high_impact_actor',
    '["pofv","flowers","high_impact"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['flowers','seasonal_fields'], 'temperament', 'dangerous')
  ),
  (
    'gensokyo_main','iku','Iku Nagae','Messenger of Heaven','oarfish youkai','independent',
    'heaven','heaven',
    'A messenger whose scenes fit omens, weather-linked warning, and floating celestial formality.',
    'Useful where impending disruption needs to arrive with poise rather than panic.',
    'graceful, measured, courteous',
    'A warning still matters even when delivered beautifully.',
    'messenger',
    '["swr","weather","heaven"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['omens','weather_change','heaven'], 'temperament', 'courteous')
  ),
  (
    'gensokyo_main','tenshi','Tenshi Hinanawi','Spoiled Celestial','celestial','independent',
    'bhavaagra','heaven',
    'A celestial whose scenes combine privilege, boredom, weather-scale disruption, and careless superiority.',
    'Best used when a story wants a large problem caused by detached appetite or arrogance.',
    'proud, bored, reckless',
    'If you have enough height, the ground starts looking like a toy.',
    'instigator',
    '["swr","celestial","weather"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['heaven','weather_disturbance'], 'temperament', 'reckless')
  ),
  (
    'gensokyo_main','kokoro','Hata no Kokoro','Mask Youkai','menreiki','independent',
    'human_village','human_village',
    'A mask-bearing youkai whose scenes naturally center emotion display, identity performance, and public affect.',
    'Strong when feeling itself is part of the plot machinery.',
    'plain, curious, emotionally searching',
    'A face shown and a face felt are not always the same thing.',
    'performer',
    '["hm","masks","emotion"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['emotion','public_performance'], 'temperament', 'searching')
  ),
  (
    'gensokyo_main','doremy','Doremy Sweet','Dream Shepherd','baku','independent',
    'dream_world','dream_world',
    'A dream shepherd whose scenes naturally mediate dream-space logic, access, and symbolic instability.',
    'Useful whenever dream geography needs an actual caretaker rather than vague abstraction.',
    'sleepy, knowing, patient',
    'Dreams still need someone who knows the paths between them.',
    'guide',
    '["lolk","dream","guide"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['dream_world','dream_navigation'], 'temperament', 'patient')
  ),
  (
    'gensokyo_main','aunn','Aunn Komano','Guardian Komainu','komainu','hakurei',
    'hakurei_shrine','hakurei_shrine',
    'A shrine guardian whose scenes fit faithful local protection, friendliness, and practical watchfulness.',
    'Excellent for shrine-ground everyday texture that still feels defended.',
    'friendly, earnest, watchful',
    'Guarding a place properly means liking it enough to stay.',
    'guardian',
    '["hsifs","shrine","guardian"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['hakurei_shrine','local_visitors'], 'temperament', 'friendly')
  ),
  (
    'gensokyo_main','eternity','Eternity Larva','Summer Butterfly Fairy','fairy','independent',
    'hakurei_shrine','human_village',
    'A summer fairy whose scenes fit visible seasonality, public flutter, and light uncanny movement.',
    'Good as a seasonal marker with a bit more presence than a passing sign.',
    'bright, fluttery, excitable',
    'A season should be felt in motion, not only in calendars.',
    'seasonal_actor',
    '["hsifs","summer","fairy"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['summer','seasonal_change'], 'temperament', 'excitable')
  ),
  (
    'gensokyo_main','nemuno','Nemuno Sakata','Mountain Hag','youkai','independent',
    'youkai_mountain_foot','youkai_mountain_foot',
    'A mountain-dwelling youkai whose scenes fit remote local life, rough hospitality, and mountain edges away from institutions.',
    'Useful when the mountain should feel inhabited beyond organized tengu or kappa systems.',
    'rough, practical, protective',
    'A remote place still has its own ways of taking care of itself.',
    'local_guardian',
    '["hsifs","mountain","local"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mountain_edges','local_life'], 'temperament', 'practical')
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
