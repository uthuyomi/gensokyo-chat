-- World seed: print-work, documentation, and urban-legend claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_village_records','world_rule','Village Record Logic','Gensokyo''s human-side continuity becomes much easier to maintain when records, teachers, and booksellers are treated as active social infrastructure.',jsonb_build_object('focus',array['akyuu','keine','kosuzu']),'["records","village","history"]'::jsonb,84),
  ('gensokyo_main','lore_kourindou_objects','location_trait','Kourindou Object Logic','Kourindou scenes work best when objects and their interpretation drive the exchange.',jsonb_build_object('location_id','kourindou'),'["kourindou","objects"]'::jsonb,74),
  ('gensokyo_main','lore_suzunaan_books','location_trait','Suzunaan Book Logic','Suzunaan should be treated as a book-circulation node, not just a shop front.',jsonb_build_object('location_id','suzunaan'),'["suzunaan","books"]'::jsonb,76),
  ('gensokyo_main','lore_hatate_media_angle','character_role','Hatate Media Angle','Hatate is more naturally a trend-sensitive observer than a broad public authority.',jsonb_build_object('character_id','hatate'),'["hatate","media"]'::jsonb,71),
  ('gensokyo_main','lore_kasen_guidance','character_role','Kasen Guidance Logic','Kasen belongs to scenes of discipline, advice, and partially concealed deeper authority.',jsonb_build_object('character_id','kasen'),'["kasen","guidance"]'::jsonb,79),
  ('gensokyo_main','lore_urban_legend_bleed','world_rule','Urban Legend Bleed','Outside-world rumor logic can enter Gensokyo scenes, but it should feel like a leak or contamination, not a full replacement of local rules.',jsonb_build_object('focus','sumireko'),'["ulil","rumor","boundary"]'::jsonb,77),
  ('gensokyo_main','lore_yorigami_pair','character_role','Yorigami Pair Logic','Joon and Shion work best as an unequal pair of glamour and depletion rather than independent random walk-ons.',jsonb_build_object('characters',array['joon','shion']),'["aocf","yorigami","pair"]'::jsonb,75)
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
  ('claim_rinnosuke_object_interpreter','gensokyo_main','character','rinnosuke','role','Rinnosuke is best treated as an interpreter of objects, tools, and outside-world remnants rather than a front-line incident lead.',jsonb_build_object('role','interpreter'),'src_lotus_asia','official',81,'["rinnosuke","objects","cola"]'::jsonb),
  ('claim_akyuu_historian','gensokyo_main','character','akyuu','role','Akyuu is a chronicler whose narrative value lies in structured memory, records, and historical framing.',jsonb_build_object('role','historian'),'src_sixty_years','official',88,'["akyuu","history","records"]'::jsonb),
  ('claim_kosuzu_book_curator','gensokyo_main','character','kosuzu','role','Kosuzu belongs naturally in book-centered stories where curiosity and textual danger coexist.',jsonb_build_object('role','librarian'),'src_fs','official',78,'["kosuzu","books","fs"]'::jsonb),
  ('claim_hatate_trend_observer','gensokyo_main','character','hatate','role','Hatate is a trend-sensitive tengu observer whose reporting logic differs from Aya''s more frontal style.',jsonb_build_object('role','observer'),'src_ds','official',73,'["hatate","tengu","media"]'::jsonb),
  ('claim_kasen_advisor','gensokyo_main','character','kasen','role','Kasen is a corrective advisor around shrine-side life and should be framed through guidance and pressure rather than idle presence.',jsonb_build_object('role','advisor'),'src_wahh','official',82,'["kasen","advisor","wahh"]'::jsonb),
  ('claim_sumireko_urban_legend','gensokyo_main','character','sumireko','role','Sumireko is a boundary-leaking outsider best used through urban legends and outside-world rumor pressure.',jsonb_build_object('role','outsider'),'src_ulil','official',79,'["sumireko","urban_legend","outside_world"]'::jsonb),
  ('claim_joon_social_drain','gensokyo_main','character','joon','role','Joon''s scenes should foreground glamour, appetite, and social drain under attractive presentation.',jsonb_build_object('role','social_drain'),'src_aocf','official',74,'["joon","aocf","glamour"]'::jsonb),
  ('claim_shion_misfortune','gensokyo_main','character','shion','role','Shion should be understood through depletion, bad luck, and the social cost of misfortune.',jsonb_build_object('role','misfortune_actor'),'src_aocf','official',75,'["shion","aocf","misfortune"]'::jsonb),
  ('claim_kourindou_profile','gensokyo_main','location','kourindou','profile','Kourindou is a curio space where objects and interpretation are central to the scene.',jsonb_build_object('role','curio_shop'),'src_lotus_asia','official',77,'["location","kourindou","objects"]'::jsonb),
  ('claim_suzunaan_profile','gensokyo_main','location','suzunaan','profile','Suzunaan is a village book node where circulation of texts can create both knowledge and trouble.',jsonb_build_object('role','bookshop_library'),'src_fs','official',79,'["location","suzunaan","books"]'::jsonb)
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
