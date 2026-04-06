-- World seed: second wave of supporting cast across underground, temple, and fairy layers

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','kisume','Kisume','Bucket Well Youkai','youkai','independent',
    'former_hell','former_hell',
    'A small underground youkai best used for narrow passage, ambush, and local mood in vertical spaces.',
    'Useful for making underground routes feel inhabited before larger actors arrive.',
    'quiet, abrupt, eerie',
    'The smallest opening can still become a proper approach.',
    'local_actor',
    '["sa","underground","ambush"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['former_hell','vertical_routes'], 'temperament', 'eerie')
  ),
  (
    'gensokyo_main','yamame','Yamame Kurodani','Spider Youkai','tsuchigumo','independent',
    'former_hell','former_hell',
    'An underground spider youkai suited to rumor, disease talk, and social ties in hidden communities.',
    'Best for showing that the underground has gossip and social texture, not only threat.',
    'friendly, sly, grounded',
    'A network matters most when people forget it is there.',
    'network_actor',
    '["sa","underground","rumor"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['former_hell','underground_social'], 'temperament', 'sly')
  ),
  (
    'gensokyo_main','parsee','Parsee Mizuhashi','Jealousy of the Bridge','hashihime','independent',
    'former_hell','former_hell',
    'A bridge guardian whose scenes fit resentment, observation, and the emotional toll of passage.',
    'Useful where crossing points need emotional pressure rather than simple combat.',
    'sharp, bitter, observant',
    'Crossings are easiest to judge from the side.',
    'threshold_actor',
    '["sa","bridge","emotion"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['bridges','crossings','former_hell'], 'temperament', 'bitter')
  ),
  (
    'gensokyo_main','yuugi','Yuugi Hoshiguma','Powerful Oni','oni','independent',
    'old_capital','old_capital',
    'An oni of former hell suited to convivial force, straightforward challenge, and old-power prestige.',
    'Best used where underground authority should feel social as well as physical.',
    'boisterous, direct, fearless',
    'Strength is easiest to trust when it does not hide.',
    'power_anchor',
    '["sa","oni","old_capital"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['old_capital','oni_customs'], 'temperament', 'boisterous')
  ),
  (
    'gensokyo_main','kyouko','Kyouko Kasodani','Yamabiko Monk','yamabiko','myouren',
    'myouren_temple','myouren_temple',
    'A temple-affiliated yamabiko whose scenes fit discipline, cheerful repetition, and audible presence.',
    'Useful for making Myouren Temple feel inhabited at an everyday level.',
    'cheerful, diligent, loud',
    'If a lesson is worth saying once, it may be worth hearing twice.',
    'temple_support',
    '["td","temple","echo"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['myouren_temple','temple_routine'], 'temperament', 'diligent')
  ),
  (
    'gensokyo_main','yoshika','Yoshika Miyako','Loyal Jiang-shi','jiangshi','taoist',
    'divine_spirit_mausoleum','divine_spirit_mausoleum',
    'A jiang-shi retainer suited to loyalty, blunt force, and visibly controlled service under a stronger agenda.',
    'Useful for giving the mausoleum side physical presence without overcomplicating motive.',
    'simple, eager, obedient',
    'If the order is clear, the work is easy.',
    'retainer',
    '["td","mausoleum","retainer"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mausoleum_service','basic_orders'], 'temperament', 'obedient')
  ),
  (
    'gensokyo_main','shou','Shou Toramaru','Avatar of Bishamonten','youkai','myouren',
    'myouren_temple','myouren_temple',
    'A temple leader whose scenes fit religious authority, treasure symbolism, and dutiful responsibility.',
    'Useful where Myouren Temple needs leadership distinct from Byakuren herself.',
    'earnest, formal, responsible',
    'Responsibility becomes visible when others place trust in it.',
    'religious_lead',
    '["ufo","temple","authority"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['myouren_temple','religious_authority'], 'temperament', 'earnest')
  ),
  (
    'gensokyo_main','sunny_milk','Sunny Milk','Fairy of Sunlight','fairy','independent',
    'hakurei_shrine','hakurei_shrine',
    'A prank-minded fairy suited to shrine-adjacent daily life, mischief, and trio scenes.',
    'Best used with the other fairies to make ordinary days feel alive and slightly troublesome.',
    'bright, playful, smug',
    'A sunny opening is best when someone else walks into it first.',
    'daily_life_actor',
    '["fairy","daily_life","sunlight"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['shrine_daily_life','fairy_pranks'], 'temperament', 'playful')
  ),
  (
    'gensokyo_main','luna_child','Luna Child','Fairy of Silence','fairy','independent',
    'hakurei_shrine','hakurei_shrine',
    'A quiet but mischievous fairy suited to stealth, atmosphere shifts, and trio rhythm.',
    'Useful for making fairy scenes feel composed rather than only loud.',
    'soft, sly, mischievous',
    'Silence can be more useful than hiding in plain sight.',
    'daily_life_actor',
    '["fairy","daily_life","silence"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['shrine_daily_life','fairy_pranks'], 'temperament', 'sly')
  ),
  (
    'gensokyo_main','star_sapphire','Star Sapphire','Fairy of Starlight','fairy','independent',
    'hakurei_shrine','hakurei_shrine',
    'A perceptive fairy suited to awareness, teasing observation, and trio coordination.',
    'Useful for giving fairy scenes a lookout who notices more than she should.',
    'clever, teasing, alert',
    'Noticing first is its own kind of advantage.',
    'daily_life_actor',
    '["fairy","daily_life","perception"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['shrine_daily_life','fairy_pranks'], 'temperament', 'alert')
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
