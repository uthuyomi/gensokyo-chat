-- World seed: wiki glossary pages for recurring terms

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_shinto','gensokyo_main','terms/shinto','Shinto','glossary','term','shinto','A glossary page for shrine-centered religious order in Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_buddhism','gensokyo_main','terms/buddhism','Buddhism','glossary','term','buddhism','A glossary page for temple-centered religious community and discipline in Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_taoism','gensokyo_main','terms/taoism','Taoism','glossary','term','taoism','A glossary page for hermit cultivation, ritual order, and cultivated authority.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_lunarians','gensokyo_main','terms/lunarians','Lunarians','glossary','term','lunarians','A glossary page for the culturally and politically distinct lunar sphere.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_tengu','gensokyo_main','terms/tengu','Tengu','glossary','term','tengu','A glossary page for mountain authority and fast-moving information actors.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_kappa','gensokyo_main','terms/kappa','Kappa','glossary','term','kappa','A glossary page for engineering, trade, and usable invention culture.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_tsukumogami','gensokyo_main','terms/tsukumogami','Tsukumogami','glossary','term','tsukumogami','A glossary page for awakened objects and their public adaptation into personhood.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_urban_legends','gensokyo_main','terms/urban-legends','Urban Legends','glossary','term','urban_legends','A glossary page for outside-world rumor logic leaking into Gensokyo.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_term_shinto:section:definition','wiki_term_shinto','definition',1,'Definition','Shinto as shrine-centered sacred order.','In Gensokyo, Shinto is tied to shrines, rites, public legitimacy, and the maintenance of visible sacred order through institutions like Hakurei and Moriya.','["claim_glossary_shinto","lore_glossary_shinto"]'::jsonb,'{}'::jsonb),
  ('wiki_term_buddhism:section:definition','wiki_term_buddhism','definition',1,'Definition','Buddhism as temple-centered coexistence structure.','Buddhism in Gensokyo is tied to temple life, discipline, community, and coexistence-minded public religious practice.','["claim_glossary_buddhism","lore_glossary_buddhism"]'::jsonb,'{}'::jsonb),
  ('wiki_term_taoism:section:definition','wiki_term_taoism','definition',1,'Definition','Taoism as cultivated authority.','Taoist actors in Gensokyo tend to be framed through hermit practice, ritual expertise, and claims to cultivated or restored authority.','["claim_glossary_taoism","lore_glossary_taoism"]'::jsonb,'{}'::jsonb),
  ('wiki_term_lunarians:section:definition','wiki_term_lunarians','definition',1,'Definition','Lunarians as distinct political-cultural sphere.','Lunarians should be understood as distinct from ordinary Gensokyo circulation in culture, standards, and political perspective.','["claim_glossary_lunarians","lore_glossary_lunarians"]'::jsonb,'{}'::jsonb),
  ('wiki_term_tengu:section:definition','wiki_term_tengu','definition',1,'Definition','Tengu as authority and media sphere.','Tengu in Gensokyo are not only mountain residents. They also shape circulation of information, reportage, and institutional mountain order.','["claim_glossary_tengu","lore_glossary_tengu"]'::jsonb,'{}'::jsonb),
  ('wiki_term_kappa:section:definition','wiki_term_kappa','definition',1,'Definition','Kappa as engineering and trade culture.','Kappa are strongly associated with useful invention, terrain-savvy engineering, trade, and practical mechanism culture.','["claim_glossary_kappa","lore_glossary_kappa"]'::jsonb,'{}'::jsonb),
  ('wiki_term_tsukumogami:section:definition','wiki_term_tsukumogami','definition',1,'Definition','Tsukumogami as awakened objects.','Tsukumogami stories are about objects becoming persons, then negotiating public identity, performance, and belonging.','["claim_glossary_tsukumogami","lore_glossary_tsukumogami"]'::jsonb,'{}'::jsonb),
  ('wiki_term_urban_legends:section:definition','wiki_term_urban_legends','definition',1,'Definition','Urban legends as leaked rumor logic.','Urban legends in Gensokyo are best understood as outside-world rumor forms leaking into local narrative structure rather than replacing it entirely.','["claim_glossary_urban_legends","lore_glossary_urban_legends"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
