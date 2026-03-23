-- World seed: historian notes for backdoor and market residual systems

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_akyuu_backdoor_attendants',
    'gensokyo_main',
    'akyuu',
    'theme',
    'backdoor_attendants',
    'editorial',
    'On Backdoor Attendants',
    'Akyuu records Satono and Mai as a paired logic of access rather than two isolated personalities.',
    'When hidden-stage authority appears in Gensokyo, attendants often matter less as independent household figures than as visible mechanisms of invitation, selection, and stage management. Satono and Mai belong to that category.',
    '["claim_satono_selected_attendant","claim_mai_backstage_executor","claim_backdoor_attendants_pairing","claim_backdoor_realm_profile"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_market_rest_routes',
    'gensokyo_main',
    'akyuu',
    'theme',
    'market_rest_routes',
    'editorial',
    'On Informal Market Routes',
    'Akyuu notes that market circulation in Gensokyo depends on informal resting places as much as on overt stalls.',
    'Trade in Gensokyo rarely persists by commerce alone. Repeated exchange is often stabilized by places where people pause, smoke, gossip, and loosen their guard. Figures such as Sannyo become important because they embody that social layer.',
    '["claim_sannyo_informal_merchant","claim_market_route_rest_stops","claim_rainbow_dragon_cave_profile"]'::jsonb,
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
