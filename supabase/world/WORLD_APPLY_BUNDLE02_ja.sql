-- 自動生成された日本語版: WORLD_APPLY_BUNDLE02.sql

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  (
    'claim_ability_kisume',
    'gensokyo_main',
    'character',
    'kisume',
    'ability',
    'キスメに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'キスメ', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    66,
    '["ability","kisume","sa"]'::jsonb
  ),
  (
    'claim_ability_yamame',
    'gensokyo_main',
    'character',
    'yamame',
    'ability',
    '黒谷 ヤマメに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '黒谷 ヤマメ', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    71,
    '["ability","yamame","sa"]'::jsonb
  ),
  (
    'claim_ability_parsee',
    'gensokyo_main',
    'character',
    'parsee',
    'ability',
    '水橋 パルスィに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '水橋 パルスィ', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    73,
    '["ability","parsee","sa"]'::jsonb
  ),
  (
    'claim_ability_yuugi',
    'gensokyo_main',
    'character',
    'yuugi',
    'ability',
    '星熊 勇儀に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '星熊 勇儀', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    74,
    '["ability","yuugi","sa"]'::jsonb
  ),
  (
    'claim_ability_kyouko',
    'gensokyo_main',
    'character',
    'kyouko',
    'ability',
    '幽谷 響子に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '幽谷 響子', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    67,
    '["ability","kyouko","td"]'::jsonb
  ),
  (
    'claim_ability_yoshika',
    'gensokyo_main',
    'character',
    'yoshika',
    'ability',
    '宮古 芳香に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '宮古 芳香', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    69,
    '["ability","yoshika","td"]'::jsonb
  ),
  (
    'claim_ability_shou',
    'gensokyo_main',
    'character',
    'shou',
    'ability',
    '寅丸 星に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '寅丸 星', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    72,
    '["ability","shou","ufo"]'::jsonb
  ),
  (
    'claim_ability_sunny_milk',
    'gensokyo_main',
    'character',
    'sunny_milk',
    'ability',
    'サニーミルクに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'サニーミルク', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_osp',
    'official',
    66,
    '["ability","sunny_milk","fairy"]'::jsonb
  ),
  (
    'claim_ability_luna_child',
    'gensokyo_main',
    'character',
    'luna_child',
    'ability',
    'ルナチャイルドに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'ルナチャイルド', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_osp',
    'official',
    66,
    '["ability","luna_child","fairy"]'::jsonb
  ),
  (
    'claim_ability_star_sapphire',
    'gensokyo_main',
    'character',
    'star_sapphire',
    'ability',
    'スターサファイアに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'スターサファイア', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_osp',
    'official',
    67,
    '["ability","star_sapphire","fairy"]'::jsonb
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_yamame',
    'gensokyo_main',
    'characters/yamame-kurodani',
    '黒谷 ヤマメ',
    'character',
    'character',
    'yamame',
    '黒谷 ヤマメに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_parsee',
    'gensokyo_main',
    'characters/parsee-mizuhashi',
    '水橋 パルスィ',
    'character',
    'character',
    'parsee',
    '水橋 パルスィに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_yuugi',
    'gensokyo_main',
    'characters/yuugi-hoshiguma',
    '星熊 勇儀',
    'character',
    'character',
    'yuugi',
    '星熊 勇儀に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_kyouko',
    'gensokyo_main',
    'characters/kyouko-kasodani',
    '幽谷 響子',
    'character',
    'character',
    'kyouko',
    '幽谷 響子に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_yoshika',
    'gensokyo_main',
    'characters/yoshika-miyako',
    '宮古 芳香',
    'character',
    'character',
    'yoshika',
    '宮古 芳香に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_shou',
    'gensokyo_main',
    'characters/shou-toramaru',
    '寅丸 星',
    'character',
    'character',
    'shou',
    '寅丸 星に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_three_fairies',
    'gensokyo_main',
    'characters/three-fairies-of-light',
    '光の三妖精',
    'group',
    'group',
    'three_fairies_of_light',
    '光の三妖精に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_yamame:section:overview',
    'wiki_character_yamame',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_yamame_network_underground","claim_ability_yamame"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_parsee:section:overview',
    'wiki_character_parsee',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_parsee_threshold_pressure","claim_ability_parsee"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_yuugi:section:overview',
    'wiki_character_yuugi',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_yuugi_old_capital_anchor","claim_ability_yuugi"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_kyouko:section:overview',
    'wiki_character_kyouko',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_kyouko_temple_daily_voice","claim_ability_kyouko"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_yoshika:section:overview',
    'wiki_character_yoshika',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_yoshika_mausoleum_retainer","claim_ability_yoshika"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_shou:section:overview',
    'wiki_character_shou',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_shou_temple_authority","claim_ability_shou"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_three_fairies:section:overview',
    'wiki_character_three_fairies',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_sunny_daily_fairy","claim_luna_daily_fairy","claim_star_daily_fairy"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

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
    '黒谷 ヤマメの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '黒谷 ヤマメの会話や振る舞いに関する文脈データです。'),
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
    '水橋 パルスィの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '水橋 パルスィの会話や振る舞いに関する文脈データです。'),
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
    '星熊 勇儀の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '星熊 勇儀の会話や振る舞いに関する文脈データです。'),
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
    '幽谷 響子の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '幽谷 響子の会話や振る舞いに関する文脈データです。'),
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
    '宮古 芳香の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '宮古 芳香の会話や振る舞いに関する文脈データです。'),
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
    '寅丸 星の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '寅丸 星の会話や振る舞いに関する文脈データです。'),
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
    '博麗神社に関する場面文脈データです。',
    jsonb_build_object('説明', '博麗神社に関する場面文脈データです。'),
    0.84,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_book_fairy_everyday',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","fairy","daily_life"]'::jsonb,
    77
  ),
  (
    'gensokyo_main',
    'lore_book_tengu_bias',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","tengu","reporting"]'::jsonb,
    76
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
    'claim_book_fairy_everyday',
    'gensokyo_main',
    'printwork',
    'fairy_everyday_cluster',
    'summary',
    '妖精の日常記録に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '妖精の日常記録', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_vfi',
    'official',
    78,
    '["printwork","fairy","summary"]'::jsonb
  ),
  (
    'claim_book_tengu_bias',
    'gensokyo_main',
    'printwork',
    'tengu_reporting_cluster',
    'summary',
    '天狗報道記録に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '天狗報道記録', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_alt_truth',
    'official',
    77,
    '["printwork","tengu","summary"]'::jsonb
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

insert into public.world_chronicle_chapters (
  id, book_id, chapter_code, chapter_order, title, summary, period_start, period_end, metadata
)
values (
  'chronicle_gensokyo_history:chapter:daily_life',
  'chronicle_gensokyo_history',
  'daily_life',
  4,
  '年代記の章',
  '年代記の章の内容を整理した章説明です。',
  null,
  null,
  '{}'::jsonb
)
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    period_start = excluded.period_start,
    period_end = excluded.period_end,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_entries (
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body, subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values (
  'chronicle_entry_fairy_everyday',
  'chronicle_gensokyo_history',
  'chronicle_gensokyo_history:chapter:daily_life',
  'fairy_everyday',
  3,
  'essay',
  '光の三妖精に関する年代記',
  '光の三妖精に関する年代記の記録です。',
  '光の三妖精に関する経緯や位置づけを日本語で整理した本文です。',
  'group',
  'three_fairies_of_light',
  'keine',
  null,
  null,
  '["fairy","daily_life","history"]'::jsonb,
  '{}'::jsonb
)
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    narrator_character_id = excluded.narrator_character_id,
    tags = excluded.tags,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_entry_sources (
  id, entry_id, source_kind, source_ref_id, source_label, weight, notes
)
values
  (
    'chronicle_entry_fairy_everyday:src:claim',
    'chronicle_entry_fairy_everyday',
    'canon_claim',
    'claim_book_fairy_everyday',
    '参照資料',
    0.86,
    '年代記の根拠として参照した資料です。'
  ),
  (
    'chronicle_entry_fairy_everyday:src:lore',
    'chronicle_entry_fairy_everyday',
    'lore',
    'lore_book_fairy_everyday',
    '参照資料',
    0.82,
    '年代記の根拠として参照した資料です。'
  )
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_ref_id = excluded.source_ref_id,
    source_label = excluded.source_label,
    weight = excluded.weight,
    notes = excluded.notes;

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id, public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main',
    'rumia',
    'ルーミア',
    '宵闇の妖怪',
    '妖怪',
    'independent',
    'misty_lake',
    'misty_lake',
    'ルーミアに関する基本人物紹介です。',
    'ルーミアを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'ルーミアの価値観や見方を整理した文面です。',
    'ルーミアの役割です。',
    '["eosd","night","local"]'::jsonb,
    jsonb_build_object('表示名', 'ルーミア', '肩書き', '宵闇の妖怪', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'mystia',
    'ミスティア・ローレライ',
    '夜雀の妖怪',
    '種族',
    'independent',
    'human_village',
    'human_village',
    'ミスティア・ローレライに関する基本人物紹介です。',
    'ミスティア・ローレライを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'ミスティア・ローレライの価値観や見方を整理した文面です。',
    'ミスティア・ローレライの役割です。',
    '["in","night","music","food"]'::jsonb,
    jsonb_build_object('表示名', 'ミスティア・ローレライ', '肩書き', '夜雀の妖怪', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'wriggle',
    'リグル・ナイトバグ',
    '蠢く光の蟲',
    '種族',
    'independent',
    'human_village',
    'human_village',
    'リグル・ナイトバグに関する基本人物紹介です。',
    'リグル・ナイトバグを配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    'リグル・ナイトバグの価値観や見方を整理した文面です。',
    'リグル・ナイトバグの役割です。',
    '["in","night","summer","insects"]'::jsonb,
    jsonb_build_object('表示名', 'リグル・ナイトバグ', '肩書き', '蠢く光の蟲', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
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

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  (
    'gensokyo_main',
    'rumia',
    'cirno',
    'minor_chaos_overlap',
    'ルーミアとチルノのあいだにある関係を示す関係データです。',
    0.26,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'mystia',
    'keine',
    'night_village_overlap',
    'ミスティア・ローレライと上白沢 慧音のあいだにある関係を示す関係データです。',
    0.41,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'mystia',
    'wriggle',
    'night_creature_peer',
    'ミスティア・ローレライとリグル・ナイトバグのあいだにある関係を示す関係データです。',
    0.46,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'wriggle',
    'cirno',
    'seasonal_smallscale',
    'リグル・ナイトバグとチルノのあいだにある関係を示す関係データです。',
    0.28,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'rumia',
    'reimu',
    'minor_incident_target',
    'ルーミアと博麗 霊夢のあいだにある関係を示す関係データです。',
    0.35,
    '{}'::jsonb
  )
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values (
  'gensokyo_main',
  'lore_supporting_cast_night_life',
  'daily_life_texture',
  '幻想郷設定項目',
  '幻想郷の世界設定を整理した設定項目です。',
  jsonb_build_object('対象', '幻想郷', '分類', 'daily_life_texture', '説明', '日本語表示向けに整理した説明データです。'),
  '["supporting_cast","night","daily_life"]'::jsonb,
  73
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
    'claim_rumia_minor_night_threat',
    'gensokyo_main',
    'character',
    'rumia',
    'role',
    'ルーミアに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'ルーミア', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    63,
    '["rumia","eosd","night"]'::jsonb
  ),
  (
    'claim_mystia_night_vendor',
    'gensokyo_main',
    'character',
    'mystia',
    'role',
    'ミスティア・ローレライに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'ミスティア・ローレライ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    69,
    '["mystia","in","night"]'::jsonb
  ),
  (
    'claim_wriggle_small_collective_night',
    'gensokyo_main',
    'character',
    'wriggle',
    'role',
    'リグル・ナイトバグに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', 'リグル・ナイトバグ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    67,
    '["wriggle","in","summer"]'::jsonb
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

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  (
    'claim_ability_rumia',
    'gensokyo_main',
    'character',
    'rumia',
    'ability',
    'ルーミアに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'ルーミア', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    67,
    '["ability","rumia","eosd"]'::jsonb
  ),
  (
    'claim_ability_mystia',
    'gensokyo_main',
    'character',
    'mystia',
    'ability',
    'ミスティア・ローレライに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'ミスティア・ローレライ', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    71,
    '["ability","mystia","in"]'::jsonb
  ),
  (
    'claim_ability_wriggle',
    'gensokyo_main',
    'character',
    'wriggle',
    'ability',
    'リグル・ナイトバグに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'リグル・ナイトバグ', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    69,
    '["ability","wriggle","in"]'::jsonb
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_rumia',
    'gensokyo_main',
    'characters/rumia',
    'ルーミア',
    'character',
    'character',
    'rumia',
    'ルーミアに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_mystia',
    'gensokyo_main',
    'characters/mystia-lorelei',
    'ミスティア・ローレライ',
    'character',
    'character',
    'mystia',
    'ミスティア・ローレライに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_wriggle',
    'gensokyo_main',
    'characters/wriggle-nightbug',
    'リグル・ナイトバグ',
    'character',
    'character',
    'wriggle',
    'リグル・ナイトバグに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_rumia:section:overview',
    'wiki_character_rumia',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_rumia_minor_night_threat","claim_ability_rumia"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_mystia:section:overview',
    'wiki_character_mystia',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_mystia_night_vendor","claim_ability_mystia"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_wriggle:section:overview',
    'wiki_character_wriggle',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_wriggle_small_collective_night","claim_ability_wriggle"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_rumia_core',
    'gensokyo_main',
    'global',
    'rumia',
    null,
    null,
    'character_voice',
    'ルーミアの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'ルーミアの会話や振る舞いに関する文脈データです。'),
    0.80,
    now()
  ),
  (
    'chat_voice_mystia_core',
    'gensokyo_main',
    'global',
    'mystia',
    null,
    null,
    'character_voice',
    'ミスティア・ローレライの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'ミスティア・ローレライの会話や振る舞いに関する文脈データです。'),
    0.85,
    now()
  ),
  (
    'chat_voice_wriggle_core',
    'gensokyo_main',
    'global',
    'wriggle',
    null,
    null,
    'character_voice',
    'リグル・ナイトバグの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'リグル・ナイトバグの会話や振る舞いに関する文脈データです。'),
    0.83,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_regional_old_capital',
    'regional_culture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'regional_culture', '説明', '日本語表示向けに整理した説明データです。'),
    '["region","old_capital","oni"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_regional_former_hell',
    'regional_culture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'regional_culture', '説明', '日本語表示向けに整理した説明データです。'),
    '["region","former_hell","routes"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_regional_myouren_temple',
    'regional_culture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'regional_culture', '説明', '日本語表示向けに整理した説明データです。'),
    '["region","myouren_temple","daily_life"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_regional_night_village_edges',
    'regional_culture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'regional_culture', '説明', '日本語表示向けに整理した説明データです。'),
    '["region","night","village"]'::jsonb,
    77
  ),
  (
    'gensokyo_main',
    'lore_regional_shrine_fairy_life',
    'regional_culture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'regional_culture', '説明', '日本語表示向けに整理した説明データです。'),
    '["region","fairy","shrine"]'::jsonb,
    76
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
    'claim_regional_old_capital_culture',
    'gensokyo_main',
    'location',
    'old_capital',
    'setting',
    '旧都に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '旧都', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    78,
    '["old_capital","culture","oni"]'::jsonb
  ),
  (
    'claim_regional_former_hell_routes',
    'gensokyo_main',
    'location',
    'former_hell',
    'setting',
    '旧地獄に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '旧地獄', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_subterranean_animism',
    'official',
    77,
    '["former_hell","routes","culture"]'::jsonb
  ),
  (
    'claim_regional_myouren_daily_life',
    'gensokyo_main',
    'location',
    'myouren_temple',
    'setting',
    '命蓮寺に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '命蓮寺', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    79,
    '["myouren_temple","culture","daily_life"]'::jsonb
  ),
  (
    'claim_regional_village_night_life',
    'gensokyo_main',
    'location',
    'human_village',
    'setting',
    '人里に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '人里', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    75,
    '["human_village","night","culture"]'::jsonb
  ),
  (
    'claim_regional_shrine_fairy_life',
    'gensokyo_main',
    'location',
    'hakurei_shrine',
    'setting',
    '博麗神社に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '博麗神社', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_osp',
    'official',
    74,
    '["hakurei_shrine","fairy","culture"]'::jsonb
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_region_old_capital_culture',
    'gensokyo_main',
    'regions/old-capital-culture',
    '旧都',
    'glossary',
    'location',
    'old_capital',
    '旧都に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_region_myouren_daily_life',
    'gensokyo_main',
    'regions/myouren-daily-life',
    '命蓮寺',
    'glossary',
    'location',
    'myouren_temple',
    '命蓮寺に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_region_village_night_life',
    'gensokyo_main',
    'regions/village-night-life',
    '人里',
    'glossary',
    'location',
    'human_village',
    '人里に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_region_old_capital_culture:section:overview',
    'wiki_region_old_capital_culture',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_regional_old_capital_culture","lore_regional_old_capital"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_region_myouren_daily_life:section:overview',
    'wiki_region_myouren_daily_life',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_regional_myouren_daily_life","lore_regional_myouren_temple"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_region_village_night_life:section:overview',
    'wiki_region_village_night_life',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_regional_village_night_life","lore_regional_night_village_edges"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_old_capital_culture',
    'gensokyo_main',
    'global',
    null,
    'old_capital',
    null,
    'location_mood',
    '旧都に関する場面文脈データです。',
    jsonb_build_object('説明', '旧都に関する場面文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_location_myouren_daily_life',
    'gensokyo_main',
    'global',
    null,
    'myouren_temple',
    null,
    'location_mood',
    '命蓮寺に関する場面文脈データです。',
    jsonb_build_object('説明', '命蓮寺に関する場面文脈データです。'),
    0.85,
    now()
  ),
  (
    'chat_location_village_night_life',
    'gensokyo_main',
    'global',
    null,
    'human_village',
    null,
    'location_mood',
    '人里に関する場面文脈データです。',
    jsonb_build_object('説明', '人里に関する場面文脈データです。'),
    0.83,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_source_index (
  id, world_id, source_kind, source_code, title, short_label, notes, metadata
)
values
  (
    'src_le',
    'gensokyo_main',
    'official_book',
    'le',
    '公式資料 le',
    '公式資料 le',
    '公式資料 leに関する参照用ソース情報です。',
    '{}'::jsonb
  ),
  (
    'src_fds',
    'gensokyo_main',
    'official_book',
    'fds',
    '公式資料 fds',
    '公式資料 fds',
    '公式資料 fdsに関する参照用ソース情報です。',
    '{}'::jsonb
  )
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_code = excluded.source_code,
    title = excluded.title,
    short_label = excluded.short_label,
    notes = excluded.notes,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id, public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main',
    'toyohime',
    '綿月 豊姫',
    '山海の豊姫',
    '月人',
    'lunar_capital',
    'lunar_capital',
    'lunar_capital',
    '綿月 豊姫に関する基本人物紹介です。',
    '綿月 豊姫を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '綿月 豊姫の価値観や見方を整理した文面です。',
    '綿月 豊姫の役割です。',
    '["ssib","moon","nobility"]'::jsonb,
    jsonb_build_object('表示名', '綿月 豊姫', '肩書き', '山海の豊姫', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'yorihime',
    '綿月 依姫',
    '神霊に取り憑かれた月の姫',
    '月人',
    'lunar_capital',
    'lunar_capital',
    'lunar_capital',
    '綿月 依姫に関する基本人物紹介です。',
    '綿月 依姫を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '綿月 依姫の価値観や見方を整理した文面です。',
    '綿月 依姫の役割です。',
    '["ssib","moon","military"]'::jsonb,
    jsonb_build_object('表示名', '綿月 依姫', '肩書き', '神霊に取り憑かれた月の姫', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'miyoi',
    '奥野田 美宵',
    '酔いどれの看板娘',
    '種族',
    'independent',
    'human_village',
    'human_village',
    '奥野田 美宵に関する基本人物紹介です。',
    '奥野田 美宵を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '奥野田 美宵の価値観や見方を整理した文面です。',
    '奥野田 美宵の役割です。',
    '["le","village","tavern"]'::jsonb,
    jsonb_build_object('表示名', '奥野田 美宵', '肩書き', '酔いどれの看板娘', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
  ),
  (
    'gensokyo_main',
    'mizuchi',
    '宮出口 瑞霊',
    '祟りを秘めた怨霊',
    '種族',
    'independent',
    'human_village',
    'human_village',
    '宮出口 瑞霊に関する基本人物紹介です。',
    '宮出口 瑞霊を配置するときの補足メモです。',
    '人物ごとの口調設定です。',
    '宮出口 瑞霊の価値観や見方を整理した文面です。',
    '宮出口 瑞霊の役割です。',
    '["fds","vengeful_spirit","mystery"]'::jsonb,
    jsonb_build_object('表示名', '宮出口 瑞霊', '肩書き', '祟りを秘めた怨霊', '説明', '人物の基礎プロフィールを日本語で整理した内部データです。')
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

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  (
    'gensokyo_main',
    'toyohime',
    'yorihime',
    'lunar_sibling_rule',
    '綿月 豊姫と綿月 依姫のあいだにある関係を示す関係データです。',
    0.86,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'toyohime',
    'sagume',
    'lunar_high_command',
    '綿月 豊姫と稀神 サグメのあいだにある関係を示す関係データです。',
    0.49,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'yorihime',
    'eirin',
    'lunar_old_order',
    '綿月 依姫と八意 永琳のあいだにある関係を示す関係データです。',
    0.52,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'miyoi',
    'mystia',
    'night_hospitality_overlap',
    '奥野田 美宵とミスティア・ローレライのあいだにある関係を示す関係データです。',
    0.38,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'miyoi',
    'suika',
    'drinking_scene_overlap',
    '奥野田 美宵と伊吹 萃香のあいだにある関係を示す関係データです。',
    0.44,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'mizuchi',
    'satori',
    'mystery_investigation_axis',
    '宮出口 瑞霊と古明地 さとりのあいだにある関係を示す関係データです。',
    0.55,
    '{}'::jsonb
  ),
  (
    'gensokyo_main',
    'mizuchi',
    'reimu',
    'hidden_incident_target',
    '宮出口 瑞霊と博麗 霊夢のあいだにある関係を示す関係データです。',
    0.41,
    '{}'::jsonb
  )
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_lunar_nobility_texture',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
    '["moon","nobility","texture"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_village_afterhours_texture',
    'daily_life_texture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'daily_life_texture', '説明', '日本語表示向けに整理した説明データです。'),
    '["village","night","tavern"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_hidden_possession_texture',
    'incident_pattern',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["mystery","possession","late_era"]'::jsonb,
    79
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
    'claim_toyohime_lunar_noble',
    'gensokyo_main',
    'character',
    'toyohime',
    'role',
    '綿月 豊姫に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '綿月 豊姫', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ssib',
    'official',
    75,
    '["toyohime","moon","role"]'::jsonb
  ),
  (
    'claim_yorihime_lunar_martial_elite',
    'gensokyo_main',
    'character',
    'yorihime',
    'role',
    '綿月 依姫に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '綿月 依姫', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ssib',
    'official',
    77,
    '["yorihime","moon","role"]'::jsonb
  ),
  (
    'claim_miyoi_night_hospitality',
    'gensokyo_main',
    'character',
    'miyoi',
    'role',
    '奥野田 美宵に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '奥野田 美宵', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_le',
    'official',
    72,
    '["miyoi","night","village"]'::jsonb
  ),
  (
    'claim_mizuchi_hidden_possession',
    'gensokyo_main',
    'character',
    'mizuchi',
    'role',
    '宮出口 瑞霊に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '宮出口 瑞霊', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_fds',
    'official',
    74,
    '["mizuchi","mystery","possession"]'::jsonb
  ),
  (
    'claim_lunar_nobility_culture',
    'gensokyo_main',
    'world',
    'gensokyo_main',
    'world_rule',
    '幻想郷に関する正史設定です。分類は世界ルールです。',
    jsonb_build_object('対象', '幻想郷', '分類', '世界ルール', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ciLR',
    'official',
    80,
    '["moon","culture","rule"]'::jsonb
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

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  (
    'claim_ability_toyohime',
    'gensokyo_main',
    'character',
    'toyohime',
    'ability',
    '綿月 豊姫に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '綿月 豊姫', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ssib',
    'official',
    73,
    '["ability","toyohime","moon"]'::jsonb
  ),
  (
    'claim_ability_yorihime',
    'gensokyo_main',
    'character',
    'yorihime',
    'ability',
    '綿月 依姫に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '綿月 依姫', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ssib',
    'official',
    78,
    '["ability","yorihime","moon"]'::jsonb
  ),
  (
    'claim_ability_miyoi',
    'gensokyo_main',
    'character',
    'miyoi',
    'ability',
    '奥野田 美宵に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '奥野田 美宵', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_le',
    'official',
    69,
    '["ability","miyoi","nightlife"]'::jsonb
  ),
  (
    'claim_ability_mizuchi',
    'gensokyo_main',
    'character',
    'mizuchi',
    'ability',
    '宮出口 瑞霊に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '宮出口 瑞霊', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_fds',
    'official',
    75,
    '["ability","mizuchi","mystery"]'::jsonb
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_toyohime',
    'gensokyo_main',
    'characters/watatsuki-no-toyohime',
    '綿月 豊姫',
    'character',
    'character',
    'toyohime',
    '綿月 豊姫に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_yorihime',
    'gensokyo_main',
    'characters/watatsuki-no-yorihime',
    '綿月 依姫',
    'character',
    'character',
    'yorihime',
    '綿月 依姫に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_miyoi',
    'gensokyo_main',
    'characters/okunoda-miyoi',
    '奥野田 美宵',
    'character',
    'character',
    'miyoi',
    '奥野田 美宵に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_mizuchi',
    'gensokyo_main',
    'characters/mizuchi-miyadeguchi',
    '宮出口 瑞霊',
    'character',
    'character',
    'mizuchi',
    '宮出口 瑞霊に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_lunar_nobility',
    'gensokyo_main',
    'terms/lunar-nobility',
    '月の貴族階層',
    'glossary',
    'term',
    'lunar_nobility',
    '月の貴族階層に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_toyohime:section:overview',
    'wiki_character_toyohime',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_toyohime_lunar_noble","claim_ability_toyohime"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_yorihime:section:overview',
    'wiki_character_yorihime',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_yorihime_lunar_martial_elite","claim_ability_yorihime"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_miyoi:section:overview',
    'wiki_character_miyoi',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_miyoi_night_hospitality","claim_ability_miyoi"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_mizuchi:section:overview',
    'wiki_character_mizuchi',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_mizuchi_hidden_possession","claim_ability_mizuchi"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_lunar_nobility:section:definition',
    'wiki_term_lunar_nobility',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_lunar_nobility_culture","lore_lunar_nobility_texture"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_toyohime_core',
    'gensokyo_main',
    'global',
    'toyohime',
    null,
    null,
    'character_voice',
    '綿月 豊姫の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '綿月 豊姫の会話や振る舞いに関する文脈データです。'),
    0.87,
    now()
  ),
  (
    'chat_voice_yorihime_core',
    'gensokyo_main',
    'global',
    'yorihime',
    null,
    null,
    'character_voice',
    '綿月 依姫の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '綿月 依姫の会話や振る舞いに関する文脈データです。'),
    0.88,
    now()
  ),
  (
    'chat_voice_miyoi_core',
    'gensokyo_main',
    'global',
    'miyoi',
    null,
    null,
    'character_voice',
    '奥野田 美宵の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '奥野田 美宵の会話や振る舞いに関する文脈データです。'),
    0.85,
    now()
  ),
  (
    'chat_voice_mizuchi_core',
    'gensokyo_main',
    'global',
    'mizuchi',
    null,
    null,
    'character_voice',
    '宮出口 瑞霊の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '宮出口 瑞霊の会話や振る舞いに関する文脈データです。'),
    0.86,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_book_lotus_eaters',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","le","nightlife"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_book_foul_detective_satori',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","fds","mystery"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_book_lunar_expedition',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","moon","politics"]'::jsonb,
    81
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
    'claim_book_lotus_eaters',
    'gensokyo_main',
    'printwork',
    'lotus_eaters',
    'summary',
    '酔蝶華記録に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '酔蝶華記録', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_le',
    'official',
    79,
    '["printwork","le","summary"]'::jsonb
  ),
  (
    'claim_book_foul_detective_satori',
    'gensokyo_main',
    'printwork',
    'foul_detective_satori',
    'summary',
    '智霊奇伝記録に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '智霊奇伝記録', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_fds',
    'official',
    80,
    '["printwork","fds","summary"]'::jsonb
  ),
  (
    'claim_book_lunar_expedition',
    'gensokyo_main',
    'printwork',
    'lunar_expedition_cluster',
    'summary',
    '月都遠征記録に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '月都遠征記録', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ssib',
    'official',
    81,
    '["printwork","moon","summary"]'::jsonb
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

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_term_faith_economy',
    'term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'term', '説明', '日本語表示向けに整理した説明データです。'),
    '["term","faith","economy"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_term_perfect_possession',
    'term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'term', '説明', '日本語表示向けに整理した説明データです。'),
    '["term","possession","incident"]'::jsonb,
    79
  ),
  (
    'gensokyo_main',
    'lore_term_outside_world_leakage',
    'term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'term', '説明', '日本語表示向けに整理した説明データです。'),
    '["term","outside_world","leakage"]'::jsonb,
    81
  ),
  (
    'gensokyo_main',
    'lore_term_animal_spirits',
    'term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'term', '説明', '日本語表示向けに整理した説明データです。'),
    '["term","animal_spirits","beast_realm"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_term_market_cards',
    'term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'term', '説明', '日本語表示向けに整理した説明データです。'),
    '["term","ability_cards","market"]'::jsonb,
    80
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
    'claim_term_faith_economy',
    'gensokyo_main',
    'term',
    'faith_economy',
    'definition',
    '信仰経済に関する正史設定です。分類は定義です。',
    jsonb_build_object('対象', '信仰経済', '分類', '定義', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    81,
    '["term","faith","economy"]'::jsonb
  ),
  (
    'claim_term_perfect_possession',
    'gensokyo_main',
    'term',
    'perfect_possession',
    'definition',
    '完全憑依に関する正史設定です。分類は定義です。',
    jsonb_build_object('対象', '完全憑依', '分類', '定義', '説明', '日本語表示向けに整理した説明データです。'),
    'src_aocf',
    'official',
    79,
    '["term","possession","aocf"]'::jsonb
  ),
  (
    'claim_term_outside_world_leakage',
    'gensokyo_main',
    'term',
    'outside_world_leakage',
    'definition',
    '外界流入に関する正史設定です。分類は定義です。',
    jsonb_build_object('対象', '外界流入', '分類', '定義', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ulil',
    'official',
    82,
    '["term","outside_world","leakage"]'::jsonb
  ),
  (
    'claim_term_animal_spirits',
    'gensokyo_main',
    'term',
    'animal_spirits',
    'definition',
    '動物霊に関する正史設定です。分類は定義です。',
    jsonb_build_object('対象', '動物霊', '分類', '定義', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    78,
    '["term","animal_spirits","politics"]'::jsonb
  ),
  (
    'claim_term_market_cards',
    'gensokyo_main',
    'term',
    'ability_cards',
    'definition',
    '能力カードに関する正史設定です。分類は定義です。',
    jsonb_build_object('対象', '能力カード', '分類', '定義', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    80,
    '["term","ability_cards","market"]'::jsonb
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_term_faith_economy',
    'gensokyo_main',
    'terms/faith-economy',
    '信仰経済',
    'glossary',
    'term',
    'faith_economy',
    '信仰経済に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_perfect_possession',
    'gensokyo_main',
    'terms/perfect-possession',
    '完全憑依',
    'glossary',
    'term',
    'perfect_possession',
    '完全憑依に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_outside_world_leakage',
    'gensokyo_main',
    'terms/outside-world-leakage',
    '外界流入',
    'glossary',
    'term',
    'outside_world_leakage',
    '外界流入に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_animal_spirits',
    'gensokyo_main',
    'terms/animal-spirits',
    '動物霊',
    'glossary',
    'term',
    'animal_spirits',
    '動物霊に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_ability_cards',
    'gensokyo_main',
    'terms/ability-cards',
    '能力カード',
    'glossary',
    'term',
    'ability_cards',
    '能力カードに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_term_faith_economy:section:definition',
    'wiki_term_faith_economy',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_faith_economy","lore_term_faith_economy"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_perfect_possession:section:definition',
    'wiki_term_perfect_possession',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_perfect_possession","lore_term_perfect_possession"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_outside_world_leakage:section:definition',
    'wiki_term_outside_world_leakage',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_outside_world_leakage","lore_term_outside_world_leakage"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_animal_spirits:section:definition',
    'wiki_term_animal_spirits',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_animal_spirits","lore_term_animal_spirits"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_ability_cards:section:definition',
    'wiki_term_ability_cards',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_market_cards","lore_term_market_cards"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_story_events (
  id, world_id, event_code, title, theme, canon_level, status, start_at, end_at, current_phase_id, current_phase_order, lead_location_id, organizer_character_id, synopsis, narrative_hook, payload, metadata
)
values
  (
    'story_incident_scarlet_mist_archive',
    'gensokyo_main',
    'incident_scarlet_mist_archive',
    '紅霧異変記録',
    '紅霧異変記録に関する主題をまとめた文面です。',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'scarlet_devil_mansion',
    'reimu',
    '紅霧異変記録の概要を日本語で整理した物語説明です。',
    '紅霧異変記録に参加するときの導入文です。',
    jsonb_build_object('概要', '紅霧異変記録の概要を日本語で整理した物語説明です。'),
    jsonb_build_object('状態', '日本語化済み')
  ),
  (
    'story_incident_faith_shift_archive',
    'gensokyo_main',
    'incident_faith_shift_archive',
    '信仰勢力変動記録',
    '信仰勢力変動記録に関する主題をまとめた文面です。',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'moriya_shrine',
    'reimu',
    '信仰勢力変動記録の概要を日本語で整理した物語説明です。',
    '信仰勢力変動記録に参加するときの導入文です。',
    jsonb_build_object('概要', '信仰勢力変動記録の概要を日本語で整理した物語説明です。'),
    jsonb_build_object('状態', '日本語化済み')
  ),
  (
    'story_incident_perfect_possession_archive',
    'gensokyo_main',
    'incident_perfect_possession_archive',
    '完全憑依騒動記録',
    '完全憑依騒動記録に関する主題をまとめた文面です。',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'human_village',
    'reimu',
    '完全憑依騒動記録の概要を日本語で整理した物語説明です。',
    '完全憑依騒動記録に参加するときの導入文です。',
    jsonb_build_object('概要', '完全憑依騒動記録の概要を日本語で整理した物語説明です。'),
    jsonb_build_object('状態', '日本語化済み')
  ),
  (
    'story_incident_market_cards_archive',
    'gensokyo_main',
    'incident_market_cards_archive',
    '能力カード騒動記録',
    '能力カード騒動記録に関する主題をまとめた文面です。',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'rainbow_dragon_cave',
    'marisa',
    '能力カード騒動記録の概要を日本語で整理した物語説明です。',
    '能力カード騒動記録に参加するときの導入文です。',
    jsonb_build_object('概要', '能力カード騒動記録の概要を日本語で整理した物語説明です。'),
    jsonb_build_object('状態', '日本語化済み')
  )
on conflict (id) do update
set event_code = excluded.event_code,
    title = excluded.title,
    theme = excluded.theme,
    canon_level = excluded.canon_level,
    status = excluded.status,
    start_at = excluded.start_at,
    end_at = excluded.end_at,
    current_phase_id = excluded.current_phase_id,
    current_phase_order = excluded.current_phase_order,
    lead_location_id = excluded.lead_location_id,
    organizer_character_id = excluded.organizer_character_id,
    synopsis = excluded.synopsis,
    narrative_hook = excluded.narrative_hook,
    payload = excluded.payload,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_story_history (
  id, world_id, event_id, phase_id, history_kind, fact_summary, location_id, actor_ids, payload, committed_at
)
values
  (
    'history_incident_scarlet_mist_resolution',
    'gensokyo_main',
    'story_incident_scarlet_mist_archive',
    null,
    'aftereffect',
    '紅霧異変記録に関する履歴記録です。',
    'scarlet_devil_mansion',
    '["reimu","marisa","remilia","sakuya"]'::jsonb,
    jsonb_build_object('説明', '紅霧異変記録に関する履歴記録です。'),
    now()
  ),
  (
    'history_incident_mountain_faith_shift',
    'gensokyo_main',
    'story_incident_faith_shift_archive',
    null,
    'aftereffect',
    '信仰勢力変動記録に関する履歴記録です。',
    'moriya_shrine',
    '["reimu","sanae","kanako","suwako","nitori"]'::jsonb,
    jsonb_build_object('説明', '信仰勢力変動記録に関する履歴記録です。'),
    now()
  ),
  (
    'history_incident_perfect_possession',
    'gensokyo_main',
    'story_incident_perfect_possession_archive',
    null,
    'aftereffect',
    '完全憑依騒動記録に関する履歴記録です。',
    'human_village',
    '["reimu","marisa","yukari","sumireko","shion","joon"]'::jsonb,
    jsonb_build_object('説明', '完全憑依騒動記録に関する履歴記録です。'),
    now()
  ),
  (
    'history_incident_market_cards_aftereffect',
    'gensokyo_main',
    'story_incident_market_cards_archive',
    null,
    'aftereffect',
    '能力カード騒動記録に関する履歴記録です。',
    'rainbow_dragon_cave',
    '["marisa","takane","chimata","tsukasa","mike"]'::jsonb,
    jsonb_build_object('説明', '能力カード騒動記録に関する履歴記録です。'),
    now()
  )
on conflict (id) do update
set history_kind = excluded.history_kind,
    fact_summary = excluded.fact_summary,
    location_id = excluded.location_id,
    actor_ids = excluded.actor_ids,
    payload = excluded.payload,
    committed_at = excluded.committed_at;

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_keine_scarlet_mist',
    'gensokyo_main',
    'keine',
    'incident',
    'scarlet_mist',
    'editorial',
    '対象項目に関する注記',
    '対象項目を歴史記録として扱うための補足注記です。',
    '対象項目に関する記録上の見方や整理方針をまとめた歴史家注記です。',
    '["history_incident_scarlet_mist_resolution","claim_sdm_household"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_keine_faith_shift',
    'gensokyo_main',
    'keine',
    'incident',
    'faith_shift',
    'editorial',
    '対象項目に関する注記',
    '対象項目を歴史記録として扱うための補足注記です。',
    '対象項目に関する記録上の見方や整理方針をまとめた歴史家注記です。',
    '["history_incident_mountain_faith_shift","claim_moriya_proactive","claim_term_faith_economy"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_keine_perfect_possession',
    'gensokyo_main',
    'keine',
    'incident',
    'perfect_possession',
    'editorial',
    '完全憑依に関する注記',
    '完全憑依を歴史記録として扱うための補足注記です。',
    '完全憑依に関する記録上の見方や整理方針をまとめた歴史家注記です。',
    '["history_incident_perfect_possession","claim_term_perfect_possession"]'::jsonb,
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

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_incident_beat_scarlet_mist',
    'gensokyo_main',
    'global',
    null,
    null,
    null,
    'incident_beat',
    '幻想郷の会話文脈を整理したデータです。',
    jsonb_build_object('説明', '幻想郷の会話文脈を整理したデータです。'),
    0.84,
    now()
  ),
  (
    'chat_incident_beat_faith_shift',
    'gensokyo_main',
    'global',
    null,
    null,
    null,
    'incident_beat',
    '幻想郷の会話文脈を整理したデータです。',
    jsonb_build_object('説明', '幻想郷の会話文脈を整理したデータです。'),
    0.83,
    now()
  ),
  (
    'chat_incident_beat_perfect_possession',
    'gensokyo_main',
    'global',
    null,
    null,
    null,
    'incident_beat',
    '幻想郷の会話文脈を整理したデータです。',
    jsonb_build_object('説明', '幻想郷の会話文脈を整理したデータです。'),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  (
    'claim_ability_meiling',
    'gensokyo_main',
    'character',
    'meiling',
    'ability',
    '紅 美鈴に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '紅 美鈴', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    73,
    '["ability","meiling","sdm"]'::jsonb
  ),
  (
    'claim_ability_momiji',
    'gensokyo_main',
    'character',
    'momiji',
    'ability',
    '犬走 椛に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '犬走 椛', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    71,
    '["ability","momiji","mountain"]'::jsonb
  ),
  (
    'claim_ability_hina',
    'gensokyo_main',
    'character',
    'hina',
    'ability',
    '鍵山 雛に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '鍵山 雛', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    74,
    '["ability","hina","misfortune"]'::jsonb
  ),
  (
    'claim_ability_minoriko',
    'gensokyo_main',
    'character',
    'minoriko',
    'ability',
    '秋 穣子に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '秋 穣子', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    70,
    '["ability","minoriko","harvest"]'::jsonb
  ),
  (
    'claim_ability_shizuha',
    'gensokyo_main',
    'character',
    'shizuha',
    'ability',
    '秋 静葉に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '秋 静葉', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    69,
    '["ability","shizuha","autumn"]'::jsonb
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_momiji',
    'gensokyo_main',
    'characters/momiji-inubashiri',
    '犬走 椛',
    'character',
    'character',
    'momiji',
    '犬走 椛に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_hina',
    'gensokyo_main',
    'characters/hina-kagiyama',
    '鍵山 雛',
    'character',
    'character',
    'hina',
    '鍵山 雛に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_minoriko',
    'gensokyo_main',
    'characters/minoriko-aki',
    '秋 穣子',
    'character',
    'character',
    'minoriko',
    '秋 穣子に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_shizuha',
    'gensokyo_main',
    'characters/shizuha-aki',
    '秋 静葉',
    'character',
    'character',
    'shizuha',
    '秋 静葉に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_region_scarlet_gate',
    'gensokyo_main',
    'regions/scarlet-gate',
    '紅魔館の門',
    'glossary',
    'location',
    'scarlet_gate',
    '紅魔館の門に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_momiji:section:overview',
    'wiki_character_momiji',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_momiji_mountain_guard","claim_ability_momiji"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_hina:section:overview',
    'wiki_character_hina',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_hina_mountain_warning","claim_ability_hina"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_minoriko:section:overview',
    'wiki_character_minoriko',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ability_minoriko"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_shizuha:section:overview',
    'wiki_character_shizuha',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ability_shizuha"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_region_scarlet_gate:section:overview',
    'wiki_region_scarlet_gate',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_meiling_gatekeeper","claim_ability_meiling"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_meiling_core',
    'gensokyo_main',
    'global',
    'meiling',
    null,
    null,
    'character_voice',
    '紅 美鈴の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '紅 美鈴の会話や振る舞いに関する文脈データです。'),
    0.86,
    now()
  ),
  (
    'chat_voice_momiji_core',
    'gensokyo_main',
    'global',
    'momiji',
    null,
    null,
    'character_voice',
    '犬走 椛の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '犬走 椛の会話や振る舞いに関する文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_voice_hina_core',
    'gensokyo_main',
    'global',
    'hina',
    null,
    null,
    'character_voice',
    '鍵山 雛の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '鍵山 雛の会話や振る舞いに関する文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_voice_minoriko_core',
    'gensokyo_main',
    'global',
    'minoriko',
    null,
    null,
    'character_voice',
    '秋 穣子の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '秋 穣子の会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  ),
  (
    'chat_voice_shizuha_core',
    'gensokyo_main',
    'global',
    'shizuha',
    null,
    null,
    'character_voice',
    '秋 静葉の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '秋 静葉の会話や振る舞いに関する文脈データです。'),
    0.81,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_regional_mountain_approach_hazards',
    'regional_culture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'regional_culture', '説明', '日本語表示向けに整理した説明データです。'),
    '["region","mountain","hazard"]'::jsonb,
    77
  ),
  (
    'gensokyo_main',
    'lore_regional_scarlet_gate_threshold',
    'regional_culture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'regional_culture', '説明', '日本語表示向けに整理した説明データです。'),
    '["region","sdm","threshold"]'::jsonb,
    78
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
    'claim_regional_mountain_approach_hazards',
    'gensokyo_main',
    'location',
    'youkai_mountain_foot',
    'setting',
    '妖怪の山の麓に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '妖怪の山の麓', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_mofa',
    'official',
    77,
    '["mountain","approach","culture"]'::jsonb
  ),
  (
    'claim_regional_scarlet_gate_threshold',
    'gensokyo_main',
    'location',
    'scarlet_gate',
    'setting',
    '紅魔館の門に関する正史設定です。分類は設定です。',
    jsonb_build_object('対象', '紅魔館の門', '分類', '設定', '説明', '日本語表示向けに整理した説明データです。'),
    'src_eosd',
    'official',
    78,
    '["scarlet_gate","threshold","culture"]'::jsonb
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

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_book_mountain_watch_pattern',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","mountain","watch"]'::jsonb,
    77
  ),
  (
    'gensokyo_main',
    'lore_book_sdm_threshold_pattern',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","sdm","threshold"]'::jsonb,
    76
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
    'claim_book_mountain_watch_pattern',
    'gensokyo_main',
    'printwork',
    'mountain_watch_cluster',
    'summary',
    '妖怪の山の見張り記録に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '妖怪の山の見張り記録', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_boaFW',
    'official',
    76,
    '["printwork","mountain","summary"]'::jsonb
  ),
  (
    'claim_book_sdm_threshold_pattern',
    'gensokyo_main',
    'printwork',
    'sdm_threshold_cluster',
    'summary',
    '紅魔館門前記録に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '紅魔館門前記録', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pmss',
    'official',
    75,
    '["printwork","sdm","summary"]'::jsonb
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

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  (
    'claim_ability_lunasa',
    'gensokyo_main',
    'character',
    'lunasa',
    'ability',
    'ルナサ・プリズムリバーに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'ルナサ・プリズムリバー', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    71,
    '["ability","lunasa","music"]'::jsonb
  ),
  (
    'claim_ability_merlin',
    'gensokyo_main',
    'character',
    'merlin',
    'ability',
    'メルラン・プリズムリバーに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'メルラン・プリズムリバー', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    71,
    '["ability","merlin","music"]'::jsonb
  ),
  (
    'claim_ability_lyrica',
    'gensokyo_main',
    'character',
    'lyrica',
    'ability',
    'リリカ・プリズムリバーに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'リリカ・プリズムリバー', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    70,
    '["ability","lyrica","music"]'::jsonb
  ),
  (
    'claim_ability_hatate',
    'gensokyo_main',
    'character',
    'hatate',
    'ability',
    '姫海棠 はたてに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '姫海棠 はたて', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ds',
    'official',
    72,
    '["ability","hatate","media"]'::jsonb
  ),
  (
    'claim_ability_lily_white',
    'gensokyo_main',
    'character',
    'lily_white',
    'ability',
    'リリーホワイトに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'リリーホワイト', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    66,
    '["ability","lily_white","season"]'::jsonb
  ),
  (
    'claim_ability_letty',
    'gensokyo_main',
    'character',
    'letty',
    'ability',
    'レティ・ホワイトロックに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'レティ・ホワイトロック', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    68,
    '["ability","letty","winter"]'::jsonb
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_lunasa',
    'gensokyo_main',
    'characters/lunasa-prismriver',
    'ルナサ・プリズムリバー',
    'character',
    'character',
    'lunasa',
    'ルナサ・プリズムリバーに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_merlin',
    'gensokyo_main',
    'characters/merlin-prismriver',
    'メルラン・プリズムリバー',
    'character',
    'character',
    'merlin',
    'メルラン・プリズムリバーに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_lyrica',
    'gensokyo_main',
    'characters/lyrica-prismriver',
    'リリカ・プリズムリバー',
    'character',
    'character',
    'lyrica',
    'リリカ・プリズムリバーに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_hatate',
    'gensokyo_main',
    'characters/hatate-himekaidou',
    '姫海棠 はたて',
    'character',
    'character',
    'hatate',
    '姫海棠 はたてに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_letty',
    'gensokyo_main',
    'characters/letty-whiterock',
    'レティ・ホワイトロック',
    'character',
    'character',
    'letty',
    'レティ・ホワイトロックに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_lily_white',
    'gensokyo_main',
    'characters/lily-white',
    'リリーホワイト',
    'character',
    'character',
    'lily_white',
    'リリーホワイトに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_lunasa:section:overview',
    'wiki_character_lunasa',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_prismriver_ensemble","claim_ability_lunasa"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_merlin:section:overview',
    'wiki_character_merlin',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_prismriver_ensemble","claim_ability_merlin"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_lyrica:section:overview',
    'wiki_character_lyrica',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_prismriver_ensemble","claim_ability_lyrica"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_hatate:section:overview',
    'wiki_character_hatate',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_hatate_trend_observer","claim_ability_hatate"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_letty:section:overview',
    'wiki_character_letty',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ability_letty"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_lily_white:section:overview',
    'wiki_character_lily_white',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ability_lily_white"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_lunasa_core',
    'gensokyo_main',
    'global',
    'lunasa',
    null,
    null,
    'character_voice',
    'ルナサ・プリズムリバーの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'ルナサ・プリズムリバーの会話や振る舞いに関する文脈データです。'),
    0.83,
    now()
  ),
  (
    'chat_voice_merlin_core',
    'gensokyo_main',
    'global',
    'merlin',
    null,
    null,
    'character_voice',
    'メルラン・プリズムリバーの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'メルラン・プリズムリバーの会話や振る舞いに関する文脈データです。'),
    0.83,
    now()
  ),
  (
    'chat_voice_lyrica_core',
    'gensokyo_main',
    'global',
    'lyrica',
    null,
    null,
    'character_voice',
    'リリカ・プリズムリバーの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'リリカ・プリズムリバーの会話や振る舞いに関する文脈データです。'),
    0.83,
    now()
  ),
  (
    'chat_voice_hatate_core',
    'gensokyo_main',
    'global',
    'hatate',
    null,
    null,
    'character_voice',
    '姫海棠 はたての会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '姫海棠 はたての会話や振る舞いに関する文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_voice_letty_core',
    'gensokyo_main',
    'global',
    'letty',
    null,
    null,
    'character_voice',
    'レティ・ホワイトロックの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'レティ・ホワイトロックの会話や振る舞いに関する文脈データです。'),
    0.81,
    now()
  ),
  (
    'chat_voice_lily_white_core',
    'gensokyo_main',
    'global',
    'lily_white',
    null,
    null,
    'character_voice',
    'リリーホワイトの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'リリーホワイトの会話や振る舞いに関する文脈データです。'),
    0.80,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_regional_public_performance',
    'regional_culture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'regional_culture', '説明', '日本語表示向けに整理した説明データです。'),
    '["performance","festival","culture"]'::jsonb,
    77
  ),
  (
    'gensokyo_main',
    'lore_regional_tengu_media',
    'regional_culture',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'regional_culture', '説明', '日本語表示向けに整理した説明データです。'),
    '["media","tengu","culture"]'::jsonb,
    79
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
    'claim_regional_public_performance',
    'gensokyo_main',
    'world',
    'gensokyo_main',
    'world_rule',
    '幻想郷に関する正史設定です。分類は世界ルールです。',
    jsonb_build_object('対象', '幻想郷', '分類', '世界ルール', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    76,
    '["performance","culture","world_rule"]'::jsonb
  ),
  (
    'claim_regional_tengu_media',
    'gensokyo_main',
    'faction',
    'tengu',
    'glossary',
    '天狗に関する正史設定です。分類は用語です。',
    jsonb_build_object('対象', '天狗', '分類', '用語', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ds',
    'official',
    78,
    '["media","tengu","glossary"]'::jsonb
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

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_book_public_performance_pattern',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","performance","public_mood"]'::jsonb,
    76
  ),
  (
    'gensokyo_main',
    'lore_book_split_media_pattern',
    'printwork_pattern',
    '幻想郷設定項目',
    '書籍や媒体に見られる傾向を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'printwork_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["printwork","media","tengu"]'::jsonb,
    78
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
    'claim_book_public_performance_pattern',
    'gensokyo_main',
    'printwork',
    'public_performance_cluster',
    'summary',
    '公演と演奏の記録に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '公演と演奏の記録', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_pcb',
    'official',
    75,
    '["printwork","performance","summary"]'::jsonb
  ),
  (
    'claim_book_split_media_pattern',
    'gensokyo_main',
    'printwork',
    'split_media_cluster',
    'summary',
    '報道分化の記録に関する正史設定です。分類は要約です。',
    jsonb_build_object('対象', '報道分化の記録', '分類', '要約', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ds',
    'official',
    77,
    '["printwork","media","summary"]'::jsonb
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
    '人里に関する場面文脈データです。',
    jsonb_build_object('説明', '人里に関する場面文脈データです。'),
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
    '博麗神社に関する場面文脈データです。',
    jsonb_build_object('説明', '博麗神社に関する場面文脈データです。'),
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
    '霧の湖に関する場面文脈データです。',
    jsonb_build_object('説明', '霧の湖に関する場面文脈データです。'),
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
    '人里に関する場面文脈データです。',
    jsonb_build_object('説明', '人里に関する場面文脈データです。'),
    0.85,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_minor_incident_fairy_pranks',
    'incident_pattern',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","fairy","minor"]'::jsonb,
    73
  ),
  (
    'gensokyo_main',
    'lore_minor_incident_night_detours',
    'incident_pattern',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","night","minor"]'::jsonb,
    74
  ),
  (
    'gensokyo_main',
    'lore_minor_incident_text_circulation',
    'incident_pattern',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'incident_pattern', '説明', '日本語表示向けに整理した説明データです。'),
    '["incident","books","knowledge"]'::jsonb,
    75
  )
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_story_events (
  id, world_id, event_code, title, theme, canon_level, status, start_at, end_at, current_phase_id, current_phase_order, lead_location_id, organizer_character_id, synopsis, narrative_hook, payload, metadata
)
values
  (
    'story_minor_fairy_pranks_archive',
    'gensokyo_main',
    'minor_fairy_pranks_archive',
    '妖精いたずら記録',
    '妖精いたずら記録に関する主題をまとめた文面です。',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'hakurei_shrine',
    'cirno',
    '妖精いたずら記録の概要を日本語で整理した物語説明です。',
    '妖精いたずら記録に参加するときの導入文です。',
    jsonb_build_object('概要', '妖精いたずら記録の概要を日本語で整理した物語説明です。'),
    jsonb_build_object('状態', '日本語化済み')
  ),
  (
    'story_minor_night_detours_archive',
    'gensokyo_main',
    'minor_night_detours_archive',
    '夜道寄り道記録',
    '夜道寄り道記録に関する主題をまとめた文面です。',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'human_village',
    'mystia',
    '夜道寄り道記録の概要を日本語で整理した物語説明です。',
    '夜道寄り道記録に参加するときの導入文です。',
    jsonb_build_object('概要', '夜道寄り道記録の概要を日本語で整理した物語説明です。'),
    jsonb_build_object('状態', '日本語化済み')
  ),
  (
    'story_minor_text_circulation_archive',
    'gensokyo_main',
    'minor_text_circulation_archive',
    '書物と記事の流通記録',
    '書物と記事の流通記録に関する主題をまとめた文面です。',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'suzunaan',
    'akyuu',
    '書物と記事の流通記録の概要を日本語で整理した物語説明です。',
    '書物と記事の流通記録に参加するときの導入文です。',
    jsonb_build_object('概要', '書物と記事の流通記録の概要を日本語で整理した物語説明です。'),
    jsonb_build_object('状態', '日本語化済み')
  )
on conflict (id) do update
set event_code = excluded.event_code,
    title = excluded.title,
    theme = excluded.theme,
    canon_level = excluded.canon_level,
    status = excluded.status,
    start_at = excluded.start_at,
    end_at = excluded.end_at,
    current_phase_id = excluded.current_phase_id,
    current_phase_order = excluded.current_phase_order,
    lead_location_id = excluded.lead_location_id,
    organizer_character_id = excluded.organizer_character_id,
    synopsis = excluded.synopsis,
    narrative_hook = excluded.narrative_hook,
    payload = excluded.payload,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_story_history (
  id, world_id, event_id, phase_id, history_kind, fact_summary, location_id, actor_ids, payload, committed_at
)
values
  (
    'history_minor_fairy_pranks',
    'gensokyo_main',
    'story_minor_fairy_pranks_archive',
    null,
    'texture',
    '妖精いたずら記録に関する履歴記録です。',
    'hakurei_shrine',
    '["sunny_milk","luna_child","star_sapphire","cirno"]'::jsonb,
    jsonb_build_object('説明', '妖精いたずら記録に関する履歴記録です。'),
    now()
  ),
  (
    'history_minor_night_detours',
    'gensokyo_main',
    'story_minor_night_detours_archive',
    null,
    'texture',
    '夜道寄り道記録に関する履歴記録です。',
    'human_village',
    '["mystia","rumia","tewi","miyoi","wriggle"]'::jsonb,
    jsonb_build_object('説明', '夜道寄り道記録に関する履歴記録です。'),
    now()
  ),
  (
    'history_minor_text_circulation',
    'gensokyo_main',
    'story_minor_text_circulation_archive',
    null,
    'texture',
    '書物と記事の流通記録に関する履歴記録です。',
    'suzunaan',
    '["kosuzu","akyuu","rinnosuke","aya","hatate"]'::jsonb,
    jsonb_build_object('説明', '書物と記事の流通記録に関する履歴記録です。'),
    now()
  )
on conflict (id) do update
set history_kind = excluded.history_kind,
    fact_summary = excluded.fact_summary,
    location_id = excluded.location_id,
    actor_ids = excluded.actor_ids,
    payload = excluded.payload,
    committed_at = excluded.committed_at;

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_keine_minor_pranks',
    'gensokyo_main',
    'keine',
    'incident',
    'minor_fairy_pranks',
    'editorial',
    '対象項目に関する注記',
    '対象項目を歴史記録として扱うための補足注記です。',
    '対象項目に関する記録上の見方や整理方針をまとめた歴史家注記です。',
    '["history_minor_fairy_pranks","lore_minor_incident_fairy_pranks"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_akyuu_text_circulation',
    'gensokyo_main',
    'akyuu',
    'incident',
    'minor_text_circulation',
    'editorial',
    '対象項目に関する注記',
    '対象項目を歴史記録として扱うための補足注記です。',
    '対象項目に関する記録上の見方や整理方針をまとめた歴史家注記です。',
    '["history_minor_text_circulation","lore_minor_incident_text_circulation"]'::jsonb,
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_term_minor_incidents',
    'gensokyo_main',
    'terms/minor-incidents',
    '小規模事件',
    'glossary',
    'term',
    'minor_incidents',
    '小規模事件に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_night_detours',
    'gensokyo_main',
    'terms/night-detours',
    '夜道の寄り道',
    'glossary',
    'term',
    'night_detours',
    '夜道の寄り道に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_text_circulation',
    'gensokyo_main',
    'terms/text-circulation',
    '文字と記録の流通',
    'glossary',
    'term',
    'text_circulation',
    '文字と記録の流通に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_term_minor_incidents:section:definition',
    'wiki_term_minor_incidents',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["lore_minor_incident_fairy_pranks","history_minor_fairy_pranks"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_night_detours:section:definition',
    'wiki_term_night_detours',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["lore_minor_incident_night_detours","history_minor_night_detours"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_text_circulation:section:definition',
    'wiki_term_text_circulation',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["lore_minor_incident_text_circulation","history_minor_text_circulation"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  (
    'claim_ability_rinnosuke',
    'gensokyo_main',
    'character',
    'rinnosuke',
    'ability',
    '森近 霖之助に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '森近 霖之助', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lotus_asia',
    'official',
    79,
    '["ability","rinnosuke","objects"]'::jsonb
  ),
  (
    'claim_ability_kosuzu',
    'gensokyo_main',
    'character',
    'kosuzu',
    'ability',
    '本居 小鈴に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '本居 小鈴', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_fs',
    'official',
    77,
    '["ability","kosuzu","books"]'::jsonb
  ),
  (
    'claim_ability_sumireko',
    'gensokyo_main',
    'character',
    'sumireko',
    'ability',
    '宇佐見 菫子に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '宇佐見 菫子', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ulil',
    'official',
    76,
    '["ability","sumireko","occult"]'::jsonb
  ),
  (
    'claim_ability_joon',
    'gensokyo_main',
    'character',
    'joon',
    'ability',
    '依神 女苑に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '依神 女苑', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_aocf',
    'official',
    73,
    '["ability","joon","glamour"]'::jsonb
  ),
  (
    'claim_ability_shion',
    'gensokyo_main',
    'character',
    'shion',
    'ability',
    '依神 紫苑に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '依神 紫苑', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_aocf',
    'official',
    74,
    '["ability","shion","misfortune"]'::jsonb
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_kosuzu',
    'gensokyo_main',
    'characters/kosuzu-motoori',
    '本居 小鈴',
    'character',
    'character',
    'kosuzu',
    '本居 小鈴に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_joon',
    'gensokyo_main',
    'characters/joon-yorigami',
    '依神 女苑',
    'character',
    'character',
    'joon',
    '依神 女苑に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_shion',
    'gensokyo_main',
    'characters/shion-yorigami',
    '依神 紫苑',
    'character',
    'character',
    'shion',
    '依神 紫苑に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_kosuzu:section:overview',
    'wiki_character_kosuzu',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_kosuzu_book_curator","claim_ability_kosuzu"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_joon:section:overview',
    'wiki_character_joon',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_joon_social_drain","claim_ability_joon"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_shion:section:overview',
    'wiki_character_shion',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_shion_misfortune","claim_ability_shion"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_rinnosuke_core',
    'gensokyo_main',
    'global',
    'rinnosuke',
    null,
    null,
    'character_voice',
    '森近 霖之助の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '森近 霖之助の会話や振る舞いに関する文脈データです。'),
    0.86,
    now()
  ),
  (
    'chat_voice_kosuzu_core',
    'gensokyo_main',
    'global',
    'kosuzu',
    null,
    null,
    'character_voice',
    '本居 小鈴の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '本居 小鈴の会話や振る舞いに関する文脈データです。'),
    0.85,
    now()
  ),
  (
    'chat_voice_joon_core',
    'gensokyo_main',
    'global',
    'joon',
    null,
    null,
    'character_voice',
    '依神 女苑の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '依神 女苑の会話や振る舞いに関する文脈データです。'),
    0.83,
    now()
  ),
  (
    'chat_voice_shion_core',
    'gensokyo_main',
    'global',
    'shion',
    null,
    null,
    'character_voice',
    '依神 紫苑の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '依神 紫苑の会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_term_record_culture',
    'term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'term', '説明', '日本語表示向けに整理した説明データです。'),
    '["term","records","culture"]'::jsonb,
    82
  ),
  (
    'gensokyo_main',
    'lore_term_book_circulation',
    'term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'term', '説明', '日本語表示向けに整理した説明データです。'),
    '["term","books","circulation"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_term_boundary_spots',
    'term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'term', '説明', '日本語表示向けに整理した説明データです。'),
    '["term","boundaries","locations"]'::jsonb,
    79
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
    'claim_term_record_culture',
    'gensokyo_main',
    'term',
    'record_culture',
    'definition',
    '記録文化に関する正史設定です。分類は定義です。',
    jsonb_build_object('対象', '記録文化', '分類', '定義', '説明', '日本語表示向けに整理した説明データです。'),
    'src_sixty_years',
    'official',
    83,
    '["term","records","definition"]'::jsonb
  ),
  (
    'claim_term_book_circulation',
    'gensokyo_main',
    'term',
    'book_circulation',
    'definition',
    '書物流通に関する正史設定です。分類は定義です。',
    jsonb_build_object('対象', '書物流通', '分類', '定義', '説明', '日本語表示向けに整理した説明データです。'),
    'src_fs',
    'official',
    81,
    '["term","books","definition"]'::jsonb
  ),
  (
    'claim_term_boundary_spots',
    'gensokyo_main',
    'term',
    'boundary_spots',
    'definition',
    '境界の要所に関する正史設定です。分類は定義です。',
    jsonb_build_object('対象', '境界の要所', '分類', '定義', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ulil',
    'official',
    79,
    '["term","boundaries","definition"]'::jsonb
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_term_record_culture',
    'gensokyo_main',
    'terms/record-culture',
    '記録文化',
    'glossary',
    'term',
    'record_culture',
    '記録文化に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_book_circulation',
    'gensokyo_main',
    'terms/book-circulation',
    '書物流通',
    'glossary',
    'term',
    'book_circulation',
    '書物流通に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_boundary_spots',
    'gensokyo_main',
    'terms/boundary-spots',
    '境界の要所',
    'glossary',
    'term',
    'boundary_spots',
    '境界の要所に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_term_record_culture:section:definition',
    'wiki_term_record_culture',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_record_culture","lore_term_record_culture"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_book_circulation:section:definition',
    'wiki_term_book_circulation',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_book_circulation","lore_term_book_circulation"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_boundary_spots:section:definition',
    'wiki_term_boundary_spots',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_boundary_spots","lore_term_boundary_spots"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_okina_core',
    'gensokyo_main',
    'global',
    'okina',
    null,
    null,
    'character_voice',
    '摩多羅 隠岐奈の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '摩多羅 隠岐奈の会話や振る舞いに関する文脈データです。'),
    0.87,
    now()
  ),
  (
    'chat_voice_yachie_core',
    'gensokyo_main',
    'global',
    'yachie',
    null,
    null,
    'character_voice',
    '吉弔 八千慧の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '吉弔 八千慧の会話や振る舞いに関する文脈データです。'),
    0.86,
    now()
  ),
  (
    'chat_voice_keiki_core',
    'gensokyo_main',
    'global',
    'keiki',
    null,
    null,
    'character_voice',
    '埴安神 袿姫の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '埴安神 袿姫の会話や振る舞いに関する文脈データです。'),
    0.85,
    now()
  ),
  (
    'chat_voice_chimata_core',
    'gensokyo_main',
    'global',
    'chimata',
    null,
    null,
    'character_voice',
    '天弓 千亦の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '天弓 千亦の会話や振る舞いに関する文脈データです。'),
    0.85,
    now()
  ),
  (
    'chat_voice_takane_market_core',
    'gensokyo_main',
    'global',
    'takane',
    null,
    null,
    'character_voice',
    '山城 たかねの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '山城 たかねの会話や振る舞いに関する文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_voice_tsukasa_core',
    'gensokyo_main',
    'global',
    'tsukasa',
    null,
    null,
    'character_voice',
    '菅牧 典の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '菅牧 典の会話や振る舞いに関する文脈データです。'),
    0.83,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_term_hidden_seasons',
    'term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'term', '説明', '日本語表示向けに整理した説明データです。'),
    '["term","hidden_seasons","hsifs"]'::jsonb,
    78
  ),
  (
    'gensokyo_main',
    'lore_term_beast_realm_politics',
    'term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'term', '説明', '日本語表示向けに整理した説明データです。'),
    '["term","beast_realm","politics"]'::jsonb,
    80
  ),
  (
    'gensokyo_main',
    'lore_term_market_competition',
    'term',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'term', '説明', '日本語表示向けに整理した説明データです。'),
    '["term","market","competition"]'::jsonb,
    80
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
    'claim_term_hidden_seasons',
    'gensokyo_main',
    'term',
    'hidden_seasons',
    'definition',
    '秘匿された四季に関する正史設定です。分類は定義です。',
    jsonb_build_object('対象', '秘匿された四季', '分類', '定義', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hsifs',
    'official',
    78,
    '["term","hidden_seasons","definition"]'::jsonb
  ),
  (
    'claim_term_beast_realm_politics',
    'gensokyo_main',
    'term',
    'beast_realm_politics',
    'definition',
    '畜生界の政に関する正史設定です。分類は定義です。',
    jsonb_build_object('対象', '畜生界の政', '分類', '定義', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    80,
    '["term","beast_realm","definition"]'::jsonb
  ),
  (
    'claim_term_market_competition',
    'gensokyo_main',
    'term',
    'market_competition',
    'definition',
    '市場競争に関する正史設定です。分類は定義です。',
    jsonb_build_object('対象', '市場競争', '分類', '定義', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    80,
    '["term","market","definition"]'::jsonb
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_term_hidden_seasons',
    'gensokyo_main',
    'terms/hidden-seasons',
    '秘匿された四季',
    'glossary',
    'term',
    'hidden_seasons',
    '秘匿された四季に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_beast_realm_politics',
    'gensokyo_main',
    'terms/beast-realm-politics',
    '畜生界の政',
    'glossary',
    'term',
    'beast_realm_politics',
    '畜生界の政に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_market_competition',
    'gensokyo_main',
    'terms/market-competition',
    '市場競争',
    'glossary',
    'term',
    'market_competition',
    '市場競争に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_term_hidden_seasons:section:definition',
    'wiki_term_hidden_seasons',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_hidden_seasons","lore_term_hidden_seasons"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_beast_realm_politics:section:definition',
    'wiki_term_beast_realm_politics',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_beast_realm_politics","lore_term_beast_realm_politics"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_market_competition:section:definition',
    'wiki_term_market_competition',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_market_competition","lore_term_market_competition"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  (
    'claim_ability_nazrin',
    'gensokyo_main',
    'character',
    'nazrin',
    'ability',
    'ナズーリンに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'ナズーリン', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    72,
    '["ability","nazrin","ufo"]'::jsonb
  ),
  (
    'claim_ability_kogasa',
    'gensokyo_main',
    'character',
    'kogasa',
    'ability',
    '多々良 小傘に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '多々良 小傘', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    69,
    '["ability","kogasa","ufo"]'::jsonb
  ),
  (
    'claim_ability_murasa',
    'gensokyo_main',
    'character',
    'murasa',
    'ability',
    '村紗 水蜜に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '村紗 水蜜', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    72,
    '["ability","murasa","ufo"]'::jsonb
  ),
  (
    'claim_ability_nue',
    'gensokyo_main',
    'character',
    'nue',
    'ability',
    '封獣 ぬえに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '封獣 ぬえ', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    75,
    '["ability","nue","ufo"]'::jsonb
  ),
  (
    'claim_ability_seiga',
    'gensokyo_main',
    'character',
    'seiga',
    'ability',
    '霍 青娥に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '霍 青娥', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    74,
    '["ability","seiga","td"]'::jsonb
  ),
  (
    'claim_ability_futo',
    'gensokyo_main',
    'character',
    'futo',
    'ability',
    '物部 布都に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '物部 布都', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    71,
    '["ability","futo","td"]'::jsonb
  ),
  (
    'claim_ability_tojiko',
    'gensokyo_main',
    'character',
    'tojiko',
    'ability',
    '蘇我 屠自古に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '蘇我 屠自古', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_td',
    'official',
    70,
    '["ability","tojiko","td"]'::jsonb
  ),
  (
    'claim_ability_narumi',
    'gensokyo_main',
    'character',
    'narumi',
    'ability',
    '矢田寺 成美に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '矢田寺 成美', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hsifs',
    'official',
    69,
    '["ability","narumi","hsifs"]'::jsonb
  ),
  (
    'claim_ability_saki',
    'gensokyo_main',
    'character',
    'saki',
    'ability',
    '驪駒 早鬼に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '驪駒 早鬼', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    74,
    '["ability","saki","wbawc"]'::jsonb
  ),
  (
    'claim_ability_misumaru',
    'gensokyo_main',
    'character',
    'misumaru',
    'ability',
    '玉造 魅須丸に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '玉造 魅須丸', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    72,
    '["ability","misumaru","um"]'::jsonb
  ),
  (
    'claim_ability_momoyo',
    'gensokyo_main',
    'character',
    'momoyo',
    'ability',
    '姫虫 百々世に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '姫虫 百々世', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    72,
    '["ability","momoyo","um"]'::jsonb
  ),
  (
    'claim_ability_megumu',
    'gensokyo_main',
    'character',
    'megumu',
    'ability',
    '飯綱丸 龍に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '飯綱丸 龍', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    74,
    '["ability","megumu","um"]'::jsonb
  ),
  (
    'claim_ability_mike',
    'gensokyo_main',
    'character',
    'mike',
    'ability',
    '豪徳寺 ミケに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '豪徳寺 ミケ', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_um',
    'official',
    69,
    '["ability","mike","um"]'::jsonb
  ),
  (
    'claim_ability_aunn',
    'gensokyo_main',
    'character',
    'aunn',
    'ability',
    '高麗野 あうんに関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '高麗野 あうん', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_hsifs',
    'official',
    71,
    '["ability","aunn","hsifs"]'::jsonb
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_nazrin',
    'gensokyo_main',
    'characters/nazrin',
    'ナズーリン',
    'character',
    'character',
    'nazrin',
    'ナズーリンに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_kogasa',
    'gensokyo_main',
    'characters/kogasa-tatara',
    '多々良 小傘',
    'character',
    'character',
    'kogasa',
    '多々良 小傘に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_murasa',
    'gensokyo_main',
    'characters/minamitsu-murasa',
    '村紗 水蜜',
    'character',
    'character',
    'murasa',
    '村紗 水蜜に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_nue',
    'gensokyo_main',
    'characters/nue-houjuu',
    '封獣 ぬえ',
    'character',
    'character',
    'nue',
    '封獣 ぬえに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_seiga',
    'gensokyo_main',
    'characters/seiga-kaku',
    '霍 青娥',
    'character',
    'character',
    'seiga',
    '霍 青娥に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_futo',
    'gensokyo_main',
    'characters/mononobe-no-futo',
    '物部 布都',
    'character',
    'character',
    'futo',
    '物部 布都に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_tojiko',
    'gensokyo_main',
    'characters/soga-no-tojiko',
    '蘇我 屠自古',
    'character',
    'character',
    'tojiko',
    '蘇我 屠自古に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_narumi',
    'gensokyo_main',
    'characters/narumi-yatadera',
    '矢田寺 成美',
    'character',
    'character',
    'narumi',
    '矢田寺 成美に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_saki',
    'gensokyo_main',
    'characters/saki-kurokoma',
    '驪駒 早鬼',
    'character',
    'character',
    'saki',
    '驪駒 早鬼に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_misumaru',
    'gensokyo_main',
    'characters/misumaru-tamatsukuri',
    '玉造 魅須丸',
    'character',
    'character',
    'misumaru',
    '玉造 魅須丸に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_momoyo',
    'gensokyo_main',
    'characters/momoyo-himemushi',
    '姫虫 百々世',
    'character',
    'character',
    'momoyo',
    '姫虫 百々世に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_megumu',
    'gensokyo_main',
    'characters/megumu-iizunamaru',
    '飯綱丸 龍',
    'character',
    'character',
    'megumu',
    '飯綱丸 龍に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_nazrin:section:overview',
    'wiki_character_nazrin',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_nazrin_search_specialist","claim_ability_nazrin"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_kogasa:section:overview',
    'wiki_character_kogasa',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_kogasa_surprise","claim_ability_kogasa"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_murasa:section:overview',
    'wiki_character_murasa',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_murasa_navigation","claim_ability_murasa"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_nue:section:overview',
    'wiki_character_nue',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_nue_ambiguity","claim_ability_nue"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_seiga:section:overview',
    'wiki_character_seiga',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_seiga_intrusion","claim_ability_seiga"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_futo:section:overview',
    'wiki_character_futo',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ability_futo"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_tojiko:section:overview',
    'wiki_character_tojiko',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ability_tojiko"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_narumi:section:overview',
    'wiki_character_narumi',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_narumi_local_guardian","claim_ability_narumi"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_saki:section:overview',
    'wiki_character_saki',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ability_saki"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_misumaru:section:overview',
    'wiki_character_misumaru',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ability_misumaru"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_momoyo:section:overview',
    'wiki_character_momoyo',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ability_momoyo"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_megumu:section:overview',
    'wiki_character_megumu',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_megumu_mountain_authority","claim_ability_megumu"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_nazrin_core',
    'gensokyo_main',
    'global',
    'nazrin',
    null,
    null,
    'character_voice',
    'ナズーリンの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'ナズーリンの会話や振る舞いに関する文脈データです。'),
    0.83,
    now()
  ),
  (
    'chat_voice_kogasa_core',
    'gensokyo_main',
    'global',
    'kogasa',
    null,
    null,
    'character_voice',
    '多々良 小傘の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '多々良 小傘の会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  ),
  (
    'chat_voice_murasa_core',
    'gensokyo_main',
    'global',
    'murasa',
    null,
    null,
    'character_voice',
    '村紗 水蜜の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '村紗 水蜜の会話や振る舞いに関する文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_voice_nue_core',
    'gensokyo_main',
    'global',
    'nue',
    null,
    null,
    'character_voice',
    '封獣 ぬえの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '封獣 ぬえの会話や振る舞いに関する文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_voice_seiga_core',
    'gensokyo_main',
    'global',
    'seiga',
    null,
    null,
    'character_voice',
    '霍 青娥の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '霍 青娥の会話や振る舞いに関する文脈データです。'),
    0.85,
    now()
  ),
  (
    'chat_voice_narumi_core',
    'gensokyo_main',
    'global',
    'narumi',
    null,
    null,
    'character_voice',
    '矢田寺 成美の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '矢田寺 成美の会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  ),
  (
    'chat_voice_saki_core',
    'gensokyo_main',
    'global',
    'saki',
    null,
    null,
    'character_voice',
    '驪駒 早鬼の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '驪駒 早鬼の会話や振る舞いに関する文脈データです。'),
    0.83,
    now()
  ),
  (
    'chat_voice_misumaru_core',
    'gensokyo_main',
    'global',
    'misumaru',
    null,
    null,
    'character_voice',
    '玉造 魅須丸の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '玉造 魅須丸の会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  ),
  (
    'chat_voice_momoyo_core',
    'gensokyo_main',
    'global',
    'momoyo',
    null,
    null,
    'character_voice',
    '姫虫 百々世の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '姫虫 百々世の会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  ),
  (
    'chat_voice_megumu_core',
    'gensokyo_main',
    'global',
    'megumu',
    null,
    null,
    'character_voice',
    '飯綱丸 龍の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '飯綱丸 龍の会話や振る舞いに関する文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_voice_mike_core',
    'gensokyo_main',
    'global',
    'mike',
    null,
    null,
    'character_voice',
    '豪徳寺 ミケの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '豪徳寺 ミケの会話や振る舞いに関する文脈データです。'),
    0.81,
    now()
  ),
  (
    'chat_voice_aunn_core',
    'gensokyo_main',
    'global',
    'aunn',
    null,
    null,
    'character_voice',
    '高麗野 あうんの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '高麗野 あうんの会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  (
    'claim_ichirin_temple_strength',
    'gensokyo_main',
    'character',
    'ichirin',
    'role',
    '雲居 一輪に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '雲居 一輪', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ufo',
    'official',
    72,
    '["ichirin","ufo","temple"]'::jsonb
  ),
  (
    'claim_reisen_eientei_operator',
    'gensokyo_main',
    'character',
    'reisen',
    'role',
    '鈴仙・優曇華院・イナバに関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '鈴仙・優曇華院・イナバ', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_imperishable_night',
    'official',
    77,
    '["reisen","in","eientei"]'::jsonb
  ),
  (
    'claim_eika_riverbank_persistence',
    'gensokyo_main',
    'character',
    'eika',
    'role',
    '戎 瓔花に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '戎 瓔花', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    68,
    '["eika","wbawc","riverbank"]'::jsonb
  ),
  (
    'claim_urumi_threshold_guard',
    'gensokyo_main',
    'character',
    'urumi',
    'role',
    '牛崎 潤美に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '牛崎 潤美', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    69,
    '["urumi","wbawc","threshold"]'::jsonb
  ),
  (
    'claim_kutaka_checkpoint_guard',
    'gensokyo_main',
    'character',
    'kutaka',
    'role',
    '庭渡 久侘歌に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '庭渡 久侘歌', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    71,
    '["kutaka","wbawc","checkpoint"]'::jsonb
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

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_myouren_temple_core',
    'gensokyo_main',
    'global',
    null,
    'myouren_temple',
    null,
    'location_mood',
    '命蓮寺に関する場面文脈データです。',
    jsonb_build_object('説明', '命蓮寺に関する場面文脈データです。'),
    0.86,
    now()
  ),
  (
    'chat_location_chireiden_core',
    'gensokyo_main',
    'global',
    null,
    'chireiden',
    null,
    'location_mood',
    '地霊殿に関する場面文脈データです。',
    jsonb_build_object('説明', '地霊殿に関する場面文脈データです。'),
    0.87,
    now()
  ),
  (
    'chat_location_divine_spirit_mausoleum_core',
    'gensokyo_main',
    'global',
    null,
    'divine_spirit_mausoleum',
    null,
    'location_mood',
    '神霊廟に関する場面文脈データです。',
    jsonb_build_object('説明', '神霊廟に関する場面文脈データです。'),
    0.85,
    now()
  ),
  (
    'chat_location_bamboo_forest_core',
    'gensokyo_main',
    'global',
    null,
    'bamboo_forest',
    null,
    'location_mood',
    '迷いの竹林に関する場面文脈データです。',
    jsonb_build_object('説明', '迷いの竹林に関する場面文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_location_eientei_core',
    'gensokyo_main',
    'global',
    null,
    'eientei',
    null,
    'location_mood',
    '永遠亭に関する場面文脈データです。',
    jsonb_build_object('説明', '永遠亭に関する場面文脈データです。'),
    0.86,
    now()
  ),
  (
    'chat_location_kappa_workshop_core',
    'gensokyo_main',
    'global',
    null,
    'kappa_workshop',
    null,
    'location_mood',
    '河童工房に関する場面文脈データです。',
    jsonb_build_object('説明', '河童工房に関する場面文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_location_suzunaan_core',
    'gensokyo_main',
    'global',
    null,
    'suzunaan',
    null,
    'location_mood',
    '鈴奈庵に関する場面文脈データです。',
    jsonb_build_object('説明', '鈴奈庵に関する場面文脈データです。'),
    0.85,
    now()
  ),
  (
    'chat_location_kourindou_core',
    'gensokyo_main',
    'global',
    null,
    'kourindou',
    null,
    'location_mood',
    '香霖堂に関する場面文脈データです。',
    jsonb_build_object('説明', '香霖堂に関する場面文脈データです。'),
    0.85,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_byakuren',
    'gensokyo_main',
    'characters/byakuren-hijiri',
    '聖 白蓮',
    'character',
    'character',
    'byakuren',
    '聖 白蓮に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_ichirin',
    'gensokyo_main',
    'characters/ichirin-kumoi',
    '雲居 一輪',
    'character',
    'character',
    'ichirin',
    '雲居 一輪に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_reisen',
    'gensokyo_main',
    'characters/reisen-udongein-inaba',
    '鈴仙・優曇華院・イナバ',
    'character',
    'character',
    'reisen',
    '鈴仙・優曇華院・イナバに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_eika',
    'gensokyo_main',
    'characters/eika-ebisu',
    '戎 瓔花',
    'character',
    'character',
    'eika',
    '戎 瓔花に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_urumi',
    'gensokyo_main',
    'characters/urumi-ushizaki',
    '牛崎 潤美',
    'character',
    'character',
    'urumi',
    '牛崎 潤美に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_kutaka',
    'gensokyo_main',
    'characters/kutaka-niwatari',
    '庭渡 久侘歌',
    'character',
    'character',
    'kutaka',
    '庭渡 久侘歌に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_byakuren:section:overview',
    'wiki_character_byakuren',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_byakuren_coexistence","claim_ability_byakuren"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_ichirin:section:overview',
    'wiki_character_ichirin',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ichirin_temple_strength"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_reisen:section:overview',
    'wiki_character_reisen',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_reisen_eientei_operator"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_eika:section:overview',
    'wiki_character_eika',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_eika_riverbank_persistence"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_urumi:section:overview',
    'wiki_character_urumi',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_urumi_threshold_guard"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_kutaka:section:overview',
    'wiki_character_kutaka',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_kutaka_checkpoint_guard"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_byakuren_core',
    'gensokyo_main',
    'global',
    'byakuren',
    null,
    null,
    'character_voice',
    '聖 白蓮の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '聖 白蓮の会話や振る舞いに関する文脈データです。'),
    0.86,
    now()
  ),
  (
    'chat_voice_ichirin_core',
    'gensokyo_main',
    'global',
    'ichirin',
    null,
    null,
    'character_voice',
    '雲居 一輪の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '雲居 一輪の会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  ),
  (
    'chat_voice_reisen_core',
    'gensokyo_main',
    'global',
    'reisen',
    null,
    null,
    'character_voice',
    '鈴仙・優曇華院・イナバの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '鈴仙・優曇華院・イナバの会話や振る舞いに関する文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_voice_eika_core',
    'gensokyo_main',
    'global',
    'eika',
    null,
    null,
    'character_voice',
    '戎 瓔花の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '戎 瓔花の会話や振る舞いに関する文脈データです。'),
    0.80,
    now()
  ),
  (
    'chat_voice_urumi_core',
    'gensokyo_main',
    'global',
    'urumi',
    null,
    null,
    'character_voice',
    '牛崎 潤美の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '牛崎 潤美の会話や振る舞いに関する文脈データです。'),
    0.80,
    now()
  ),
  (
    'chat_voice_kutaka_core',
    'gensokyo_main',
    'global',
    'kutaka',
    null,
    null,
    'character_voice',
    '庭渡 久侘歌の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '庭渡 久侘歌の会話や振る舞いに関する文脈データです。'),
    0.81,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

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
    'わかさぎ姫の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'わかさぎ姫の会話や振る舞いに関する文脈データです。'),
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
    '赤蛮奇の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '赤蛮奇の会話や振る舞いに関する文脈データです。'),
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
    '今泉 影狼の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '今泉 影狼の会話や振る舞いに関する文脈データです。'),
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
    '九十九 弁々の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '九十九 弁々の会話や振る舞いに関する文脈データです。'),
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
    '九十九 八橋の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '九十九 八橋の会話や振る舞いに関する文脈データです。'),
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
    '清蘭の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '清蘭の会話や振る舞いに関する文脈データです。'),
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
    '鈴瑚の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '鈴瑚の会話や振る舞いに関する文脈データです。'),
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
    'キスメの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'キスメの会話や振る舞いに関する文脈データです。'),
    0.79,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_scarlet_devil_mansion_core',
    'gensokyo_main',
    'global',
    null,
    'scarlet_devil_mansion',
    null,
    'location_mood',
    '紅魔館に関する場面文脈データです。',
    jsonb_build_object('説明', '紅魔館に関する場面文脈データです。'),
    0.85,
    now()
  ),
  (
    'chat_location_misty_lake_core',
    'gensokyo_main',
    'global',
    null,
    'misty_lake',
    null,
    'location_mood',
    '霧の湖に関する場面文脈データです。',
    jsonb_build_object('説明', '霧の湖に関する場面文脈データです。'),
    0.83,
    now()
  ),
  (
    'chat_location_former_hell_core',
    'gensokyo_main',
    'global',
    null,
    'former_hell',
    null,
    'location_mood',
    '旧地獄に関する場面文脈データです。',
    jsonb_build_object('説明', '旧地獄に関する場面文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_location_rainbow_dragon_cave_core',
    'gensokyo_main',
    'global',
    null,
    'rainbow_dragon_cave',
    null,
    'location_mood',
    '虹龍洞に関する場面文脈データです。',
    jsonb_build_object('説明', '虹龍洞に関する場面文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_location_backdoor_realm_core',
    'gensokyo_main',
    'global',
    null,
    'backdoor_realm',
    null,
    'location_mood',
    '後戸の国に関する場面文脈データです。',
    jsonb_build_object('説明', '後戸の国に関する場面文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_location_beast_realm_core',
    'gensokyo_main',
    'global',
    null,
    'beast_realm',
    null,
    'location_mood',
    '畜生界に関する場面文脈データです。',
    jsonb_build_object('説明', '畜生界に関する場面文脈データです。'),
    0.85,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_satono_core',
    'gensokyo_main',
    'global',
    'satono',
    null,
    null,
    'character_voice',
    '爾子田 里乃の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '爾子田 里乃の会話や振る舞いに関する文脈データです。'),
    0.80,
    now()
  ),
  (
    'chat_voice_mai_core',
    'gensokyo_main',
    'global',
    'mai',
    null,
    null,
    'character_voice',
    '丁礼田 舞の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '丁礼田 舞の会話や振る舞いに関する文脈データです。'),
    0.80,
    now()
  ),
  (
    'chat_voice_sannyo_core',
    'gensokyo_main',
    'global',
    'sannyo',
    null,
    null,
    'character_voice',
    '駒草 山如の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '駒草 山如の会話や振る舞いに関する文脈データです。'),
    0.80,
    now()
  ),
  (
    'chat_voice_biten_core',
    'gensokyo_main',
    'global',
    'biten',
    null,
    null,
    'character_voice',
    '孫 美天の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '孫 美天の会話や振る舞いに関する文脈データです。'),
    0.79,
    now()
  ),
  (
    'chat_voice_enoko_core',
    'gensokyo_main',
    'global',
    'enoko',
    null,
    null,
    'character_voice',
    '三頭 慧ノ子の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '三頭 慧ノ子の会話や振る舞いに関する文脈データです。'),
    0.80,
    now()
  ),
  (
    'chat_voice_chiyari_core',
    'gensokyo_main',
    'global',
    'chiyari',
    null,
    null,
    'character_voice',
    '天火人 ちやりの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '天火人 ちやりの会話や振る舞いに関する文脈データです。'),
    0.80,
    now()
  ),
  (
    'chat_voice_hisami_core',
    'gensokyo_main',
    'global',
    'hisami',
    null,
    null,
    'character_voice',
    '豫母都 日狭美の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '豫母都 日狭美の会話や振る舞いに関する文脈データです。'),
    0.79,
    now()
  ),
  (
    'chat_voice_zanmu_core',
    'gensokyo_main',
    'global',
    'zanmu',
    null,
    null,
    'character_voice',
    '日白 残無の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '日白 残無の会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_location_blood_pool_hell_core',
    'gensokyo_main',
    'global',
    null,
    'blood_pool_hell',
    null,
    'location_mood',
    '血の池地獄に関する場面文脈データです。',
    jsonb_build_object('説明', '血の池地獄に関する場面文脈データです。'),
    0.81,
    now()
  ),
  (
    'chat_location_sanzu_river_core',
    'gensokyo_main',
    'global',
    null,
    'sanzu_river',
    null,
    'location_mood',
    '三途の川に関する場面文脈データです。',
    jsonb_build_object('説明', '三途の川に関する場面文脈データです。'),
    0.81,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

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
    '四季異変に関する注記',
    '四季異変を歴史記録として扱うための補足注記です。',
    '四季異変に関する記録上の見方や整理方針をまとめた歴史家注記です。',
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
    '畜生界異変に関する注記',
    '畜生界異変を歴史記録として扱うための補足注記です。',
    '畜生界異変に関する記録上の見方や整理方針をまとめた歴史家注記です。',
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
    '能力カード騒動に関する注記',
    '能力カード騒動を歴史記録として扱うための補足注記です。',
    '能力カード騒動に関する記録上の見方や整理方針をまとめた歴史家注記です。',
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
    '生ける亡霊騒動に関する注記',
    '生ける亡霊騒動を歴史記録として扱うための補足注記です。',
    '生ける亡霊騒動に関する記録上の見方や整理方針をまとめた歴史家注記です。',
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_satono',
    'gensokyo_main',
    'characters/satono-nishida',
    '爾子田 里乃',
    'character',
    'character',
    'satono',
    '爾子田 里乃に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_mai',
    'gensokyo_main',
    'characters/mai-teireida',
    '丁礼田 舞',
    'character',
    'character',
    'mai',
    '丁礼田 舞に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_sannyo',
    'gensokyo_main',
    'characters/sannyo-komakusa',
    '駒草 山如',
    'character',
    'character',
    'sannyo',
    '駒草 山如に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_biten',
    'gensokyo_main',
    'characters/son-biten',
    '孫 美天',
    'character',
    'character',
    'biten',
    '孫 美天に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_enoko',
    'gensokyo_main',
    'characters/enoko-mitsugashira',
    '三頭 慧ノ子',
    'character',
    'character',
    'enoko',
    '三頭 慧ノ子に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_chiyari',
    'gensokyo_main',
    'characters/chiyari-tenkajin',
    '天火人 ちやり',
    'character',
    'character',
    'chiyari',
    '天火人 ちやりに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_hisami',
    'gensokyo_main',
    'characters/hisami-yomotsu',
    '豫母都 日狭美',
    'character',
    'character',
    'hisami',
    '豫母都 日狭美に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_satono:section:overview',
    'wiki_character_satono',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_hidden_seasons"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_mai:section:overview',
    'wiki_character_mai',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_term_hidden_seasons"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_sannyo:section:overview',
    'wiki_character_sannyo',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_incident_market_cards"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_biten:section:overview',
    'wiki_character_biten',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_biten_mountain_fighter"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_enoko:section:overview',
    'wiki_character_enoko',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_enoko_pack_order"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_chiyari:section:overview',
    'wiki_character_chiyari',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_chiyari_underworld_operator"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_hisami:section:overview',
    'wiki_character_hisami',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_hisami_loyal_retainer"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_satono_selected_service',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["hsifs","satono","service"]'::jsonb,
    74
  ),
  (
    'gensokyo_main',
    'lore_mai_backstage_motion',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["hsifs","mai","movement"]'::jsonb,
    74
  ),
  (
    'gensokyo_main',
    'lore_sannyo_informal_market_rest',
    'character_role',
    '幻想郷設定項目',
    '人物の立ち位置や役割を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_role', '説明', '日本語表示向けに整理した説明データです。'),
    '["um","sannyo","market"]'::jsonb,
    73
  ),
  (
    'gensokyo_main',
    'lore_market_route_rest_logic',
    'world_rule',
    '幻想郷設定項目',
    '幻想郷全体に関わる基本ルールを整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'world_rule', '説明', '日本語表示向けに整理した説明データです。'),
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
    '爾子田 里乃に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '爾子田 里乃', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
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
    '丁礼田 舞に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '丁礼田 舞', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
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
    '駒草 山如に関する正史設定です。分類は役割です。',
    jsonb_build_object('対象', '駒草 山如', '分類', '役割', '説明', '日本語表示向けに整理した説明データです。'),
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
    '爾子田 里乃と丁礼田 舞に関する正史設定です。分類は関係です。',
    jsonb_build_object('対象', '爾子田 里乃と丁礼田 舞', '分類', '関係', '説明', '日本語表示向けに整理した説明データです。'),
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
    '市場街道の休息所に関する正史設定です。分類は世界ルールです。',
    jsonb_build_object('対象', '市場街道の休息所', '分類', '世界ルール', '説明', '日本語表示向けに整理した説明データです。'),
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

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_satono:section:story_use',
    'wiki_character_satono',
    'story_use',
    2,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_satono_selected_attendant","claim_backdoor_attendants_pairing","lore_satono_selected_service"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_mai:section:story_use',
    'wiki_character_mai',
    'story_use',
    2,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_mai_backstage_executor","claim_backdoor_attendants_pairing","lore_mai_backstage_motion"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_sannyo:section:story_use',
    'wiki_character_sannyo',
    'story_use',
    2,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_sannyo_informal_merchant","claim_market_route_rest_stops","lore_sannyo_informal_market_rest"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_context_global_satono_backdoor',
    'gensokyo_main',
    'global',
    'satono',
    'backdoor_realm',
    null,
    'character_location_story',
    '爾子田 里乃の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '爾子田 里乃の会話や振る舞いに関する文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_context_global_mai_backdoor',
    'gensokyo_main',
    'global',
    'mai',
    'backdoor_realm',
    null,
    'character_location_story',
    '丁礼田 舞の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '丁礼田 舞の会話や振る舞いに関する文脈データです。'),
    0.84,
    now()
  ),
  (
    'chat_context_global_sannyo_market_rest',
    'gensokyo_main',
    'global',
    'sannyo',
    'rainbow_dragon_cave',
    null,
    'character_location_story',
    '駒草 山如の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '駒草 山如の会話や振る舞いに関する文脈データです。'),
    0.84,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

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
    '対象項目に関する注記',
    '対象項目を歴史記録として扱うための補足注記です。',
    '対象項目に関する記録上の見方や整理方針をまとめた歴史家注記です。',
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
    '対象項目に関する注記',
    '対象項目を歴史記録として扱うための補足注記です。',
    '対象項目に関する記録上の見方や整理方針をまとめた歴史家注記です。',
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_term_backdoor_service',
    'gensokyo_main',
    'terms/backdoor-service',
    '後戸の奉仕体系',
    'glossary',
    'term',
    'backdoor_service',
    '後戸の奉仕体系に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_market_rest_stops',
    'gensokyo_main',
    'terms/market-rest-stops',
    '市場街道の休憩所',
    'glossary',
    'term',
    'market_rest_stops',
    '市場街道の休憩所に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_term_backdoor_service:section:definition',
    'wiki_term_backdoor_service',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_satono_selected_attendant","claim_mai_backstage_executor","claim_backdoor_attendants_pairing","claim_backdoor_realm_profile"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_market_rest_stops:section:definition',
    'wiki_term_market_rest_stops',
    'definition',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_sannyo_informal_merchant","claim_market_route_rest_stops","claim_rainbow_dragon_cave_profile"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_satono_core',
    'gensokyo_main',
    'global',
    'satono',
    null,
    null,
    'character_voice',
    '爾子田 里乃の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '爾子田 里乃の会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  ),
  (
    'chat_voice_mai_core',
    'gensokyo_main',
    'global',
    'mai',
    null,
    null,
    'character_voice',
    '丁礼田 舞の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '丁礼田 舞の会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  ),
  (
    'chat_voice_sannyo_core',
    'gensokyo_main',
    'global',
    'sannyo',
    null,
    null,
    'character_voice',
    '駒草 山如の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '駒草 山如の会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  (
    'gensokyo_main',
    'lore_ability_wakasagihime',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","wakasagihime"]'::jsonb,
    65
  ),
  (
    'gensokyo_main',
    'lore_ability_sekibanki',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","sekibanki"]'::jsonb,
    68
  ),
  (
    'gensokyo_main',
    'lore_ability_kagerou',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","kagerou"]'::jsonb,
    67
  ),
  (
    'gensokyo_main',
    'lore_ability_benben',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","benben"]'::jsonb,
    66
  ),
  (
    'gensokyo_main',
    'lore_ability_yatsuhashi',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","yatsuhashi"]'::jsonb,
    66
  ),
  (
    'gensokyo_main',
    'lore_ability_seiran',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","seiran"]'::jsonb,
    67
  ),
  (
    'gensokyo_main',
    'lore_ability_ringo',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","ringo"]'::jsonb,
    67
  ),
  (
    'gensokyo_main',
    'lore_ability_mayumi',
    'character_ability',
    '幻想郷設定項目',
    '幻想郷の世界設定を整理した設定項目です。',
    jsonb_build_object('対象', '幻想郷', '分類', 'character_ability', '説明', '日本語表示向けに整理した説明データです。'),
    '["ability","mayumi"]'::jsonb,
    70
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
    'claim_ability_wakasagihime',
    'gensokyo_main',
    'character',
    'wakasagihime',
    'ability',
    'わかさぎ姫に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', 'わかさぎ姫', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    66,
    '["ability","wakasagihime","ddc"]'::jsonb
  ),
  (
    'claim_ability_sekibanki',
    'gensokyo_main',
    'character',
    'sekibanki',
    'ability',
    '赤蛮奇に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '赤蛮奇', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    69,
    '["ability","sekibanki","ddc"]'::jsonb
  ),
  (
    'claim_ability_kagerou',
    'gensokyo_main',
    'character',
    'kagerou',
    'ability',
    '今泉 影狼に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '今泉 影狼', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    68,
    '["ability","kagerou","ddc"]'::jsonb
  ),
  (
    'claim_ability_benben',
    'gensokyo_main',
    'character',
    'benben',
    'ability',
    '九十九 弁々に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '九十九 弁々', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    67,
    '["ability","benben","ddc"]'::jsonb
  ),
  (
    'claim_ability_yatsuhashi',
    'gensokyo_main',
    'character',
    'yatsuhashi',
    'ability',
    '九十九 八橋に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '九十九 八橋', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_ddc',
    'official',
    67,
    '["ability","yatsuhashi","ddc"]'::jsonb
  ),
  (
    'claim_ability_seiran',
    'gensokyo_main',
    'character',
    'seiran',
    'ability',
    '清蘭に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '清蘭', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    68,
    '["ability","seiran","lolk"]'::jsonb
  ),
  (
    'claim_ability_ringo',
    'gensokyo_main',
    'character',
    'ringo',
    'ability',
    '鈴瑚に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '鈴瑚', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_lolk',
    'official',
    68,
    '["ability","ringo","lolk"]'::jsonb
  ),
  (
    'claim_ability_mayumi',
    'gensokyo_main',
    'character',
    'mayumi',
    'ability',
    '杖刀偶 磨弓に関する正史設定です。分類は能力です。',
    jsonb_build_object('対象', '杖刀偶 磨弓', '分類', '能力', '説明', '日本語表示向けに整理した説明データです。'),
    'src_wbawc',
    'official',
    72,
    '["ability","mayumi","wbawc"]'::jsonb
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

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_character_wakasagihime',
    'gensokyo_main',
    'characters/wakasagihime',
    'わかさぎ姫',
    'character',
    'character',
    'wakasagihime',
    'わかさぎ姫に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_sekibanki',
    'gensokyo_main',
    'characters/sekibanki',
    '赤蛮奇',
    'character',
    'character',
    'sekibanki',
    '赤蛮奇に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_kagerou',
    'gensokyo_main',
    'characters/kagerou-imaizumi',
    '今泉 影狼',
    'character',
    'character',
    'kagerou',
    '今泉 影狼に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_benben',
    'gensokyo_main',
    'characters/benben-tsukumo',
    '九十九 弁々',
    'character',
    'character',
    'benben',
    '九十九 弁々に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_yatsuhashi',
    'gensokyo_main',
    'characters/yatsuhashi-tsukumo',
    '九十九 八橋',
    'character',
    'character',
    'yatsuhashi',
    '九十九 八橋に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_seiran',
    'gensokyo_main',
    'characters/seiran',
    '清蘭',
    'character',
    'character',
    'seiran',
    '清蘭に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_ringo',
    'gensokyo_main',
    'characters/ringo',
    '鈴瑚',
    'character',
    'character',
    'ringo',
    '鈴瑚に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_clownpiece',
    'gensokyo_main',
    'characters/clownpiece',
    'クラウンピース',
    'character',
    'character',
    'clownpiece',
    'クラウンピースに関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_character_mayumi',
    'gensokyo_main',
    'characters/mayumi-joutouguu',
    '杖刀偶 磨弓',
    'character',
    'character',
    'mayumi',
    '杖刀偶 磨弓に関する幻想郷事典項目です。',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_wakasagihime:section:overview',
    'wiki_character_wakasagihime',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_wakasagihime_local_lake","claim_ability_wakasagihime"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_sekibanki:section:overview',
    'wiki_character_sekibanki',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_sekibanki_village_uncanny","claim_ability_sekibanki"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_kagerou:section:overview',
    'wiki_character_kagerou',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_kagerou_bamboo_night","claim_ability_kagerou"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_benben:section:overview',
    'wiki_character_benben',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_benben_performer","claim_ability_benben"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_yatsuhashi:section:overview',
    'wiki_character_yatsuhashi',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_yatsuhashi_performer","claim_ability_yatsuhashi"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_seiran:section:overview',
    'wiki_character_seiran',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_seiran_soldier","claim_ability_seiran"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_ringo:section:overview',
    'wiki_character_ringo',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ringo_daily_lunar","claim_ability_ringo"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_clownpiece:section:overview',
    'wiki_character_clownpiece',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ability_clownpiece"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_mayumi:section:overview',
    'wiki_character_mayumi',
    'overview',
    1,
    '補足',
    '幻想郷事典項目の説明節です。',
    '項目の要点を日本語で整理した節です。',
    '["claim_ability_mayumi"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chat_context_cache (
  id, world_id, user_scope, character_id, location_id, event_id, context_type, summary, payload, freshness_score, last_used_at
)
values
  (
    'chat_voice_clownpiece_core',
    'gensokyo_main',
    'global',
    'clownpiece',
    null,
    null,
    'character_voice',
    'クラウンピースの会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'クラウンピースの会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  ),
  (
    'chat_voice_mayumi_core',
    'gensokyo_main',
    'global',
    'mayumi',
    null,
    null,
    'character_voice',
    '杖刀偶 磨弓の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '杖刀偶 磨弓の会話や振る舞いに関する文脈データです。'),
    0.82,
    now()
  ),
  (
    'chat_context_global_wakasagihime_lake',
    'gensokyo_main',
    'global',
    'wakasagihime',
    'misty_lake',
    null,
    'character_location_story',
    'わかさぎ姫の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', 'わかさぎ姫の会話や振る舞いに関する文脈データです。'),
    0.80,
    now()
  ),
  (
    'chat_context_global_kagerou_bamboo',
    'gensokyo_main',
    'global',
    'kagerou',
    'bamboo_forest',
    null,
    'character_location_story',
    '今泉 影狼の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '今泉 影狼の会話や振る舞いに関する文脈データです。'),
    0.80,
    now()
  ),
  (
    'chat_context_global_seiran_ringo_lunar',
    'gensokyo_main',
    'global',
    null,
    'lunar_capital',
    null,
    'location_story',
    '月の都に関する場面文脈データです。',
    jsonb_build_object('説明', '月の都に関する場面文脈データです。'),
    0.80,
    now()
  ),
  (
    'chat_context_global_mayumi_beast_realm',
    'gensokyo_main',
    'global',
    'mayumi',
    'beast_realm',
    null,
    'character_location_story',
    '杖刀偶 磨弓の会話や振る舞いに関する文脈データです。',
    jsonb_build_object('説明', '杖刀偶 磨弓の会話や振る舞いに関する文脈データです。'),
    0.81,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

insert into public.world_chronicle_chapters (
  id, book_id, chapter_code, chapter_order, title, summary, period_start, period_end, metadata
)
values
  (
    'chronicle_chapter_regional_customs',
    'chronicle_gensokyo_history',
    'regional_customs',
    10,
    '年代記の章',
    '年代記の章の内容を整理した章説明です。',
    null,
    null,
    '{}'::jsonb
  ),
  (
    'chronicle_chapter_recent_incidents',
    'chronicle_gensokyo_history',
    'recent_incidents_texture',
    11,
    '年代記の章',
    '年代記の章の内容を整理した章説明です。',
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
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body, subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values
  (
    'chronicle_entry_misty_lake_local_calm',
    'chronicle_gensokyo_history',
    'chronicle_chapter_regional_customs',
    'misty_lake_local_calm',
    70,
    'regional_note',
    '霧の湖に関する年代記',
    '霧の湖に関する年代記の記録です。',
    '霧の湖に関する経緯や位置づけを日本語で整理した本文です。',
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
    '迷いの竹林に関する年代記',
    '迷いの竹林に関する年代記の記録です。',
    '迷いの竹林に関する経緯や位置づけを日本語で整理した本文です。',
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
    '月都の下級層に関する年代記',
    '月都の下級層に関する年代記の記録です。',
    '月都の下級層に関する経緯や位置づけを日本語で整理した本文です。',
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
    '畜生界の防衛に関する年代記',
    '畜生界の防衛に関する年代記の記録です。',
    '畜生界の防衛に関する経緯や位置づけを日本語で整理した本文です。',
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
    '霧の湖に関する注記',
    '霧の湖を歴史記録として扱うための補足注記です。',
    '霧の湖に関する記録上の見方や整理方針をまとめた歴史家注記です。',
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
    '迷いの竹林に関する注記',
    '迷いの竹林を歴史記録として扱うための補足注記です。',
    '迷いの竹林に関する記録上の見方や整理方針をまとめた歴史家注記です。',
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
    '月都の下級層に関する注記',
    '月都の下級層を歴史記録として扱うための補足注記です。',
    '月都の下級層に関する記録上の見方や整理方針をまとめた歴史家注記です。',
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
    '畜生界の防衛に関する注記',
    '畜生界の防衛を歴史記録として扱うための補足注記です。',
    '畜生界の防衛に関する記録上の見方や整理方針をまとめた歴史家注記です。',
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





select public.world_refresh_embedding_documents('gensokyo_main');


select public.world_queue_embedding_refresh('gensokyo_main');
