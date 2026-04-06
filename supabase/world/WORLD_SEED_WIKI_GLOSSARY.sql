-- World seed: wiki glossary pages for institutions and world rules

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_glossary_hakurei','gensokyo_main','glossary/hakurei-shrine','Hakurei Shrine','glossary','institution','hakurei_shrine','A glossary entry for the shrine as sacred site and public balancing institution.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_moriya','gensokyo_main','glossary/moriya-shrine','Moriya Shrine','glossary','institution','moriya_shrine','A glossary entry for Moriya Shrine as proactive faith institution and mountain-side authority.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_myouren','gensokyo_main','glossary/myouren-temple','Myouren Temple','glossary','institution','myouren_temple','A glossary entry for Myouren Temple as coexistence-oriented religious community.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_eientei','gensokyo_main','glossary/eientei','Eientei','glossary','institution','eientei','A glossary entry for Eientei as secluded expert household with lunar ties.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_spell_cards','gensokyo_main','glossary/spell-card-rules','Spell Card Rules','glossary','world','gensokyo_main','A glossary entry for ritualized conflict and its social constraints.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_incidents','gensokyo_main','glossary/incidents','Incidents','glossary','world','gensokyo_main','A glossary entry for recurring disturbances and how they become public history.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_boundaries','gensokyo_main','glossary/boundaries','Boundaries','glossary','world','gensokyo_main','A glossary entry for the many structural meanings of boundaries in Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_glossary_human_village','gensokyo_main','glossary/human-village','Human Village','glossary','institution','human_village','A glossary entry for the main human public sphere, rumor hub, and social memory center.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_glossary_hakurei:section:definition','wiki_glossary_hakurei','definition',1,'Definition','Hakurei Shrine as sacred and public institution.','Hakurei Shrine is not only a religious site. It is one of the chief public balancing institutions through which incidents become visible, legible, and socially answered inside Gensokyo.','["claim_glossary_hakurei","lore_glossary_hakurei"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_moriya:section:definition','wiki_glossary_moriya','definition',1,'Definition','Moriya Shrine as proactive institution.','Moriya Shrine should be understood as a mountain-side faith institution that gathers influence proactively and treats expansion as a practical problem rather than a taboo.','["claim_glossary_moriya","lore_glossary_moriya"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_myouren:section:definition','wiki_glossary_myouren','definition',1,'Definition','Myouren Temple as coexistence institution.','Myouren Temple is best treated as a broad coexistence-minded religious community whose public reach extends beyond any single resident or incident.','["claim_glossary_myouren","lore_glossary_myouren"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_eientei:section:definition','wiki_glossary_eientei','definition',1,'Definition','Eientei as secluded expert household.','Eientei combines seclusion, expertise, lunar history, and selective hospitality into one institutional household shape.','["claim_glossary_eientei","lore_glossary_eientei"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_spell_cards:section:definition','wiki_glossary_spell_cards','definition',1,'Definition','Spell card rules as ritualized conflict culture.','Spell card rules are a social and symbolic system that makes conflict legible, bounded, and repeatable without collapsing Gensokyo into constant total war.','["claim_glossary_spell_cards","lore_glossary_spell_cards"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_incidents:section:definition','wiki_glossary_incidents','definition',1,'Definition','Incidents as recurring public disturbances.','An incident is not merely a strange event. It is a disturbance that enters rumor, draws response, and becomes part of shared memory and later record.','["claim_glossary_incidents","lore_glossary_incidents"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_boundaries:section:definition','wiki_glossary_boundaries','definition',1,'Definition','Boundaries as structural grammar.','Boundaries in Gensokyo are spatial, social, symbolic, and often personified. They shape movement, exclusion, contact, and who can intervene from which angle.','["claim_glossary_boundaries","lore_glossary_boundaries"]'::jsonb,'{}'::jsonb),
  ('wiki_glossary_human_village:section:definition','wiki_glossary_human_village','definition',1,'Definition','Human Village as public sphere.','The Human Village is the main public sphere of ordinary human life, trade, rumor, instruction, and memory inside Gensokyo.','["claim_glossary_human_village","lore_glossary_human_village"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
