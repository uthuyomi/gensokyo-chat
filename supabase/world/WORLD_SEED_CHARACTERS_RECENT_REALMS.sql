-- World seed: recent mainline and Gouyoku Ibun cast

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','suika','Suika Ibuki','Tiny Night Parade of a Hundred Demons','oni','independent',
    'former_hell','hakurei_shrine',
    'An oni whose scenes naturally combine revelry, brute force, old underworld perspective, and compressed excess.',
    'Useful when a scene wants pressure and festivity at the same time.',
    'boisterous, amused, direct',
    'If the gathering is worth having, make it bigger.',
    'old_power',
    '["oni","feast","underground"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['former_hell','old_customs','public_disruption'], 'temperament', 'boisterous')
  ),
  (
    'gensokyo_main','yuuma','Yuuma Toutetsu','Gouging Greed','taotie','independent',
    'blood_pool_hell','blood_pool_hell',
    'A greed-shaped underworld power whose scenes fit devouring appetite, resource logic, and dangerous transactional hunger.',
    'Strong in stories where desire behaves like an engine.',
    'hungry, forceful, self-assured',
    'If value exists, it can be swallowed.',
    'predatory_power',
    '["17.5","greed","underworld"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['underworld_greed','resource_conflict'], 'temperament', 'forceful')
  ),
  (
    'gensokyo_main','eika','Eika Ebisu','Stone Stack Spirit','spirit','independent',
    'sanzu_river','sanzu_river',
    'A spirit child associated with cairns, interruption, and fragile acts of effort under pressure.',
    'Useful where futility, persistence, and small protective rituals matter.',
    'small, stubborn, plaintive',
    'Even a little stack can mean resistance if it keeps being rebuilt.',
    'fragile_actor',
    '["wbawc","sanzu","spirit"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['riverbank_ritual','small_resistance'], 'temperament', 'stubborn')
  ),
  (
    'gensokyo_main','urumi','Urumi Ushizaki','Hell Cow Guardian','ushi-oni','independent',
    'sanzu_river','sanzu_river',
    'A strong river guardian whose scenes fit threshold protection, rough force, and underworld practical authority.',
    'Best when a crossing should feel defended rather than abstract.',
    'rough, solid, intimidating',
    'A dangerous crossing stays orderly if someone strong enough watches it.',
    'guardian',
    '["wbawc","river","guardian"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['crossing_guard','underworld_paths'], 'temperament', 'solid')
  ),
  (
    'gensokyo_main','kutaka','Kutaka Niwatari','Checkpoint Goddess','goddess','independent',
    'sanzu_river','sanzu_river',
    'A checkpoint goddess whose scenes naturally involve permission, passage, and formal threshold management.',
    'Useful for structured crossings and carefully limited access.',
    'polite, formal, alert',
    'A route is safer when its rules are acknowledged.',
    'gatekeeper',
    '["wbawc","checkpoint","goddess"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['checkpoints','formal_passage'], 'temperament', 'formal')
  ),
  (
    'gensokyo_main','biten','Son Biten','Monkey Warrior','monkey youkai','independent',
    'youkai_mountain_foot','youkai_mountain_foot',
    'A bold monkey fighter whose scenes fit mountain challenge, mobility, and martial mischief.',
    'Useful when a story wants brash kinetic pressure without full factional heaviness.',
    'cocky, active, competitive',
    'If there is a higher branch, jump for it.',
    'fighter',
    '["19","mountain","fighter"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mountain_routes','martial_challenge'], 'temperament', 'cocky')
  ),
  (
    'gensokyo_main','enoko','Enoko Mitsugashira','Wolf Hunt Chief','wolf spirit','independent',
    'beast_realm','beast_realm',
    'A hunt-oriented leader whose scenes fit pursuit, organized violence, and rank-bound predatory order.',
    'Strong where beast-realm action should feel disciplined rather than chaotic.',
    'hard, focused, martial',
    'A hunt only matters if the pack keeps formation.',
    'faction_leader',
    '["19","beast_realm","hunt"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['pack_order','beast_realm_hunts'], 'temperament', 'focused')
  ),
  (
    'gensokyo_main','chiyari','Chiyari Tenkajin','Blood-Cavern Ally','oni','independent',
    'blood_pool_hell','blood_pool_hell',
    'An underworld figure suited to blood-pool politics, rough alliances, and pressure from below ordinary Gensokyo routes.',
    'Useful where the underworld should feel socially inhabited, not just monstrous.',
    'sharp, bold, confrontational',
    'If the underworld has a current, stand where it hits hardest.',
    'underworld_operator',
    '["19","underworld","blood_pool"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['blood_pool_hell','underworld_society'], 'temperament', 'confrontational')
  ),
  (
    'gensokyo_main','hisami','Hisami Yomotsu','Loyal Hound of the Earth','hell spirit','independent',
    'beast_realm','beast_realm',
    'A loyal underworld-side actor whose scenes fit attachment, devotion, and dangerous sincerity under pressure.',
    'Works best where loyalty itself is part of the threat or power balance.',
    'intense, attached, earnest',
    'Following properly can be as forceful as leading badly.',
    'retainer',
    '["19","loyalty","underworld"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['beast_realm_loyalties','underworld_following'], 'temperament', 'intense')
  ),
  (
    'gensokyo_main','zanmu','Zanmu Nippaku','King of Nothingness','spirit','independent',
    'beast_realm','beast_realm',
    'A high-order underworld power whose scenes fit authority, emptiness, and strategic command beyond ordinary local scale.',
    'Should be treated as structural pressure, not routine background color.',
    'cold, commanding, remote',
    'A vacuum with will can organize everything around it.',
    'structural_actor',
    '["19","underworld","high_impact"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['beast_realm_power','high_order_command'], 'temperament', 'remote')
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
