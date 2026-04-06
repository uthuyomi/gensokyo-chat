-- World seed: glossary terms for religions, realms, and recurring concepts

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_glossary_shinto','glossary_term','Shinto in Gensokyo','Shinto in Gensokyo is tied to shrine institutions, rites, and public-facing sacred order.',jsonb_build_object('term','shinto'),'["glossary","religion","shinto"]'::jsonb,80),
  ('gensokyo_main','lore_glossary_buddhism','glossary_term','Buddhism in Gensokyo','Buddhism in Gensokyo is tied to temple life, discipline, coexistence, and public religious community.',jsonb_build_object('term','buddhism'),'["glossary","religion","buddhism"]'::jsonb,79),
  ('gensokyo_main','lore_glossary_taoism','glossary_term','Taoism in Gensokyo','Taoist actors in Gensokyo are tied to hermit practice, ritual order, and claims of cultivated authority.',jsonb_build_object('term','taoism'),'["glossary","religion","taoism"]'::jsonb,78),
  ('gensokyo_main','lore_glossary_lunarians','glossary_term','Lunarian Sphere','Lunarian actors should be treated as culturally and politically distinct from ordinary Gensokyo circulation.',jsonb_build_object('term','lunarians'),'["glossary","moon","lunarian"]'::jsonb,83),
  ('gensokyo_main','lore_glossary_tengu','glossary_term','Tengu Information Sphere','Tengu in Gensokyo are not merely mountain residents; they also shape reportage, speed of circulation, and mediated public narrative.',jsonb_build_object('term','tengu'),'["glossary","tengu","media"]'::jsonb,76),
  ('gensokyo_main','lore_glossary_kappa','glossary_term','Kappa Engineering Sphere','Kappa are strongly associated with engineering, trade, terrain knowledge, and usable invention culture.',jsonb_build_object('term','kappa'),'["glossary","kappa","engineering"]'::jsonb,76),
  ('gensokyo_main','lore_glossary_tsukumogami','glossary_term','Tsukumogami','Tsukumogami stories work best when objects, new identity, and public adaptation all matter at once.',jsonb_build_object('term','tsukumogami'),'["glossary","tsukumogami","objects"]'::jsonb,74),
  ('gensokyo_main','lore_glossary_urban_legends','glossary_term','Urban Legends','Urban legends in Gensokyo should feel like outside-world rumor logic leaking into local narrative structure.',jsonb_build_object('term','urban_legends'),'["glossary","urban_legends","outside_world"]'::jsonb,77),
  ('gensokyo_main','lore_glossary_beast_realm','glossary_term','Beast Realm Power','Beast Realm power is factional, coercive, and structurally distinct from ordinary village or shrine sociality.',jsonb_build_object('term','beast_realm'),'["glossary","beast_realm","power"]'::jsonb,80),
  ('gensokyo_main','lore_glossary_dream_world','glossary_term','Dream World','Dream World should be treated as symbolic space with routes, mediators, and recurring logic, not random nonsense.',jsonb_build_object('term','dream_world'),'["glossary","dream","symbolic"]'::jsonb,78)
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
  ('claim_glossary_shinto','gensokyo_main','term','shinto','glossary','Shinto in Gensokyo is centered on shrines, rites, and public sacred legitimacy.',jsonb_build_object('linked_institutions',array['hakurei_shrine','moriya_shrine']),'src_hm','official',79,'["glossary","shinto","religion"]'::jsonb),
  ('claim_glossary_buddhism','gensokyo_main','term','buddhism','glossary','Buddhism in Gensokyo is tied to temple life, discipline, and organized coexistence.',jsonb_build_object('linked_institutions',array['myouren_temple']),'src_hm','official',79,'["glossary","buddhism","religion"]'::jsonb),
  ('claim_glossary_taoism','gensokyo_main','term','taoism','glossary','Taoist actors in Gensokyo are bound to cultivated authority, ritual, and hermit-derived legitimacy.',jsonb_build_object('linked_characters',array['miko','futo','seiga']),'src_hm','official',78,'["glossary","taoism","religion"]'::jsonb),
  ('claim_glossary_lunarians','gensokyo_main','term','lunarians','glossary','Lunarian actors should be framed as culturally distant, high-standard, and politically distinct from ordinary Gensokyo life.',jsonb_build_object('linked_characters',array['eirin','kaguya','reisen','sagume']),'src_lolk','official',84,'["glossary","lunarians","moon"]'::jsonb),
  ('claim_glossary_tengu','gensokyo_main','term','tengu','glossary','Tengu are strongly associated with rapid information flow, mountain authority, and public reportage.',jsonb_build_object('linked_characters',array['aya','hatate','megumu','momiji']),'src_boaFW','official',77,'["glossary","tengu","media"]'::jsonb),
  ('claim_glossary_kappa','gensokyo_main','term','kappa','glossary','Kappa are tied to engineering, trade, river and mountain terrain, and useful invention culture.',jsonb_build_object('linked_characters',array['nitori','takane']),'src_mofa','official',77,'["glossary","kappa","engineering"]'::jsonb),
  ('claim_glossary_tsukumogami','gensokyo_main','term','tsukumogami','glossary','Tsukumogami should be understood through awakened objects, new personhood, and public adaptation.',jsonb_build_object('linked_characters',array['kogasa','raiko','benben','yatsuhashi']),'src_ddc','official',75,'["glossary","tsukumogami","objects"]'::jsonb),
  ('claim_glossary_urban_legends','gensokyo_main','term','urban_legends','glossary','Urban legends represent outside-world rumor pressure leaking into Gensokyo''s narrative structure.',jsonb_build_object('linked_characters',array['sumireko']),'src_ulil','official',78,'["glossary","urban_legends","rumor"]'::jsonb),
  ('claim_glossary_beast_realm','gensokyo_main','term','beast_realm','glossary','Beast Realm power should be framed as factional, coercive, and pressure-driven.',jsonb_build_object('linked_characters',array['yachie','saki','enoko','zanmu']),'src_wbawc','official',81,'["glossary","beast_realm","power"]'::jsonb),
  ('claim_glossary_dream_world','gensokyo_main','term','dream_world','glossary','Dream World is symbolic space with its own routes, mediators, and conflict logic.',jsonb_build_object('linked_characters',array['doremy']),'src_lolk','official',79,'["glossary","dream_world","dream"]'::jsonb)
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
