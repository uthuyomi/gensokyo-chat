-- World seed: chronicle, wiki, and chat context
-- Generated from WORLD_FULL_SETUP.sql for maintainable split loading.

insert into public.world_chronicle_books (
  id, world_id, title, author_character_id, chronicle_type, era_label, summary, tone, is_public, metadata
)
values
  (
    'chronicle_gensokyo_history',
    'gensokyo_main',
    'Chronicle of Gensokyo',
    'keine',
    'history',
    'Current Era',
    'A continuously maintained historical compilation intended to summarize major places, actors, and notable events in Gensokyo.',
    'measured',
    true,
    jsonb_build_object('editorial_style', 'keine_archival')
  ),
  (
    'chronicle_seasonal_incidents',
    'gensokyo_main',
    'Seasonal Gatherings and Incidents',
    'keine',
    'incident_record',
    'Recent Seasons',
    'A focused record of seasonal public events, disturbances, and how they entered common memory.',
    'documentary',
    true,
    jsonb_build_object('editorial_style', 'public_record')
  )
on conflict (id) do update
set title = excluded.title,
    author_character_id = excluded.author_character_id,
    chronicle_type = excluded.chronicle_type,
    era_label = excluded.era_label,
    summary = excluded.summary,
    tone = excluded.tone,
    is_public = excluded.is_public,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_chronicle_chapters (
  id, book_id, chapter_code, chapter_order, title, summary, period_start, period_end, metadata
)
values
  (
    'chronicle_gensokyo_history:chapter:foundations',
    'chronicle_gensokyo_history',
    'foundations',
    1,
    'Foundations of the World',
    'A structural overview of how Gensokyo maintains balance across people, places, and recurring disturbances.',
    null,
    null,
    '{}'::jsonb
  ),
  (
    'chronicle_gensokyo_history:chapter:principal_actors',
    'chronicle_gensokyo_history',
    'principal_actors',
    2,
    'Principal Actors',
    'A summary of those individuals whose roles most strongly shape the public life of Gensokyo.',
    null,
    null,
    '{}'::jsonb
  ),
  (
    'chronicle_seasonal_incidents:chapter:spring_festival',
    'chronicle_seasonal_incidents',
    'spring_festival',
    1,
    'Hakurei Spring Festival',
    'An ongoing record of the Hakurei Spring Festival as it passes from rumor into a shared public event.',
    now() - interval '1 day',
    now() + interval '7 day',
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
    'chronicle_entry_gensokyo_balance',
    'chronicle_gensokyo_history',
    'chronicle_gensokyo_history:chapter:foundations',
    'gensokyo_balance',
    1,
    'essay',
    'On the Balance of Gensokyo',
    'A summary of the social and symbolic balance that allows Gensokyo to continue functioning.',
    'Gensokyo is not merely a collection of locations and residents. It persists because conflict, authority, rumor, and public life settle into repeating forms rather than endless collapse. Those who resolve incidents, those who amplify them, and those who record them all participate in the maintenance of that balance.',
    'world',
    'gensokyo_main',
    'keine',
    null,
    null,
    '["balance","history","world_rule"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'chronicle_entry_principal_actors',
    'chronicle_gensokyo_history',
    'chronicle_gensokyo_history:chapter:principal_actors',
    'principal_actors',
    1,
    'catalog',
    'Principal Public Actors of Gensokyo',
    'A historian''s overview of the people most likely to shape public events and incidents.',
    'Certain names recur whenever Gensokyo shifts: Reimu Hakurei, by official burden; Marisa Kirisame, by restless initiative; Aya Shameimaru, by speed of circulation; and other figures whose institutional or symbolic weight can reshape a local event into a widely remembered one.',
    'world',
    'gensokyo_main',
    'keine',
    null,
    null,
    '["actors","history","reference"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'chronicle_entry_spring_festival',
    'chronicle_seasonal_incidents',
    'chronicle_seasonal_incidents:chapter:spring_festival',
    'spring_festival_preparation',
    1,
    'incident_record',
    'The Hakurei Spring Festival Takes Public Shape',
    'An account of how a local seasonal preparation became a visible shared event.',
    'What first circulated as rumor in the Human Village soon hardened into expectation. Once preparations became visible at the Hakurei Shrine, the event ceased to be private labor and entered the category of public life. As ever, the work did not fall equally upon all involved.',
    'event',
    'story_spring_festival_001',
    'keine',
    'story_spring_festival_001',
    'story_spring_festival_001:history:preparation_visible',
    '["festival","spring","incident_record"]'::jsonb,
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
  ('chronicle_entry_gensokyo_balance:src:lore', 'chronicle_entry_gensokyo_balance', 'lore_entry', 'lore_gensokyo_balance', 'Balance Between Human and Youkai', 1.0, 'Foundational lore source'),
  ('chronicle_entry_gensokyo_balance:src:claim', 'chronicle_entry_gensokyo_balance', 'canon_claim', 'claim_spell_card_constraint', 'Spell Card Constraint', 0.9, 'Supports the non-total-war framing'),
  ('chronicle_entry_principal_actors:src:claim:reimu', 'chronicle_entry_principal_actors', 'canon_claim', 'claim_reimu_incident_resolver', 'Reimu Incident Resolver Claim', 1.0, 'Primary actor reference'),
  ('chronicle_entry_principal_actors:src:claim:marisa', 'chronicle_entry_principal_actors', 'canon_claim', 'claim_marisa_incident_actor', 'Marisa Incident Actor Claim', 0.9, 'Primary actor reference'),
  ('chronicle_entry_spring_festival:src:history:rumor', 'chronicle_entry_spring_festival', 'history', 'story_spring_festival_001:history:opening_rumor', 'Village Rumor History', 0.8, 'Chronological lead-in'),
  ('chronicle_entry_spring_festival:src:history:prep', 'chronicle_entry_spring_festival', 'history', 'story_spring_festival_001:history:preparation_visible', 'Preparation Visible History', 1.0, 'Main event source')
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
    'historian_note_keine_reimu',
    'gensokyo_main',
    'keine',
    'character',
    'reimu',
    'editorial',
    'On Reimu''s Place in Public Memory',
    'A note on why Reimu appears disproportionately in historical summaries of disturbances.',
    'Reimu Hakurei appears often in the records not because all events are hers, but because many disturbances become legible to the public through the fact of her involvement. This should not be mistaken for solitary authorship of Gensokyo''s history.',
    '["claim_reimu_incident_resolver","lore_reimu_position"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'historian_note_keine_festival',
    'gensokyo_main',
    'keine',
    'event',
    'story_spring_festival_001',
    'editorial',
    'On Recording Seasonal Events',
    'A note on why public seasonal events deserve historical treatment.',
    'Seasonal gatherings are not trivial simply because they are peaceful. They show how Gensokyo organizes expectation, labor, rumor, and local cooperation without requiring a formal crisis.',
    '["story_spring_festival_001:history:opening_rumor","story_spring_festival_001:history:preparation_visible"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set title = excluded.title,
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
    'wiki_character_reimu',
    'gensokyo_main',
    'characters/reimu-hakurei',
    'Reimu Hakurei',
    'character',
    'character',
    'reimu',
    'Shrine maiden of the Hakurei Shrine and a central public actor in Gensokyo incident resolution.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_location_hakurei_shrine',
    'gensokyo_main',
    'locations/hakurei-shrine',
    'Hakurei Shrine',
    'location',
    'location',
    'hakurei_shrine',
    'A shrine that acts both as a symbol of order and as a magnet for public trouble.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_rule_spell_cards',
    'gensokyo_main',
    'world/spell-card-rules',
    'Spell Card Rule Culture',
    'world_rule',
    'world',
    'gensokyo_main',
    'A summary of how conflict is ritualized and socially constrained within Gensokyo.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_event_spring_festival',
    'gensokyo_main',
    'events/hakurei-spring-festival',
    'Hakurei Spring Festival',
    'event',
    'event',
    'story_spring_festival_001',
    'An ongoing seasonal event centered on public preparation, uneven enthusiasm, and shrine-centered visibility.',
    'published',
    'chronicle_seasonal_incidents',
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
    'wiki_character_reimu:section:overview',
    'wiki_character_reimu',
    'overview',
    1,
    'Overview',
    'Reimu as a public figure and incident resolver.',
    'Reimu Hakurei is central to many public disturbances in Gensokyo. Her role is not simply ceremonial; it is tied to how the public understands restoration of balance.',
    '["claim_reimu_incident_resolver","lore_reimu_position"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_location_hakurei_shrine:section:profile',
    'wiki_location_hakurei_shrine',
    'profile',
    1,
    'Profile',
    'Hakurei Shrine as social and symbolic space.',
    'The Hakurei Shrine functions both as a shrine and as a public symbolic center where incidents, rumors, and gatherings often become visible to the wider world.',
    '["lore_hakurei_role"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_rule_spell_cards:section:world_rule',
    'wiki_rule_spell_cards',
    'world_rule',
    1,
    'Rule Summary',
    'Conflict limitation through ritualized structure.',
    'Gensokyo does not treat every dispute as an unrestricted fight. Cultural and formal rules shape many conflicts into bounded contests, helping preserve continuity instead of permanent ruin.',
    '["claim_spell_card_constraint","lore_spell_card_rules"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_event_spring_festival:section:current_state',
    'wiki_event_spring_festival',
    'current_state',
    1,
    'Current State',
    'The event is in preparation and already public.',
    'The Hakurei Spring Festival has passed beyond rumor. Preparations are visible, public expectations are forming, and the people involved are not yet aligned in mood or motive.',
    '["story_spring_festival_001:history:opening_rumor","story_spring_festival_001:history:preparation_visible"]'::jsonb,
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
    'chat_context_global_reimu_shrine',
    'gensokyo_main',
    'global',
    'reimu',
    'hakurei_shrine',
    'story_spring_festival_001',
    'character_location_story',
    'Reimu is at Hakurei Shrine during a public preparation phase and is likely to frame the festival as work before celebration.',
    jsonb_build_object(
      'memory_ids', array['story_spring_festival_001:memory:reimu:prep'],
      'claim_ids', array['claim_reimu_incident_resolver'],
      'event_ids', array['story_spring_festival_001']
    ),
    0.95,
    now()
  ),
  (
    'chat_context_global_aya_village',
    'gensokyo_main',
    'global',
    'aya',
    'human_village',
    'story_spring_festival_001',
    'character_location_story',
    'Aya is positioned to talk about how rumors and public framing are shaping the spring festival before it fully opens.',
    jsonb_build_object(
      'memory_ids', array['story_spring_festival_001:memory:aya:rumor'],
      'claim_ids', array['claim_aya_public_narrative'],
      'event_ids', array['story_spring_festival_001']
    ),
    0.88,
    now()
  ),
  (
    'chat_context_global_world_balance',
    'gensokyo_main',
    'global',
    null,
    '',
    null,
    'world_rule_summary',
    'Gensokyo persists through a managed balance of conflict, order, rumor, and recurring public roles.',
    jsonb_build_object(
      'lore_ids', array['lore_gensokyo_balance','lore_spell_card_rules'],
      'claim_ids', array['claim_spell_card_constraint']
    ),
    1.00,
    now()
  )
on conflict (id) do update
set summary = excluded.summary,
    payload = excluded.payload,
    freshness_score = excluded.freshness_score,
    last_used_at = excluded.last_used_at,
    updated_at = now();

-- Seed examples for user-scoped chat/history tables are intentionally omitted
-- because they depend on real authenticated user ids.
-- The tables below are ready for runtime population:
-- - world_user_chat_summaries
-- - world_user_seen_entries
