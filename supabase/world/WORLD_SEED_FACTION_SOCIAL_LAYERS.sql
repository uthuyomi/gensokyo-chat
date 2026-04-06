-- World seed: social layers, faction frames, and organizational glue

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_faction_hakurei','faction_trait','Hakurei Sphere','The Hakurei sphere is best treated as a public balancing layer rather than a large staffed bureaucracy.',jsonb_build_object('faction_id','hakurei'),'["faction","hakurei","public_balance"]'::jsonb,84),
  ('gensokyo_main','lore_faction_moriya','faction_trait','Moriya Sphere','The Moriya sphere represents organized ambition, gathered faith, and strategic mountain-side reach.',jsonb_build_object('faction_id','moriya'),'["faction","moriya","ambition"]'::jsonb,82),
  ('gensokyo_main','lore_faction_sdm','faction_trait','Scarlet Devil Mansion Sphere','The SDM sphere is structured by household hierarchy, symbolic prestige, and threshold management.',jsonb_build_object('faction_id','sdm'),'["faction","sdm","household"]'::jsonb,83),
  ('gensokyo_main','lore_faction_eientei','faction_trait','Eientei Sphere','The Eientei sphere is structured by seclusion, expertise, moon-linked history, and selective local permeability.',jsonb_build_object('faction_id','eientei'),'["faction","eientei","expertise"]'::jsonb,83),
  ('gensokyo_main','lore_faction_tengu','faction_trait','Tengu Sphere','The tengu sphere joins mountain authority, surveillance, fast mobility, and information shaping.',jsonb_build_object('faction_id','tengu'),'["faction","tengu","media"]'::jsonb,79),
  ('gensokyo_main','lore_faction_kappa','faction_trait','Kappa Sphere','The kappa sphere is built from engineering, trade, terrain knowledge, and practical mechanism exchange.',jsonb_build_object('faction_id','kappa'),'["faction","kappa","engineering"]'::jsonb,79),
  ('gensokyo_main','lore_faction_myouren','faction_trait','Myouren Sphere','The Myouren sphere is a community and coexistence structure broad enough to contain many tones and residents.',jsonb_build_object('faction_id','myouren'),'["faction","myouren","community"]'::jsonb,80),
  ('gensokyo_main','lore_faction_yakumo','faction_trait','Yakumo Sphere','The Yakumo sphere is not a public institution but a structural intervention layer tied to boundaries and shikigami administration.',jsonb_build_object('faction_id','yakumo'),'["faction","yakumo","structural"]'::jsonb,78),
  ('gensokyo_main','lore_social_rumor_network','social_function','Rumor Network','Rumor in Gensokyo should be treated as a real social function carried by the village, tengu, and recurring public actors.',jsonb_build_object('focus',array['human_village','aya','hatate']),'["social","rumor","network"]'::jsonb,86),
  ('gensokyo_main','lore_social_festivals','social_function','Festival Function','Festivals in Gensokyo are social stress-tests of cooperation, labor, hierarchy, and public mood rather than decorative downtime.',jsonb_build_object('focus','festival'),'["social","festival","public_life"]'::jsonb,85),
  ('gensokyo_main','lore_social_teaching','social_function','Teaching and Transmission','Teaching in Gensokyo should be treated as an active continuity mechanism through schools, books, records, and oral correction.',jsonb_build_object('focus',array['keine','akyuu','kosuzu']),'["social","teaching","continuity"]'::jsonb,83),
  ('gensokyo_main','lore_social_trade','social_function','Trade and Exchange','Trade in Gensokyo includes stalls, curio circulation, mountain brokerage, and market-scale divine or semi-divine influence.',jsonb_build_object('focus',array['rinnosuke','takane','chimata','mike']),'["social","trade","exchange"]'::jsonb,82)
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
  ('claim_faction_hakurei','gensokyo_main','faction','hakurei','glossary','The Hakurei sphere is a balancing layer centered on sacred legitimacy and public incident response.',jsonb_build_object('linked_characters',array['reimu','aunn','kasen']),'src_sopm','official',84,'["faction","hakurei"]'::jsonb),
  ('claim_faction_moriya','gensokyo_main','faction','moriya','glossary','The Moriya sphere is organized, ambitious, and oriented toward active faith gathering.',jsonb_build_object('linked_characters',array['sanae','kanako','suwako']),'src_mofa','official',83,'["faction","moriya"]'::jsonb),
  ('claim_faction_sdm','gensokyo_main','faction','sdm','glossary','The Scarlet Devil Mansion sphere is a hierarchized household with symbolic prestige and strong threshold control.',jsonb_build_object('linked_characters',array['remilia','sakuya','meiling','patchouli']),'src_eosd','official',84,'["faction","sdm"]'::jsonb),
  ('claim_faction_eientei','gensokyo_main','faction','eientei','glossary','The Eientei sphere is secluded, expert, and moon-touched, with controlled points of entry into wider life.',jsonb_build_object('linked_characters',array['eirin','kaguya','reisen','tewi']),'src_imperishable_night','official',84,'["faction","eientei"]'::jsonb),
  ('claim_faction_tengu','gensokyo_main','faction','tengu','glossary','The tengu sphere mixes authority, mobility, surveillance, and public mediation of information.',jsonb_build_object('linked_characters',array['aya','hatate','megumu','momiji']),'src_boaFW','official',80,'["faction","tengu"]'::jsonb),
  ('claim_faction_kappa','gensokyo_main','faction','kappa','glossary','The kappa sphere is defined by engineering culture, trade, and practical use of terrain and mechanisms.',jsonb_build_object('linked_characters',array['nitori','takane']),'src_mofa','official',80,'["faction","kappa"]'::jsonb),
  ('claim_social_rumor_network','gensokyo_main','social_function','rumor_network','glossary','Rumor in Gensokyo should be understood as a real transmission network rather than flavor text.',jsonb_build_object('linked_locations',array['human_village']),'src_boaFW','official',86,'["social","rumor"]'::jsonb),
  ('claim_social_festivals','gensokyo_main','social_function','festivals','glossary','Festivals are important public mechanisms for revealing cooperation, strain, and shared expectation.',jsonb_build_object('linked_event','story_spring_festival_001'),'src_sixty_years','official',83,'["social","festival"]'::jsonb),
  ('claim_social_teaching','gensokyo_main','social_function','teaching','glossary','Teaching, records, and books are continuity structures rather than background decoration.',jsonb_build_object('linked_characters',array['keine','akyuu','kosuzu']),'src_fs','official',82,'["social","teaching"]'::jsonb),
  ('claim_social_trade','gensokyo_main','social_function','trade','glossary','Trade in Gensokyo includes everyday stalls, curio circulation, and larger market-scale power.',jsonb_build_object('linked_characters',array['rinnosuke','takane','chimata','mike']),'src_um','official',81,'["social","trade"]'::jsonb)
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
