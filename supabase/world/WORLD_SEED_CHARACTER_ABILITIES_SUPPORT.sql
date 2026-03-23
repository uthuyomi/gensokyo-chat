-- World seed: support-side abilities for key recurring non-lead actors

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_ability_nitori','character_ability','Nitori Ability Frame','Nitori should be framed through engineering, practical invention, and curious optimization rather than generic gadget clutter.',jsonb_build_object('character_id','nitori'),'["ability","nitori"]'::jsonb,80),
  ('gensokyo_main','lore_ability_keine','character_ability','Keine Ability Frame','Keine belongs to protection, instruction, and continuity-minded intervention around village life and history.',jsonb_build_object('character_id','keine'),'["ability","keine"]'::jsonb,79),
  ('gensokyo_main','lore_ability_akyuu','character_ability','Akyuu Ability Frame','Akyuu should be used through structured memory, classification, and documentary intelligence.',jsonb_build_object('character_id','akyuu'),'["ability","akyuu"]'::jsonb,80),
  ('gensokyo_main','lore_ability_kasen','character_ability','Kasen Ability Frame','Kasen scenes should combine advice, training, hidden depth, and corrective pressure.',jsonb_build_object('character_id','kasen'),'["ability","kasen"]'::jsonb,78),
  ('gensokyo_main','lore_ability_komachi','character_ability','Komachi Ability Frame','Komachi should be tied to crossings, managed delay, ferryman duty, and lazy consequentiality.',jsonb_build_object('character_id','komachi'),'["ability","komachi"]'::jsonb,76),
  ('gensokyo_main','lore_ability_eiki','character_ability','Eiki Ability Frame','Eiki belongs to moral judgment, corrective speech, and formal afterlife authority.',jsonb_build_object('character_id','eiki'),'["ability","eiki"]'::jsonb,80),
  ('gensokyo_main','lore_ability_tewi','character_ability','Tewi Ability Frame','Tewi should be framed through luck, detours, and evasive local manipulation rather than broad command.',jsonb_build_object('character_id','tewi'),'["ability","tewi"]'::jsonb,74),
  ('gensokyo_main','lore_ability_suika','character_ability','Suika Ability Frame','Suika belongs to compression, revelry, oni force, and social pressure through gathering.',jsonb_build_object('character_id','suika'),'["ability","suika"]'::jsonb,78)
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
  ('claim_ability_nitori','gensokyo_main','character','nitori','ability','Nitori is associated with engineering, mechanical invention, and practical technical improvisation.',jsonb_build_object('ability','engineering and invention'),'src_mofa','official',81,'["ability","nitori"]'::jsonb),
  ('claim_ability_keine','gensokyo_main','character','keine','ability','Keine is tied to protection, instruction, and the preservation of village continuity and history.',jsonb_build_object('ability','protection and history-linked guardianship'),'src_imperishable_night','official',80,'["ability","keine"]'::jsonb),
  ('claim_ability_akyuu','gensokyo_main','character','akyuu','ability','Akyuu is associated with structured memory, records, and historical compilation.',jsonb_build_object('ability','memory and documentation'),'src_sixty_years','official',82,'["ability","akyuu"]'::jsonb),
  ('claim_ability_kasen','gensokyo_main','character','kasen','ability','Kasen belongs to hermit discipline, guidance, and hidden depth under corrective demeanor.',jsonb_build_object('ability','hermit training and guidance'),'src_wahh','official',79,'["ability","kasen"]'::jsonb),
  ('claim_ability_komachi','gensokyo_main','character','komachi','ability','Komachi is associated with ferrying, crossing management, and consequential laziness at the border of life and death.',jsonb_build_object('ability','ferrying and crossing management'),'src_poFV','official',77,'["ability","komachi"]'::jsonb),
  ('claim_ability_eiki','gensokyo_main','character','eiki','ability','Eiki is defined by judgment, moral correction, and formal authority over the dead.',jsonb_build_object('ability','judgment'),'src_poFV','official',82,'["ability","eiki"]'::jsonb),
  ('claim_ability_tewi','gensokyo_main','character','tewi','ability','Tewi belongs to luck, trickery, and the production of useful detours.',jsonb_build_object('ability','luck and evasive trickery'),'src_imperishable_night','official',75,'["ability","tewi"]'::jsonb),
  ('claim_ability_suika','gensokyo_main','character','suika','ability','Suika is associated with oni strength, density, and revelry as social force.',jsonb_build_object('ability','density and oni force'),'src_swl','official',79,'["ability","suika"]'::jsonb)
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
