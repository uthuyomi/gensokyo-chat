-- World seed: final micro-texture chronicle and historian notes

insert into public.world_chronicle_chapters (
  id, book_id, chapter_code, chapter_order, title, summary, period_start, period_end, metadata
)
values
  (
    'chronicle_chapter_regional_customs',
    'chronicle_gensokyo_history',
    'regional_customs',
    10,
    'Regional Customs and Everyday Texture',
    'A chapter for the small local habits, route logic, and social atmospheres that make Gensokyo legible between major incidents.',
    null,
    null,
    '{}'::jsonb
  ),
  (
    'chronicle_chapter_recent_incidents',
    'chronicle_gensokyo_history',
    'recent_incidents_texture',
    11,
    'Recent Incidents and Social Texture',
    'A chapter for the social details and rank-and-file realities surrounding later major incidents.',
    null,
    null,
    '{}'::jsonb
  )
on conflict (id) do update
set book_id = excluded.book_id,
    chapter_code = excluded.chapter_code,
    chapter_order = excluded.chapter_order,
    title = excluded.title,
    summary = excluded.summary,
    period_start = excluded.period_start,
    period_end = excluded.period_end,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_entries (
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body,
  subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values
  (
    'chronicle_entry_misty_lake_local_calm',
    'chronicle_gensokyo_history',
    'chronicle_chapter_regional_customs',
    'misty_lake_local_calm',
    70,
    'regional_note',
    'Misty Lake and Local Calm',
    'Even noisy lakeside areas preserve a quiet local layer beneath fairy movement and mansion traffic.',
    'Misty Lake is not only a place of fairy noise and incidental trouble. Its local atmosphere also depends on quieter presences whose value is measured by steadiness, reflection, and familiarity with the water''s margin.',
    'location',
    'misty_lake',
    'akyuu',
    null,
    null,
    '["misty_lake","regional_texture","wakasagihime"]'::jsonb,
    jsonb_build_object('claim_ids', array['claim_glossary_misty_lake','claim_wakasagihime_local_lake','claim_ability_wakasagihime'])
  ),
  (
    'chronicle_entry_bamboo_forest_social_routes',
    'chronicle_gensokyo_history',
    'chronicle_chapter_regional_customs',
    'bamboo_forest_social_routes',
    71,
    'regional_note',
    'Bamboo Forest and Social Routes',
    'The Bamboo Forest stays livable because instinct, luck, and local guidance all act as route-making forces.',
    'The Bamboo Forest is not navigated by geography alone. Its ordinary usability depends on local beings whose instincts, tricks, or long familiarity turn a maze into a social route.',
    'location',
    'bamboo_forest',
    'akyuu',
    null,
    null,
    '["bamboo_forest","regional_texture","routes"]'::jsonb,
    jsonb_build_object('claim_ids', array['claim_glossary_bamboo_forest','claim_kagerou_bamboo_night','claim_ability_kagerou'])
  ),
  (
    'chronicle_entry_lunar_rank_and_file',
    'chronicle_gensokyo_history',
    'chronicle_chapter_recent_incidents',
    'lunar_rank_and_file',
    72,
    'social_note',
    'Lunar Rank-and-File Presence',
    'The moon''s settings feel real only when ordinary rabbit labor and routine are visible beneath high strategy.',
    'Lunar politics easily become too distant if only nobles and strategists are remembered. Daily work, appetite, and enlisted motion keep that world from flattening into pure abstraction.',
    'theme',
    'lunar_rank_and_file',
    'akyuu',
    null,
    null,
    '["lunar_capital","lunar_rank_and_file","recent_incidents"]'::jsonb,
    jsonb_build_object('claim_ids', array['claim_seiran_soldier','claim_ringo_daily_lunar','claim_ability_seiran','claim_ability_ringo','claim_lunar_capital_profile'])
  ),
  (
    'chronicle_entry_beast_realm_defense_texture',
    'chronicle_gensokyo_history',
    'chronicle_chapter_recent_incidents',
    'beast_realm_defense_texture',
    73,
    'social_note',
    'Beast Realm Defense Texture',
    'Beast Realm order is not only predation; it also appears through formation, discipline, and constructed loyalty.',
    'Scenes from the Beast Realm grow more legible when defense and rank are represented by figures built for duty rather than only by reckless power or faction slogans.',
    'theme',
    'beast_realm_defense',
    'akyuu',
    null,
    null,
    '["beast_realm","formation","recent_incidents"]'::jsonb,
    jsonb_build_object('claim_ids', array['claim_ability_mayumi','claim_beast_realm_profile'])
  )
on conflict (id) do update
set book_id = excluded.book_id,
    chapter_id = excluded.chapter_id,
    entry_code = excluded.entry_code,
    entry_order = excluded.entry_order,
    entry_type = excluded.entry_type,
    title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    narrator_character_id = excluded.narrator_character_id,
    event_id = excluded.event_id,
    history_id = excluded.history_id,
    tags = excluded.tags,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_akyuu_misty_lake_local_calm',
    'gensokyo_main',
    'akyuu',
    'location',
    'misty_lake',
    'editorial',
    'On Misty Lake Locality',
    'Akyuu notes that Misty Lake should not be reduced to fairy noise and mansion approach alone.',
    'Even locations famous for visible trouble retain quieter inhabitants who give them continuity. Misty Lake gains depth when local calm is remembered alongside spectacle.',
    '["claim_glossary_misty_lake","claim_wakasagihime_local_lake","claim_ability_wakasagihime"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_bamboo_social_routes',
    'gensokyo_main',
    'akyuu',
    'location',
    'bamboo_forest',
    'editorial',
    'On Bamboo Forest Routes',
    'Akyuu frames the Bamboo Forest as socially navigated, not merely geographically confusing.',
    'A forest becomes livable when local beings repeatedly turn danger and obscurity into recognizable pathways. In that sense, instinct and trickery are as infrastructural as roads.',
    '["claim_glossary_bamboo_forest","claim_kagerou_bamboo_night","claim_ability_kagerou"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_lunar_rank_and_file',
    'gensokyo_main',
    'akyuu',
    'theme',
    'lunar_rank_and_file',
    'editorial',
    'On Lunar Routine',
    'Akyuu notes that even the moon requires ordinary routine to remain legible as a society.',
    'Grand strategy alone does not make a social world. Figures like Seiran and Ringo matter because they imply kitchens, orders, pauses, and repeated tasks beneath the visible conflict.',
    '["claim_seiran_soldier","claim_ringo_daily_lunar","claim_ability_seiran","claim_ability_ringo","claim_lunar_capital_profile"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_beast_realm_formation',
    'gensokyo_main',
    'akyuu',
    'theme',
    'beast_realm_defense',
    'editorial',
    'On Beast Realm Formation',
    'Akyuu notes that later Beast Realm scenes became clearer once discipline and made soldiery were treated as part of the picture.',
    'Predatory realms are easy to flatten into chaos. They become more intelligible when one also records their habits of defense, formation, and constructed obligation.',
    '["claim_ability_mayumi","claim_beast_realm_profile"]'::jsonb,
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
