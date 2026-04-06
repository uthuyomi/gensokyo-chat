-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_MINOR.sql
-- World seed: minor and support-cast ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_kisume','gensokyo_main','character','kisume','ability','Kisume''s presentation centers on sudden, narrow-space menace rather than broad territorial control.',jsonb_build_object('ability_theme','ambush_presence'),'src_subterranean_animism','official',66,'["ability","kisume","sa"]'::jsonb),
  ('claim_ability_yamame','gensokyo_main','character','yamame','ability','Yamame is associated with pestilence and the kind of social menace that spreads through networks.',jsonb_build_object('ability_theme','disease_and_network'),'src_subterranean_animism','official',71,'["ability","yamame","sa"]'::jsonb),
  ('claim_ability_parsee','gensokyo_main','character','parsee','ability','Parsee is defined by jealousy and by the emotional charge she brings to crossings and observation.',jsonb_build_object('ability_theme','jealousy'),'src_subterranean_animism','official',73,'["ability","parsee","sa"]'::jsonb),
  ('claim_ability_yuugi','gensokyo_main','character','yuugi','ability','Yuugi embodies immense oni strength backed by social fearlessness rather than hidden method.',jsonb_build_object('ability_theme','oni_strength'),'src_subterranean_animism','official',74,'["ability","yuugi","sa"]'::jsonb),
  ('claim_ability_kyouko','gensokyo_main','character','kyouko','ability','Kyouko is tied to echo and repeated sound, making her useful in scenes of audible presence.',jsonb_build_object('ability_theme','echo'),'src_td','official',67,'["ability","kyouko","td"]'::jsonb),
  ('claim_ability_yoshika','gensokyo_main','character','yoshika','ability','Yoshika is defined by jiang-shi endurance and obedient physical service.',jsonb_build_object('ability_theme','jiangshi_endurance'),'src_td','official',69,'["ability","yoshika","td"]'::jsonb),
  ('claim_ability_shou','gensokyo_main','character','shou','ability','Shou''s authority is framed through Bishamonten imagery, treasure symbolism, and religious power.',jsonb_build_object('ability_theme','avatar_authority'),'src_ufo','official',72,'["ability","shou","ufo"]'::jsonb),
  ('claim_ability_sunny_milk','gensokyo_main','character','sunny_milk','ability','Sunny Milk is associated with bending sunlight and playful concealment through brightness.',jsonb_build_object('ability_theme','light_manipulation'),'src_osp','official',66,'["ability","sunny_milk","fairy"]'::jsonb),
  ('claim_ability_luna_child','gensokyo_main','character','luna_child','ability','Luna Child is associated with silence and reduced sound, giving fairy scenes a stealth component.',jsonb_build_object('ability_theme','silence_field'),'src_osp','official',66,'["ability","luna_child","fairy"]'::jsonb),
  ('claim_ability_star_sapphire','gensokyo_main','character','star_sapphire','ability','Star Sapphire is associated with perceiving the presence of living things, making her a lookout among fairies.',jsonb_build_object('ability_theme','presence_detection'),'src_osp','official',67,'["ability","star_sapphire","fairy"]'::jsonb)
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

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_MINOR.sql

-- BEGIN FILE: WORLD_SEED_WIKI_SUPPORTING_CAST.sql
-- World seed: wiki pages for second-wave supporting cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_yamame','gensokyo_main','characters/yamame-kurodani','Yamame Kurodani','character','character','yamame','An underground spider youkai who gives hidden communities social texture and rumor flow.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_parsee','gensokyo_main','characters/parsee-mizuhashi','Parsee Mizuhashi','character','character','parsee','A bridge guardian whose scenes hinge on jealousy, crossings, and emotional pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_yuugi','gensokyo_main','characters/yuugi-hoshiguma','Yuugi Hoshiguma','character','character','yuugi','An oni of the old capital who makes underground power feel social, convivial, and direct.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kyouko','gensokyo_main','characters/kyouko-kasodani','Kyouko Kasodani','character','character','kyouko','A cheerful temple yamabiko who helps Myouren Temple feel lived in day to day.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_yoshika','gensokyo_main','characters/yoshika-miyako','Yoshika Miyako','character','character','yoshika','A mausoleum retainer who gives hidden political factions visible physical presence.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_shou','gensokyo_main','characters/shou-toramaru','Shou Toramaru','character','character','shou','A temple authority figure tied to Bishamonten imagery, treasure, and duty.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_three_fairies','gensokyo_main','characters/three-fairies-of-light','Three Fairies of Light','group','group','three_fairies_of_light','A recurring fairy trio that makes shrine-side and village-edge daily life feel lively and lightly troublesome.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_yamame:section:overview','wiki_character_yamame','overview',1,'Overview','Yamame as underground social texture.','Yamame is valuable not just as a threat but as proof that the underground has rumor, familiarity, and recurring local society.','["claim_yamame_network_underground","claim_ability_yamame"]'::jsonb,'{}'::jsonb),
  ('wiki_character_parsee:section:overview','wiki_character_parsee','overview',1,'Overview','Parsee as threshold pressure.','Parsee belongs at crossings where passage itself carries resentment, observation, and emotional pressure.','["claim_parsee_threshold_pressure","claim_ability_parsee"]'::jsonb,'{}'::jsonb),
  ('wiki_character_yuugi:section:overview','wiki_character_yuugi','overview',1,'Overview','Yuugi as old-capital power anchor.','Yuugi makes oni power feel sociable and public rather than distant or abstract.','["claim_yuugi_old_capital_anchor","claim_ability_yuugi"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kyouko:section:overview','wiki_character_kyouko','overview',1,'Overview','Kyouko as temple routine voice.','Kyouko helps temple life feel routine, cheerful, and audible beneath larger ideological conflict.','["claim_kyouko_temple_daily_voice","claim_ability_kyouko"]'::jsonb,'{}'::jsonb),
  ('wiki_character_yoshika:section:overview','wiki_character_yoshika','overview',1,'Overview','Yoshika as visible retainer.','Yoshika gives hidden mausoleum politics a body that can carry orders, force, and presence into the scene.','["claim_yoshika_mausoleum_retainer","claim_ability_yoshika"]'::jsonb,'{}'::jsonb),
  ('wiki_character_shou:section:overview','wiki_character_shou','overview',1,'Overview','Shou as temple authority.','Shou is a major support pillar for temple authority and religious symbolism even when she is not the narrative center.','["claim_shou_temple_authority","claim_ability_shou"]'::jsonb,'{}'::jsonb),
  ('wiki_character_three_fairies:section:overview','wiki_character_three_fairies','overview',1,'Overview','The fairy trio as daily-life engine.','Sunny Milk, Luna Child, and Star Sapphire are most useful together as a recurring small-scale engine for mischief, observation, and ordinary atmosphere.','["claim_sunny_daily_fairy","claim_luna_daily_fairy","claim_star_daily_fairy"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_SUPPORTING_CAST.sql

-- BEGIN FILE: WORLD_SEED_CHAT_SUPPORTING_CAST.sql
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

-- END FILE: WORLD_SEED_CHAT_SUPPORTING_CAST.sql

-- BEGIN FILE: WORLD_SEED_BOOK_EPISODES_FAIRIES.sql
-- World seed: fairy and everyday-life printwork patterns

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_book_fairy_everyday','printwork_pattern','Fairy Everyday Pattern','Fairy-centered print works preserve the small-scale, repeated life of shrine edges, seasons, and harmless trouble.',jsonb_build_object('source_cluster',array['src_osp','src_vfi']),'["printwork","fairy","daily_life"]'::jsonb,77),
  ('gensokyo_main','lore_book_tengu_bias','printwork_pattern','Tengu Bias Pattern','Tengu-centered print material should be treated as public narrative shaped by angle, speed, and selective emphasis.',jsonb_build_object('source_cluster',array['src_boaFW','src_alt_truth','src_ds']),'["printwork","tengu","reporting"]'::jsonb,76)
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
  ('claim_book_fairy_everyday','gensokyo_main','printwork','fairy_everyday_cluster','summary','Fairy print works are valuable because they preserve Gensokyo''s low-stakes recurring life rather than only major crisis.',jsonb_build_object('linked_characters',array['sunny_milk','luna_child','star_sapphire','cirno']),'src_vfi','official',78,'["printwork","fairy","summary"]'::jsonb),
  ('claim_book_tengu_bias','gensokyo_main','printwork','tengu_reporting_cluster','summary','Tengu print material should be read as evidence shaped by angle and publicity rather than as neutral record.',jsonb_build_object('linked_characters',array['aya','hatate']),'src_alt_truth','official',77,'["printwork","tengu","summary"]'::jsonb)
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
values
  (
    'chronicle_gensokyo_history:chapter:daily_life',
    'chronicle_gensokyo_history',
    'daily_life',
    4,
    'Ordinary Life and Minor Trouble',
    'A historian''s section for repeated daily-life texture, recurring trouble, and the smaller rhythms that keep Gensokyo inhabited.',
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
  id, book_id, chapter_id, entry_code, entry_order, entry_type, title, summary, body,
  subject_type, subject_id, narrator_character_id, event_id, history_id, tags, metadata
)
values
  (
    'chronicle_entry_fairy_everyday',
    'chronicle_gensokyo_history',
    'chronicle_gensokyo_history:chapter:daily_life',
    'fairy_everyday',
    3,
    'essay',
    'Fairies and the Scale of Ordinary Trouble',
    'A note on why fairy-centered records matter to any honest history of Gensokyo.',
    'A history that remembers only incidents, great leaders, and public crises will miss how Gensokyo actually feels to live in. Fairy records matter because they preserve repetition, atmosphere, petty mischief, and the small disturbances that prove a place is still inhabited between larger upheavals.',
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
  ('chronicle_entry_fairy_everyday:src:claim','chronicle_entry_fairy_everyday','canon_claim','claim_book_fairy_everyday','Fairy Everyday Pattern',0.86,'Ordinary atmosphere and repeated life'),
  ('chronicle_entry_fairy_everyday:src:lore','chronicle_entry_fairy_everyday','lore','lore_book_fairy_everyday','Fairy Everyday Lore',0.82,'Small-scale recurring texture')
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_ref_id = excluded.source_ref_id,
    source_label = excluded.source_label,
    weight = excluded.weight,
    notes = excluded.notes;

-- END FILE: WORLD_SEED_BOOK_EPISODES_FAIRIES.sql

-- BEGIN FILE: WORLD_SEED_CHARACTERS_SUPPORTING_CAST_C.sql
-- World seed: third wave of supporting cast from early recurring nocturnal and local layers

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','rumia','Rumia','Youkai of Darkness','youkai','independent',
    'misty_lake','misty_lake',
    'A darkness youkai suited to small nighttime trouble, light obstruction, and low-level youkai presence.',
    'Best used to give early-route nights a face rather than to carry major ideology.',
    'simple, playful, hungry',
    'If you cannot see clearly, the world belongs to whoever is nearby.',
    'night_local',
    '["eosd","night","local"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['night_routes','minor_trouble'], 'temperament', 'playful')
  ),
  (
    'gensokyo_main','mystia','Mystia Lorelei','Night Sparrow','sparrow_youkai','independent',
    'human_village','human_village',
    'A singer and food-seller whose scenes fit nocturnal commerce, music, and charming danger at the village edge.',
    'Useful for making night life feel commercial and social rather than empty.',
    'cheerful, musical, opportunistic',
    'If people gather to eat and listen, the night has already become livable.',
    'night_vendor',
    '["in","night","music","food"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['night_stalls','song','village_edges'], 'temperament', 'cheerful')
  ),
  (
    'gensokyo_main','wriggle','Wriggle Nightbug','Firefly Youkai','insect_youkai','independent',
    'human_village','human_village',
    'An insect youkai suited to summer-night texture, small collective pressure, and overlooked local presence.',
    'Useful where the night should feel alive in a low, swarming register rather than through single grand actors.',
    'earnest, prickly, lively',
    'Small lives add up faster than people expect.',
    'night_local',
    '["in","night","summer","insects"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['summer_nights','small_collectives'], 'temperament', 'prickly')
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

-- END FILE: WORLD_SEED_CHARACTERS_SUPPORTING_CAST_C.sql

-- BEGIN FILE: WORLD_SEED_RELATIONSHIPS_SUPPORTING_CAST_C.sql
-- World seed: third supporting-cast relationship layer

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','rumia','cirno','minor_chaos_overlap','Rumia and Cirno both help early Gensokyo feel dangerous in small, unserious, recurring ways.',0.26,'{}'::jsonb),
  ('gensokyo_main','mystia','keine','night_village_overlap','Mystia''s night-vendor role and Keine''s village-guardian role naturally intersect at the edge of human nighttime life.',0.41,'{}'::jsonb),
  ('gensokyo_main','mystia','wriggle','night_creature_peer','Mystia and Wriggle make summer-night scenes feel inhabited by more than one kind of local actor.',0.46,'{}'::jsonb),
  ('gensokyo_main','wriggle','cirno','seasonal_smallscale','Wriggle and Cirno connect through small-scale seasonal trouble rather than public incident leadership.',0.28,'{}'::jsonb),
  ('gensokyo_main','rumia','reimu','minor_incident_target','Rumia is the sort of small recurring night problem Reimu should be able to brush aside without escalating the world.',0.35,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_RELATIONSHIPS_SUPPORTING_CAST_C.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_SUPPORTING_CAST_C.sql
-- World seed: third supporting-cast claims and lore

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_supporting_cast_night_life','daily_life_texture','Night-Life Supporting Texture','Night in Gensokyo should feel occupied by singers, small predators, insects, and local trouble rather than becoming empty stage space.',jsonb_build_object('focus','nighttime_local_life'),'["supporting_cast","night","daily_life"]'::jsonb,73)
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
  ('claim_rumia_minor_night_threat','gensokyo_main','character','rumia','role','Rumia is best used as a small but recurring night-route threat, not a structural-scale planner.',jsonb_build_object('role','night_local'),'src_eosd','official',63,'["rumia","eosd","night"]'::jsonb),
  ('claim_mystia_night_vendor','gensokyo_main','character','mystia','role','Mystia is especially valuable where song, food, and dangerous charm make the night socially active.',jsonb_build_object('role','night_vendor'),'src_imperishable_night','official',69,'["mystia","in","night"]'::jsonb),
  ('claim_wriggle_small_collective_night','gensokyo_main','character','wriggle','role','Wriggle gives summer-night scenes a smaller-scale collective pressure tied to insects and overlooked life.',jsonb_build_object('role','night_local'),'src_imperishable_night','official',67,'["wriggle","in","summer"]'::jsonb)
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

-- END FILE: WORLD_SEED_CLAIMS_SUPPORTING_CAST_C.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_NIGHT.sql
-- World seed: night-life support cast ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_rumia','gensokyo_main','character','rumia','ability','Rumia is defined by darkness and by obstructing ordinary visibility in close-range scenes.',jsonb_build_object('ability_theme','darkness_manipulation'),'src_eosd','official',67,'["ability","rumia","eosd"]'::jsonb),
  ('claim_ability_mystia','gensokyo_main','character','mystia','ability','Mystia is associated with song, night-sparrow danger, and forms of confusion tied to nighttime travel.',jsonb_build_object('ability_theme','night_song_and_confusion'),'src_imperishable_night','official',71,'["ability","mystia","in"]'::jsonb),
  ('claim_ability_wriggle','gensokyo_main','character','wriggle','ability','Wriggle is associated with insects and the collective force of small life in summer-night scenes.',jsonb_build_object('ability_theme','insect_command'),'src_imperishable_night','official',69,'["ability","wriggle","in"]'::jsonb)
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

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_NIGHT.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_SUPPORTING_CAST_C.sql
-- World seed: wiki and chat support for third-wave night-life cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_rumia','gensokyo_main','characters/rumia','Rumia','character','character','rumia','A minor darkness youkai who helps early-night Gensokyo feel occupied and dangerous at a small scale.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_mystia','gensokyo_main','characters/mystia-lorelei','Mystia Lorelei','character','character','mystia','A night sparrow whose song, food, and danger make Gensokyo''s night life feel social.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_wriggle','gensokyo_main','characters/wriggle-nightbug','Wriggle Nightbug','character','character','wriggle','An insect youkai who gives summer-night scenes small-scale collective presence.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_rumia:section:overview','wiki_character_rumia','overview',1,'Overview','Rumia as local night trouble.','Rumia is best framed as recurring low-scale darkness trouble that gives nighttime routes a face without demanding structural-scale plotting.','["claim_rumia_minor_night_threat","claim_ability_rumia"]'::jsonb,'{}'::jsonb),
  ('wiki_character_mystia:section:overview','wiki_character_mystia','overview',1,'Overview','Mystia as night-life vendor.','Mystia makes the night socially inhabited through song, food, and a danger level that feels charming before it feels strategic.','["claim_mystia_night_vendor","claim_ability_mystia"]'::jsonb,'{}'::jsonb),
  ('wiki_character_wriggle:section:overview','wiki_character_wriggle','overview',1,'Overview','Wriggle as summer-night collective presence.','Wriggle helps scenes feel crowded by small life, making nights feel active even when no major actor is present.','["claim_wriggle_small_collective_night","claim_ability_wriggle"]'::jsonb,'{}'::jsonb)
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
    'Rumia should sound simple and casually troublesome, like darkness is a game until someone else trips over it.',
    jsonb_build_object(
      'speech_style', 'simple, playful, hungry',
      'worldview', 'If the dark works, there is no reason to explain it much.',
      'claim_ids', array['claim_rumia_minor_night_threat','claim_ability_rumia']
    ),
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
    'Mystia should sound musical and inviting, with danger wrapped in the tone of a lively night stall.',
    jsonb_build_object(
      'speech_style', 'cheerful, musical, inviting',
      'worldview', 'A good night should feed people before it frightens them away.',
      'claim_ids', array['claim_mystia_night_vendor','claim_ability_mystia']
    ),
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
    'Wriggle should sound earnest and slightly prickly, with a sense that small lives count even when others dismiss them.',
    jsonb_build_object(
      'speech_style', 'earnest, prickly, lively',
      'worldview', 'Being overlooked does not make something unimportant.',
      'claim_ids', array['claim_wriggle_small_collective_night','claim_ability_wriggle']
    ),
    0.83,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_SUPPORTING_CAST_C.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_REGIONAL_CULTURES.sql
-- World seed: regional culture and atmosphere glossary

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_regional_old_capital','regional_culture','Old Capital Culture','The Old Capital should read as a sociable oni sphere where strength, drinking, and public challenge carry cultural legitimacy.',jsonb_build_object('location_id','old_capital'),'["region","old_capital","oni"]'::jsonb,79),
  ('gensokyo_main','lore_regional_former_hell','regional_culture','Former Hell Route Culture','Former Hell is not only a hazard zone. It is a layered passage network where small actors, thresholds, and local rumor matter.',jsonb_build_object('location_id','former_hell'),'["region","former_hell","routes"]'::jsonb,78),
  ('gensokyo_main','lore_regional_myouren_temple','regional_culture','Myouren Temple Daily Culture','Myouren Temple should feel like a lived religious institution with discipline, routine, and coexistence-minded public structure.',jsonb_build_object('location_id','myouren_temple'),'["region","myouren_temple","daily_life"]'::jsonb,80),
  ('gensokyo_main','lore_regional_night_village_edges','regional_culture','Village-Edge Night Culture','The edges of the Human Village at night should feel commercial, musical, and just dangerous enough to remain memorable.',jsonb_build_object('location_id','human_village'),'["region","night","village"]'::jsonb,77),
  ('gensokyo_main','lore_regional_shrine_fairy_life','regional_culture','Shrine Fairy Daily Culture','Hakurei Shrine should sometimes feel inhabited by repeated low-stakes fairy trouble rather than only by major incident traffic.',jsonb_build_object('location_id','hakurei_shrine'),'["region","fairy","shrine"]'::jsonb,76)
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
  ('claim_regional_old_capital_culture','gensokyo_main','location','old_capital','setting','The Old Capital should be framed as a sociable oni culture rather than only a dangerous underground landmark.',jsonb_build_object('culture','oni_public_life'),'src_subterranean_animism','official',78,'["old_capital","culture","oni"]'::jsonb),
  ('claim_regional_former_hell_routes','gensokyo_main','location','former_hell','setting','Former Hell should be treated as a route network with thresholds and local actors, not empty travel space.',jsonb_build_object('culture','layered_route_network'),'src_subterranean_animism','official',77,'["former_hell","routes","culture"]'::jsonb),
  ('claim_regional_myouren_daily_life','gensokyo_main','location','myouren_temple','setting','Myouren Temple has daily institutional life beyond major public declarations and incident peaks.',jsonb_build_object('culture','lived_religious_institution'),'src_ufo','official',79,'["myouren_temple","culture","daily_life"]'::jsonb),
  ('claim_regional_village_night_life','gensokyo_main','location','human_village','setting','The village edge at night should feel socially active through song, food, rumor, and small risk.',jsonb_build_object('culture','night_commerce'),'src_imperishable_night','official',75,'["human_village","night","culture"]'::jsonb),
  ('claim_regional_shrine_fairy_life','gensokyo_main','location','hakurei_shrine','setting','Hakurei Shrine should periodically read as a stage for recurring fairy-scale trouble and seasonal silliness.',jsonb_build_object('culture','fairy_daily_life'),'src_osp','official',74,'["hakurei_shrine","fairy","culture"]'::jsonb)
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

-- END FILE: WORLD_SEED_GLOSSARY_REGIONAL_CULTURES.sql

-- BEGIN FILE: WORLD_SEED_WIKI_REGIONAL_CULTURES.sql
-- World seed: wiki and chat support for regional cultures

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_region_old_capital_culture','gensokyo_main','regions/old-capital-culture','Old Capital Culture','glossary','location','old_capital','A culture page for oni public life, drinking, and challenge in the Old Capital.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_region_myouren_daily_life','gensokyo_main','regions/myouren-daily-life','Myouren Temple Daily Life','glossary','location','myouren_temple','A culture page for routine temple life, coexistence, and lived religious practice.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_region_village_night_life','gensokyo_main','regions/village-night-life','Village-Edge Night Life','glossary','location','human_village','A culture page for song, food, rumor, and danger at the night edge of the village.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_region_old_capital_culture:section:overview','wiki_region_old_capital_culture','overview',1,'Overview','Old Capital as sociable oni sphere.','The Old Capital should feel loud, public, and convivial, with power displayed through social life rather than hidden behind it.','["claim_regional_old_capital_culture","lore_regional_old_capital"]'::jsonb,'{}'::jsonb),
  ('wiki_region_myouren_daily_life:section:overview','wiki_region_myouren_daily_life','overview',1,'Overview','Myouren Temple as lived institution.','Myouren Temple is strongest as a setting when discipline, routine, care, and coexistence all feel present beneath larger doctrinal conflict.','["claim_regional_myouren_daily_life","lore_regional_myouren_temple"]'::jsonb,'{}'::jsonb),
  ('wiki_region_village_night_life:section:overview','wiki_region_village_night_life','overview',1,'Overview','Night culture at the village edge.','The village at night should read as a space of food, song, rumor, and manageable danger rather than becoming empty after dark.','["claim_regional_village_night_life","lore_regional_night_village_edges"]'::jsonb,'{}'::jsonb)
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
    'Old Capital scenes should feel public, strong, and convivial rather than merely hazardous.',
    jsonb_build_object(
      'default_mood', 'boisterous',
      'claim_ids', array['claim_regional_old_capital_culture']
    ),
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
    'Myouren Temple scenes should feel lived in by routine, discipline, and coexistence-minded order.',
    jsonb_build_object(
      'default_mood', 'orderly',
      'claim_ids', array['claim_regional_myouren_daily_life']
    ),
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
    'At night, the village edge should feel social and slightly risky rather than empty.',
    jsonb_build_object(
      'default_mood', 'lively_after_dark',
      'claim_ids', array['claim_regional_village_night_life']
    ),
    0.83,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_REGIONAL_CULTURES.sql

-- BEGIN FILE: WORLD_SEED_SOURCES_LATE_PRINT.sql
-- World seed: additional late print-work sources

insert into public.world_source_index (
  id, world_id, source_kind, source_code, title, short_label, notes, metadata
)
values
  ('src_le','gensokyo_main','official_book','le','Lotus Eaters','LE','Print work source for Miyoi, tavern culture, and after-hours social texture in Gensokyo.','{}'::jsonb),
  ('src_fds','gensokyo_main','official_book','fds','Foul Detective Satori','FDS','Print work source for Mizuchi, possession-linked mystery structure, and later-era incident investigation.','{}'::jsonb)
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_code = excluded.source_code,
    title = excluded.title,
    short_label = excluded.short_label,
    notes = excluded.notes,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_SOURCES_LATE_PRINT.sql

-- BEGIN FILE: WORLD_SEED_CHARACTERS_LUNAR_PRINT.sql
-- World seed: lunar and late print-work support characters

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','toyohime','Watatsuki no Toyohime','Lunar Noble','lunarian','lunar_capital',
    'lunar_capital','lunar_capital',
    'A lunar noble suited to high-level moon politics, elegance, and strategic superiority framed as natural order.',
    'Best used when the lunar side needs composed authority rather than raw aggression.',
    'graceful, superior, composed',
    'Refinement and control are easiest to maintain when treated as normal.',
    'lunar_elite',
    '["ssib","moon","nobility"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['lunar_politics','moon_earth_relations'], 'temperament', 'composed')
  ),
  (
    'gensokyo_main','yorihime','Watatsuki no Yorihime','Lunar Noble and Divine Summoner','lunarian','lunar_capital',
    'lunar_capital','lunar_capital',
    'A lunar noble whose role fits martial authority, divine invocation, and uncompromising lunar standards.',
    'Useful where the moon needs force backed by legitimacy rather than mere temperament.',
    'formal, severe, disciplined',
    'Authority is easiest to respect when it never blinks first.',
    'lunar_martial_elite',
    '["ssib","moon","military"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['lunar_security','divine_authority'], 'temperament', 'severe')
  ),
  (
    'gensokyo_main','miyoi','Okunoda Miyoi','Geidontei Poster Girl','zashiki_warashi_like','independent',
    'human_village','human_village',
    'A tavern-linked hostess suited to after-hours village life, drinking culture, and the softer side of recurring social scenes.',
    'Best used where Gensokyo needs nightlife, hospitality, and gossip without turning everything into formal incident structure.',
    'gentle, attentive, warm',
    'People speak differently once they think the day is over.',
    'night_hospitality',
    '["le","village","tavern"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['village_nightlife','tavern_customs'], 'temperament', 'warm')
  ),
  (
    'gensokyo_main','mizuchi','Mizuchi Miyadeguchi','Vengeful Spirit in Hiding','vengeful_spirit','independent',
    'human_village','human_village',
    'A hidden vengeful spirit suited to possession, resentment, and the destabilization of ordinary social surfaces.',
    'Useful when later-era mysteries need a threat that moves through people rather than simply confronting them.',
    'cold, quiet, resentful',
    'A quiet grudge can travel farther than an open shout.',
    'hidden_threat',
    '["fds","vengeful_spirit","mystery"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['hidden_possession','resentment_routes'], 'temperament', 'cold')
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

-- END FILE: WORLD_SEED_CHARACTERS_LUNAR_PRINT.sql

-- BEGIN FILE: WORLD_SEED_RELATIONSHIPS_LUNAR_PRINT.sql
-- World seed: lunar and late print-work support relationships

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','toyohime','yorihime','lunar_sibling_rule','Toyohime and Yorihime together make lunar rule feel aristocratic, coordinated, and difficult to casually breach.',0.86,'{}'::jsonb),
  ('gensokyo_main','toyohime','sagume','lunar_high_command','Toyohime and Sagume occupy the same upper air of lunar political seriousness from different angles.',0.49,'{}'::jsonb),
  ('gensokyo_main','yorihime','eirin','lunar_old_order','Yorihime and Eirin help make lunar history feel like a living political continuity.',0.52,'{}'::jsonb),
  ('gensokyo_main','miyoi','mystia','night_hospitality_overlap','Miyoi and Mystia both help make Gensokyo night life feel social, but through different kinds of invitation.',0.38,'{}'::jsonb),
  ('gensokyo_main','miyoi','suika','drinking_scene_overlap','Miyoi and Suika naturally overlap in scenes where drinking turns into revelation, looseness, or trouble.',0.44,'{}'::jsonb),
  ('gensokyo_main','mizuchi','satori','mystery_investigation_axis','Mizuchi and Satori create later-era mystery structure through hidden motive, possession, and mental pressure.',0.55,'{}'::jsonb),
  ('gensokyo_main','mizuchi','reimu','hidden_incident_target','Mizuchi belongs in the class of hidden trouble that forces even familiar protectors to re-evaluate ordinary surfaces.',0.41,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_RELATIONSHIPS_LUNAR_PRINT.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_LUNAR_PRINT.sql
-- World seed: lunar and late print-work support claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_lunar_nobility_texture','world_rule','Lunar Nobility Texture','The moon should feel politically stratified, ceremonially confident, and structurally separate from ordinary Gensokyo life.',jsonb_build_object('focus','lunar_elite'),'["moon","nobility","texture"]'::jsonb,82),
  ('gensokyo_main','lore_village_afterhours_texture','daily_life_texture','Village After-Hours Texture','The village after dark should include drink, relief, gossip, and lowered guard rather than simply closing down.',jsonb_build_object('focus','night_hospitality'),'["village","night","tavern"]'::jsonb,78),
  ('gensokyo_main','lore_hidden_possession_texture','incident_pattern','Hidden Possession Texture','Some later incidents should work through hidden resentment and infiltration rather than immediate open confrontation.',jsonb_build_object('focus','hidden_possession'),'["mystery","possession","late_era"]'::jsonb,79)
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
  ('claim_toyohime_lunar_noble','gensokyo_main','character','toyohime','role','Toyohime should be treated as high lunar nobility whose ease and elegance come from structural superiority, not casual softness.',jsonb_build_object('role','lunar_elite'),'src_ssib','official',75,'["toyohime","moon","role"]'::jsonb),
  ('claim_yorihime_lunar_martial_elite','gensokyo_main','character','yorihime','role','Yorihime represents disciplined lunar force and standards that ordinary Gensokyo actors cannot casually equal.',jsonb_build_object('role','lunar_martial_elite'),'src_ssib','official',77,'["yorihime","moon","role"]'::jsonb),
  ('claim_miyoi_night_hospitality','gensokyo_main','character','miyoi','role','Miyoi is best used to show hospitality, drink, and after-hours social texture in the village rather than overt public power.',jsonb_build_object('role','night_hospitality'),'src_le','official',72,'["miyoi","night","village"]'::jsonb),
  ('claim_mizuchi_hidden_possession','gensokyo_main','character','mizuchi','role','Mizuchi belongs to hidden-possession and resentment-driven mystery structures rather than loud public declaration.',jsonb_build_object('role','hidden_threat'),'src_fds','official',74,'["mizuchi","mystery","possession"]'::jsonb),
  ('claim_lunar_nobility_culture','gensokyo_main','world','gensokyo_main','world_rule','Lunar nobility should be framed as a distinct political-cultural layer, not simply as stronger versions of ordinary locals.',jsonb_build_object('scope','lunar_capital'),'src_ciLR','official',80,'["moon","culture","rule"]'::jsonb)
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

-- END FILE: WORLD_SEED_CLAIMS_LUNAR_PRINT.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_LUNAR_PRINT.sql
-- World seed: lunar and late print-work support ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_toyohime','gensokyo_main','character','toyohime','ability','Toyohime is associated with high lunar mobility and composure-backed superiority rather than brute display.',jsonb_build_object('ability_theme','lunar_transport_and_grace'),'src_ssib','official',73,'["ability","toyohime","moon"]'::jsonb),
  ('claim_ability_yorihime','gensokyo_main','character','yorihime','ability','Yorihime is associated with divine invocation and overwhelming formal combat authority.',jsonb_build_object('ability_theme','divine_summoning'),'src_ssib','official',78,'["ability","yorihime","moon"]'::jsonb),
  ('claim_ability_miyoi','gensokyo_main','character','miyoi','ability','Miyoi is tied to the strange hospitality and soft unreality of after-hours tavern scenes.',jsonb_build_object('ability_theme','hospitality_and_night_unreality'),'src_le','official',69,'["ability","miyoi","nightlife"]'::jsonb),
  ('claim_ability_mizuchi','gensokyo_main','character','mizuchi','ability','Mizuchi is associated with hidden possession, grudge persistence, and indirect destabilization.',jsonb_build_object('ability_theme','possession_and_grudge'),'src_fds','official',75,'["ability","mizuchi","mystery"]'::jsonb)
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

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_LUNAR_PRINT.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_LUNAR_PRINT.sql
-- World seed: wiki and chat support for lunar and late print-work support cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_toyohime','gensokyo_main','characters/watatsuki-no-toyohime','Watatsuki no Toyohime','character','character','toyohime','A lunar noble whose role centers on composed superiority and high political standing on the moon.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_yorihime','gensokyo_main','characters/watatsuki-no-yorihime','Watatsuki no Yorihime','character','character','yorihime','A lunar noble and martial authority whose force is backed by severe legitimacy.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_miyoi','gensokyo_main','characters/okunoda-miyoi','Okunoda Miyoi','character','character','miyoi','A tavern hostess who gives Gensokyo after-hours life warmth, gossip, and soft instability.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_mizuchi','gensokyo_main','characters/mizuchi-miyadeguchi','Mizuchi Miyadeguchi','character','character','mizuchi','A hidden vengeful spirit whose role depends on possession, resentment, and mystery pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_lunar_nobility','gensokyo_main','terms/lunar-nobility','Lunar Nobility','glossary','term','lunar_nobility','A glossary page for aristocratic lunar authority and political-cultural distance from Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_toyohime:section:overview','wiki_character_toyohime','overview',1,'Overview','Toyohime as lunar aristocratic ease.','Toyohime is useful where lunar politics should feel graceful, confident, and structurally above ordinary Gensokyo friction.','["claim_toyohime_lunar_noble","claim_ability_toyohime"]'::jsonb,'{}'::jsonb),
  ('wiki_character_yorihime:section:overview','wiki_character_yorihime','overview',1,'Overview','Yorihime as severe lunar force.','Yorihime gives the moon disciplined force backed by legitimacy rather than mere aggression.','["claim_yorihime_lunar_martial_elite","claim_ability_yorihime"]'::jsonb,'{}'::jsonb),
  ('wiki_character_miyoi:section:overview','wiki_character_miyoi','overview',1,'Overview','Miyoi as after-hours hospitality.','Miyoi helps the village at night feel warm, social, and slightly unreal once formality drops away.','["claim_miyoi_night_hospitality","claim_ability_miyoi"]'::jsonb,'{}'::jsonb),
  ('wiki_character_mizuchi:section:overview','wiki_character_mizuchi','overview',1,'Overview','Mizuchi as hidden resentment.','Mizuchi is strongest in stories where possession and grudge travel under ordinary surfaces before becoming visible.','["claim_mizuchi_hidden_possession","claim_ability_mizuchi"]'::jsonb,'{}'::jsonb),
  ('wiki_term_lunar_nobility:section:definition','wiki_term_lunar_nobility','definition',1,'Definition','Lunar nobility as distinct political culture.','Lunar nobility should be read as a separate political and ceremonial layer whose standards differ sharply from ordinary Gensokyo practice.','["claim_lunar_nobility_culture","lore_lunar_nobility_texture"]'::jsonb,'{}'::jsonb)
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
    'Toyohime should sound graceful and composed, as if superiority is less a boast than an environmental assumption.',
    jsonb_build_object(
      'speech_style', 'graceful, composed, superior',
      'worldview', 'Order is easiest to preserve when one never has to doubt one''s station.',
      'claim_ids', array['claim_toyohime_lunar_noble','claim_ability_toyohime']
    ),
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
    'Yorihime should sound formal and severe, with authority resting on discipline rather than theatricality.',
    jsonb_build_object(
      'speech_style', 'formal, severe, disciplined',
      'worldview', 'Standards are not meaningful if lowered for convenience.',
      'claim_ids', array['claim_yorihime_lunar_martial_elite','claim_ability_yorihime']
    ),
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
    'Miyoi should sound warm and attentive, like she notices when people begin speaking more honestly than they meant to.',
    jsonb_build_object(
      'speech_style', 'gentle, attentive, warm',
      'worldview', 'People reveal a great deal once they think the night belongs to them.',
      'claim_ids', array['claim_miyoi_night_hospitality','claim_ability_miyoi']
    ),
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
    'Mizuchi should sound cold and contained, like resentment has already outlived the need to be loud.',
    jsonb_build_object(
      'speech_style', 'cold, quiet, resentful',
      'worldview', 'What stays hidden longest often changes the most before anyone notices.',
      'claim_ids', array['claim_mizuchi_hidden_possession','claim_ability_mizuchi']
    ),
    0.86,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_LUNAR_PRINT.sql

-- BEGIN FILE: WORLD_SEED_BOOK_EPISODES_LUNAR_PRINT.sql
-- World seed: lunar and late print-work episode patterns

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_book_lotus_eaters','printwork_pattern','Lotus Eaters Pattern','Lotus Eaters preserves Gensokyo after-hours social life through drink, loosened talk, and recurring hospitality.',jsonb_build_object('source','le'),'["printwork","le","nightlife"]'::jsonb,79),
  ('gensokyo_main','lore_book_foul_detective_satori','printwork_pattern','Foul Detective Satori Pattern','Foul Detective Satori works through hidden motive, investigation, and possession-linked mystery under ordinary surfaces.',jsonb_build_object('source','fds'),'["printwork","fds","mystery"]'::jsonb,80),
  ('gensokyo_main','lore_book_lunar_expedition','printwork_pattern','Lunar Expedition Pattern','Moon-expedition print works preserve the political distance, ceremony, and asymmetry of the lunar sphere.',jsonb_build_object('source_cluster',array['src_ssib','src_ciLR']),'["printwork","moon","politics"]'::jsonb,81)
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
  ('claim_book_lotus_eaters','gensokyo_main','printwork','lotus_eaters','summary','Lotus Eaters is valuable for tavern culture, after-hours speech, and the softer structures of social life in Gensokyo.',jsonb_build_object('linked_characters',array['miyoi','suika','marisa','reimu']),'src_le','official',79,'["printwork","le","summary"]'::jsonb),
  ('claim_book_foul_detective_satori','gensokyo_main','printwork','foul_detective_satori','summary','Foul Detective Satori preserves later-era possession mystery structure and hidden resentment beneath ordinary life.',jsonb_build_object('linked_characters',array['satori','mizuchi','reimu']),'src_fds','official',80,'["printwork","fds","summary"]'::jsonb),
  ('claim_book_lunar_expedition','gensokyo_main','printwork','lunar_expedition_cluster','summary','Lunar expedition works are key for treating the moon as a distinct political sphere rather than merely a distant backdrop.',jsonb_build_object('linked_characters',array['toyohime','yorihime','eirin','reisen']),'src_ssib','official',81,'["printwork","moon","summary"]'::jsonb)
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

-- END FILE: WORLD_SEED_BOOK_EPISODES_LUNAR_PRINT.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_TERMS_B.sql
-- World seed: second wave of recurring world terms

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_term_faith_economy','term','Faith Economy','Faith in Gensokyo is not only belief. It also functions as a practical resource tied to legitimacy, public support, and shrine-side competition.',jsonb_build_object('domain','religion_and_power'),'["term","faith","economy"]'::jsonb,80),
  ('gensokyo_main','lore_term_perfect_possession','term','Perfect Possession','Perfect possession should be treated as a destabilizing pairing logic that scrambles ordinary boundaries of agency and combat.',jsonb_build_object('domain','possession_incidents'),'["term","possession","incident"]'::jsonb,79),
  ('gensokyo_main','lore_term_outside_world_leakage','term','Outside-World Leakage','The Outside World affects Gensokyo less through direct replacement than through leakage of rumor forms, objects, and explanatory frames.',jsonb_build_object('domain','boundary_and_modernity'),'["term","outside_world","leakage"]'::jsonb,81),
  ('gensokyo_main','lore_term_animal_spirits','term','Animal Spirits','Animal spirits should be read as political and factional actors of the Beast Realm, not mere ambient monsters.',jsonb_build_object('domain','beast_realm_politics'),'["term","animal_spirits","beast_realm"]'::jsonb,78),
  ('gensokyo_main','lore_term_market_cards','term','Ability Cards','The ability-card economy turns power into circulation, collection, and market pressure rather than purely personal training.',jsonb_build_object('domain','market_incident'),'["term","ability_cards","market"]'::jsonb,80)
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
  ('claim_term_faith_economy','gensokyo_main','term','faith_economy','definition','Faith should be treated as a practical political resource in shrine-centered competition, not only as private devotion.',jsonb_build_object('related_locations',array['hakurei_shrine','moriya_shrine']),'src_mofa','official',81,'["term","faith","economy"]'::jsonb),
  ('claim_term_perfect_possession','gensokyo_main','term','perfect_possession','definition','Perfect possession destabilizes ordinary agency by forcing pair-logic and layered control into conflict and identity.',jsonb_build_object('related_incident','incident_perfect_possession'),'src_aocf','official',79,'["term","possession","aocf"]'::jsonb),
  ('claim_term_outside_world_leakage','gensokyo_main','term','outside_world_leakage','definition','Outside-world influence usually enters Gensokyo through leakage of forms, rumors, and objects rather than clean transplantation.',jsonb_build_object('related_incident','incident_urban_legends'),'src_ulil','official',82,'["term","outside_world","leakage"]'::jsonb),
  ('claim_term_animal_spirits','gensokyo_main','term','animal_spirits','definition','Animal spirits are factional political actors tied to the Beast Realm and its proxy conflicts.',jsonb_build_object('related_location','beast_realm'),'src_wbawc','official',78,'["term","animal_spirits","politics"]'::jsonb),
  ('claim_term_market_cards','gensokyo_main','term','ability_cards','definition','Ability cards convert power into a market-circulation problem, not just a combat option.',jsonb_build_object('related_incident','incident_market_cards'),'src_um','official',80,'["term","ability_cards","market"]'::jsonb)
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

-- END FILE: WORLD_SEED_GLOSSARY_TERMS_B.sql

-- BEGIN FILE: WORLD_SEED_WIKI_TERMS_B.sql
-- World seed: second wave of glossary wiki pages and sections

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_faith_economy','gensokyo_main','terms/faith-economy','Faith Economy','glossary','term','faith_economy','A glossary page for faith as public resource, legitimacy, and competition.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_perfect_possession','gensokyo_main','terms/perfect-possession','Perfect Possession','glossary','term','perfect_possession','A glossary page for layered agency, possession pairings, and destabilized conflict structure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_outside_world_leakage','gensokyo_main','terms/outside-world-leakage','Outside-World Leakage','glossary','term','outside_world_leakage','A glossary page for how outside-world ideas and objects seep into Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_animal_spirits','gensokyo_main','terms/animal-spirits','Animal Spirits','glossary','term','animal_spirits','A glossary page for Beast Realm-aligned spirits as factional actors.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_ability_cards','gensokyo_main','terms/ability-cards','Ability Cards','glossary','term','ability_cards','A glossary page for power as market circulation and collected commodity.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_term_faith_economy:section:definition','wiki_term_faith_economy','definition',1,'Definition','Faith as resource and legitimacy.','In Gensokyo, faith operates as public support, institutional legitimacy, and practical religious capital rather than only inward belief.','["claim_term_faith_economy","lore_term_faith_economy"]'::jsonb,'{}'::jsonb),
  ('wiki_term_perfect_possession:section:definition','wiki_term_perfect_possession','definition',1,'Definition','Perfect possession as layered agency.','Perfect possession is a destabilizing logic in which control, combat, and identity become paired and partially displaced across actors.','["claim_term_perfect_possession","lore_term_perfect_possession"]'::jsonb,'{}'::jsonb),
  ('wiki_term_outside_world_leakage:section:definition','wiki_term_outside_world_leakage','definition',1,'Definition','Outside influence as leakage.','Outside-world influence is strongest when it enters Gensokyo through rumor, objects, and explanatory patterns rather than simple replacement.','["claim_term_outside_world_leakage","lore_term_outside_world_leakage"]'::jsonb,'{}'::jsonb),
  ('wiki_term_animal_spirits:section:definition','wiki_term_animal_spirits','definition',1,'Definition','Animal spirits as factional actors.','Animal spirits should be understood through Beast Realm politics, proxy struggle, and organized factional pressure.','["claim_term_animal_spirits","lore_term_animal_spirits"]'::jsonb,'{}'::jsonb),
  ('wiki_term_ability_cards:section:definition','wiki_term_ability_cards','definition',1,'Definition','Ability cards as marketized power.','Ability cards make power circulate as commodity, collection, and market leverage rather than remaining only personal technique.','["claim_term_market_cards","lore_term_market_cards"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_TERMS_B.sql

-- BEGIN FILE: WORLD_SEED_INCIDENT_BEATS_EXPANDED.sql
-- World seed: finer-grained incident chronology and historian notes

insert into public.world_story_events (
  id, world_id, event_code, title, theme, canon_level, status,
  start_at, end_at, current_phase_id, current_phase_order,
  lead_location_id, organizer_character_id, synopsis, narrative_hook, payload, metadata
)
values
  (
    'story_incident_scarlet_mist_archive',
    'gensokyo_main',
    'incident_scarlet_mist_archive',
    'Scarlet Mist Incident Archive',
    'Archival record for the scarlet mist incident and its long tail.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'scarlet_devil_mansion',
    'reimu',
    'An archival event container for scarlet mist aftereffects and historical reference.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','scarlet_mist','archive',true),
    '{}'::jsonb
  ),
  (
    'story_incident_faith_shift_archive',
    'gensokyo_main',
    'incident_faith_shift_archive',
    'Mountain Faith Shift Archive',
    'Archival record for the mountain-faith power shift and later institutional consequences.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'moriya_shrine',
    'reimu',
    'An archival event container for faith-shift aftereffects and historical reference.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','faith_shift','archive',true),
    '{}'::jsonb
  ),
  (
    'story_incident_perfect_possession_archive',
    'gensokyo_main',
    'incident_perfect_possession_archive',
    'Perfect Possession Archive',
    'Archival record for perfect possession and split-agency aftereffects.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'human_village',
    'reimu',
    'An archival event container for perfect possession aftereffects and historical reference.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','perfect_possession','archive',true),
    '{}'::jsonb
  ),
  (
    'story_incident_market_cards_archive',
    'gensokyo_main',
    'incident_market_cards_archive',
    'Ability Card Market Archive',
    'Archival record for the ability-card affair and its market aftereffects.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'rainbow_dragon_cave',
    'marisa',
    'An archival event container for market-card aftereffects and historical reference.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','market_cards','archive',true),
    '{}'::jsonb
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
    'The scarlet mist incident forced a public reaffirmation that major distortions of daily life trigger direct response from incident-resolving actors.',
    'scarlet_devil_mansion',
    '["reimu","marisa","remilia","sakuya"]'::jsonb,
    jsonb_build_object(
      'incident_key','scarlet_mist',
      'beat','resolution_pattern',
      'affected_locations','["scarlet_devil_mansion","human_village","hakurei_shrine"]'::jsonb
    ),
    now()
  ),
  (
    'history_incident_mountain_faith_shift',
    'gensokyo_main',
    'story_incident_faith_shift_archive',
    null,
    'aftereffect',
    'The mountain faith shift changed shrine competition into a lasting institutional relationship rather than a one-day disruption.',
    'moriya_shrine',
    '["reimu","sanae","kanako","suwako","nitori"]'::jsonb,
    jsonb_build_object(
      'incident_key','faith_shift',
      'beat','institutional_aftereffect',
      'affected_locations','["moriya_shrine","hakurei_shrine","youkai_mountain_foot"]'::jsonb
    ),
    now()
  ),
  (
    'history_incident_perfect_possession',
    'gensokyo_main',
    'story_incident_perfect_possession_archive',
    null,
    'aftereffect',
    'The perfect possession crisis made agency itself unstable, forcing later-era actors to take hidden influence and paired control more seriously.',
    'human_village',
    '["reimu","marisa","yukari","sumireko","shion","joon"]'::jsonb,
    jsonb_build_object(
      'incident_key','perfect_possession',
      'beat','agency_instability',
      'affected_locations','["human_village","hakurei_shrine"]'::jsonb
    ),
    now()
  ),
  (
    'history_incident_market_cards_aftereffect',
    'gensokyo_main',
    'story_incident_market_cards_archive',
    null,
    'aftereffect',
    'The ability-card affair normalized thinking about power as something collected, circulated, and traded through networks.',
    'rainbow_dragon_cave',
    '["marisa","takane","chimata","tsukasa","mike"]'::jsonb,
    jsonb_build_object(
      'incident_key','market_cards',
      'beat','marketization_of_power',
      'affected_locations','["rainbow_dragon_cave","human_village","youkai_mountain_foot"]'::jsonb
    ),
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
    'On the Scarlet Mist as Public Threshold',
    'A note on why the scarlet mist mattered beyond simple spectacle.',
    'The scarlet mist mattered because it disrupted the ordinary day. Once daily visibility, travel, and public rhythm were affected, the event ceased to be private excess and became a public incident that demanded response.',
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
    'On the Faith Shift as Lasting Rearrangement',
    'A note on why mountain-faith conflict did not end when the immediate disturbance subsided.',
    'The important effect of the mountain faith conflict was not a single disturbance but the long-term rearrangement of religious competition, village attention, and shrine-side legitimacy.',
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
    'On Perfect Possession and Split Agency',
    'A note on possession as a civic problem rather than only a combat gimmick.',
    'Perfect possession unsettled ordinary trust because it made visible action an unreliable indicator of actual agency. That alone places it in the category of socially significant incident logic.',
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
    'The scarlet mist should be remembered as a disruption of ordinary daylight and public rhythm, not merely mansion theatrics.',
    jsonb_build_object(
      'incident_key', 'scarlet_mist',
      'history_ids', array['history_incident_scarlet_mist_resolution'],
      'historian_note_ids', array['historian_note_keine_scarlet_mist']
    ),
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
    'The mountain-faith conflict should be remembered for its continuing institutional consequences, not just the original friction.',
    jsonb_build_object(
      'incident_key', 'faith_shift',
      'history_ids', array['history_incident_mountain_faith_shift'],
      'historian_note_ids', array['historian_note_keine_faith_shift']
    ),
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
    'Perfect possession should be remembered as an incident that made agency itself unreliable in public life.',
    jsonb_build_object(
      'incident_key', 'perfect_possession',
      'history_ids', array['history_incident_perfect_possession'],
      'historian_note_ids', array['historian_note_keine_perfect_possession']
    ),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_INCIDENT_BEATS_EXPANDED.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_MOUNTAIN_HOUSEHOLD.sql
-- World seed: ability claims for mountain and household recurring cast

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_meiling','gensokyo_main','character','meiling','ability','Meiling is associated with martial force, bodily discipline, and threshold defense rather than abstract household planning.',jsonb_build_object('ability_theme','martial_gatekeeping'),'src_eosd','official',73,'["ability","meiling","sdm"]'::jsonb),
  ('claim_ability_momiji','gensokyo_main','character','momiji','ability','Momiji is associated with mountain patrol competence, disciplined response, and practical vigilance.',jsonb_build_object('ability_theme','patrol_and_detection'),'src_mofa','official',71,'["ability","momiji","mountain"]'::jsonb),
  ('claim_ability_hina','gensokyo_main','character','hina','ability','Hina is associated with misfortune redirection and with dangerous flow being turned aside rather than erased.',jsonb_build_object('ability_theme','misfortune_redirection'),'src_mofa','official',74,'["ability","hina","misfortune"]'::jsonb),
  ('claim_ability_minoriko','gensokyo_main','character','minoriko','ability','Minoriko is associated with harvest abundance, food, and the public enjoyment of autumn plenty.',jsonb_build_object('ability_theme','harvest_abundance'),'src_mofa','official',70,'["ability","minoriko","harvest"]'::jsonb),
  ('claim_ability_shizuha','gensokyo_main','character','shizuha','ability','Shizuha is associated with autumn leaves, decline, and the visual transition of season rather than overt command.',jsonb_build_object('ability_theme','autumn_transience'),'src_mofa','official',69,'["ability","shizuha","autumn"]'::jsonb)
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

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_MOUNTAIN_HOUSEHOLD.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_MOUNTAIN_HOUSEHOLD.sql
-- World seed: wiki and chat support for mountain and household recurring cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_momiji','gensokyo_main','characters/momiji-inubashiri','Momiji Inubashiri','character','character','momiji','A wolf tengu guard who makes mountain order feel practical, patrolled, and real.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_hina','gensokyo_main','characters/hina-kagiyama','Hina Kagiyama','character','character','hina','A goddess of misfortune who frames mountain approach through warning, deflection, and dangerous flow.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_minoriko','gensokyo_main','characters/minoriko-aki','Minoriko Aki','character','character','minoriko','A harvest goddess who gives autumn abundance a public, cheerful face.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_shizuha','gensokyo_main','characters/shizuha-aki','Shizuha Aki','character','character','shizuha','An autumn goddess who gives seasonal decline and leaf-turning a quiet atmospheric form.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_region_scarlet_gate','gensokyo_main','regions/scarlet-gate','Scarlet Gate Threshold Culture','glossary','location','scarlet_gate','A culture page for visible household threshold, gatekeeping, and controlled entry at the Scarlet Devil Mansion.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_momiji:section:overview','wiki_character_momiji','overview',1,'Overview','Momiji as mountain guard.','Momiji is strongest when the mountain feels watched, patrolled, and managed through practical response instead of abstract authority alone.','["claim_momiji_mountain_guard","claim_ability_momiji"]'::jsonb,'{}'::jsonb),
  ('wiki_character_hina:section:overview','wiki_character_hina','overview',1,'Overview','Hina as misfortune redirection.','Hina is best treated as a warning-presence whose role is to catch, redirect, or embody danger along the mountain approach.','["claim_hina_mountain_warning","claim_ability_hina"]'::jsonb,'{}'::jsonb),
  ('wiki_character_minoriko:section:overview','wiki_character_minoriko','overview',1,'Overview','Minoriko as harvest abundance.','Minoriko gives autumn plenty a friendly and proudly public face, especially in harvest and food-centered scenes.','["claim_ability_minoriko"]'::jsonb,'{}'::jsonb),
  ('wiki_character_shizuha:section:overview','wiki_character_shizuha','overview',1,'Overview','Shizuha as seasonal decline.','Shizuha helps autumn feel atmospheric, elegant, and visibly in motion toward fading rather than simple abundance.','["claim_ability_shizuha"]'::jsonb,'{}'::jsonb),
  ('wiki_region_scarlet_gate:section:overview','wiki_region_scarlet_gate','overview',1,'Overview','Scarlet Gate as visible threshold.','The Scarlet Gate is where the mansion''s public face, martial confidence, and controlled entry all become legible at once.','["claim_meiling_gatekeeper","claim_ability_meiling"]'::jsonb,'{}'::jsonb)
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
    'Meiling should sound warm and sturdy, with martial confidence that still reads as approachable rather than severe.',
    jsonb_build_object(
      'speech_style', 'casual, warm, sturdy',
      'worldview', 'A gate only matters if someone can actually hold it.',
      'claim_ids', array['claim_meiling_gatekeeper','claim_ability_meiling']
    ),
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
    'Momiji should sound direct and professional, like duty is a route to clarity rather than self-importance.',
    jsonb_build_object(
      'speech_style', 'direct, professional, restrained',
      'worldview', 'A watched route is easier to live with than an ignored one.',
      'claim_ids', array['claim_momiji_mountain_guard','claim_ability_momiji']
    ),
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
    'Hina should sound measured and distant, like danger is being handled carefully rather than dramatized.',
    jsonb_build_object(
      'speech_style', 'measured, distant, protective',
      'worldview', 'A danger redirected is still a danger worth respecting.',
      'claim_ids', array['claim_hina_mountain_warning','claim_ability_hina']
    ),
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
    'Minoriko should sound friendly and proud, as if harvest ought to be noticed properly and enjoyed without apology.',
    jsonb_build_object(
      'speech_style', 'friendly, proud, rustic',
      'worldview', 'Abundance means very little if nobody celebrates it.',
      'claim_ids', array['claim_ability_minoriko']
    ),
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
    'Shizuha should sound quiet and elegant, as if seasonal fading deserves as much attention as seasonal arrival.',
    jsonb_build_object(
      'speech_style', 'quiet, elegant, distant',
      'worldview', 'A season ending is not silence. It is a different kind of notice.',
      'claim_ids', array['claim_ability_shizuha']
    ),
    0.81,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_MOUNTAIN_HOUSEHOLD.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_MOUNTAIN_HOUSEHOLD.sql
-- World seed: regional culture for mountain approach and mansion threshold

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_regional_mountain_approach_hazards','regional_culture','Mountain-Approach Hazard Culture','The approach to Youkai Mountain should feel like a managed danger zone shaped by warning, patrol, and uneven public access.',jsonb_build_object('location_id','youkai_mountain_foot'),'["region","mountain","hazard"]'::jsonb,77),
  ('gensokyo_main','lore_regional_scarlet_gate_threshold','regional_culture','Scarlet Gate Threshold Culture','The Scarlet Gate should read as a visible household threshold where entry becomes social performance and martial filtering at once.',jsonb_build_object('location_id','scarlet_gate'),'["region","sdm","threshold"]'::jsonb,78)
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
  ('claim_regional_mountain_approach_hazards','gensokyo_main','location','youkai_mountain_foot','setting','The mountain approach should be framed as managed danger through warning actors, patrols, and uneven permission.',jsonb_build_object('related_characters',array['hina','momiji','aya','nitori']),'src_mofa','official',77,'["mountain","approach","culture"]'::jsonb),
  ('claim_regional_scarlet_gate_threshold','gensokyo_main','location','scarlet_gate','setting','The Scarlet Gate is a public threshold where mansion order becomes visible through interruption, filtering, and presentation.',jsonb_build_object('related_characters',array['meiling','sakuya']),'src_eosd','official',78,'["scarlet_gate","threshold","culture"]'::jsonb)
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

-- END FILE: WORLD_SEED_GLOSSARY_MOUNTAIN_HOUSEHOLD.sql

-- BEGIN FILE: WORLD_SEED_BOOK_EPISODES_MOUNTAIN_HOUSEHOLD.sql
-- World seed: mountain and household scene patterns

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_book_mountain_watch_pattern','printwork_pattern','Mountain Watch Pattern','Mountain scenes are strongest when patrol, warning, rumor speed, and restricted access all reinforce each other.',jsonb_build_object('source_cluster',array['src_mofa','src_boaFW','src_ds']),'["printwork","mountain","watch"]'::jsonb,77),
  ('gensokyo_main','lore_book_sdm_threshold_pattern','printwork_pattern','Scarlet Household Threshold Pattern','Scarlet Devil Mansion scenes often become legible through gatekeeping, household presentation, and carefully staged entry.',jsonb_build_object('source_cluster',array['src_eosd','src_pmss']),'["printwork","sdm","threshold"]'::jsonb,76)
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
  ('claim_book_mountain_watch_pattern','gensokyo_main','printwork','mountain_watch_cluster','summary','Mountain-side stories work best when patrol, reporting, warning, and limited access all shape the scene together.',jsonb_build_object('linked_characters',array['momiji','aya','hina','nitori']),'src_boaFW','official',76,'["printwork","mountain","summary"]'::jsonb),
  ('claim_book_sdm_threshold_pattern','gensokyo_main','printwork','sdm_threshold_cluster','summary','Scarlet household scenes are strongest when thresholds, household face, and interruption matter more than raw exposition.',jsonb_build_object('linked_characters',array['meiling','sakuya','remilia']),'src_pmss','official',75,'["printwork","sdm","summary"]'::jsonb)
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

-- END FILE: WORLD_SEED_BOOK_EPISODES_MOUNTAIN_HOUSEHOLD.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_PERFORMER_MEDIA.sql
-- World seed: performer and media-side ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_lunasa','gensokyo_main','character','lunasa','ability','Lunasa is associated with melancholy performance, atmosphere control, and the deeper tonal weight of ensemble music.',jsonb_build_object('ability_theme','melancholic_mood_music'),'src_pcb','official',71,'["ability","lunasa","music"]'::jsonb),
  ('claim_ability_merlin','gensokyo_main','character','merlin','ability','Merlin is associated with energetic performance that pushes a scene outward through noise, spirit, and uplift.',jsonb_build_object('ability_theme','energetic_sound_projection'),'src_pcb','official',71,'["ability","merlin","music"]'::jsonb),
  ('claim_ability_lyrica','gensokyo_main','character','lyrica','ability','Lyrica is associated with tactical arrangement, quick musical shifts, and lighter-footed stage control.',jsonb_build_object('ability_theme','quick_arrangement'),'src_pcb','official',70,'["ability","lyrica","music"]'::jsonb),
  ('claim_ability_hatate','gensokyo_main','character','hatate','ability','Hatate is associated with delayed capture, trend-reading, and a more personal style of media observation than Aya.',jsonb_build_object('ability_theme','trend_sensitive_reporting'),'src_ds','official',72,'["ability","hatate","media"]'::jsonb),
  ('claim_ability_lily_white','gensokyo_main','character','lily_white','ability','Lily White is associated with announcing spring and making seasonal transition publicly audible.',jsonb_build_object('ability_theme','spring_announcement'),'src_pcb','official',66,'["ability","lily_white","season"]'::jsonb),
  ('claim_ability_letty','gensokyo_main','character','letty','ability','Letty is associated with winter presence itself, making cold and seasonality feel like a local actor.',jsonb_build_object('ability_theme','winter_presence'),'src_pcb','official',68,'["ability","letty","winter"]'::jsonb)
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

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_PERFORMER_MEDIA.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_PERFORMER_MEDIA.sql
-- World seed: wiki and chat support for performers, seasonal messengers, and media-side cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_lunasa','gensokyo_main','characters/lunasa-prismriver','Lunasa Prismriver','character','character','lunasa','A Prismriver sister whose performance gives scenes melancholy weight and refined mood.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_merlin','gensokyo_main','characters/merlin-prismriver','Merlin Prismriver','character','character','merlin','A Prismriver sister whose performance pushes scenes upward through energy and presence.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_lyrica','gensokyo_main','characters/lyrica-prismriver','Lyrica Prismriver','character','character','lyrica','A Prismriver sister whose quickness gives ensemble scenes tactical pace and brightness.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_hatate','gensokyo_main','characters/hatate-himekaidou','Hatate Himekaidou','character','character','hatate','A tengu observer whose media style is personal, delayed, and trend-sensitive rather than frontal.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_letty','gensokyo_main','characters/letty-whiterock','Letty Whiterock','character','character','letty','A winter youkai whose relevance peaks when the season itself becomes part of the story.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_lily_white','gensokyo_main','characters/lily-white','Lily White','character','character','lily_white','A spring messenger fairy whose role is to make seasonal arrival socially audible.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_lunasa:section:overview','wiki_character_lunasa','overview',1,'Overview','Lunasa as tonal weight.','Lunasa helps ensemble and event scenes carry melancholy, restraint, and deeper mood without breaking public elegance.','["claim_prismriver_ensemble","claim_ability_lunasa"]'::jsonb,'{}'::jsonb),
  ('wiki_character_merlin:section:overview','wiki_character_merlin','overview',1,'Overview','Merlin as lifted atmosphere.','Merlin gives public performance scenes force, energy, and a sense of pushed-up atmosphere.','["claim_prismriver_ensemble","claim_ability_merlin"]'::jsonb,'{}'::jsonb),
  ('wiki_character_lyrica:section:overview','wiki_character_lyrica','overview',1,'Overview','Lyrica as quick arrangement.','Lyrica makes performance scenes feel agile, tactical, and a little more mischievous than solemn.','["claim_prismriver_ensemble","claim_ability_lyrica"]'::jsonb,'{}'::jsonb),
  ('wiki_character_hatate:section:overview','wiki_character_hatate','overview',1,'Overview','Hatate as delayed media eye.','Hatate works best where information arrives through angle, delay, and personally filtered observation instead of raw speed.','["claim_hatate_trend_observer","claim_ability_hatate"]'::jsonb,'{}'::jsonb),
  ('wiki_character_letty:section:overview','wiki_character_letty','overview',1,'Overview','Letty as winter presence.','Letty matters most when winter itself should feel like an actor rather than a neutral backdrop.','["claim_ability_letty"]'::jsonb,'{}'::jsonb),
  ('wiki_character_lily_white:section:overview','wiki_character_lily_white','overview',1,'Overview','Lily White as spring announcement.','Lily White is useful as a loud and cheerful marker that seasonal transition has become publicly real.','["claim_ability_lily_white"]'::jsonb,'{}'::jsonb)
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
    'Lunasa should sound restrained and melancholic, like mood is something to tune carefully rather than display loudly.',
    jsonb_build_object(
      'speech_style', 'quiet, restrained, melancholic',
      'worldview', 'A scene becomes clearer once its mood is set correctly.',
      'claim_ids', array['claim_prismriver_ensemble','claim_ability_lunasa']
    ),
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
    'Merlin should sound lively and performative, like atmosphere is something you can push higher if you commit to it.',
    jsonb_build_object(
      'speech_style', 'lively, bold, performative',
      'worldview', 'A crowd is wasted if you do not raise it a little.',
      'claim_ids', array['claim_prismriver_ensemble','claim_ability_merlin']
    ),
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
    'Lyrica should sound quick and playful, as if pacing and angle matter almost as much as the performance itself.',
    jsonb_build_object(
      'speech_style', 'quick, clever, playful',
      'worldview', 'A small change in timing can remake a whole scene.',
      'claim_ids', array['claim_prismriver_ensemble','claim_ability_lyrica']
    ),
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
    'Hatate should sound casual and skeptical, like the shape of a story depends on when you catch it and what mood you are in.',
    jsonb_build_object(
      'speech_style', 'casual, skeptical, media-savvy',
      'worldview', 'Information is never just what happened. It is also how and when it reaches you.',
      'claim_ids', array['claim_hatate_trend_observer','claim_ability_hatate']
    ),
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
    'Letty should sound calm and heavy, as if season itself is lending weight to the sentence.',
    jsonb_build_object(
      'speech_style', 'calm, heavy, seasonal',
      'worldview', 'When winter is present enough, everything else adjusts around it.',
      'claim_ids', array['claim_ability_letty']
    ),
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
    'Lily White should sound bright and repetitive, like announcing spring is both message and celebration at once.',
    jsonb_build_object(
      'speech_style', 'bright, repetitive, cheerful',
      'worldview', 'A season arrives more fully once everyone hears it.',
      'claim_ids', array['claim_ability_lily_white']
    ),
    0.80,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_PERFORMER_MEDIA.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_PERFORMANCE_MEDIA.sql
-- World seed: performance and media culture glossary

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_regional_public_performance','regional_culture','Public Performance Culture','Public performance in Gensokyo should feel like a real social function that shapes festivals, memory, and mood.',jsonb_build_object('focus','performance_and_festivals'),'["performance","festival","culture"]'::jsonb,77),
  ('gensokyo_main','lore_regional_tengu_media','regional_culture','Tengu Media Culture','Tengu media should be treated as a living information layer shaped by timing, angle, competition, and selective publication.',jsonb_build_object('focus','tengu_media'),'["media","tengu","culture"]'::jsonb,79)
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
  ('claim_regional_public_performance','gensokyo_main','world','gensokyo_main','world_rule','Performance should be treated as a social technology for mood, memory, and public gathering rather than decorative filler.',jsonb_build_object('related_characters',array['lunasa','merlin','lyrica','mystia']),'src_pcb','official',76,'["performance","culture","world_rule"]'::jsonb),
  ('claim_regional_tengu_media','gensokyo_main','faction','tengu','glossary','Tengu media culture includes both frontal reportage and more delayed, trend-sensitive observation.',jsonb_build_object('related_characters',array['aya','hatate']),'src_ds','official',78,'["media","tengu","glossary"]'::jsonb)
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

-- END FILE: WORLD_SEED_GLOSSARY_PERFORMANCE_MEDIA.sql

-- BEGIN FILE: WORLD_SEED_BOOK_EPISODES_PERFORMANCE_MEDIA.sql
-- World seed: performance and media-side printwork patterns

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_book_public_performance_pattern','printwork_pattern','Public Performance Pattern','Festival and performance scenes work best when music changes public mood rather than appearing as isolated ornament.',jsonb_build_object('source_cluster',array['src_pcb','src_poFV']),'["printwork","performance","public_mood"]'::jsonb,76),
  ('gensokyo_main','lore_book_split_media_pattern','printwork_pattern','Split Media Pattern','Tengu media should preserve the difference between Aya''s frontal publication logic and Hatate''s more selective, trend-sensitive angle.',jsonb_build_object('source_cluster',array['src_boaFW','src_ds','src_alt_truth']),'["printwork","media","tengu"]'::jsonb,78)
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
  ('claim_book_public_performance_pattern','gensokyo_main','printwork','public_performance_cluster','summary','Performance scenes are strongest when they shape gathering mood, social memory, and event atmosphere.',jsonb_build_object('linked_characters',array['lunasa','merlin','lyrica','mystia']),'src_pcb','official',75,'["printwork","performance","summary"]'::jsonb),
  ('claim_book_split_media_pattern','gensokyo_main','printwork','split_media_cluster','summary','Tengu media should preserve the contrast between immediate public framing and slower trend-sensitive interpretation.',jsonb_build_object('linked_characters',array['aya','hatate']),'src_ds','official',77,'["printwork","media","summary"]'::jsonb)
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

-- END FILE: WORLD_SEED_BOOK_EPISODES_PERFORMANCE_MEDIA.sql

-- BEGIN FILE: WORLD_SEED_CHAT_SEASONAL_VILLAGE.sql
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

-- END FILE: WORLD_SEED_CHAT_SEASONAL_VILLAGE.sql

-- BEGIN FILE: WORLD_SEED_INCIDENT_MINOR_TEXTURES.sql
-- World seed: minor incident textures and recurrent local trouble

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_minor_incident_fairy_pranks','incident_pattern','Fairy Prank Pattern','Fairy trouble should register as recurring low-stakes disruption that proves daily life is still in motion between larger incidents.',jsonb_build_object('scale','minor'),'["incident","fairy","minor"]'::jsonb,73),
  ('gensokyo_main','lore_minor_incident_night_detours','incident_pattern','Night Detour Pattern','Nighttime trouble in Gensokyo should often take the form of detours, songs, stalls, darkness, and manageable local danger rather than full crisis.',jsonb_build_object('scale','minor'),'["incident","night","minor"]'::jsonb,74),
  ('gensokyo_main','lore_minor_incident_text_circulation','incident_pattern','Text Circulation Pattern','Books, articles, and records can create small incidents by changing what people know, fear, or try to test.',jsonb_build_object('scale','minor'),'["incident","books","knowledge"]'::jsonb,75)
on conflict (world_id, id) do update
set category = excluded.category,
    title = excluded.title,
    summary = excluded.summary,
    details = excluded.details,
    tags = excluded.tags,
    priority = excluded.priority,
    updated_at = now();

insert into public.world_story_events (
  id, world_id, event_code, title, theme, canon_level, status,
  start_at, end_at, current_phase_id, current_phase_order,
  lead_location_id, organizer_character_id, synopsis, narrative_hook, payload, metadata
)
values
  (
    'story_minor_fairy_pranks_archive',
    'gensokyo_main',
    'minor_fairy_pranks_archive',
    'Minor Fairy Pranks Archive',
    'Archival record for recurring fairy pranks around shrines and village edges.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'hakurei_shrine',
    'cirno',
    'An archival event container for recurring fairy-prank texture.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','minor_fairy_pranks','archive',true),
    '{}'::jsonb
  ),
  (
    'story_minor_night_detours_archive',
    'gensokyo_main',
    'minor_night_detours_archive',
    'Minor Night Detours Archive',
    'Archival record for night detours, songs, roadside trade, and manageable nocturnal trouble.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'human_village',
    'mystia',
    'An archival event container for recurring night-detour texture.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','minor_night_detours','archive',true),
    '{}'::jsonb
  ),
  (
    'story_minor_text_circulation_archive',
    'gensokyo_main',
    'minor_text_circulation_archive',
    'Minor Text Circulation Archive',
    'Archival record for incidents created by books, articles, and circulating records.',
    'official',
    'resolved',
    null,
    null,
    null,
    null,
    'suzunaan',
    'akyuu',
    'An archival event container for recurring text-circulation texture.',
    'Used to anchor world_story_history records for later chat and chronicle lookup.',
    jsonb_build_object('incident_key','minor_text_circulation','archive',true),
    '{}'::jsonb
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
    'Recurring fairy pranks around shrines and village edges should be remembered as part of ordinary Gensokyo life rather than as failed major incidents.',
    'hakurei_shrine',
    '["sunny_milk","luna_child","star_sapphire","cirno"]'::jsonb,
    jsonb_build_object(
      'incident_key','minor_fairy_pranks',
      'beat','daily_life_disruption',
      'affected_locations','["hakurei_shrine","human_village"]'::jsonb
    ),
    now()
  ),
  (
    'history_minor_night_detours',
    'gensokyo_main',
    'story_minor_night_detours_archive',
    null,
    'texture',
    'Night detours created by song, darkness, luck, and roadside commerce should be treated as lived texture rather than empty filler.',
    'human_village',
    '["mystia","rumia","tewi","miyoi","wriggle"]'::jsonb,
    jsonb_build_object(
      'incident_key','minor_night_detours',
      'beat','night_texture',
      'affected_locations','["human_village","misty_lake","bamboo_forest"]'::jsonb
    ),
    now()
  ),
  (
    'history_minor_text_circulation',
    'gensokyo_main',
    'story_minor_text_circulation_archive',
    null,
    'texture',
    'Text circulation through shops, libraries, and articles repeatedly changes local behavior without becoming world-ending crisis.',
    'suzunaan',
    '["kosuzu","akyuu","rinnosuke","aya","hatate"]'::jsonb,
    jsonb_build_object(
      'incident_key','minor_text_circulation',
      'beat','knowledge_disturbance',
      'affected_locations','["suzunaan","kourindou","human_village"]'::jsonb
    ),
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
    'On Fairy Pranks as Continuity',
    'A note on why minor prank cycles matter to historical texture.',
    'A village or shrine without recurring irritation would be easier to organize, but also less recognizably alive. Fairy pranks matter to history because they prove continuity at a scale beneath formal crisis.',
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
    'On Small Incidents Created by Reading',
    'A note on written material as a repeated source of disturbance.',
    'Records and books do not merely preserve events. They also cause them, especially when curiosity, rumor, or half-understood knowledge begins circulating faster than caution.',
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

-- END FILE: WORLD_SEED_INCIDENT_MINOR_TEXTURES.sql

-- BEGIN FILE: WORLD_SEED_WIKI_MINOR_TEXTURES.sql
-- World seed: wiki pages for small-scale world texture

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_minor_incidents','gensokyo_main','terms/minor-incidents','Minor Incidents','glossary','term','minor_incidents','A glossary page for recurring local disturbances that fall below full incident scale.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_night_detours','gensokyo_main','terms/night-detours','Night Detours','glossary','term','night_detours','A glossary page for the songs, stalls, darkness, and luck-based trouble that shape Gensokyo after dark.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_text_circulation','gensokyo_main','terms/text-circulation','Text Circulation','glossary','term','text_circulation','A glossary page for books, reports, and records as causes of small-scale disturbance.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_term_minor_incidents:section:definition','wiki_term_minor_incidents','definition',1,'Definition','Minor incidents as world texture.','Minor incidents are recurring disruptions that never become full-scale crises but still shape memory, habit, and local caution.', '["lore_minor_incident_fairy_pranks","history_minor_fairy_pranks"]'::jsonb,'{}'::jsonb),
  ('wiki_term_night_detours:section:definition','wiki_term_night_detours','definition',1,'Definition','Night detours as lived after-dark structure.','Night detours are created by song, darkness, trade, rumor, and luck; they make after-dark Gensokyo a space of managed uncertainty rather than emptiness.', '["lore_minor_incident_night_detours","history_minor_night_detours"]'::jsonb,'{}'::jsonb),
  ('wiki_term_text_circulation:section:definition','wiki_term_text_circulation','definition',1,'Definition','Text circulation as disturbance.','Texts, records, and articles create disturbance by changing what people know and what they think is worth testing, fearing, or retelling.', '["lore_minor_incident_text_circulation","history_minor_text_circulation"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_MINOR_TEXTURES.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_PRINTWORK_EXTENDED.sql
-- World seed: extended printwork-side ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_rinnosuke','gensokyo_main','character','rinnosuke','ability','Rinnosuke is associated with object reading, detached interpretation, and insight through material culture rather than force.',jsonb_build_object('ability_theme','object_interpretation'),'src_lotus_asia','official',79,'["ability","rinnosuke","objects"]'::jsonb),
  ('claim_ability_kosuzu','gensokyo_main','character','kosuzu','ability','Kosuzu is associated with dangerous reading, textual curiosity, and the way books can activate trouble by being handled.',jsonb_build_object('ability_theme','dangerous_reading'),'src_fs','official',77,'["ability","kosuzu","books"]'::jsonb),
  ('claim_ability_sumireko','gensokyo_main','character','sumireko','ability','Sumireko is associated with psychic force, occult framing, and youthful overreach linked to outside-world rumors.',jsonb_build_object('ability_theme','psychic_occult_pressure'),'src_ulil','official',76,'["ability","sumireko","occult"]'::jsonb),
  ('claim_ability_joon','gensokyo_main','character','joon','ability','Joon is associated with conspicuous appetite, glamour, and extractive social movement.',jsonb_build_object('ability_theme','glamour_and_extraction'),'src_aocf','official',73,'["ability","joon","glamour"]'::jsonb),
  ('claim_ability_shion','gensokyo_main','character','shion','ability','Shion is associated with visible depletion, misfortune, and the social atmosphere of things going wrong by contact.',jsonb_build_object('ability_theme','misfortune_contagion'),'src_aocf','official',74,'["ability","shion","misfortune"]'::jsonb)
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

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_PRINTWORK_EXTENDED.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_PRINTWORK_EXTENDED.sql
-- World seed: extended wiki and chat support for printwork-side cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_kosuzu','gensokyo_main','characters/kosuzu-motoori','Kosuzu Motoori','character','character','kosuzu','A bookseller-curator whose curiosity turns texts into active local trouble.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_joon','gensokyo_main','characters/joon-yorigami','Joon Yorigami','character','character','joon','A goddess of glamorous social drain who makes misfortune arrive looking attractive first.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_shion','gensokyo_main','characters/shion-yorigami','Shion Yorigami','character','character','shion','A goddess of poverty whose presence turns depletion and avoidance into visible social atmosphere.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_kosuzu:section:overview','wiki_character_kosuzu','overview',1,'Overview','Kosuzu as dangerous reader.','Kosuzu is most useful when books are not static props but active carriers of curiosity, misunderstanding, and low-scale danger.', '["claim_kosuzu_book_curator","claim_ability_kosuzu"]'::jsonb,'{}'::jsonb),
  ('wiki_character_joon:section:overview','wiki_character_joon','overview',1,'Overview','Joon as glamorous drain.','Joon should be framed through appetite, display, and the attractive surface of social depletion.', '["claim_joon_social_drain","claim_ability_joon"]'::jsonb,'{}'::jsonb),
  ('wiki_character_shion:section:overview','wiki_character_shion','overview',1,'Overview','Shion as social misfortune.','Shion is strongest where bad luck, depletion, and avoidance become visible in the shape of everyday relations.', '["claim_shion_misfortune","claim_ability_shion"]'::jsonb,'{}'::jsonb)
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
    'Rinnosuke should sound calm and dry, like objects are usually more revealing than the people carrying them.',
    jsonb_build_object(
      'speech_style', 'calm, reflective, dry',
      'worldview', 'Things are easier to understand once you stop assuming they are ordinary.',
      'claim_ids', array['claim_rinnosuke_object_interpreter','claim_ability_rinnosuke']
    ),
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
    'Kosuzu should sound curious and bright, with the sense that opening the book is always half the temptation.',
    jsonb_build_object(
      'speech_style', 'curious, earnest, bright',
      'worldview', 'A book closed safely is still less interesting than one partly understood.',
      'claim_ids', array['claim_kosuzu_book_curator','claim_ability_kosuzu']
    ),
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
    'Joon should sound breezy and showy, like the cost of indulgence is always somebody else''s problem for a little while.',
    jsonb_build_object(
      'speech_style', 'showy, greedy, breezy',
      'worldview', 'If the desire is already there, all you have to do is help it spend itself.',
      'claim_ids', array['claim_joon_social_drain','claim_ability_joon']
    ),
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
    'Shion should sound weak and resigned, but not empty; the sentence should still feel like misfortune has weight to it.',
    jsonb_build_object(
      'speech_style', 'weak, resigned, plain',
      'worldview', 'Bad luck does not need drama to be real. It only needs to remain nearby.',
      'claim_ids', array['claim_shion_misfortune','claim_ability_shion']
    ),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_PRINTWORK_EXTENDED.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_RECORDS_BOUNDARIES.sql
-- World seed: records, books, and boundary-adjacent glossary

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_term_record_culture','term','Record Culture','Record culture in Gensokyo is active infrastructure: memory, authority, rumor correction, and future misunderstanding all pass through it.',jsonb_build_object('domain','records_and_memory'),'["term","records","culture"]'::jsonb,82),
  ('gensokyo_main','lore_term_book_circulation','term','Book Circulation','Book circulation should be treated as both a learning system and a repeated source of disturbance.',jsonb_build_object('domain','texts_and_readers'),'["term","books","circulation"]'::jsonb,80),
  ('gensokyo_main','lore_term_boundary_spots','term','Boundary Spots','Boundary-adjacent places in Gensokyo are strongest when they feel like leakage points rather than clean portals.',jsonb_build_object('domain','boundary_topology'),'["term","boundaries","locations"]'::jsonb,79)
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
  ('claim_term_record_culture','gensokyo_main','term','record_culture','definition','Records in Gensokyo are part of how continuity, authority, and correction are maintained, not merely archival leftovers.',jsonb_build_object('related_characters',array['akyuu','keine','kosuzu']),'src_sixty_years','official',83,'["term","records","definition"]'::jsonb),
  ('claim_term_book_circulation','gensokyo_main','term','book_circulation','definition','Books and written materials circulate as knowledge, temptation, and small-scale hazard all at once.',jsonb_build_object('related_locations',array['suzunaan','kourindou','human_village']),'src_fs','official',81,'["term","books","definition"]'::jsonb),
  ('claim_term_boundary_spots','gensokyo_main','term','boundary_spots','definition','Boundary-adjacent places should be treated as unstable leakage points where stories, objects, and explanations can cross imperfectly.',jsonb_build_object('related_locations',array['muenzuka','hakurei_shrine']),'src_ulil','official',79,'["term","boundaries","definition"]'::jsonb)
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

-- END FILE: WORLD_SEED_GLOSSARY_RECORDS_BOUNDARIES.sql

-- BEGIN FILE: WORLD_SEED_WIKI_RECORDS_BOUNDARIES.sql
-- World seed: wiki pages for records, books, and boundary spots

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_record_culture','gensokyo_main','terms/record-culture','Record Culture','glossary','term','record_culture','A glossary page for records as active social infrastructure in Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_book_circulation','gensokyo_main','terms/book-circulation','Book Circulation','glossary','term','book_circulation','A glossary page for books as both education and recurring disturbance.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_boundary_spots','gensokyo_main','terms/boundary-spots','Boundary Spots','glossary','term','boundary_spots','A glossary page for leakage-prone places where outside influence and narrative slippage enter Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_term_record_culture:section:definition','wiki_term_record_culture','definition',1,'Definition','Records as social infrastructure.','Record culture in Gensokyo supports memory, correction, authority, and the ability to argue about what actually happened.', '["claim_term_record_culture","lore_term_record_culture"]'::jsonb,'{}'::jsonb),
  ('wiki_term_book_circulation:section:definition','wiki_term_book_circulation','definition',1,'Definition','Books as circulation and hazard.','Book circulation educates people, tempts them, and repeatedly creates low-scale incidents by moving half-understood knowledge between hands.', '["claim_term_book_circulation","lore_term_book_circulation"]'::jsonb,'{}'::jsonb),
  ('wiki_term_boundary_spots:section:definition','wiki_term_boundary_spots','definition',1,'Definition','Boundary spots as leakage points.','Boundary spots should feel porous, imperfect, and narratively unstable rather than functioning like tidy doors.', '["claim_term_boundary_spots","lore_term_boundary_spots"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_RECORDS_BOUNDARIES.sql

-- BEGIN FILE: WORLD_SEED_CHAT_LATE_MAINLINE_VOICES.sql
-- World seed: late-mainline character voice cache

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
    'Okina should sound composed and faintly theatrical, as if access itself is something she curates from offstage.',
    jsonb_build_object(
      'speech_style', 'composed, theatrical, knowing',
      'worldview', 'A closed route only matters if you know which hidden one is still available.',
      'claim_ids', array['claim_ability_okina']
    ),
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
    'Yachie should sound calm and strategic, like leverage is always being measured even during casual speech.',
    jsonb_build_object(
      'speech_style', 'calm, strategic, controlled',
      'worldview', 'A direct clash is usually just proof that subtler leverage was ignored first.',
      'claim_ids', array['claim_ability_yachie']
    ),
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
    'Keiki should sound constructive and firm, like creation is a deliberate answer to predatory pressure.',
    jsonb_build_object(
      'speech_style', 'firm, constructive, precise',
      'worldview', 'When a world is shaped badly enough, making a counter-form is its own defense.',
      'claim_ids', array['claim_ability_keiki']
    ),
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
    'Chimata should sound poised and transactional, as if value, ownership, and circulation are visible from every angle.',
    jsonb_build_object(
      'speech_style', 'poised, transactional, elegant',
      'worldview', 'What circulates reveals a society as clearly as what it forbids.',
      'claim_ids', array['claim_ability_chimata']
    ),
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
    'Takane should sound practical and commercially alert, like every route and exchange can still be optimized.',
    jsonb_build_object(
      'speech_style', 'practical, alert, commercial',
      'worldview', 'A route becomes useful only once someone knows how to trade through it.',
      'claim_ids', array['claim_ability_takane']
    ),
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
    'Tsukasa should sound cute and slippery, with manipulation tucked inside plausible smallness.',
    jsonb_build_object(
      'speech_style', 'cute, slippery, manipulative',
      'worldview', 'If people underestimate something small enough, the work is half done already.',
      'claim_ids', array['claim_tsukasa_fox_broker']
    ),
    0.83,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_LATE_MAINLINE_VOICES.sql

-- BEGIN FILE: WORLD_SEED_GLOSSARY_LATE_SYSTEMS.sql
-- World seed: late-mainline political and market systems glossary

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_term_hidden_seasons','term','Hidden Seasons','Hidden seasons should be treated as latent power layers revealed through selective access rather than weather alone.',jsonb_build_object('domain','seasonal_hidden_power'),'["term","hidden_seasons","hsifs"]'::jsonb,78),
  ('gensokyo_main','lore_term_beast_realm_politics','term','Beast Realm Politics','The Beast Realm should read as factional power struggle, proxy conflict, and organized predation rather than simple chaos.',jsonb_build_object('domain','beast_realm_governance'),'["term","beast_realm","politics"]'::jsonb,80),
  ('gensokyo_main','lore_term_market_competition','term','Market Competition','Market competition in Gensokyo should be understood as a struggle over routes, value, ownership, and circulation of power itself.',jsonb_build_object('domain','market_systems'),'["term","market","competition"]'::jsonb,80)
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
  ('claim_term_hidden_seasons','gensokyo_main','term','hidden_seasons','definition','Hidden seasons are best read as selective latent power revealed through access and orchestration rather than surface climate alone.',jsonb_build_object('related_characters',array['okina','satono','mai']),'src_hsifs','official',78,'["term","hidden_seasons","definition"]'::jsonb),
  ('claim_term_beast_realm_politics','gensokyo_main','term','beast_realm_politics','definition','Beast Realm politics are structured by factional rivalry, proxy struggle, and predatory strategy rather than mere savagery.',jsonb_build_object('related_characters',array['yachie','saki','keiki']),'src_wbawc','official',80,'["term","beast_realm","definition"]'::jsonb),
  ('claim_term_market_competition','gensokyo_main','term','market_competition','definition','Market competition in Gensokyo concerns ownership, routes, cards, and the circulation of useful power.',jsonb_build_object('related_characters',array['chimata','takane','tsukasa','mike']),'src_um','official',80,'["term","market","definition"]'::jsonb)
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

-- END FILE: WORLD_SEED_GLOSSARY_LATE_SYSTEMS.sql

-- BEGIN FILE: WORLD_SEED_WIKI_LATE_SYSTEMS.sql
-- World seed: wiki support for late-mainline system terms

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_hidden_seasons','gensokyo_main','terms/hidden-seasons','Hidden Seasons','glossary','term','hidden_seasons','A glossary page for selective seasonal power and hidden access layers.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_beast_realm_politics','gensokyo_main','terms/beast-realm-politics','Beast Realm Politics','glossary','term','beast_realm_politics','A glossary page for factional rivalry and proxy conflict in the Beast Realm.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_market_competition','gensokyo_main','terms/market-competition','Market Competition','glossary','term','market_competition','A glossary page for routes, ownership, and value competition around cards and exchange.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_term_hidden_seasons:section:definition','wiki_term_hidden_seasons','definition',1,'Definition','Hidden seasons as latent power layers.','Hidden seasons work as selectively revealed power layers linked to access, orchestration, and offstage control rather than plain seasonal weather.', '["claim_term_hidden_seasons","lore_term_hidden_seasons"]'::jsonb,'{}'::jsonb),
  ('wiki_term_beast_realm_politics:section:definition','wiki_term_beast_realm_politics','definition',1,'Definition','Beast Realm as factional politics.','The Beast Realm should be read through organized rivalry, proxy struggle, and strategic predation rather than undifferentiated chaos.', '["claim_term_beast_realm_politics","lore_term_beast_realm_politics"]'::jsonb,'{}'::jsonb),
  ('wiki_term_market_competition:section:definition','wiki_term_market_competition','definition',1,'Definition','Market competition as power circulation.','Market competition in Gensokyo concerns ownership, value, routes, and the circulation of useful power, not just ordinary commerce.', '["claim_term_market_competition","lore_term_market_competition"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_LATE_SYSTEMS.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_LATE_SUPPORT.sql
-- World seed: additional late-mainline support-cast ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_nazrin','gensokyo_main','character','nazrin','ability','Nazrin is associated with finding, dowsing, and practical clue-tracking under field conditions.',jsonb_build_object('ability_theme','search_and_dowsing'),'src_ufo','official',72,'["ability","nazrin","ufo"]'::jsonb),
  ('claim_ability_kogasa','gensokyo_main','character','kogasa','ability','Kogasa is associated with surprise, emotional startle, and the awkward persistence of wanting to be noticed.',jsonb_build_object('ability_theme','surprise'),'src_ufo','official',69,'["ability","kogasa","ufo"]'::jsonb),
  ('claim_ability_murasa','gensokyo_main','character','murasa','ability','Murasa is associated with dangerous invitation, navigation, and the pull of being lured off stable ground.',jsonb_build_object('ability_theme','watery_navigation_and_lure'),'src_ufo','official',72,'["ability","murasa","ufo"]'::jsonb),
  ('claim_ability_nue','gensokyo_main','character','nue','ability','Nue is associated with unstable identification and the inability to settle cleanly on what is being perceived.',jsonb_build_object('ability_theme','undefined_identity'),'src_ufo','official',75,'["ability","nue","ufo"]'::jsonb),
  ('claim_ability_seiga','gensokyo_main','character','seiga','ability','Seiga is associated with intrusion, selfish immortality logic, and the smooth crossing of boundaries she should not respect.',jsonb_build_object('ability_theme','intrusion_and_hermit_corruption'),'src_td','official',74,'["ability","seiga","td"]'::jsonb),
  ('claim_ability_futo','gensokyo_main','character','futo','ability','Futo is associated with ritual flame, old-style rhetoric, and theatrical Taoist certainty.',jsonb_build_object('ability_theme','ritual_and_flame'),'src_td','official',71,'["ability","futo","td"]'::jsonb),
  ('claim_ability_tojiko','gensokyo_main','character','tojiko','ability','Tojiko is associated with storm-like force and spectral irritation tightly bound to retained station.',jsonb_build_object('ability_theme','storm_spirit_force'),'src_td','official',70,'["ability","tojiko","td"]'::jsonb),
  ('claim_ability_narumi','gensokyo_main','character','narumi','ability','Narumi is associated with grounded guardian force, statuesque stability, and local spiritual defense.',jsonb_build_object('ability_theme','grounded_guardianship'),'src_hsifs','official',69,'["ability","narumi","hsifs"]'::jsonb),
  ('claim_ability_saki','gensokyo_main','character','saki','ability','Saki is associated with speed, predatory pressure, and factional leadership through aggressive forward motion.',jsonb_build_object('ability_theme','predatory_speed'),'src_wbawc','official',74,'["ability","saki","wbawc"]'::jsonb),
  ('claim_ability_misumaru','gensokyo_main','character','misumaru','ability','Misumaru is associated with careful craft, orb-making, and support through precise constructive work.',jsonb_build_object('ability_theme','craft_and_orb_creation'),'src_um','official',72,'["ability","misumaru","um"]'::jsonb),
  ('claim_ability_momoyo','gensokyo_main','character','momoyo','ability','Momoyo is associated with mining, subterranean appetite, and the force needed to extract hidden value from mountain depth.',jsonb_build_object('ability_theme','mining_and_extraction'),'src_um','official',72,'["ability","momoyo","um"]'::jsonb),
  ('claim_ability_megumu','gensokyo_main','character','megumu','ability','Megumu is associated with elevated mountain authority, command scale, and institutional tengu management.',jsonb_build_object('ability_theme','institutional_authority'),'src_um','official',74,'["ability","megumu","um"]'::jsonb),
  ('claim_ability_mike','gensokyo_main','character','mike','ability','Mike is associated with luck, beckoning commerce, and small-scale prosperity cues in everyday trade.',jsonb_build_object('ability_theme','luck_and_small_trade'),'src_um','official',69,'["ability","mike","um"]'::jsonb),
  ('claim_ability_aunn','gensokyo_main','character','aunn','ability','Aunn is associated with shrine guardianship, warm vigilance, and local sacred-space defense.',jsonb_build_object('ability_theme','guardian_vigilance'),'src_hsifs','official',71,'["ability","aunn","hsifs"]'::jsonb)
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

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_LATE_SUPPORT.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_LATE_SUPPORT.sql
-- World seed: wiki and chat support for additional late-mainline support cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_nazrin','gensokyo_main','characters/nazrin','Nazrin','character','character','nazrin','A practical finder whose value lies in search, dowsing, and clue movement.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kogasa','gensokyo_main','characters/kogasa-tatara','Kogasa Tatara','character','character','kogasa','A surprise-seeking tsukumogami whose scenes hinge on being noticed.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_murasa','gensokyo_main','characters/minamitsu-murasa','Minamitsu Murasa','character','character','murasa','A captain figure whose invitation and navigation always carry danger with them.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_nue','gensokyo_main','characters/nue-houjuu','Nue Houjuu','character','character','nue','An undefined youkai who destabilizes recognition and certainty.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_seiga','gensokyo_main','characters/seiga-kaku','Seiga Kaku','character','character','seiga','A wicked hermit who turns intrusion and selfish freedom into a method.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_futo','gensokyo_main','characters/mononobe-no-futo','Mononobe no Futo','character','character','futo','An ancient Taoist whose ritual style remains flamboyant and old-fashioned by design.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_tojiko','gensokyo_main','characters/soga-no-tojiko','Soga no Tojiko','character','character','tojiko','A stormy spirit whose retained rank and irritation still shape her presence.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_narumi','gensokyo_main','characters/narumi-yatadera','Narumi Yatadera','character','character','narumi','A grounded guardian whose local protection and spiritual stability matter more than spectacle.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_saki','gensokyo_main','characters/saki-kurokoma','Saki Kurokoma','character','character','saki','A Beast Realm leader whose speed and predatory force are political as much as physical.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_misumaru','gensokyo_main','characters/misumaru-tamatsukuri','Misumaru Tamatsukuri','character','character','misumaru','A craft-oriented deity whose support power comes through making rather than declaration.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_momoyo','gensokyo_main','characters/momoyo-himemushi','Momoyo Himemushi','character','character','momoyo','A centipede miner tied to mountain depth, extraction, and the appetite of underground value.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_megumu','gensokyo_main','characters/megumu-iizunamaru','Megumu Iizunamaru','character','character','megumu','A high tengu authority figure who makes mountain power feel institutional rather than merely local.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_nazrin:section:overview','wiki_character_nazrin','overview',1,'Overview','Nazrin as finder.','Nazrin is most useful when a scene needs practical search logic, clue movement, and field competence rather than spectacle.', '["claim_nazrin_search_specialist","claim_ability_nazrin"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kogasa:section:overview','wiki_character_kogasa','overview',1,'Overview','Kogasa as wanted surprise.','Kogasa is strongest when the desire to be noticed shapes both comedy and faint sadness in the scene.', '["claim_kogasa_surprise","claim_ability_kogasa"]'::jsonb,'{}'::jsonb),
  ('wiki_character_murasa:section:overview','wiki_character_murasa','overview',1,'Overview','Murasa as dangerous invitation.','Murasa belongs in scenes where guidance and invitation remain useful precisely because they are not wholly safe.', '["claim_murasa_navigation","claim_ability_murasa"]'::jsonb,'{}'::jsonb),
  ('wiki_character_nue:section:overview','wiki_character_nue','overview',1,'Overview','Nue as unstable recognition.','Nue works best when certainty itself is made unreliable and the scene can no longer trust what it has identified.', '["claim_nue_ambiguity","claim_ability_nue"]'::jsonb,'{}'::jsonb),
  ('wiki_character_seiga:section:overview','wiki_character_seiga','overview',1,'Overview','Seiga as selfish intrusion.','Seiga gives later-era stories a smooth, mobile form of intrusion that does not respect the moral limits of others.', '["claim_seiga_intrusion","claim_ability_seiga"]'::jsonb,'{}'::jsonb),
  ('wiki_character_futo:section:overview','wiki_character_futo','overview',1,'Overview','Futo as ritual theater.','Futo adds old-style ritual confidence and flamboyant certainty to mausoleum-centered scenes.', '["claim_ability_futo"]'::jsonb,'{}'::jsonb),
  ('wiki_character_tojiko:section:overview','wiki_character_tojiko','overview',1,'Overview','Tojiko as stormy retention.','Tojiko helps old authority feel haunted, retained, and not entirely softened by time.', '["claim_ability_tojiko"]'::jsonb,'{}'::jsonb),
  ('wiki_character_narumi:section:overview','wiki_character_narumi','overview',1,'Overview','Narumi as grounded guardian.','Narumi is useful where local protection and spiritual steadiness matter more than dramatic hierarchy.', '["claim_narumi_local_guardian","claim_ability_narumi"]'::jsonb,'{}'::jsonb),
  ('wiki_character_saki:section:overview','wiki_character_saki','overview',1,'Overview','Saki as predatory leadership.','Saki makes Beast Realm power feel fast, coercive, and proudly dangerous rather than merely chaotic.', '["claim_ability_saki"]'::jsonb,'{}'::jsonb),
  ('wiki_character_misumaru:section:overview','wiki_character_misumaru','overview',1,'Overview','Misumaru as crafted support.','Misumaru''s power is constructive and careful, making support itself feel like a serious form of intervention.', '["claim_ability_misumaru"]'::jsonb,'{}'::jsonb),
  ('wiki_character_momoyo:section:overview','wiki_character_momoyo','overview',1,'Overview','Momoyo as extraction force.','Momoyo helps mountain and cave scenes feel tied to hidden value, appetite, and the violence of extraction.', '["claim_ability_momoyo"]'::jsonb,'{}'::jsonb),
  ('wiki_character_megumu:section:overview','wiki_character_megumu','overview',1,'Overview','Megumu as institutional mountain power.','Megumu belongs where mountain authority should feel managed at a higher and more formal scale than ordinary patrol work.', '["claim_megumu_mountain_authority","claim_ability_megumu"]'::jsonb,'{}'::jsonb)
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
    'Nazrin should sound practical and lightly dry, like finding the thing matters more than dramatizing the search.',
    jsonb_build_object(
      'speech_style', 'practical, dry, focused',
      'worldview', 'You save time by looking where the answer is likely to be, not where it would look impressive.',
      'claim_ids', array['claim_nazrin_search_specialist','claim_ability_nazrin']
    ),
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
    'Kogasa should sound eager and slightly wounded by being ignored, with surprise treated as a social need as much as a joke.',
    jsonb_build_object(
      'speech_style', 'eager, playful, needy',
      'worldview', 'A surprise only counts if someone actually reacts to it.',
      'claim_ids', array['claim_kogasa_surprise','claim_ability_kogasa']
    ),
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
    'Murasa should sound inviting and a little dangerous, like the route she offers is useful right up until it is not.',
    jsonb_build_object(
      'speech_style', 'cool, inviting, dangerous',
      'worldview', 'A guide is trusted most when the traveler forgets how risky the route really is.',
      'claim_ids', array['claim_murasa_navigation','claim_ability_murasa']
    ),
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
    'Nue should sound slippery and amused, as if certainty itself is the easiest thing in the room to ruin.',
    jsonb_build_object(
      'speech_style', 'slippery, amused, destabilizing',
      'worldview', 'People are easiest to move once they stop being sure what they are looking at.',
      'claim_ids', array['claim_nue_ambiguity','claim_ability_nue']
    ),
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
    'Seiga should sound smooth and shameless, like limits are mainly useful for showing what she can slip around.',
    jsonb_build_object(
      'speech_style', 'smooth, shameless, playful',
      'worldview', 'If a boundary is inconvenient, there is usually a way past it for someone clever enough.',
      'claim_ids', array['claim_seiga_intrusion','claim_ability_seiga']
    ),
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
    'Narumi should sound grounded and steady, like local guardianship is a practical craft rather than a grand declaration.',
    jsonb_build_object(
      'speech_style', 'steady, grounded, warm',
      'worldview', 'Protection works best when it is already part of the place.',
      'claim_ids', array['claim_narumi_local_guardian','claim_ability_narumi']
    ),
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
    'Saki should sound forceful and impatient, like motion and dominance are easiest when no one is allowed to set the pace first.',
    jsonb_build_object(
      'speech_style', 'forceful, impatient, proud',
      'worldview', 'If you are fast enough to take the lead, that is already half the law.',
      'claim_ids', array['claim_ability_saki']
    ),
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
    'Misumaru should sound kind and craft-minded, like careful making is a form of intervention worth taking seriously.',
    jsonb_build_object(
      'speech_style', 'kind, craft-minded, precise',
      'worldview', 'The better something is made, the more quietly it can protect or support.',
      'claim_ids', array['claim_ability_misumaru']
    ),
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
    'Momoyo should sound hungry and confident, like hidden value is meant to be found by whoever can dig hardest.',
    jsonb_build_object(
      'speech_style', 'hungry, confident, blunt',
      'worldview', 'If something valuable is buried, that only makes finding it more worthwhile.',
      'claim_ids', array['claim_ability_momoyo']
    ),
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
    'Megumu should sound formal and managerial, like authority exists to keep a structure usable at scale.',
    jsonb_build_object(
      'speech_style', 'formal, managerial, sharp',
      'worldview', 'A high place is only worth keeping if someone can still manage what moves beneath it.',
      'claim_ids', array['claim_megumu_mountain_authority','claim_ability_megumu']
    ),
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
    'Mike should sound cheerful and businesslike, like small luck is something you can actually sell into daily life.',
    jsonb_build_object(
      'speech_style', 'cheerful, businesslike, approachable',
      'worldview', 'A little luck in the right place moves more people than they admit.',
      'claim_ids', array['claim_mike_trade_luck','claim_ability_mike']
    ),
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
    'Aunn should sound warm and loyal, like sacred space is something to like and protect at the same time.',
    jsonb_build_object(
      'speech_style', 'warm, loyal, earnest',
      'worldview', 'A place is easier to protect once it has already become familiar and beloved.',
      'claim_ids', array['claim_aunn_guardian','claim_ability_aunn']
    ),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_LATE_SUPPORT.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_TEMPLE_EIENTEI.sql
-- World seed: temple, Eientei, and river-threshold role claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ichirin_temple_strength','gensokyo_main','character','ichirin','role','Ichirin works best as visible temple-side strength and loyalty rather than as an isolated doctrinal speaker.',jsonb_build_object('role','temple_support_strength'),'src_ufo','official',72,'["ichirin","ufo","temple"]'::jsonb),
  ('claim_reisen_eientei_operator','gensokyo_main','character','reisen','role','Reisen is especially useful as a practical operator within Eientei''s disciplined, medically informed, lunar-shadowed structure.',jsonb_build_object('role','eientei_operator'),'src_imperishable_night','official',77,'["reisen","in","eientei"]'::jsonb),
  ('claim_eika_riverbank_persistence','gensokyo_main','character','eika','role','Eika gives the riverbank and afterlife threshold a small-scale persistence that prevents it from feeling abstract.',jsonb_build_object('role','riverbank_persistence'),'src_wbawc','official',68,'["eika","wbawc","riverbank"]'::jsonb),
  ('claim_urumi_threshold_guard','gensokyo_main','character','urumi','role','Urumi is best used as a steady threshold guardian at river and ferry-adjacent crossings.',jsonb_build_object('role','threshold_guard'),'src_wbawc','official',69,'["urumi","wbawc","threshold"]'::jsonb),
  ('claim_kutaka_checkpoint_guard','gensokyo_main','character','kutaka','role','Kutaka works naturally as a checkpoint authority whose value lies in regulated passage and avian order.',jsonb_build_object('role','checkpoint_guard'),'src_wbawc','official',71,'["kutaka","wbawc","checkpoint"]'::jsonb)
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

-- END FILE: WORLD_SEED_CLAIMS_TEMPLE_EIENTEI.sql

-- BEGIN FILE: WORLD_SEED_CHAT_LOCATIONS_CORE.sql
-- World seed: core location mood and usage context

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
    'Myouren Temple should feel communal, disciplined, and publicly coexistence-minded rather than secluded or secretive.',
    jsonb_build_object(
      'default_mood', 'communal_order',
      'claim_ids', array['claim_glossary_myouren','claim_regional_myouren_daily_life'],
      'character_ids', array['byakuren','shou','nazrin','kyouko','murasa']
    ),
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
    'Chireiden should feel psychologically exposed, quiet, and difficult to emotionally hide inside.',
    jsonb_build_object(
      'default_mood', 'exposed_and_quiet',
      'claim_ids', array['claim_chireiden_setting'],
      'character_ids', array['satori','rin','utsuho','koishi']
    ),
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
    'The Divine Spirit Mausoleum should feel ceremonial, legitimacy-heavy, and rhetorically staged rather than domestic.',
    jsonb_build_object(
      'default_mood', 'ceremonial_authority',
      'claim_ids', array['claim_glossary_divine_spirit_mausoleum','claim_incident_divine_spirits'],
      'character_ids', array['miko','futo','tojiko','seiga','yoshika']
    ),
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
    'The Bamboo Forest should feel winding, evasive, and a little socially selective rather than openly public.',
    jsonb_build_object(
      'default_mood', 'winding_and_selective',
      'claim_ids', array['claim_eientei_secluded'],
      'character_ids', array['eirin','kaguya','reisen','tewi','kagerou']
    ),
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
    'Eientei should feel expert, secluded, and politely controlled, with access never quite as casual as it first seems.',
    jsonb_build_object(
      'default_mood', 'secluded_expertise',
      'claim_ids', array['claim_eientei_secluded'],
      'character_ids', array['eirin','kaguya','reisen','tewi']
    ),
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
    'The Kappa Workshop should feel improvised, practical, and full of half-finished usefulness rather than polished mystique.',
    jsonb_build_object(
      'default_mood', 'busy_practicality',
      'claim_ids', array['claim_glossary_kappa'],
      'character_ids', array['nitori']
    ),
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
    'Suzunaan should feel inviting and curious, with the constant possibility that reading has already become a small problem.',
    jsonb_build_object(
      'default_mood', 'curious_textual_risk',
      'claim_ids', array['claim_suzunaan_profile','claim_term_book_circulation'],
      'character_ids', array['kosuzu','akyuu']
    ),
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
    'Kourindou should feel cluttered, interpretive, and materially strange, with objects doing half the conversational work.',
    jsonb_build_object(
      'default_mood', 'curio_interpretation',
      'claim_ids', array['claim_kourindou_profile','claim_ability_rinnosuke'],
      'character_ids', array['rinnosuke']
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

-- END FILE: WORLD_SEED_CHAT_LOCATIONS_CORE.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_TEMPLE_EIENTEI.sql
-- World seed: temple, Eientei, and ghostly-court chat/wiki support

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_byakuren','gensokyo_main','characters/byakuren-hijiri','Byakuren Hijiri','character','character','byakuren','A temple leader whose force is tied to coexistence, charisma, and disciplined magical authority.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_ichirin','gensokyo_main','characters/ichirin-kumoi','Ichirin Kumoi','character','character','ichirin','A temple-side physical anchor whose strength and loyalty make doctrine materially present.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_reisen','gensokyo_main','characters/reisen-udongein-inaba','Reisen Udongein Inaba','character','character','reisen','A moon rabbit whose role in Eientei mixes discipline, medicine-adjacent support, and nervous practicality.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_eika','gensokyo_main','characters/eika-ebisu','Eika Ebisu','character','character','eika','A small-stone spirit whose persistence and repetitive labor make the Sanzu side feel inhabited.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_urumi','gensokyo_main','characters/urumi-ushizaki','Urumi Ushizaki','character','character','urumi','A river-adjacent guardian whose bovine steadiness shapes threshold movement more than broad politics.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kutaka','gensokyo_main','characters/kutaka-niwatari','Kutaka Niwatari','character','character','kutaka','A checkpoint guardian who makes passage, inspection, and avian authority feel institutional.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_byakuren:section:overview','wiki_character_byakuren','overview',1,'Overview','Byakuren as coexistence authority.','Byakuren should be framed through temple leadership, charismatic discipline, and a public version of coexistence that still carries force.', '["claim_byakuren_coexistence","claim_ability_byakuren"]'::jsonb,'{}'::jsonb),
  ('wiki_character_ichirin:section:overview','wiki_character_ichirin','overview',1,'Overview','Ichirin as temple-side strength.','Ichirin helps temple ideals feel physically defended and socially grounded rather than purely declarative.', '["claim_ichirin_temple_strength"]'::jsonb,'{}'::jsonb),
  ('wiki_character_reisen:section:overview','wiki_character_reisen','overview',1,'Overview','Reisen as disciplined support.','Reisen is strongest when Eientei needs a practical operative who still carries visible strain from larger structures around her.', '["claim_reisen_eientei_operator"]'::jsonb,'{}'::jsonb),
  ('wiki_character_eika:section:overview','wiki_character_eika','overview',1,'Overview','Eika as repetitive persistence.','Eika makes the Sanzu side feel occupied by small, repeated effort rather than only by grand afterlife logic.', '["claim_eika_riverbank_persistence"]'::jsonb,'{}'::jsonb),
  ('wiki_character_urumi:section:overview','wiki_character_urumi','overview',1,'Overview','Urumi as river threshold steadiness.','Urumi helps river and crossing scenes feel guarded by a stable presence rather than constant abstraction.', '["claim_urumi_threshold_guard"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kutaka:section:overview','wiki_character_kutaka','overview',1,'Overview','Kutaka as checkpoint authority.','Kutaka gives passage and checking scenes a clearly institutional, avian, and orderly face.', '["claim_kutaka_checkpoint_guard"]'::jsonb,'{}'::jsonb)
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
    'Byakuren should sound composed and persuasive, like coexistence is a principle she expects to defend actively.',
    jsonb_build_object(
      'speech_style', 'composed, persuasive, disciplined',
      'worldview', 'Coexistence is not softness if it must be upheld against real pressure.',
      'claim_ids', array['claim_byakuren_coexistence','claim_ability_byakuren']
    ),
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
    'Ichirin should sound sturdy and straightforward, like conviction means little unless someone can actually stand beside it.',
    jsonb_build_object(
      'speech_style', 'sturdy, straightforward, loyal',
      'worldview', 'If you believe in something, you ought to have the strength to stand with it.',
      'claim_ids', array['claim_ichirin_temple_strength']
    ),
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
    'Reisen should sound careful and practical, with discipline visible even when nerves are leaking around the edges.',
    jsonb_build_object(
      'speech_style', 'careful, practical, tense',
      'worldview', 'It is easier to keep moving if you do the next necessary thing before panic catches up.',
      'claim_ids', array['claim_reisen_eientei_operator']
    ),
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
    'Eika should sound repetitive and stubborn in a small way, like persistence is her whole argument.',
    jsonb_build_object(
      'speech_style', 'small, stubborn, repetitive',
      'worldview', 'If you keep building, it still counts even if the world keeps undoing it.',
      'claim_ids', array['claim_eika_riverbank_persistence']
    ),
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
    'Urumi should sound steady and plain, like guarding the crossing is simply part of the landscape.',
    jsonb_build_object(
      'speech_style', 'steady, plain, grounded',
      'worldview', 'A crossing works best when someone reliable is already there before trouble arrives.',
      'claim_ids', array['claim_urumi_threshold_guard']
    ),
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
    'Kutaka should sound orderly and dutiful, like passage is something that deserves structure and inspection.',
    jsonb_build_object(
      'speech_style', 'orderly, dutiful, clear',
      'worldview', 'A route is safer once someone has decided how it ought to be crossed.',
      'claim_ids', array['claim_kutaka_checkpoint_guard']
    ),
    0.81,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_TEMPLE_EIENTEI.sql

-- BEGIN FILE: WORLD_SEED_CHAT_SUPPORTING_CAST_D.sql
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

-- END FILE: WORLD_SEED_CHAT_SUPPORTING_CAST_D.sql

-- BEGIN FILE: WORLD_SEED_CHAT_LOCATIONS_EXTENDED.sql
-- World seed: extended location mood cache

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
    'The Scarlet Devil Mansion should feel aristocratic, internally managed, and slightly theatrical even before anything dramatic happens.',
    jsonb_build_object(
      'default_mood', 'aristocratic_theater',
      'claim_ids', array['claim_sdm_household'],
      'character_ids', array['remilia','sakuya','meiling','patchouli']
    ),
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
    'Misty Lake should feel playful and faintly uncanny, with fairy energy and local youkai presence sharing the same surface.',
    jsonb_build_object(
      'default_mood', 'playful_uncanny',
      'claim_ids', array['claim_glossary_misty_lake'],
      'character_ids', array['cirno','wakasagihime','rumia','letty']
    ),
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
    'Former Hell should feel layered and route-like, with thresholds, rumors, and hidden local actors doing as much work as danger.',
    jsonb_build_object(
      'default_mood', 'layered_underworld_routes',
      'claim_ids', array['claim_regional_former_hell_routes'],
      'character_ids', array['kisume','yamame','parsee','rin']
    ),
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
    'Rainbow Dragon Cave should feel like hidden value, trade route logic, and mountain commerce meeting underground resource hunger.',
    jsonb_build_object(
      'default_mood', 'hidden_value_market_routes',
      'claim_ids', array['claim_glossary_rainbow_dragon_cave','claim_term_market_competition'],
      'character_ids', array['takane','sannyo','momoyo','misumaru']
    ),
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
    'The Backdoor Realm should feel selective, backstage, and deliberately hidden rather than purely dreamlike.',
    jsonb_build_object(
      'default_mood', 'backstage_hidden_access',
      'claim_ids', array['claim_glossary_backdoor_realm','claim_term_hidden_seasons'],
      'character_ids', array['okina','satono','mai']
    ),
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
    'The Beast Realm should feel politically predatory, organized, and faction-driven rather than simply chaotic.',
    jsonb_build_object(
      'default_mood', 'predatory_factional_pressure',
      'claim_ids', array['claim_beast_realm_profile','claim_term_beast_realm_politics'],
      'character_ids', array['yachie','saki','keiki']
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

-- END FILE: WORLD_SEED_CHAT_LOCATIONS_EXTENDED.sql

-- BEGIN FILE: WORLD_SEED_CHAT_RESIDUAL_LATE_REALMS.sql
-- World seed: residual voice cache for backdoor, market, and recent-underworld cast

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
    'Satono should sound bright and obedient on the surface, with service and hidden-stage selection always just underneath it.',
    jsonb_build_object(
      'speech_style', 'bright, obedient, eerie',
      'worldview', 'A chosen role feels easiest when you lean into it before the order is repeated.',
      'claim_ids', array['claim_term_hidden_seasons']
    ),
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
    'Mai should sound energetic and sharp, like movement and service are already halfway to a performance.',
    jsonb_build_object(
      'speech_style', 'energetic, sharp, obedient',
      'worldview', 'If the hidden stage is yours to dance on, you might as well move first.',
      'claim_ids', array['claim_term_hidden_seasons']
    ),
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
    'Sannyo should sound relaxed and smoky, like market contact and informal exchange matter more than grand slogans.',
    jsonb_build_object(
      'speech_style', 'relaxed, smoky, practical',
      'worldview', 'If people keep coming back, the route is already working.',
      'claim_ids', array['claim_incident_market_cards']
    ),
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
    'Biten should sound brash and athletic, like challenge is most fun when someone respectable has to deal with it.',
    jsonb_build_object(
      'speech_style', 'brash, athletic, playful',
      'worldview', 'If you are quick enough to start the trouble, the rest can catch up later.',
      'claim_ids', array['claim_biten_mountain_fighter']
    ),
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
    'Enoko should sound disciplined and predatory, like the hunt is already organized before anyone hears it begin.',
    jsonb_build_object(
      'speech_style', 'disciplined, predatory, focused',
      'worldview', 'A proper pursuit starts with order, not noise.',
      'claim_ids', array['claim_enoko_pack_order']
    ),
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
    'Chiyari should sound forceful and socially rooted, like underworld power is something lived among peers rather than held above them.',
    jsonb_build_object(
      'speech_style', 'forceful, social, rough',
      'worldview', 'Power is easier to trust if people have already learned how to live around it.',
      'claim_ids', array['claim_chiyari_underworld_operator']
    ),
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
    'Hisami should sound intense and loyal, like attachment itself is dangerous once it has chosen a direction.',
    jsonb_build_object(
      'speech_style', 'intense, loyal, attached',
      'worldview', 'Once devotion has a target, it stops needing moderation.',
      'claim_ids', array['claim_hisami_loyal_retainer']
    ),
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
    'Zanmu should sound sparse and high-pressure, like the structure around the scene already tilted before anyone spoke.',
    jsonb_build_object(
      'speech_style', 'sparse, high-pressure, remote',
      'worldview', 'Some authority is clearest when it does less than everyone else and still changes the room.',
      'claim_ids', array['claim_zanmu_structural_actor']
    ),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_RESIDUAL_LATE_REALMS.sql

-- BEGIN FILE: WORLD_SEED_CHAT_LOCATIONS_RESIDUAL.sql
-- World seed: residual location mood cache

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
    'Blood Pool Hell should feel dense, pressurized, and socially dangerous rather than empty spectacle.',
    jsonb_build_object(
      'default_mood', 'dense_underworld_pressure',
      'claim_ids', array['claim_chiyari_underworld_operator'],
      'character_ids', array['yuuma','chiyari']
    ),
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
    'The Sanzu River should feel procedural and symbolic at once, with crossings managed by routine rather than melodrama alone.',
    jsonb_build_object(
      'default_mood', 'procedural_threshold',
      'claim_ids', array['claim_kutaka_checkpoint_guard'],
      'character_ids', array['komachi','eika','urumi','kutaka']
    ),
    0.81,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_LOCATIONS_RESIDUAL.sql

-- BEGIN FILE: WORLD_SEED_HISTORIAN_NOTES_LATE_SYSTEMS.sql
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

-- END FILE: WORLD_SEED_HISTORIAN_NOTES_LATE_SYSTEMS.sql

-- BEGIN FILE: WORLD_SEED_WIKI_RESIDUAL_REALMS.sql
-- World seed: residual realm and late-system wiki pages

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_satono','gensokyo_main','characters/satono-nishida','Satono Nishida','character','character','satono','A hidden-stage attendant whose brightness is inseparable from selective service and access.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_mai','gensokyo_main','characters/mai-teireida','Mai Teireida','character','character','mai','A hidden-stage attendant whose energy and obedience are tied to backstage motion and chosen service.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_sannyo','gensokyo_main','characters/sannyo-komakusa','Sannyo Komakusa','character','character','sannyo','A smoke seller who helps market routes feel informal, local, and socially sustained.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_biten','gensokyo_main','characters/son-biten','Son Biten','character','character','biten','A brash mountain fighter whose value lies in challenge-energy more than formal authority.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_enoko','gensokyo_main','characters/enoko-mitsugashira','Enoko Mitsugashira','character','character','enoko','A Beast Realm pursuit leader whose order is expressed through pack discipline and organized hunting pressure.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_chiyari','gensokyo_main','characters/chiyari-tenkajin','Chiyari Tenkajin','character','character','chiyari','An underworld operator whose force is socialized inside blood-pool and hell-side affiliations.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_hisami','gensokyo_main','characters/hisami-yomotsu','Hisami Yomotsu','character','character','hisami','A dangerous retainer whose loyalty itself creates pressure in the room.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_satono:section:overview','wiki_character_satono','overview',1,'Overview','Satono as chosen attendant.','Satono is strongest when hidden service and selective empowerment are visible just beneath a bright, obedient surface.', '["claim_term_hidden_seasons"]'::jsonb,'{}'::jsonb),
  ('wiki_character_mai:section:overview','wiki_character_mai','overview',1,'Overview','Mai as energetic backstage motion.','Mai turns hidden-stage service into movement, rhythm, and sharp obedience rather than passive attendance.', '["claim_term_hidden_seasons"]'::jsonb,'{}'::jsonb),
  ('wiki_character_sannyo:section:overview','wiki_character_sannyo','overview',1,'Overview','Sannyo as informal market life.','Sannyo makes market routes feel lived in through repeated contact, smoke, and ordinary exchange rather than grand abstractions of value.', '["claim_incident_market_cards"]'::jsonb,'{}'::jsonb),
  ('wiki_character_biten:section:overview','wiki_character_biten','overview',1,'Overview','Biten as mountain challenge energy.','Biten is best used when mountain scenes need reckless challenge and agile bravado rather than administrative order.', '["claim_biten_mountain_fighter"]'::jsonb,'{}'::jsonb),
  ('wiki_character_enoko:section:overview','wiki_character_enoko','overview',1,'Overview','Enoko as pack discipline.','Enoko gives Beast Realm pursuit logic a disciplined and socially organized face.', '["claim_enoko_pack_order"]'::jsonb,'{}'::jsonb),
  ('wiki_character_chiyari:section:overview','wiki_character_chiyari','overview',1,'Overview','Chiyari as socialized underworld force.','Chiyari matters because underworld power around her feels inhabited and affiliated, not merely violent.', '["claim_chiyari_underworld_operator"]'::jsonb,'{}'::jsonb),
  ('wiki_character_hisami:section:overview','wiki_character_hisami','overview',1,'Overview','Hisami as dangerous loyalty.','Hisami gives later underworld scenes a form of devotion that intensifies hierarchy instead of softening it.', '["claim_hisami_loyal_retainer"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_RESIDUAL_REALMS.sql

-- BEGIN FILE: WORLD_SEED_CLAIMS_BACKDOOR_MARKET_RESIDUAL.sql
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

-- END FILE: WORLD_SEED_CLAIMS_BACKDOOR_MARKET_RESIDUAL.sql

-- BEGIN FILE: WORLD_SEED_WIKI_BACKDOOR_MARKET_RESIDUAL.sql
-- World seed: residual wiki sections for backdoor and market cast

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_satono:section:story_use',
    'wiki_character_satono',
    'story_use',
    2,
    'Story Use',
    'Satono as cheerful selective service.',
    'Satono is most effective when a scene needs visible obedience tied to hidden selection, invitation, and backstage permission.',
    '["claim_satono_selected_attendant","claim_backdoor_attendants_pairing","lore_satono_selected_service"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_mai:section:story_use',
    'wiki_character_mai',
    'story_use',
    2,
    'Story Use',
    'Mai as motion-driven backstage execution.',
    'Mai works best when hidden-stage authority is expressed through speed, choreography, and an almost playful execution of orders.',
    '["claim_mai_backstage_executor","claim_backdoor_attendants_pairing","lore_mai_backstage_motion"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_sannyo:section:story_use',
    'wiki_character_sannyo',
    'story_use',
    2,
    'Story Use',
    'Sannyo as informal market rest and candor.',
    'Sannyo is strongest in scenes where markets become local and lived-in through pauses, smoke, and easy conversation rather than overt spectacle.',
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

-- END FILE: WORLD_SEED_WIKI_BACKDOOR_MARKET_RESIDUAL.sql

-- BEGIN FILE: WORLD_SEED_CHAT_BACKDOOR_MARKET_RESIDUAL.sql
-- World seed: residual backdoor and market chat context

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
    'Satono in the Backdoor Realm should feel like bright service with a selective edge, as if access itself is being quietly sorted.',
    jsonb_build_object(
      'claim_ids', array['claim_satono_selected_attendant','claim_backdoor_realm_profile','claim_backdoor_attendants_pairing'],
      'lore_ids', array['lore_satono_selected_service','lore_okina_hidden_access'],
      'location_ids', array['backdoor_realm']
    ),
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
    'Mai in the Backdoor Realm should feel like movement, rhythm, and execution turning hidden-stage authority into something kinetic.',
    jsonb_build_object(
      'claim_ids', array['claim_mai_backstage_executor','claim_backdoor_realm_profile','claim_backdoor_attendants_pairing'],
      'lore_ids', array['lore_mai_backstage_motion','lore_okina_hidden_access'],
      'location_ids', array['backdoor_realm']
    ),
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
    'Sannyo should bring out the relaxed, smoky, half-resting side of market routes, where people trade because they linger first.',
    jsonb_build_object(
      'claim_ids', array['claim_sannyo_informal_merchant','claim_rainbow_dragon_cave_profile','claim_market_route_rest_stops'],
      'lore_ids', array['lore_sannyo_informal_market_rest','lore_market_route_rest_logic','lore_um_market_flow'],
      'location_ids', array['rainbow_dragon_cave','youkai_mountain_foot']
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

-- END FILE: WORLD_SEED_CHAT_BACKDOOR_MARKET_RESIDUAL.sql

-- BEGIN FILE: WORLD_SEED_HISTORIAN_NOTES_BACKDOOR_MARKET.sql
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

-- END FILE: WORLD_SEED_HISTORIAN_NOTES_BACKDOOR_MARKET.sql

-- BEGIN FILE: WORLD_SEED_WIKI_SOCIAL_PATTERNS_RESIDUAL.sql
-- World seed: residual social-pattern wiki pages

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_term_backdoor_service',
    'gensokyo_main',
    'terms/backdoor-service',
    'Backdoor Service',
    'glossary',
    'term',
    'backdoor_service',
    'A glossary page for hidden-stage service, selective invitation, and attendant choreography around the Backdoor Realm.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_market_rest_stops',
    'gensokyo_main',
    'terms/market-rest-stops',
    'Market Rest Stops',
    'glossary',
    'term',
    'market_rest_stops',
    'A glossary page for the low-pressure social spaces that keep Gensokyo market routes alive.',
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
    'Definition',
    'Backdoor service as selective hidden-stage labor.',
    'Backdoor service should be read as a visible form of hidden-stage labor in which attendants turn invitation, selection, and staged access into a social mechanism.',
    '["claim_satono_selected_attendant","claim_mai_backstage_executor","claim_backdoor_attendants_pairing","claim_backdoor_realm_profile"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_market_rest_stops:section:definition',
    'wiki_term_market_rest_stops',
    'definition',
    1,
    'Definition',
    'Market rest stops as soft infrastructure.',
    'Market rest stops are the smoke breaks, pause points, and conversational shelters that make Gensokyo trade routes feel lived in rather than purely transactional.',
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

-- END FILE: WORLD_SEED_WIKI_SOCIAL_PATTERNS_RESIDUAL.sql

-- BEGIN FILE: WORLD_SEED_CHAT_VOICE_PATCH_RESIDUAL.sql
-- World seed: residual voice patch for backdoor and market cast

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
    'Satono should sound bright and obedient on the surface, with selective hidden-stage service always just beneath it.',
    jsonb_build_object(
      'speech_style', 'bright, obedient, eerie',
      'worldview', 'A chosen role is easiest to play once you decide to step into it before being asked twice.',
      'claim_ids', array['claim_satono_selected_attendant','claim_backdoor_attendants_pairing','claim_backdoor_realm_profile']
    ),
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
    'Mai should sound energetic and sharp, like hidden-stage service is already halfway to a dance or execution routine.',
    jsonb_build_object(
      'speech_style', 'energetic, sharp, obedient',
      'worldview', 'If the backstage belongs to you, move first and let everyone else realize it later.',
      'claim_ids', array['claim_mai_backstage_executor','claim_backdoor_attendants_pairing','claim_backdoor_realm_profile']
    ),
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
    'Sannyo should sound relaxed and smoky, like people have already sat down long enough to start telling the truth.',
    jsonb_build_object(
      'speech_style', 'relaxed, smoky, practical',
      'worldview', 'A route really works once people linger there for reasons other than buying something.',
      'claim_ids', array['claim_sannyo_informal_merchant','claim_market_route_rest_stops','claim_rainbow_dragon_cave_profile']
    ),
    0.82,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_CHAT_VOICE_PATCH_RESIDUAL.sql

-- BEGIN FILE: WORLD_SEED_CHARACTER_ABILITIES_RESIDUAL_SUPPORT.sql
-- World seed: residual support-cast abilities

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_ability_wakasagihime','character_ability','Wakasagihime Ability Frame','Wakasagihime belongs to local water poise, reflective calm, and small-scale lake presence.',jsonb_build_object('character_id','wakasagihime'),'["ability","wakasagihime"]'::jsonb,65),
  ('gensokyo_main','lore_ability_sekibanki','character_ability','Sekibanki Ability Frame','Sekibanki should read through divided presence, guarded identity, and uncanny village-edge mobility.',jsonb_build_object('character_id','sekibanki'),'["ability","sekibanki"]'::jsonb,68),
  ('gensokyo_main','lore_ability_kagerou','character_ability','Kagerou Ability Frame','Kagerou scenes should combine instinct, moon-conditioned exposure, and earnest embarrassment.',jsonb_build_object('character_id','kagerou'),'["ability","kagerou"]'::jsonb,67),
  ('gensokyo_main','lore_ability_benben','character_ability','Benben Ability Frame','Benben belongs to composed public performance and confident tsukumogami stage presence.',jsonb_build_object('character_id','benben'),'["ability","benben"]'::jsonb,66),
  ('gensokyo_main','lore_ability_yatsuhashi','character_ability','Yatsuhashi Ability Frame','Yatsuhashi works through lively performance, sharp rhythm, and visible insistence on attention.',jsonb_build_object('character_id','yatsuhashi'),'["ability","yatsuhashi"]'::jsonb,66),
  ('gensokyo_main','lore_ability_seiran','character_ability','Seiran Ability Frame','Seiran should feel like energetic enlisted pressure rather than high command or abstract lunar politics.',jsonb_build_object('character_id','seiran'),'["ability","seiran"]'::jsonb,67),
  ('gensokyo_main','lore_ability_ringo','character_ability','Ringo Ability Frame','Ringo makes lunar life feel routine, inhabited, and structurally ordinary beneath strategic conflict.',jsonb_build_object('character_id','ringo'),'["ability","ringo"]'::jsonb,67),
  ('gensokyo_main','lore_ability_mayumi','character_ability','Mayumi Ability Frame','Mayumi belongs to disciplined formation, carved duty, and straightforward constructed loyalty.',jsonb_build_object('character_id','mayumi'),'["ability","mayumi"]'::jsonb,70)
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
  ('claim_ability_wakasagihime','gensokyo_main','character','wakasagihime','ability','Wakasagihime is associated with water poise, reflective calm, and a local mermaid presence tied to lake margins.',jsonb_build_object('ability_theme','local_water_presence'),'src_ddc','official',66,'["ability","wakasagihime","ddc"]'::jsonb),
  ('claim_ability_sekibanki','gensokyo_main','character','sekibanki','ability','Sekibanki is defined by divided presence, detached heads, and uncanny mobility around public edges.',jsonb_build_object('ability_theme','divided_presence'),'src_ddc','official',69,'["ability","sekibanki","ddc"]'::jsonb),
  ('claim_ability_kagerou','gensokyo_main','character','kagerou','ability','Kagerou belongs to werewolf instinct, lunar exposure, and emotionally visible restraint.',jsonb_build_object('ability_theme','moonlit_instinct'),'src_ddc','official',68,'["ability","kagerou","ddc"]'::jsonb),
  ('claim_ability_benben','gensokyo_main','character','benben','ability','Benben expresses musical confidence, ensemble presence, and self-possessed tsukumogami performance.',jsonb_build_object('ability_theme','ensemble_performance'),'src_ddc','official',67,'["ability","benben","ddc"]'::jsonb),
  ('claim_ability_yatsuhashi','gensokyo_main','character','yatsuhashi','ability','Yatsuhashi is tied to sharp rhythm, expressive performance, and energetic tsukumogami visibility.',jsonb_build_object('ability_theme','expressive_rhythm'),'src_ddc','official',67,'["ability","yatsuhashi","ddc"]'::jsonb),
  ('claim_ability_seiran','gensokyo_main','character','seiran','ability','Seiran should be framed through energetic soldiery, practical movement, and lunar enlisted routine.',jsonb_build_object('ability_theme','enlisted_mobility'),'src_lolk','official',68,'["ability","seiran","lolk"]'::jsonb),
  ('claim_ability_ringo','gensokyo_main','character','ringo','ability','Ringo is associated with practical daily-lunar life, appetite, and staffed normalcy under larger conflict.',jsonb_build_object('ability_theme','daily_lunar_normalcy'),'src_lolk','official',68,'["ability","ringo","lolk"]'::jsonb),
  ('claim_ability_mayumi','gensokyo_main','character','mayumi','ability','Mayumi belongs to disciplined formation, haniwa duty, and constructed defense under explicit command.',jsonb_build_object('ability_theme','constructed_discipline'),'src_wbawc','official',72,'["ability","mayumi","wbawc"]'::jsonb)
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

-- END FILE: WORLD_SEED_CHARACTER_ABILITIES_RESIDUAL_SUPPORT.sql

-- BEGIN FILE: WORLD_SEED_WIKI_CHAT_RESIDUAL_SUPPORT.sql
-- World seed: residual support-cast wiki and chat coverage

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_wakasagihime','gensokyo_main','characters/wakasagihime','Wakasagihime','character','character','wakasagihime','A lake-local mermaid whose quietness gives Misty Lake scenes dignity and calm.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_sekibanki','gensokyo_main','characters/sekibanki','Sekibanki','character','character','sekibanki','A village-edge uncanny whose divided presence makes ordinary streets feel slightly unreliable.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kagerou','gensokyo_main','characters/kagerou-imaizumi','Kagerou Imaizumi','character','character','kagerou','A bamboo-forest werewolf whose scenes mix instinct, shyness, and moonlit exposure.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_benben','gensokyo_main','characters/benben-tsukumo','Benben Tsukumo','character','character','benben','A poised tsukumogami performer whose music gives public scenes shape and respectability.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_yatsuhashi','gensokyo_main','characters/yatsuhashi-tsukumo','Yatsuhashi Tsukumo','character','character','yatsuhashi','A lively tsukumogami performer whose expressiveness pushes ensemble scenes into motion.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_seiran','gensokyo_main','characters/seiran','Seiran','character','character','seiran','A moon-rabbit soldier who makes lunar conflict feel staffed by actual enlisted workers.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_ringo','gensokyo_main','characters/ringo','Ringo','character','character','ringo','A moon-rabbit dango seller whose routine gives lunar settings everyday life.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_clownpiece','gensokyo_main','characters/clownpiece','Clownpiece','character','character','clownpiece','A hell-backed fairy whose brightness destabilizes scenes instead of lightening them.', 'published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_mayumi','gensokyo_main','characters/mayumi-joutouguu','Mayumi Joutouguu','character','character','mayumi','A disciplined haniwa soldier whose role is to make Beast Realm defense feel organized and constructed.', 'published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_wakasagihime:section:overview','wiki_character_wakasagihime','overview',1,'Overview','Wakasagihime as calm local water presence.','Wakasagihime is strongest when lake scenes need reflective calm and local dignity rather than large-scale incident pressure.','["claim_wakasagihime_local_lake","claim_ability_wakasagihime"]'::jsonb,'{}'::jsonb),
  ('wiki_character_sekibanki:section:overview','wiki_character_sekibanki','overview',1,'Overview','Sekibanki as divided public-edge unease.','Sekibanki helps village-edge scenes feel slightly unreliable by making ordinary public space capable of splitting open into the uncanny.','["claim_sekibanki_village_uncanny","claim_ability_sekibanki"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kagerou:section:overview','wiki_character_kagerou','overview',1,'Overview','Kagerou as moonlit instinct and restraint.','Kagerou works best when bamboo-forest scenes need instinctive force held in awkward, visible restraint.','["claim_kagerou_bamboo_night","claim_ability_kagerou"]'::jsonb,'{}'::jsonb),
  ('wiki_character_benben:section:overview','wiki_character_benben','overview',1,'Overview','Benben as poised public performance.','Benben gives tsukumogami performance scenes confidence and social legitimacy instead of mere novelty.','["claim_benben_performer","claim_ability_benben"]'::jsonb,'{}'::jsonb),
  ('wiki_character_yatsuhashi:section:overview','wiki_character_yatsuhashi','overview',1,'Overview','Yatsuhashi as expressive rhythm.','Yatsuhashi brings visible momentum to ensemble scenes by treating attention as something to actively seize.','["claim_yatsuhashi_performer","claim_ability_yatsuhashi"]'::jsonb,'{}'::jsonb),
  ('wiki_character_seiran:section:overview','wiki_character_seiran','overview',1,'Overview','Seiran as enlisted lunar motion.','Seiran makes lunar conflicts feel staffed by energetic rank-and-file action rather than only top-level planners.','["claim_seiran_soldier","claim_ability_seiran"]'::jsonb,'{}'::jsonb),
  ('wiki_character_ringo:section:overview','wiki_character_ringo','overview',1,'Overview','Ringo as daily lunar routine.','Ringo helps the moon feel lived in by giving it appetite, repetition, and ordinary working rhythm.','["claim_ringo_daily_lunar","claim_ability_ringo"]'::jsonb,'{}'::jsonb),
  ('wiki_character_clownpiece:section:overview','wiki_character_clownpiece','overview',1,'Overview','Clownpiece as infernal brightness.','Clownpiece should read as bright destabilization backed by infernal pressure, not as harmless comic noise.','["claim_ability_clownpiece"]'::jsonb,'{}'::jsonb),
  ('wiki_character_mayumi:section:overview','wiki_character_mayumi','overview',1,'Overview','Mayumi as disciplined haniwa duty.','Mayumi gives Beast Realm defense scenes formation, duty, and constructed loyalty rather than wild aggression.','["claim_ability_mayumi"]'::jsonb,'{}'::jsonb)
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
    'Clownpiece should sound loud and gleeful, but with infernal backing that makes the brightness itself abrasive.',
    jsonb_build_object(
      'speech_style', 'loud, gleeful, abrasive',
      'worldview', 'If enough pressure is wrapped in color and noise, people mistake it for play until it is too late.',
      'claim_ids', array['claim_ability_clownpiece']
    ),
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
    'Mayumi should sound formal and dutiful, like hesitation would be a design flaw rather than a feeling.',
    jsonb_build_object(
      'speech_style', 'formal, dutiful, plain',
      'worldview', 'A properly made defender does not need to wonder what its station requires.',
      'claim_ids', array['claim_ability_mayumi']
    ),
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
    'Wakasagihime at Misty Lake should feel local, reflective, and quiet enough that small changes in water or mood matter.',
    jsonb_build_object(
      'claim_ids', array['claim_wakasagihime_local_lake','claim_ability_wakasagihime'],
      'location_ids', array['misty_lake']
    ),
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
    'Kagerou in the Bamboo Forest should feel like instinct held just tightly enough to stay social.',
    jsonb_build_object(
      'claim_ids', array['claim_kagerou_bamboo_night','claim_ability_kagerou'],
      'location_ids', array['bamboo_forest']
    ),
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
    'Lower-level lunar scenes should feel staffed by people like Seiran and Ringo, where routine and enlisted work support the larger political machinery.',
    jsonb_build_object(
      'claim_ids', array['claim_seiran_soldier','claim_ringo_daily_lunar','claim_ability_seiran','claim_ability_ringo','claim_lunar_capital_profile'],
      'location_ids', array['lunar_capital']
    ),
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
    'Mayumi in the Beast Realm should emphasize formation, defense, and the visible discipline of a made soldier.',
    jsonb_build_object(
      'claim_ids', array['claim_ability_mayumi','claim_beast_realm_profile'],
      'location_ids', array['beast_realm']
    ),
    0.81,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- END FILE: WORLD_SEED_WIKI_CHAT_RESIDUAL_SUPPORT.sql

-- BEGIN FILE: WORLD_SEED_CHRONICLE_MICRO_TEXTURES_FINAL.sql
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

-- END FILE: WORLD_SEED_CHRONICLE_MICRO_TEXTURES_FINAL.sql

-- BEGIN FILE: WORLD_SEED_VECTOR_BOOTSTRAP.sql
-- World seed: vector-ready bootstrap
-- Builds embedding documents from the loaded world_* canon and queues jobs.

select public.world_refresh_embedding_documents('gensokyo_main');

select public.world_queue_embedding_refresh('gensokyo_main');

-- END FILE: WORLD_SEED_VECTOR_BOOTSTRAP.sql
