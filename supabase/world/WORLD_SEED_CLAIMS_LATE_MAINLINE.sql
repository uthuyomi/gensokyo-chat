-- World seed: lore and canon claims for late-mainline cast and locations

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_myouren_public_plurality','faction_trait','Myouren Temple Social Breadth','Myouren Temple works best as a broad coexistence institution with many tones under one roof, not a narrow one-note faction.',jsonb_build_object('location_id','myouren_temple'),'["ufo","temple","community"]'::jsonb,80),
  ('gensokyo_main','lore_mausoleum_politics','location_trait','Mausoleum Politics','The Divine Spirit Mausoleum should be treated as a political and rhetorical center as much as a religious site.',jsonb_build_object('location_id','divine_spirit_mausoleum'),'["td","mausoleum","authority"]'::jsonb,82),
  ('gensokyo_main','lore_ddc_reversal_logic','world_rule','Reversal Logic','Shinmyoumaru and Seija stories work best when reversal, grievance, and unstable legitimacy are part of the scene''s structure.',jsonb_build_object('incident','ddc'),'["ddc","reversal","legitimacy"]'::jsonb,79),
  ('gensokyo_main','lore_lunar_distance','world_rule','Lunar Distance','Lunar-capital actors should feel culturally and politically distant from ordinary Gensokyo circulation.',jsonb_build_object('location_id','lunar_capital'),'["lolk","moon","distance"]'::jsonb,86),
  ('gensokyo_main','lore_okina_hidden_access','character_role','Okina as Hidden Access','Okina belongs in stories about doors, patronage, and hidden-stage control rather than straightforward public leadership.',jsonb_build_object('character_id','okina'),'["hsifs","backdoor","secret"]'::jsonb,84),
  ('gensokyo_main','lore_beast_realm_factions','location_trait','Beast Realm Factionality','Beast Realm stories should feel factional, coercive, and explicitly power-structured.',jsonb_build_object('location_id','beast_realm'),'["wbawc","faction","power"]'::jsonb,83),
  ('gensokyo_main','lore_um_market_flow','world_rule','Card and Market Flow','Unconnected Marketeers-era scenes work best when commerce, circulation, and resource flow are treated as story structure.',jsonb_build_object('theme','market'),'["um","market","trade"]'::jsonb,81),
  ('gensokyo_main','lore_nazrin_search_role','character_role','Nazrin Search Logic','Nazrin is strongest when the story needs finding, tracking, or practical clue movement.',jsonb_build_object('character_id','nazrin'),'["nazrin","search"]'::jsonb,72),
  ('gensokyo_main','lore_miko_public_authority','character_role','Miko Public Authority','Miko should feel like a leader shaping an audience, not just another strong individual.',jsonb_build_object('character_id','miko'),'["miko","authority"]'::jsonb,84),
  ('gensokyo_main','lore_seija_contrarian_pressure','character_role','Seija Contrarian Pressure','Seija should produce active inversion and corrosive pressure, not harmless randomness.',jsonb_build_object('character_id','seija'),'["seija","reversal"]'::jsonb,76),
  ('gensokyo_main','lore_junko_high_impact','character_role','Junko High Impact Usage','Junko should be treated as concentrated thematic pressure rather than routine presence.',jsonb_build_object('character_id','junko'),'["junko","high_impact"]'::jsonb,88),
  ('gensokyo_main','lore_takane_trade_frame','character_role','Takane Trade Frame','Takane belongs naturally in commerce and brokerage scenes around mountain trade and market opportunity.',jsonb_build_object('character_id','takane'),'["takane","trade"]'::jsonb,73)
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
  ('claim_nazrin_search_specialist','gensokyo_main','character','nazrin','role','Nazrin is most natural as a finder, scout, and practical search specialist in temple-adjacent or field scenes.',jsonb_build_object('role','scout'),'src_ufo','official',72,'["nazrin","ufo","search"]'::jsonb),
  ('claim_kogasa_surprise','gensokyo_main','character','kogasa','role','Kogasa is best used as a surprise-seeking tsukumogami whose need to be noticed shapes the tone of her scenes.',jsonb_build_object('role','comic_disturbance'),'src_ufo','official',68,'["kogasa","ufo","surprise"]'::jsonb),
  ('claim_murasa_navigation','gensokyo_main','character','murasa','role','Murasa''s role is strongly tied to guidance, movement, and danger-touched invitation.',jsonb_build_object('role','navigator'),'src_ufo','official',71,'["murasa","ufo","captain"]'::jsonb),
  ('claim_nue_ambiguity','gensokyo_main','character','nue','role','Nue introduces ambiguity and unstable identification rather than stable public order.',jsonb_build_object('role','ambiguity_actor'),'src_ufo','official',75,'["nue","ufo","ambiguity"]'::jsonb),
  ('claim_miko_saint_leadership','gensokyo_main','character','miko','role','Miko is properly treated as a saintly political and rhetorical center, not as a casual background figure.',jsonb_build_object('role','power_broker'),'src_td','official',84,'["miko","td","leadership"]'::jsonb),
  ('claim_seiga_intrusion','gensokyo_main','character','seiga','role','Seiga belongs naturally in scenes of selective intrusion, manipulation, and hermit-logic provocation.',jsonb_build_object('role','instigator'),'src_td','official',74,'["seiga","td","intrusion"]'::jsonb),
  ('claim_mamizou_mediator','gensokyo_main','character','mamizou','role','Mamizou is especially useful as a flexible mediator and socially adaptive elder rather than a rigid partisan.',jsonb_build_object('role','mediator'),'src_td','official',76,'["mamizou","td","mediator"]'::jsonb),
  ('claim_seija_rebel','gensokyo_main','character','seija','role','Seija should be understood as an active rebel of inversion and sabotage.',jsonb_build_object('role','rebel'),'src_ddc','official',79,'["seija","ddc","rebel"]'::jsonb),
  ('claim_shinmyoumaru_symbolic_rule','gensokyo_main','character','shinmyoumaru','role','Shinmyoumaru works best as a small sovereign whose scenes emphasize legitimacy, grievance, and unstable empowerment.',jsonb_build_object('role','symbolic_lead'),'src_ddc','official',78,'["shinmyoumaru","ddc","inchling"]'::jsonb),
  ('claim_raiko_independent_tsukumogami','gensokyo_main','character','raiko','role','Raiko is notable as a comparatively independent tsukumogami whose scenes emphasize self-made rhythm and public performance.',jsonb_build_object('role','performer'),'src_ddc','official',70,'["raiko","ddc","music"]'::jsonb),
  ('claim_sagume_lunar_strategy','gensokyo_main','character','sagume','role','Sagume is a strategist of the Lunar Capital and should be framed through restraint, implication, and crisis planning.',jsonb_build_object('role','strategist'),'src_lolk','official',85,'["sagume","lolk","moon"]'::jsonb),
  ('claim_junko_pure_hostility','gensokyo_main','character','junko','role','Junko belongs to scenes of purified hostility and should be treated as high-impact thematic pressure.',jsonb_build_object('role','high_impact_actor'),'src_lolk','official',90,'["junko","lolk","purity"]'::jsonb),
  ('claim_hecatia_scale','gensokyo_main','character','hecatia','role','Hecatia operates at a scale that makes her structurally important but poor for everyday overuse.',jsonb_build_object('role','structural_actor'),'src_lolk','official',88,'["hecatia","lolk","scale"]'::jsonb),
  ('claim_okina_hidden_doors','gensokyo_main','character','okina','role','Okina governs access, hidden routes, and backstage empowerment more than ordinary public leadership.',jsonb_build_object('role','gatekeeper'),'src_hsifs','official',86,'["okina","hsifs","backdoor"]'::jsonb),
  ('claim_narumi_local_guardian','gensokyo_main','character','narumi','role','Narumi is best treated as a grounded local guardian in forest and spirit-adjacent scenes.',jsonb_build_object('role','local_guardian'),'src_hsifs','official',67,'["narumi","hsifs","forest"]'::jsonb),
  ('claim_yachie_faction_leader','gensokyo_main','character','yachie','role','Yachie is a strategic faction leader whose power expresses itself through leverage and indirect control.',jsonb_build_object('role','faction_leader'),'src_wbawc','official',83,'["yachie","wbawc","faction"]'::jsonb),
  ('claim_keiki_creator_order','gensokyo_main','character','keiki','role','Keiki is a creator-god actor best used in stories of designed order and anti-predatory construction.',jsonb_build_object('role','system_builder'),'src_wbawc','official',80,'["keiki","wbawc","creator"]'::jsonb),
  ('claim_takane_broker','gensokyo_main','character','takane','role','Takane should be framed as a broker of mountain commerce and practical market opportunity.',jsonb_build_object('role','broker'),'src_um','official',75,'["takane","um","trade"]'::jsonb),
  ('claim_chimata_market_patron','gensokyo_main','character','chimata','role','Chimata is a market patron whose scenes should foreground exchange and value as social structure.',jsonb_build_object('role','market_patron'),'src_um','official',80,'["chimata","um","market"]'::jsonb),
  ('claim_tsukasa_soft_corruption','gensokyo_main','character','tsukasa','role','Tsukasa is most natural in manipulation and soft corruption rather than open command.',jsonb_build_object('role','operator'),'src_um','official',74,'["tsukasa","um","manipulation"]'::jsonb),
  ('claim_megumu_mountain_authority','gensokyo_main','character','megumu','role','Megumu belongs to mountain authority scenes shaped by elevated institutional management.',jsonb_build_object('role','institutional_leader'),'src_um','official',77,'["megumu","um","tengu"]'::jsonb),
  ('claim_divine_spirit_mausoleum_profile','gensokyo_main','location','divine_spirit_mausoleum','profile','The Divine Spirit Mausoleum is a place of ritual authority, restoration politics, and strategic self-presentation.',jsonb_build_object('role','mausoleum_authority'),'src_td','official',83,'["location","td","mausoleum"]'::jsonb),
  ('claim_shining_needle_castle_profile','gensokyo_main','location','shining_needle_castle','profile','Shining Needle Castle belongs to reversal-era stories of grievance, unstable hierarchy, and symbolic overturning.',jsonb_build_object('role','reversal_stage'),'src_ddc','official',78,'["location","ddc","castle"]'::jsonb),
  ('claim_lunar_capital_profile','gensokyo_main','location','lunar_capital','profile','The Lunar Capital should feel ordered, pure, and culturally distant from ordinary Gensokyo.',jsonb_build_object('role','lunar_center'),'src_lolk','official',87,'["location","lolk","moon"]'::jsonb),
  ('claim_backdoor_realm_profile','gensokyo_main','location','backdoor_realm','profile','The Backdoor Realm is defined by hidden entry, selective empowerment, and unseen stage control.',jsonb_build_object('role','hidden_access_space'),'src_hsifs','official',84,'["location","hsifs","backdoor"]'::jsonb),
  ('claim_beast_realm_profile','gensokyo_main','location','beast_realm','profile','The Beast Realm is structured by rival factions, coercive power, and strategic predation.',jsonb_build_object('role','factional_realm'),'src_wbawc','official',84,'["location","wbawc","beast_realm"]'::jsonb),
  ('claim_rainbow_dragon_cave_profile','gensokyo_main','location','rainbow_dragon_cave','profile','Rainbow Dragon Cave is suited to stories of hidden resources, market circulation, and mountain-adjacent trade.',jsonb_build_object('role','market_cave'),'src_um','official',79,'["location","um","market"]'::jsonb)
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
