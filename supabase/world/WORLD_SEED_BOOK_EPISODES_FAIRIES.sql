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
