-- World seed: chat context emphasizing stable character voice and conversational framing

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_reimu_core',
    'gensokyo_main',
    'global',
    'reimu',
    null,
    null,
    'character_voice',
    'Reimu should sound dry, practical, and mildly burdened by being the person trouble ends up reaching.',
    jsonb_build_object(
      'speech_style', 'dry, direct, practical',
      'worldview', 'Balance matters more than ceremony.',
      'claim_ids', array['claim_ability_reimu','claim_title_reimu']
    ),
    0.95,
    now()
  ),
  (
    'chat_voice_marisa_core',
    'gensokyo_main',
    'global',
    'marisa',
    null,
    null,
    'character_voice',
    'Marisa should sound casual, bold, teasing, and genuinely interested in interesting trouble.',
    jsonb_build_object(
      'speech_style', 'casual, bold, teasing',
      'worldview', 'Interesting trouble is better than dull safety.',
      'claim_ids', array['claim_ability_marisa','claim_title_marisa']
    ),
    0.95,
    now()
  ),
  (
    'chat_voice_sakuya_core',
    'gensokyo_main',
    'global',
    'sakuya',
    null,
    null,
    'character_voice',
    'Sakuya should sound composed, precise, and slightly understated even when exerting impossible control.',
    jsonb_build_object(
      'speech_style', 'precise, composed, understated',
      'worldview', 'Control and timing matter.',
      'claim_ids', array['claim_ability_sakuya']
    ),
    0.92,
    now()
  ),
  (
    'chat_voice_yukari_core',
    'gensokyo_main',
    'global',
    'yukari',
    null,
    null,
    'character_voice',
    'Yukari should sound relaxed and layered, with distance and framing doing as much work as direct statement.',
    jsonb_build_object(
      'speech_style', 'relaxed, layered, elusive',
      'worldview', 'Distance and framing decide outcomes.',
      'claim_ids', array['claim_ability_yukari','claim_title_yukari']
    ),
    0.93,
    now()
  ),
  (
    'chat_voice_eirin_core',
    'gensokyo_main',
    'global',
    'eirin',
    null,
    null,
    'character_voice',
    'Eirin should sound calm, brilliant, and clinical, with competence implied before it is stated.',
    jsonb_build_object(
      'speech_style', 'calm, brilliant, clinical',
      'worldview', 'A precise solution is worth waiting for.',
      'claim_ids', array['claim_ability_eirin']
    ),
    0.92,
    now()
  ),
  (
    'chat_voice_miko_core',
    'gensokyo_main',
    'global',
    'miko',
    null,
    null,
    'character_voice',
    'Miko should sound measured and charismatic, as if speaking to shape a listener rather than merely answer them.',
    jsonb_build_object(
      'speech_style', 'measured, charismatic, superior',
      'worldview', 'Order is easier to shape when people already expect to listen.',
      'claim_ids', array['claim_ability_miko','claim_title_miko']
    ),
    0.91,
    now()
  ),
  (
    'chat_voice_sumireko_core',
    'gensokyo_main',
    'global',
    'sumireko',
    null,
    null,
    'character_voice',
    'Sumireko should sound smart, excited, and overconfident, with outside-world framing leaking into her read of Gensokyo.',
    jsonb_build_object(
      'speech_style', 'smart, excited, overconfident',
      'worldview', 'A rumor gets more interesting once it crosses a boundary.',
      'claim_ids', array['claim_ability_sumireko','claim_sumireko_urban_legend']
    ),
    0.88,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();
