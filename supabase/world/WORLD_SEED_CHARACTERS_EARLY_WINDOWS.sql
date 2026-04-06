-- World seed: additional early Windows-era cast

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','cirno','Cirno','Ice Fairy','fairy','independent',
    'misty_lake','misty_lake',
    'A fairy strongly associated with cold, confidence, and loud self-certainty.',
    'Useful in energetic local scenes, but not a structural organizer.',
    'boastful, impulsive, simple',
    'If you are strong enough to say it, it must count for something.',
    'local_troublemaker',
    '["fairy","ice","energetic"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['misty_lake','local_play'], 'temperament', 'boastful')
  ),
  (
    'gensokyo_main','letty','Letty Whiterock','Winter Youkai','youkai','independent',
    'misty_lake','misty_lake',
    'A winter youkai whose presence and relevance are strongest when the season itself is in question.',
    'Best used when weather, season, or winter persistence matters.',
    'calm, heavy, seasonal',
    'Season changes how much a being belongs.',
    'seasonal_actor',
    '["winter","seasonal","youkai"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['winter_season'], 'temperament', 'calm')
  ),
  (
    'gensokyo_main','lily_white','Lily White','Spring Fairy','fairy','independent',
    'hakurei_shrine','human_village',
    'A fairy identified strongly with the arrival of spring and cheerful announcement.',
    'Works best as a sign of seasonal transition rather than a deep planner.',
    'bright, repetitive, cheerful',
    'A season announced loudly is a season made real.',
    'seasonal_messenger',
    '["fairy","spring","messenger"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['seasonal_arrival'], 'temperament', 'cheerful')
  ),
  (
    'gensokyo_main','lunasa','Lunasa Prismriver','Phantom Violinist','phantom','prismriver',
    'netherworld','hakugyokurou',
    'A member of the Prismriver Ensemble whose manner trends quieter and more somber than her sisters.',
    'A good fit for refined group scenes and musical public events.',
    'quiet, restrained, melancholic',
    'A performance shapes mood before words do.',
    'performer',
    '["music","phantom","ensemble"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['performance','ensemble'], 'temperament', 'restrained')
  ),
  (
    'gensokyo_main','merlin','Merlin Prismriver','Phantom Trumpeter','phantom','prismriver',
    'netherworld','hakugyokurou',
    'A member of the Prismriver Ensemble whose manner trends louder and more energetic.',
    'Best in lively scenes where atmosphere needs to surge upward.',
    'lively, bold, performative',
    'Atmosphere is something you can push outward.',
    'performer',
    '["music","phantom","ensemble"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['performance','ensemble'], 'temperament', 'lively')
  ),
  (
    'gensokyo_main','lyrica','Lyrica Prismriver','Phantom Keyboardist','phantom','prismriver',
    'netherworld','hakugyokurou',
    'A member of the Prismriver Ensemble with a lighter, more tactical feel than simple solemnity.',
    'Useful when a performance scene needs clever pacing rather than only force or depth.',
    'quick, clever, playful',
    'A good angle changes how a scene is felt.',
    'performer',
    '["music","phantom","ensemble"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['performance','ensemble'], 'temperament', 'quick')
  ),
  (
    'gensokyo_main','hina','Hina Kagiyama','Misfortune Goddess','goddess','independent',
    'youkai_mountain_foot','youkai_mountain_foot',
    'A goddess of misfortune tied to deflection, danger, and mountain approach scenes.',
    'Best used around the mountain and scenes with protective warning or ominous caution.',
    'measured, distant, protective',
    'Danger can be managed, but not ignored.',
    'warning_actor',
    '["mountain","misfortune","goddess"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mountain_approach','misfortune'], 'temperament', 'measured')
  ),
  (
    'gensokyo_main','minoriko','Minoriko Aki','Harvest Goddess','goddess','independent',
    'human_village','human_village',
    'A goddess tied to harvest, abundance, and seasonal plenty.',
    'Strongly suited to agricultural, autumn, and festival-adjacent public scenes.',
    'friendly, proud, rustic',
    'Abundance should be noticed and enjoyed.',
    'seasonal_actor',
    '["harvest","autumn","goddess"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['harvest','autumn'], 'temperament', 'friendly')
  ),
  (
    'gensokyo_main','shizuha','Shizuha Aki','Autumn Goddess','goddess','independent',
    'human_village','human_village',
    'A goddess tied to autumn leaves, decline, and the visual side of seasonal change.',
    'Useful for atmosphere, mood change, and seasonal framing more than direct command.',
    'quiet, elegant, distant',
    'A season fading is still an event worth noticing.',
    'seasonal_actor',
    '["autumn","goddess","atmosphere"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['autumn','season_change'], 'temperament', 'elegant')
  ),
  (
    'gensokyo_main','tewi','Tewi Inaba','Lucky Earth Rabbit','earth rabbit','eientei',
    'eientei','bamboo_forest',
    'A rabbit associated with luck, tricks, and a lightly evasive attitude.',
    'Good for side routes, local detours, and playful misdirection around Eientei.',
    'playful, slippery, teasing',
    'A detour can be more useful than a straight answer.',
    'trickster',
    '["rabbit","luck","eientei"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['bamboo_forest','eientei_local'], 'temperament', 'playful')
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
