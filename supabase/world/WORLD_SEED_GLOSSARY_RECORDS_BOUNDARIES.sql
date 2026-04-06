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
