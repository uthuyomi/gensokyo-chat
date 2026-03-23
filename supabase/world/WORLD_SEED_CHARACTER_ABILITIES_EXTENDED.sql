-- World seed: extended character abilities and epithet frames

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_ability_remilia','character_ability','Remilia Ability Frame','Remilia should be framed through aristocratic pressure, fate-linked menace, and symbolic control rather than simple brute violence.',jsonb_build_object('character_id','remilia'),'["ability","remilia"]'::jsonb,82),
  ('gensokyo_main','lore_ability_patchouli','character_ability','Patchouli Ability Frame','Patchouli belongs to prepared magic, scholarship, and controlled elemental or library-centered knowledge scenes.',jsonb_build_object('character_id','patchouli'),'["ability","patchouli"]'::jsonb,80),
  ('gensokyo_main','lore_ability_alice','character_ability','Alice Ability Frame','Alice should read through dolls, craft precision, and socially measured distance.',jsonb_build_object('character_id','alice'),'["ability","alice"]'::jsonb,78),
  ('gensokyo_main','lore_ability_youmu','character_ability','Youmu Ability Frame','Youmu combines sword discipline, duty, and half-phantom speed rather than mere earnestness alone.',jsonb_build_object('character_id','youmu'),'["ability","youmu"]'::jsonb,79),
  ('gensokyo_main','lore_ability_yuyuko','character_ability','Yuyuko Ability Frame','Yuyuko belongs to scenes of elegant appetite, death-adjacent awareness, and lightly concealed certainty.',jsonb_build_object('character_id','yuyuko'),'["ability","yuyuko"]'::jsonb,79),
  ('gensokyo_main','lore_ability_mokou','character_ability','Mokou Ability Frame','Mokou should be treated through endurance, plainspoken force, and long historical burn rather than temporary flair.',jsonb_build_object('character_id','mokou'),'["ability","mokou"]'::jsonb,78),
  ('gensokyo_main','lore_ability_kaguya','character_ability','Kaguya Ability Frame','Kaguya scenes should combine noble distance, immortality context, and symbolic weight around status and time.',jsonb_build_object('character_id','kaguya'),'["ability","kaguya"]'::jsonb,77),
  ('gensokyo_main','lore_ability_kanako','character_ability','Kanako Ability Frame','Kanako belongs to influence, systems, gathered faith, and strategic expansion rather than passive divinity.',jsonb_build_object('character_id','kanako'),'["ability","kanako"]'::jsonb,79),
  ('gensokyo_main','lore_ability_suwako','character_ability','Suwako Ability Frame','Suwako should read as old power carried lightly, not as a harmless elder presence.',jsonb_build_object('character_id','suwako'),'["ability","suwako"]'::jsonb,76),
  ('gensokyo_main','lore_ability_mamizou','character_ability','Mamizou Ability Frame','Mamizou is tied to transformation, adaptation, and social flexibility more than fixed frontal dominance.',jsonb_build_object('character_id','mamizou'),'["ability","mamizou"]'::jsonb,77),
  ('gensokyo_main','lore_ability_raiko','character_ability','Raiko Ability Frame','Raiko scenes should foreground rhythm, independence, and post-object autonomy.',jsonb_build_object('character_id','raiko'),'["ability","raiko"]'::jsonb,72),
  ('gensokyo_main','lore_ability_sagume','character_ability','Sagume Ability Frame','Sagume belongs to implication, reversal risk, and dangerous speech-act caution.',jsonb_build_object('character_id','sagume'),'["ability","sagume"]'::jsonb,82),
  ('gensokyo_main','lore_ability_clownpiece','character_ability','Clownpiece Ability Frame','Clownpiece should feel bright, infernal, and aggressively destabilizing rather than merely silly.',jsonb_build_object('character_id','clownpiece'),'["ability","clownpiece"]'::jsonb,76),
  ('gensokyo_main','lore_ability_yachie','character_ability','Yachie Ability Frame','Yachie belongs to leverage, command through indirection, and cold political motion.',jsonb_build_object('character_id','yachie'),'["ability","yachie"]'::jsonb,78),
  ('gensokyo_main','lore_ability_takane','character_ability','Takane Ability Frame','Takane should be framed through trade intelligence, brokerage, and practical market route knowledge.',jsonb_build_object('character_id','takane'),'["ability","takane"]'::jsonb,74),
  ('gensokyo_main','lore_ability_sumireko','character_ability','Sumireko Ability Frame','Sumireko works through psychic push, rumor bleed, and outside-world overreach.',jsonb_build_object('character_id','sumireko'),'["ability","sumireko"]'::jsonb,75)
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
  ('claim_ability_remilia','gensokyo_main','character','remilia','ability','Remilia is tied to fate-linked aristocratic menace and symbolic household command.',jsonb_build_object('ability','fate and aristocratic pressure'),'src_eosd','official',83,'["ability","remilia"]'::jsonb),
  ('claim_ability_patchouli','gensokyo_main','character','patchouli','ability','Patchouli is tied to prepared magic, deep scholarship, and library-centered spellcraft.',jsonb_build_object('ability','prepared magic'),'src_eosd','official',81,'["ability","patchouli"]'::jsonb),
  ('claim_ability_alice','gensokyo_main','character','alice','ability','Alice is defined by dolls, craft precision, and controlled magical construction.',jsonb_build_object('ability','doll manipulation'),'src_pcb','official',79,'["ability","alice"]'::jsonb),
  ('claim_ability_youmu','gensokyo_main','character','youmu','ability','Youmu combines sword discipline with half-phantom speed and service-borne focus.',jsonb_build_object('ability','sword and half-phantom speed'),'src_pcb','official',80,'["ability","youmu"]'::jsonb),
  ('claim_ability_yuyuko','gensokyo_main','character','yuyuko','ability','Yuyuko is tied to death-adjacent grace, appetite, and quiet certainty.',jsonb_build_object('ability','death and ghostly nobility'),'src_pcb','official',80,'["ability","yuyuko"]'::jsonb),
  ('claim_ability_mokou','gensokyo_main','character','mokou','ability','Mokou is shaped by immortality, endurance, and practical destructive force.',jsonb_build_object('ability','immortality and fire endurance'),'src_imperishable_night','official',79,'["ability","mokou"]'::jsonb),
  ('claim_ability_kaguya','gensokyo_main','character','kaguya','ability','Kaguya belongs to noble immortality, symbolic status, and elegant distance.',jsonb_build_object('ability','immortality and lunar nobility'),'src_imperishable_night','official',78,'["ability","kaguya"]'::jsonb),
  ('claim_ability_kanako','gensokyo_main','character','kanako','ability','Kanako is associated with gathered faith, systems, and ambitious divine influence.',jsonb_build_object('ability','faith and strategic influence'),'src_mofa','official',80,'["ability","kanako"]'::jsonb),
  ('claim_ability_suwako','gensokyo_main','character','suwako','ability','Suwako is old divine power carried in a casual tone, not harmlessness.',jsonb_build_object('ability','old native divine power'),'src_mofa','official',77,'["ability","suwako"]'::jsonb),
  ('claim_ability_mamizou','gensokyo_main','character','mamizou','ability','Mamizou is associated with transformation, adaptation, and socially flexible power.',jsonb_build_object('ability','transformation'),'src_td','official',78,'["ability","mamizou"]'::jsonb),
  ('claim_ability_raiko','gensokyo_main','character','raiko','ability','Raiko is tied to rhythm, thunderous performance, and independent tsukumogami momentum.',jsonb_build_object('ability','rhythm and independent animation'),'src_ddc','official',73,'["ability","raiko"]'::jsonb),
  ('claim_ability_sagume','gensokyo_main','character','sagume','ability','Sagume should be framed through dangerous implication and carefully managed speech.',jsonb_build_object('ability','dangerous speech and reversal risk'),'src_lolk','official',83,'["ability","sagume"]'::jsonb),
  ('claim_ability_clownpiece','gensokyo_main','character','clownpiece','ability','Clownpiece combines infernal backing, fairy energy, and destabilizing brightness.',jsonb_build_object('ability','hell-backed fairy disruption'),'src_lolk','official',77,'["ability","clownpiece"]'::jsonb),
  ('claim_ability_yachie','gensokyo_main','character','yachie','ability','Yachie belongs to indirect domination, leverage, and strategic reptilian calm.',jsonb_build_object('ability','indirect control'),'src_wbawc','official',79,'["ability","yachie"]'::jsonb),
  ('claim_ability_takane','gensokyo_main','character','takane','ability','Takane is strongly associated with brokerage, trade routes, and commercially useful intelligence.',jsonb_build_object('ability','brokerage and trade intelligence'),'src_um','official',75,'["ability","takane"]'::jsonb),
  ('claim_ability_sumireko','gensokyo_main','character','sumireko','ability','Sumireko is associated with psychic action and outside-world rumor pressure crossing into Gensokyo.',jsonb_build_object('ability','psychic and urban legend pressure'),'src_ulil','official',76,'["ability","sumireko"]'::jsonb)
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
