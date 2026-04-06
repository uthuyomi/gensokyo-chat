-- World seed: historian notes for late-mainline system shifts

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_akyuu_hidden_seasons',
    'gensokyo_main',
    'akyuu',
    'incident',
    'incident_hidden_seasons',
    'editorial',
    'On Hidden Seasons as Selective Access',
    'A note on why the hidden-seasons disturbance matters as access logic as much as seasonal manipulation.',
    'The hidden-seasons incident is not important only because weather overflowed. Its deeper significance lies in selective access: who could reveal, grant, or withhold latent power, and under what hidden invitation such access became possible.',
    '["claim_incident_hidden_seasons","claim_term_hidden_seasons"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_beast_realm',
    'gensokyo_main',
    'akyuu',
    'incident',
    'incident_beast_realm',
    'editorial',
    'On the Beast Realm as Politics, Not Mere Ferocity',
    'A note on why Beast Realm involvement should be read through factional structure and coercive order.',
    'The Beast Realm incursion matters because it introduces organized predation and factional pressure into Gensokyo''s field of understanding. To misread it as mere savagery is to ignore the political form inside the violence.',
    '["claim_incident_beast_realm","claim_term_beast_realm_politics"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_market_cards',
    'gensokyo_main',
    'akyuu',
    'incident',
    'incident_market_cards',
    'editorial',
    'On Market Cards and the Circulation of Power',
    'A note on the market-card affair as a change in how ability and value were publicly understood.',
    'The ability-card affair did more than produce commercial confusion. It changed the visible grammar of power by making circulation, ownership, and exchange part of how ability itself was popularly imagined.',
    '["claim_incident_market_cards","claim_term_market_competition","claim_term_market_cards"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_living_ghost_conflict',
    'gensokyo_main',
    'akyuu',
    'incident',
    'incident_living_ghost_conflict',
    'editorial',
    'On the Living-Ghost Conflict as Escalated Structure',
    'A note on later underworld conflict as pressure from higher-order actors rather than simple local disturbance.',
    'The all-living-ghost conflict should be remembered as an escalation in structural pressure. Its notable feature is not only the number of new actors, but the way underworld hierarchy and Beast Realm logic overlap at a scale ordinary local trouble cannot contain.',
    '["claim_incident_living_ghost_conflict","claim_zanmu_structural_actor","lore_recent_underworld_power"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set note_kind = excluded.note_kind,
    title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
