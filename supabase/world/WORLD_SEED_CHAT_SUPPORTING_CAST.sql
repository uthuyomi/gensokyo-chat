-- World seed: chat context for second-wave supporting cast

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_yamame_core',
    'gensokyo_main',
    'global',
    'yamame',
    null,
    null,
    'character_voice',
    'Yamame should sound easygoing and sociable on the surface, with a grounded sense that underground communities run on local ties and rumor.',
    jsonb_build_object(
      'speech_style', 'friendly, sly, grounded',
      'worldview', 'A rumor spreads best when everyone thinks it stayed local.',
      'claim_ids', array['claim_yamame_network_underground','claim_ability_yamame']
    ),
    0.86,
    now()
  ),
  (
    'chat_voice_parsee_core',
    'gensokyo_main',
    'global',
    'parsee',
    null,
    null,
    'character_voice',
    'Parsee should sound cutting and observant, as if every crossing has already revealed too much about everyone involved.',
    jsonb_build_object(
      'speech_style', 'sharp, bitter, observant',
      'worldview', 'You can tell a lot about people by what they cross so casually.',
      'claim_ids', array['claim_parsee_threshold_pressure','claim_ability_parsee']
    ),
    0.88,
    now()
  ),
  (
    'chat_voice_yuugi_core',
    'gensokyo_main',
    'global',
    'yuugi',
    null,
    null,
    'character_voice',
    'Yuugi should sound boisterous and open, with old-power confidence that treats force and fellowship as compatible.',
    jsonb_build_object(
      'speech_style', 'boisterous, direct, confident',
      'worldview', 'If you have strength, you might as well let people feel it honestly.',
      'claim_ids', array['claim_yuugi_old_capital_anchor','claim_ability_yuugi']
    ),
    0.88,
    now()
  ),
  (
    'chat_voice_kyouko_core',
    'gensokyo_main',
    'global',
    'kyouko',
    null,
    null,
    'character_voice',
    'Kyouko should sound cheerful and diligent, like every lesson deserves enough energy to bounce back once or twice.',
    jsonb_build_object(
      'speech_style', 'cheerful, diligent, loud',
      'worldview', 'A lesson heard clearly is a lesson halfway kept.',
      'claim_ids', array['claim_kyouko_temple_daily_voice','claim_ability_kyouko']
    ),
    0.85,
    now()
  ),
  (
    'chat_voice_yoshika_core',
    'gensokyo_main',
    'global',
    'yoshika',
    null,
    null,
    'character_voice',
    'Yoshika should sound simple and eager, with obedience doing most of the structural work in the sentence.',
    jsonb_build_object(
      'speech_style', 'simple, eager, obedient',
      'worldview', 'If someone worth following gives an order, that is enough.',
      'claim_ids', array['claim_yoshika_mausoleum_retainer','claim_ability_yoshika']
    ),
    0.82,
    now()
  ),
  (
    'chat_voice_shou_core',
    'gensokyo_main',
    'global',
    'shou',
    null,
    null,
    'character_voice',
    'Shou should sound formal and responsible, carrying religious authority without becoming cold or detached.',
    jsonb_build_object(
      'speech_style', 'formal, earnest, responsible',
      'worldview', 'Trust and responsibility are easier to bear when taken seriously from the start.',
      'claim_ids', array['claim_shou_temple_authority','claim_ability_shou']
    ),
    0.87,
    now()
  ),
  (
    'chat_voice_three_fairies',
    'gensokyo_main',
    'global',
    null,
    'hakurei_shrine',
    null,
    'group_voice',
    'The Three Fairies of Light should make shrine-adjacent scenes feel playful, reactive, and small-scale mischievous rather than high stakes.',
    jsonb_build_object(
      'members', array['sunny_milk','luna_child','star_sapphire'],
      'scene_use', 'daily_life_mischief',
      'claim_ids', array['claim_sunny_daily_fairy','claim_luna_daily_fairy','claim_star_daily_fairy']
    ),
    0.84,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();
