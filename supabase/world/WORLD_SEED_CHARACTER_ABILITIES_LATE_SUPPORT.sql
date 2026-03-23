-- World seed: additional late-mainline support-cast ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_nazrin','gensokyo_main','character','nazrin','ability','Nazrin is associated with finding, dowsing, and practical clue-tracking under field conditions.',jsonb_build_object('ability_theme','search_and_dowsing'),'src_ufo','official',72,'["ability","nazrin","ufo"]'::jsonb),
  ('claim_ability_kogasa','gensokyo_main','character','kogasa','ability','Kogasa is associated with surprise, emotional startle, and the awkward persistence of wanting to be noticed.',jsonb_build_object('ability_theme','surprise'),'src_ufo','official',69,'["ability","kogasa","ufo"]'::jsonb),
  ('claim_ability_murasa','gensokyo_main','character','murasa','ability','Murasa is associated with dangerous invitation, navigation, and the pull of being lured off stable ground.',jsonb_build_object('ability_theme','watery_navigation_and_lure'),'src_ufo','official',72,'["ability","murasa","ufo"]'::jsonb),
  ('claim_ability_nue','gensokyo_main','character','nue','ability','Nue is associated with unstable identification and the inability to settle cleanly on what is being perceived.',jsonb_build_object('ability_theme','undefined_identity'),'src_ufo','official',75,'["ability","nue","ufo"]'::jsonb),
  ('claim_ability_seiga','gensokyo_main','character','seiga','ability','Seiga is associated with intrusion, selfish immortality logic, and the smooth crossing of boundaries she should not respect.',jsonb_build_object('ability_theme','intrusion_and_hermit_corruption'),'src_td','official',74,'["ability","seiga","td"]'::jsonb),
  ('claim_ability_futo','gensokyo_main','character','futo','ability','Futo is associated with ritual flame, old-style rhetoric, and theatrical Taoist certainty.',jsonb_build_object('ability_theme','ritual_and_flame'),'src_td','official',71,'["ability","futo","td"]'::jsonb),
  ('claim_ability_tojiko','gensokyo_main','character','tojiko','ability','Tojiko is associated with storm-like force and spectral irritation tightly bound to retained station.',jsonb_build_object('ability_theme','storm_spirit_force'),'src_td','official',70,'["ability","tojiko","td"]'::jsonb),
  ('claim_ability_narumi','gensokyo_main','character','narumi','ability','Narumi is associated with grounded guardian force, statuesque stability, and local spiritual defense.',jsonb_build_object('ability_theme','grounded_guardianship'),'src_hsifs','official',69,'["ability","narumi","hsifs"]'::jsonb),
  ('claim_ability_saki','gensokyo_main','character','saki','ability','Saki is associated with speed, predatory pressure, and factional leadership through aggressive forward motion.',jsonb_build_object('ability_theme','predatory_speed'),'src_wbawc','official',74,'["ability","saki","wbawc"]'::jsonb),
  ('claim_ability_misumaru','gensokyo_main','character','misumaru','ability','Misumaru is associated with careful craft, orb-making, and support through precise constructive work.',jsonb_build_object('ability_theme','craft_and_orb_creation'),'src_um','official',72,'["ability","misumaru","um"]'::jsonb),
  ('claim_ability_momoyo','gensokyo_main','character','momoyo','ability','Momoyo is associated with mining, subterranean appetite, and the force needed to extract hidden value from mountain depth.',jsonb_build_object('ability_theme','mining_and_extraction'),'src_um','official',72,'["ability","momoyo","um"]'::jsonb),
  ('claim_ability_megumu','gensokyo_main','character','megumu','ability','Megumu is associated with elevated mountain authority, command scale, and institutional tengu management.',jsonb_build_object('ability_theme','institutional_authority'),'src_um','official',74,'["ability","megumu","um"]'::jsonb),
  ('claim_ability_mike','gensokyo_main','character','mike','ability','Mike is associated with luck, beckoning commerce, and small-scale prosperity cues in everyday trade.',jsonb_build_object('ability_theme','luck_and_small_trade'),'src_um','official',69,'["ability","mike","um"]'::jsonb),
  ('claim_ability_aunn','gensokyo_main','character','aunn','ability','Aunn is associated with shrine guardianship, warm vigilance, and local sacred-space defense.',jsonb_build_object('ability_theme','guardian_vigilance'),'src_hsifs','official',71,'["ability","aunn","hsifs"]'::jsonb)
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
