-- World seed: wiki pages for factions and social functions

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_faction_hakurei','gensokyo_main','factions/hakurei','Hakurei Sphere','glossary','faction','hakurei','A glossary page for the shrine-centered balancing sphere around Hakurei.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_faction_moriya','gensokyo_main','factions/moriya','Moriya Sphere','glossary','faction','moriya','A glossary page for the organized, expansion-minded Moriya sphere.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_faction_sdm','gensokyo_main','factions/scarlet-devil-mansion','Scarlet Devil Mansion Sphere','glossary','faction','sdm','A glossary page for the SDM household hierarchy and symbolic public power.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_faction_eientei','gensokyo_main','factions/eientei','Eientei Sphere','glossary','faction','eientei','A glossary page for the secluded expert household of Eientei.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_social_rumor','gensokyo_main','social-functions/rumor-network','Rumor Network','glossary','social_function','rumor_network','A glossary page for how rumor moves through Gensokyo public life.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_social_festivals','gensokyo_main','social-functions/festivals','Festivals','glossary','social_function','festivals','A glossary page for festivals as public social mechanisms rather than ornament.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_social_trade','gensokyo_main','social-functions/trade','Trade and Exchange','glossary','social_function','trade','A glossary page for exchange, stalls, brokerage, and market-scale circulation.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_faction_hakurei:section:definition','wiki_faction_hakurei','definition',1,'Definition','Hakurei as balancing sphere.','The Hakurei sphere is not a large institution by staff count, but it is one of the most important balancing layers through which public incidents become answerable.', '["claim_faction_hakurei","lore_faction_hakurei"]'::jsonb,'{}'::jsonb),
  ('wiki_faction_moriya:section:definition','wiki_faction_moriya','definition',1,'Definition','Moriya as organized ambitious sphere.','The Moriya sphere combines mountain-side authority, organized faith gathering, and strategic expansion into public life.', '["claim_faction_moriya","lore_faction_moriya"]'::jsonb,'{}'::jsonb),
  ('wiki_faction_sdm:section:definition','wiki_faction_sdm','definition',1,'Definition','SDM as hierarchized household sphere.','The Scarlet Devil Mansion sphere is best understood as a hierarchized household whose symbolic power and threshold control matter as much as its residents.', '["claim_faction_sdm","lore_faction_sdm"]'::jsonb,'{}'::jsonb),
  ('wiki_faction_eientei:section:definition','wiki_faction_eientei','definition',1,'Definition','Eientei as secluded expert sphere.','The Eientei sphere joins medicine, lunar history, selective access, and local misdirection into one household structure.', '["claim_faction_eientei","lore_faction_eientei"]'::jsonb,'{}'::jsonb),
  ('wiki_social_rumor:section:definition','wiki_social_rumor','definition',1,'Definition','Rumor as transmission network.','Rumor in Gensokyo is a real network carried by the village, the press-minded tengu, and recurring public actors who make events legible.', '["claim_social_rumor_network","lore_social_rumor_network"]'::jsonb,'{}'::jsonb),
  ('wiki_social_festivals:section:definition','wiki_social_festivals','definition',1,'Definition','Festivals as public mechanism.','Festivals should be read as tests of cooperation, labor distribution, hierarchy, and public mood rather than mere decorative downtime.', '["claim_social_festivals","lore_social_festivals"]'::jsonb,'{}'::jsonb),
  ('wiki_social_trade:section:definition','wiki_social_trade','definition',1,'Definition','Trade as social circulation.','Trade in Gensokyo includes shops, stalls, curio movement, brokerage, and market-scale divine or semi-divine influence.', '["claim_social_trade","lore_social_trade"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
