-- World seed: wiki pages for print-work and documentary cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_akyuu','gensokyo_main','characters/hieda-no-akyuu','Hieda no Akyuu','character','character','akyuu','A chronicler of Gensokyo whose role centers on memory, records, and structured historical understanding.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_rinnosuke','gensokyo_main','characters/rinnosuke-morichika','Rinnosuke Morichika','character','character','rinnosuke','A curio merchant and object interpreter whose scenes naturally run through material culture and detached explanation.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kasen','gensokyo_main','characters/kasen-ibaraki','Kasen Ibaraki','character','character','kasen','A hermit advisor suited to corrective guidance, shrine-side discipline, and partially concealed authority.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_sumireko','gensokyo_main','characters/sumireko-usami','Sumireko Usami','character','character','sumireko','An outside-world psychic whose role hinges on urban legends, boundaries, and rumor leakage into Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_location_kourindou','gensokyo_main','locations/kourindou','Kourindou','location','location','kourindou','A curio shop where objects and interpretation drive the center of the scene.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_location_suzunaan','gensokyo_main','locations/suzunaan','Suzunaan','location','location','suzunaan','A village bookshop-library where text circulation produces knowledge, risk, and cultural memory.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_akyuu:section:overview','wiki_character_akyuu','overview',1,'Overview','Akyuu as historian and record keeper.','Akyuu is best used where memory, records, and careful historical framing are part of the scene''s structure rather than optional decoration.','["claim_akyuu_historian","lore_village_records"]'::jsonb,'{}'::jsonb),
  ('wiki_character_rinnosuke:section:overview','wiki_character_rinnosuke','overview',1,'Overview','Rinnosuke as object interpreter.','Rinnosuke Morichika should be framed through objects, explanations, and off-angle material insight rather than routine public incident leadership.','["claim_rinnosuke_object_interpreter","lore_kourindou_objects"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kasen:section:overview','wiki_character_kasen','overview',1,'Overview','Kasen as corrective advisor.','Kasen belongs naturally in scenes of guidance, pressure, and shrine-adjacent discipline that still carry concern beneath criticism.','["claim_kasen_advisor","lore_kasen_guidance"]'::jsonb,'{}'::jsonb),
  ('wiki_character_sumireko:section:overview','wiki_character_sumireko','overview',1,'Overview','Sumireko as urban-legend outsider.','Sumireko is a useful outside-world angle only when her rumors and powers feel like leakage into Gensokyo rather than total replacement of its own logic.','["claim_sumireko_urban_legend","lore_urban_legend_bleed"]'::jsonb,'{}'::jsonb),
  ('wiki_location_kourindou:section:profile','wiki_location_kourindou','profile',1,'Profile','Kourindou as object-reading scene engine.','Kourindou scenes should center on objects, interpretation, and the odd cultural angle created by goods that cross categories and worlds.','["claim_kourindou_profile","lore_kourindou_objects"]'::jsonb,'{}'::jsonb),
  ('wiki_location_suzunaan:section:profile','wiki_location_suzunaan','profile',1,'Profile','Suzunaan as book-circulation node.','Suzunaan is not just shelving. It is a social and narrative node where written material changes hands and can alter what people know or unleash.','["claim_suzunaan_profile","lore_suzunaan_books"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
