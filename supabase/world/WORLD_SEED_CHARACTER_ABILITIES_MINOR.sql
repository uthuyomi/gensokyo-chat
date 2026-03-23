-- World seed: minor and support-cast ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_kisume','gensokyo_main','character','kisume','ability','Kisume''s presentation centers on sudden, narrow-space menace rather than broad territorial control.',jsonb_build_object('ability_theme','ambush_presence'),'src_subterranean_animism','official',66,'["ability","kisume","sa"]'::jsonb),
  ('claim_ability_yamame','gensokyo_main','character','yamame','ability','Yamame is associated with pestilence and the kind of social menace that spreads through networks.',jsonb_build_object('ability_theme','disease_and_network'),'src_subterranean_animism','official',71,'["ability","yamame","sa"]'::jsonb),
  ('claim_ability_parsee','gensokyo_main','character','parsee','ability','Parsee is defined by jealousy and by the emotional charge she brings to crossings and observation.',jsonb_build_object('ability_theme','jealousy'),'src_subterranean_animism','official',73,'["ability","parsee","sa"]'::jsonb),
  ('claim_ability_yuugi','gensokyo_main','character','yuugi','ability','Yuugi embodies immense oni strength backed by social fearlessness rather than hidden method.',jsonb_build_object('ability_theme','oni_strength'),'src_subterranean_animism','official',74,'["ability","yuugi","sa"]'::jsonb),
  ('claim_ability_kyouko','gensokyo_main','character','kyouko','ability','Kyouko is tied to echo and repeated sound, making her useful in scenes of audible presence.',jsonb_build_object('ability_theme','echo'),'src_td','official',67,'["ability","kyouko","td"]'::jsonb),
  ('claim_ability_yoshika','gensokyo_main','character','yoshika','ability','Yoshika is defined by jiang-shi endurance and obedient physical service.',jsonb_build_object('ability_theme','jiangshi_endurance'),'src_td','official',69,'["ability","yoshika","td"]'::jsonb),
  ('claim_ability_shou','gensokyo_main','character','shou','ability','Shou''s authority is framed through Bishamonten imagery, treasure symbolism, and religious power.',jsonb_build_object('ability_theme','avatar_authority'),'src_ufo','official',72,'["ability","shou","ufo"]'::jsonb),
  ('claim_ability_sunny_milk','gensokyo_main','character','sunny_milk','ability','Sunny Milk is associated with bending sunlight and playful concealment through brightness.',jsonb_build_object('ability_theme','light_manipulation'),'src_osp','official',66,'["ability","sunny_milk","fairy"]'::jsonb),
  ('claim_ability_luna_child','gensokyo_main','character','luna_child','ability','Luna Child is associated with silence and reduced sound, giving fairy scenes a stealth component.',jsonb_build_object('ability_theme','silence_field'),'src_osp','official',66,'["ability","luna_child","fairy"]'::jsonb),
  ('claim_ability_star_sapphire','gensokyo_main','character','star_sapphire','ability','Star Sapphire is associated with perceiving the presence of living things, making her a lookout among fairies.',jsonb_build_object('ability_theme','presence_detection'),'src_osp','official',67,'["ability","star_sapphire","fairy"]'::jsonb)
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
