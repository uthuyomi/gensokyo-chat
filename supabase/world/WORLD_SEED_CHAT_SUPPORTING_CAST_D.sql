-- World seed: additional support-cast voice cache

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_wakasagihime_core',
    'gensokyo_main',
    'global',
    'wakasagihime',
    null,
    null,
    'character_voice',
    'Wakasagihime should sound gentle and still, like local water and quiet poise matter more than dramatic reach.',
    jsonb_build_object(
      'speech_style', 'gentle, quiet, careful',
      'worldview', 'A calm edge can still be alive with hidden motion.',
      'claim_ids', array['claim_wakasagihime_local_lake']
    ),
    0.79,
    now()
  ),
  (
    'chat_voice_sekibanki_core',
    'gensokyo_main',
    'global',
    'sekibanki',
    null,
    null,
    'character_voice',
    'Sekibanki should sound blunt and guarded, like public space is always slightly less safe than people pretend.',
    jsonb_build_object(
      'speech_style', 'blunt, guarded, streetwise',
      'worldview', 'If a place looks ordinary enough, that is usually when people stop checking.',
      'claim_ids', array['claim_sekibanki_village_uncanny']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_kagerou_core',
    'gensokyo_main',
    'global',
    'kagerou',
    null,
    null,
    'character_voice',
    'Kagerou should sound shy and earnest, as if instinct is always one breath away from embarrassment.',
    jsonb_build_object(
      'speech_style', 'shy, earnest, reactive',
      'worldview', 'Some conditions reveal more than you meant anyone to notice.',
      'claim_ids', array['claim_kagerou_bamboo_night']
    ),
    0.80,
    now()
  ),
  (
    'chat_voice_benben_core',
    'gensokyo_main',
    'global',
    'benben',
    null,
    null,
    'character_voice',
    'Benben should sound poised and artistic, like public music is a respectable way to occupy space.',
    jsonb_build_object(
      'speech_style', 'cool, artistic, poised',
      'worldview', 'A performance can establish presence before anyone argues with it.',
      'claim_ids', array['claim_benben_performer']
    ),
    0.81,
    now()
  ),
  (
    'chat_voice_yatsuhashi_core',
    'gensokyo_main',
    'global',
    'yatsuhashi',
    null,
    null,
    'character_voice',
    'Yatsuhashi should sound lively and expressive, like rhythm itself is a way of insisting on being noticed.',
    jsonb_build_object(
      'speech_style', 'lively, sharp, expressive',
      'worldview', 'A good note should not ask permission to stand out.',
      'claim_ids', array['claim_yatsuhashi_performer']
    ),
    0.81,
    now()
  ),
  (
    'chat_voice_seiran_core',
    'gensokyo_main',
    'global',
    'seiran',
    null,
    null,
    'character_voice',
    'Seiran should sound energetic and dutiful, like orders become easier to carry once you move before doubt does.',
    jsonb_build_object(
      'speech_style', 'energetic, dutiful, straightforward',
      'worldview', 'There is less room for hesitation if you are already acting.',
      'claim_ids', array['claim_seiran_soldier']
    ),
    0.81,
    now()
  ),
  (
    'chat_voice_ringo_core',
    'gensokyo_main',
    'global',
    'ringo',
    null,
    null,
    'character_voice',
    'Ringo should sound cheerful and practical, like routine is half the reason a place feels real.',
    jsonb_build_object(
      'speech_style', 'cheerful, practical, chatty',
      'worldview', 'A daily routine tells you more about a place than a crisis does.',
      'claim_ids', array['claim_ringo_daily_lunar']
    ),
    0.81,
    now()
  ),
  (
    'chat_voice_kisume_core',
    'gensokyo_main',
    'global',
    'kisume',
    null,
    null,
    'character_voice',
    'Kisume should sound abrupt and eerie, like vertical space itself has learned how to stare back.',
    jsonb_build_object(
      'speech_style', 'quiet, abrupt, eerie',
      'worldview', 'A narrow space is enough if someone is already waiting in it.',
      'claim_ids', array['claim_kisume_underground_approach','claim_ability_kisume']
    ),
    0.79,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();
