-- World seed: seasonal and village-side chat context

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_harvest_village',
    'gensokyo_main',
    'global',
    null,
    'human_village',
    null,
    'seasonal_location',
    'In harvest-season scenes, the Human Village should feel fed, social, and publicly aware of abundance.',
    jsonb_build_object(
      'season', 'autumn',
      'claim_ids', array['claim_ability_minoriko','claim_regional_village_night_life'],
      'character_ids', array['minoriko','shizuha','akyuu','keine']
    ),
    0.82,
    now()
  ),
  (
    'chat_location_spring_announcement',
    'gensokyo_main',
    'global',
    null,
    'hakurei_shrine',
    null,
    'seasonal_location',
    'In early spring scenes, Hakurei Shrine should feel noisy with announcement, fairy-scale motion, and visible seasonal change.',
    jsonb_build_object(
      'season', 'spring',
      'claim_ids', array['claim_ability_lily_white','claim_regional_shrine_fairy_life'],
      'character_ids', array['lily_white','sunny_milk','luna_child','star_sapphire']
    ),
    0.81,
    now()
  ),
  (
    'chat_location_winter_presence',
    'gensokyo_main',
    'global',
    null,
    'misty_lake',
    null,
    'seasonal_location',
    'Winter scenes at Misty Lake should feel heavy, present, and a little slower, as if cold itself has become a local actor.',
    jsonb_build_object(
      'season', 'winter',
      'claim_ids', array['claim_ability_letty'],
      'character_ids', array['letty','cirno','wakasagihime']
    ),
    0.80,
    now()
  ),
  (
    'chat_location_night_food_music',
    'gensokyo_main',
    'global',
    null,
    'human_village',
    null,
    'location_mood',
    'At night, the village edge should support food, song, tavern warmth, rumor, and low-grade danger all at once.',
    jsonb_build_object(
      'time_of_day', 'night',
      'claim_ids', array['claim_regional_village_night_life','claim_mystia_night_vendor','claim_miyoi_night_hospitality'],
      'character_ids', array['mystia','miyoi','wriggle']
    ),
    0.85,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();
