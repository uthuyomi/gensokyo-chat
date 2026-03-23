-- World seed: canonical incident claims and chronicle coverage

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_incident_scarlet_mist','incident','Scarlet Mist Incident Pattern','A major early incident in which atmospheric abnormality and mansion-centered power became public crisis.',jsonb_build_object('incident_id','incident_scarlet_mist'),'["incident","eosd","mist"]'::jsonb,88),
  ('gensokyo_main','lore_incident_spring_snow','incident','Perfect Cherry Blossom Incident Pattern','An incident where season, death-boundary aesthetics, and Netherworld interests became entangled in public disturbance.',jsonb_build_object('incident_id','incident_spring_snow'),'["incident","pcb","spring"]'::jsonb,86),
  ('gensokyo_main','lore_incident_eternal_night','incident','Imperishable Night Incident Pattern','An incident characterized by false night, lunar linkage, and secrecy around delayed dawn.',jsonb_build_object('incident_id','incident_eternal_night'),'["incident","in","night"]'::jsonb,89),
  ('gensokyo_main','lore_incident_flower_anomaly','incident','Flower Incident Pattern','A wide floral abnormality that pulled together judgment, crossing, and seasonal overflow rather than a single villain''s scheme.',jsonb_build_object('incident_id','incident_flower_anomaly'),'["incident","pofv","flowers"]'::jsonb,78),
  ('gensokyo_main','lore_incident_weather_anomaly','incident','Weather Incident Pattern','A weather-scale abnormality tied to heavenly disruption and broad atmospheric instability.',jsonb_build_object('incident_id','incident_weather_anomaly'),'["incident","swr","weather"]'::jsonb,81),
  ('gensokyo_main','lore_incident_moriya_faith','incident','Faith and Mountain Shift Pattern','An incident pattern in which faith competition and mountain-side institutional pressure reshape public order.',jsonb_build_object('incident_id','incident_faith_shift'),'["incident","mof","faith"]'::jsonb,84),
  ('gensokyo_main','lore_incident_subterranean_sun','incident','Subterranean Sun Incident Pattern','An incident where underground power, hell-side structure, and excessive energy threatened surface balance.',jsonb_build_object('incident_id','incident_subterranean_sun'),'["incident","sa","underground"]'::jsonb,85),
  ('gensokyo_main','lore_incident_floating_treasures','incident','Flying Storehouse Incident Pattern','An incident where floating treasures, temple resurrection, and public uncertainty intersected.',jsonb_build_object('incident_id','incident_floating_treasures'),'["incident","ufo","temple"]'::jsonb,82),
  ('gensokyo_main','lore_incident_divine_spirits','incident','Divine Spirit Incident Pattern','An incident pattern centered on return, legitimacy, mausoleum politics, and spiritual authority.',jsonb_build_object('incident_id','incident_divine_spirits'),'["incident","td","mausoleum"]'::jsonb,82),
  ('gensokyo_main','lore_incident_little_rebellion','incident','Little People Rebellion Pattern','An incident driven by inversion, resentment, and unstable social overturning.',jsonb_build_object('incident_id','incident_little_rebellion'),'["incident","ddc","reversal"]'::jsonb,80),
  ('gensokyo_main','lore_incident_lunar_crisis','incident','Lunar Crisis Pattern','A crisis in which the moon, dream, and purification logic pressed hard against Gensokyo.',jsonb_build_object('incident_id','incident_lunar_crisis'),'["incident","lolk","moon"]'::jsonb,89),
  ('gensokyo_main','lore_incident_hidden_seasons','incident','Hidden Seasons Pattern','A seasonal distortion incident structured by hidden access and manipulated seasonal overflow.',jsonb_build_object('incident_id','incident_hidden_seasons'),'["incident","hsifs","seasons"]'::jsonb,81),
  ('gensokyo_main','lore_incident_beast_realm','incident','Beast Realm Incursion Pattern','An incident where beast-realm faction logic and underworld coercion reached into Gensokyo affairs.',jsonb_build_object('incident_id','incident_beast_realm'),'["incident","wbawc","beast_realm"]'::jsonb,84),
  ('gensokyo_main','lore_incident_market_cards','incident','Card Market Incident Pattern','An incident pattern driven by exchange, cards, mountain trade, and distributed market power.',jsonb_build_object('incident_id','incident_market_cards'),'["incident","um","market"]'::jsonb,80),
  ('gensokyo_main','lore_incident_living_ghost_conflict','incident','All Living Ghost Conflict Pattern','A recent conflict pattern in which underworld hierarchy, beast-realm power, and new actors overlapped at larger scale.',jsonb_build_object('incident_id','incident_living_ghost_conflict'),'["incident","19","underworld"]'::jsonb,83)
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
  ('claim_incident_scarlet_mist','gensokyo_main','incident','incident_scarlet_mist','summary','The Scarlet Mist Incident is a mansion-centered atmospheric crisis that helped define the public scale of incident response.',jsonb_build_object('principal_actors',array['reimu','marisa','sakuya','remilia']),'src_eosd','official',90,'["incident","eosd","mist"]'::jsonb),
  ('claim_incident_spring_snow','gensokyo_main','incident','incident_spring_snow','summary','The Perfect Cherry Blossom incident joins late spring, Netherworld intent, and boundary-sensitive seasonal disruption.',jsonb_build_object('principal_actors',array['reimu','marisa','youmu','yuyuko']),'src_pcb','official',88,'["incident","pcb","spring"]'::jsonb),
  ('claim_incident_eternal_night','gensokyo_main','incident','incident_eternal_night','summary','The Imperishable Night incident is marked by false night, delayed dawn, and deep lunar implication.',jsonb_build_object('principal_actors',array['reimu','marisa','eirin','kaguya','reisen','mokou']),'src_imperishable_night','official',91,'["incident","in","night"]'::jsonb),
  ('claim_incident_flower_anomaly','gensokyo_main','incident','incident_flower_anomaly','summary','The flower anomaly is a broad seasonal disturbance that pulls together many actors without reducing to one local culprit.',jsonb_build_object('principal_actors',array['komachi','eiki','yuuka','medicine']),'src_poFV','official',79,'["incident","pofv","flowers"]'::jsonb),
  ('claim_incident_weather_anomaly','gensokyo_main','incident','incident_weather_anomaly','summary','The weather anomaly centers heavenly interference and broad environmental instability rather than a merely local nuisance.',jsonb_build_object('principal_actors',array['tenshi','iku','reimu']),'src_swl','official',82,'["incident","swr","weather"]'::jsonb),
  ('claim_incident_faith_shift','gensokyo_main','incident','incident_faith_shift','summary','The mountain-faith shift places shrine competition and proactive Moriya expansion into public Gensokyo life.',jsonb_build_object('principal_actors',array['sanae','kanako','suwako','reimu']),'src_mofa','official',85,'["incident","mof","faith"]'::jsonb),
  ('claim_incident_subterranean_sun','gensokyo_main','incident','incident_subterranean_sun','summary','The subterranean sun crisis is an underground power problem with consequences too large to stay underground.',jsonb_build_object('principal_actors',array['satori','rin','utsuho','reimu','marisa']),'src_subterranean_animism','official',86,'["incident","sa","underground"]'::jsonb),
  ('claim_incident_floating_treasures','gensokyo_main','incident','incident_floating_treasures','summary','The UFO incident joins floating treasure rumors, ship imagery, and temple restoration into one public disturbance.',jsonb_build_object('principal_actors',array['nazrin','murasa','ichirin','byakuren','nue']),'src_ufo','official',84,'["incident","ufo","temple"]'::jsonb),
  ('claim_incident_divine_spirits','gensokyo_main','incident','incident_divine_spirits','summary','The divine spirit incident is structured around mausoleum politics, saintly return, and legitimacy in public life.',jsonb_build_object('principal_actors',array['miko','futo','tojiko','seiga']),'src_td','official',83,'["incident","td","mausoleum"]'::jsonb),
  ('claim_incident_little_rebellion','gensokyo_main','incident','incident_little_rebellion','summary','The little people rebellion is an inversion-driven incident of grievance, symbolic power, and unstable hierarchy.',jsonb_build_object('principal_actors',array['seija','shinmyoumaru','raiko']),'src_ddc','official',81,'["incident","ddc","reversal"]'::jsonb),
  ('claim_incident_lunar_crisis','gensokyo_main','incident','incident_lunar_crisis','summary','The lunar crisis binds moon politics, dream-space mediation, and purification pressure into a high-scale conflict.',jsonb_build_object('principal_actors',array['sagume','junko','hecatia','clownpiece','doremy']),'src_lolk','official',91,'["incident","lolk","moon"]'::jsonb),
  ('claim_incident_hidden_seasons','gensokyo_main','incident','incident_hidden_seasons','summary','The hidden seasons incident uses manipulated seasonal overflow and concealed access to reshape public atmosphere.',jsonb_build_object('principal_actors',array['okina','satono','mai','aunn','eternity','nemuno']),'src_hsifs','official',82,'["incident","hsifs","seasons"]'::jsonb),
  ('claim_incident_beast_realm','gensokyo_main','incident','incident_beast_realm','summary','The beast realm incursion pulls Gensokyo into coercive underworld faction politics and constructed counter-force.',jsonb_build_object('principal_actors',array['yachie','saki','keiki','mayumi','eika','kutaka']),'src_wbawc','official',85,'["incident","wbawc","beast_realm"]'::jsonb),
  ('claim_incident_market_cards','gensokyo_main','incident','incident_market_cards','summary','The market-card incident turns exchange, cards, and circulation into the core grammar of public disruption.',jsonb_build_object('principal_actors',array['takane','sannyo','misumaru','chimata','tsukasa','megumu']),'src_um','official',81,'["incident","um","market"]'::jsonb),
  ('claim_incident_living_ghost_conflict','gensokyo_main','incident','incident_living_ghost_conflict','summary','The all-living-ghost conflict expands underworld and beast-realm power overlap through new actors and higher-order command.',jsonb_build_object('principal_actors',array['biten','enoko','chiyari','hisami','zanmu']),'src_uDoALG','official',83,'["incident","19","underworld"]'::jsonb)
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
  ('chronicle_gensokyo_history:chapter:major_incidents','chronicle_gensokyo_history','major_incidents',3,'Major Recorded Incidents','A historian''s compact record of the major incident patterns that shaped public memory in Gensokyo.',null,null,'{}'::jsonb)
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
    'chronicle_entry_major_incidents',
    'chronicle_gensokyo_history',
    'chronicle_gensokyo_history:chapter:major_incidents',
    'major_incidents_overview',
    1,
    'catalog',
    'Major Incidents in Public Memory',
    'A compact account of the disturbance patterns that recur in Gensokyo''s remembered history.',
    'Gensokyo''s major incidents are not identical, yet they often fall into recognizable forms: atmospheric abnormality, seasonal distortion, shrine or temple-centered public strain, underworld excess, market circulation gone unstable, and boundary-linked crisis. Public memory does not preserve every detail equally, but it does preserve which forms of trouble recur and which actors repeatedly make those forms legible.',
    'world',
    'gensokyo_main',
    'keine',
    null,
    null,
    '["history","incidents","catalog"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
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

insert into public.world_chronicle_entry_sources (
  id, entry_id, source_kind, source_ref_id, source_label, weight, notes
)
values
  ('chronicle_entry_major_incidents:src:eosd','chronicle_entry_major_incidents','canon_claim','claim_incident_scarlet_mist','Scarlet Mist Incident',0.95,'Foundational early incident'),
  ('chronicle_entry_major_incidents:src:in','chronicle_entry_major_incidents','canon_claim','claim_incident_eternal_night','Imperishable Night Incident',0.95,'Major lunar-linked incident'),
  ('chronicle_entry_major_incidents:src:lolk','chronicle_entry_major_incidents','canon_claim','claim_incident_lunar_crisis','Lunar Crisis Incident',0.95,'High-scale moon crisis'),
  ('chronicle_entry_major_incidents:src:um','chronicle_entry_major_incidents','canon_claim','claim_incident_market_cards','Card Market Incident',0.85,'Later market-structured incident')
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_ref_id = excluded.source_ref_id,
    source_label = excluded.source_label,
    weight = excluded.weight,
    notes = excluded.notes;

insert into public.world_historian_notes (
  id, world_id, historian_character_id, subject_type, subject_id, note_kind, title, summary, body, source_ref_ids, metadata
)
values
  (
    'historian_note_keine_major_incidents',
    'gensokyo_main',
    'keine',
    'world',
    'gensokyo_main',
    'editorial',
    'On Why Incidents Must Be Grouped',
    'A note on why incidents should be recorded as recurring forms rather than isolated spectacles.',
    'If each incident is recorded only as novelty, the structure of Gensokyo is obscured. The important question is not merely what happened once, but what kinds of disruption recur, what institutions absorb them, and which actors make them visible to the public.',
    '["claim_incident_scarlet_mist","claim_incident_eternal_night","claim_incident_market_cards"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
