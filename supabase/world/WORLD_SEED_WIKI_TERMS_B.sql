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
