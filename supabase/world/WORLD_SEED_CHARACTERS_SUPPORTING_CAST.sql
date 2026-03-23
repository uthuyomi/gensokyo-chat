-- World seed: supporting cast across multiple incidents and eras

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','wakasagihime','Wakasagihime','Mermaid of the Shining Lake','mermaid','independent',
    'misty_lake','misty_lake',
    'A lake-dwelling youkai suited to quiet local scenes where watery edges and hidden poise matter.',
    'Best used as atmosphere-bearing local presence, not broad public leadership.',
    'gentle, quiet, careful',
    'A calm surface still contains a life beneath it.',
    'local_actor',
    '["ddc","lake","local"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['misty_lake','shoreline_life'], 'temperament', 'gentle')
  ),
  (
    'gensokyo_main','sekibanki','Sekibanki','Rokurokubi Youkai','rokurokubi','independent',
    'human_village','human_village',
    'A youkai whose scenes fit divided presence, hidden identity, and urban-edge unease.',
    'Useful for local suspicion and lightly uncanny public-space tension.',
    'blunt, guarded, streetwise',
    'A face shown openly is not the only face in play.',
    'urban_actor',
    '["ddc","village","uncanny"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['village_edges','public_unease'], 'temperament', 'guarded')
  ),
  (
    'gensokyo_main','kagerou','Kagerou Imaizumi','Werewolf of the Bamboo Forest','werewolf','independent',
    'bamboo_forest','bamboo_forest',
    'A bamboo-forest werewolf suited to moonlit local scenes, embarrassment, and instinct under restraint.',
    'Best in small-scale personal or nocturnal scenes rather than public command.',
    'shy, earnest, reactive',
    'Some conditions bring out sides you would rather manage quietly.',
    'local_actor',
    '["ddc","bamboo","werewolf"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['bamboo_forest','night_conditions'], 'temperament', 'shy')
  ),
  (
    'gensokyo_main','benben','Benben Tsukumo','Biwa Tsukumogami','tsukumogami','independent',
    'human_village','human_village',
    'A musical tsukumogami suited to ensemble scenes, performance, and post-incident adaptive life.',
    'Useful in public music and tsukumogami integration stories.',
    'cool, artistic, poised',
    'A sound kept alive becomes a way of living.',
    'performer',
    '["ddc","music","tsukumogami"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['performance','public_music'], 'temperament', 'poised')
  ),
  (
    'gensokyo_main','yatsuhashi','Yatsuhashi Tsukumo','Koto Tsukumogami','tsukumogami','independent',
    'human_village','human_village',
    'A lively tsukumogami whose scenes fit performance, rhythm, and newly independent identity.',
    'Useful where musical independence and spirited public presence matter.',
    'lively, sharp, expressive',
    'A note only matters if someone lets it ring.',
    'performer',
    '["ddc","music","tsukumogami"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['performance','public_music'], 'temperament', 'lively')
  ),
  (
    'gensokyo_main','seiran','Seiran','Moon Rabbit Soldier','moon rabbit','lunar_capital',
    'lunar_capital','lunar_capital',
    'A moon rabbit soldier suited to rank, discipline, and practical operation under larger lunar command.',
    'Useful for giving lunar conflict a grounded enlisted perspective.',
    'energetic, dutiful, straightforward',
    'Orders are easier to carry if you keep moving.',
    'soldier',
    '["lolk","moon","soldier"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['lunar_operations','military_discipline'], 'temperament', 'dutiful')
  ),
  (
    'gensokyo_main','ringo','Ringo','Dango Seller Rabbit','moon rabbit','lunar_capital',
    'lunar_capital','lunar_capital',
    'A rabbit whose scenes fit food, routine, and lighter-facing lunar society under pressure.',
    'Useful for making lunar life feel inhabited beyond pure strategy.',
    'cheerful, practical, chatty',
    'Routine and appetite keep a place feeling real.',
    'support_actor',
    '["lolk","moon","daily_life"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['lunar_daily_life','food_trade'], 'temperament', 'cheerful')
  ),
  (
    'gensokyo_main','mike','Mike Goutokuji','Lucky White Cat','bakeneko','independent',
    'human_village','human_village',
    'A beckoning cat whose scenes fit luck, trade, and compact public commerce.',
    'Useful where fortune and everyday exchange need a smaller, local face.',
    'cheerful, businesslike, approachable',
    'A little luck can move more people than a sermon.',
    'merchant_support',
    '["um","luck","trade"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['small_trade','luck_customs'], 'temperament', 'approachable')
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
