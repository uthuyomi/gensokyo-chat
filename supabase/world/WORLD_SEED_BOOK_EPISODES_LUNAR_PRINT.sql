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
