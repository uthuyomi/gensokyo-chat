-- World seed: residual backdoor and market character claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_satono_selected_service',
    'character_role',
    'Satono Selected Service',
    'Satono works best when hidden-stage service feels cheerful on the surface but selective underneath.',
    jsonb_build_object('character_id','satono'),
    '["hsifs","satono","service"]'::jsonb,
    74
  ),
  (
    'gensokyo_main',
    'lore_mai_backstage_motion',
    'character_role',
    'Mai Backstage Motion',
    'Mai is strongest where hidden-stage service turns into movement, rhythm, and active execution.',
    jsonb_build_object('character_id','mai'),
    '["hsifs","mai","movement"]'::jsonb,
    74
  ),
  (
    'gensokyo_main',
    'lore_sannyo_informal_market_rest',
    'character_role',
    'Sannyo Informal Market Rest',
    'Sannyo makes market stories feel inhabited by pauses, smoke, and small-scale familiarity rather than abstract trade alone.',
    jsonb_build_object('character_id','sannyo'),
    '["um","sannyo","market"]'::jsonb,
    73
  ),
  (
    'gensokyo_main',
    'lore_market_route_rest_logic',
    'world_rule',
    'Market Route Rest Logic',
    'Market-era routes should include informal rest points, gossip nodes, and low-pressure exchange spaces in addition to overt sales.',
    jsonb_build_object('focus',array['sannyo','takane','chimata']),
    '["um","market","routes"]'::jsonb,
    77
  )
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  (
    'claim_satono_selected_attendant',
    'gensokyo_main',
    'character',
    'satono',
    'role',
    'Satono should be framed as a selectively empowering attendant whose brightness hides deliberate backstage service.',
    jsonb_build_object('role','selected_attendant'),
    'src_hsifs',
    'official',
    76,
    '["satono","hsifs","attendant"]'::jsonb
  ),
  (
    'claim_mai_backstage_executor',
    'gensokyo_main',
    'character',
    'mai',
    'role',
    'Mai is best used as an energetic backstage executor whose motion and choreography make hidden service visible.',
    jsonb_build_object('role','backstage_executor'),
    'src_hsifs',
    'official',
    76,
    '["mai","hsifs","attendant"]'::jsonb
  ),
  (
    'claim_sannyo_informal_merchant',
    'gensokyo_main',
    'character',
    'sannyo',
    'role',
    'Sannyo is most natural as an informal merchant whose space relaxes people into quieter trade, smoke, and candid talk.',
    jsonb_build_object('role','informal_merchant'),
    'src_um',
    'official',
    75,
    '["sannyo","um","merchant"]'::jsonb
  ),
  (
    'claim_backdoor_attendants_pairing',
    'gensokyo_main',
    'group',
    'satono_mai_pair',
    'relationship',
    'Satono and Mai should usually be treated as a paired hidden-stage apparatus rather than unrelated background attendants.',
    jsonb_build_object('characters',array['satono','mai']),
    'src_hsifs',
    'official',
    77,
    '["satono","mai","pairing"]'::jsonb
  ),
  (
    'claim_market_route_rest_stops',
    'gensokyo_main',
    'theme',
    'market_route_rest_stops',
    'world_rule',
    'Market routes in Gensokyo should feel sustained by pauses, small gatherings, and low-key exchange points as well as formal selling.',
    jsonb_build_object('focus',array['rainbow_dragon_cave','human_village','youkai_mountain_foot']),
    'src_um',
    'official',
    73,
    '["market","routes","rest"]'::jsonb
  )
on conflict (id) do update
set subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    claim_type = excluded.claim_type,
    summary = excluded.summary,
    details = excluded.details,
    source_id = excluded.source_id,
    confidence = excluded.confidence,
    priority = excluded.priority,
    tags = excluded.tags,
    updated_at = now();
