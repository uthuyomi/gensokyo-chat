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
