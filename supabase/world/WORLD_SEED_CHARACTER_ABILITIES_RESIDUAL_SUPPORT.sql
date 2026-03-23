-- World seed: residual support-cast abilities

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_ability_wakasagihime','character_ability','Wakasagihime Ability Frame','Wakasagihime belongs to local water poise, reflective calm, and small-scale lake presence.',jsonb_build_object('character_id','wakasagihime'),'["ability","wakasagihime"]'::jsonb,65),
  ('gensokyo_main','lore_ability_sekibanki','character_ability','Sekibanki Ability Frame','Sekibanki should read through divided presence, guarded identity, and uncanny village-edge mobility.',jsonb_build_object('character_id','sekibanki'),'["ability","sekibanki"]'::jsonb,68),
  ('gensokyo_main','lore_ability_kagerou','character_ability','Kagerou Ability Frame','Kagerou scenes should combine instinct, moon-conditioned exposure, and earnest embarrassment.',jsonb_build_object('character_id','kagerou'),'["ability","kagerou"]'::jsonb,67),
  ('gensokyo_main','lore_ability_benben','character_ability','Benben Ability Frame','Benben belongs to composed public performance and confident tsukumogami stage presence.',jsonb_build_object('character_id','benben'),'["ability","benben"]'::jsonb,66),
  ('gensokyo_main','lore_ability_yatsuhashi','character_ability','Yatsuhashi Ability Frame','Yatsuhashi works through lively performance, sharp rhythm, and visible insistence on attention.',jsonb_build_object('character_id','yatsuhashi'),'["ability","yatsuhashi"]'::jsonb,66),
  ('gensokyo_main','lore_ability_seiran','character_ability','Seiran Ability Frame','Seiran should feel like energetic enlisted pressure rather than high command or abstract lunar politics.',jsonb_build_object('character_id','seiran'),'["ability","seiran"]'::jsonb,67),
  ('gensokyo_main','lore_ability_ringo','character_ability','Ringo Ability Frame','Ringo makes lunar life feel routine, inhabited, and structurally ordinary beneath strategic conflict.',jsonb_build_object('character_id','ringo'),'["ability","ringo"]'::jsonb,67),
  ('gensokyo_main','lore_ability_mayumi','character_ability','Mayumi Ability Frame','Mayumi belongs to disciplined formation, carved duty, and straightforward constructed loyalty.',jsonb_build_object('character_id','mayumi'),'["ability","mayumi"]'::jsonb,70)
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
  ('claim_ability_wakasagihime','gensokyo_main','character','wakasagihime','ability','Wakasagihime is associated with water poise, reflective calm, and a local mermaid presence tied to lake margins.',jsonb_build_object('ability_theme','local_water_presence'),'src_ddc','official',66,'["ability","wakasagihime","ddc"]'::jsonb),
  ('claim_ability_sekibanki','gensokyo_main','character','sekibanki','ability','Sekibanki is defined by divided presence, detached heads, and uncanny mobility around public edges.',jsonb_build_object('ability_theme','divided_presence'),'src_ddc','official',69,'["ability","sekibanki","ddc"]'::jsonb),
  ('claim_ability_kagerou','gensokyo_main','character','kagerou','ability','Kagerou belongs to werewolf instinct, lunar exposure, and emotionally visible restraint.',jsonb_build_object('ability_theme','moonlit_instinct'),'src_ddc','official',68,'["ability","kagerou","ddc"]'::jsonb),
  ('claim_ability_benben','gensokyo_main','character','benben','ability','Benben expresses musical confidence, ensemble presence, and self-possessed tsukumogami performance.',jsonb_build_object('ability_theme','ensemble_performance'),'src_ddc','official',67,'["ability","benben","ddc"]'::jsonb),
  ('claim_ability_yatsuhashi','gensokyo_main','character','yatsuhashi','ability','Yatsuhashi is tied to sharp rhythm, expressive performance, and energetic tsukumogami visibility.',jsonb_build_object('ability_theme','expressive_rhythm'),'src_ddc','official',67,'["ability","yatsuhashi","ddc"]'::jsonb),
  ('claim_ability_seiran','gensokyo_main','character','seiran','ability','Seiran should be framed through energetic soldiery, practical movement, and lunar enlisted routine.',jsonb_build_object('ability_theme','enlisted_mobility'),'src_lolk','official',68,'["ability","seiran","lolk"]'::jsonb),
  ('claim_ability_ringo','gensokyo_main','character','ringo','ability','Ringo is associated with practical daily-lunar life, appetite, and staffed normalcy under larger conflict.',jsonb_build_object('ability_theme','daily_lunar_normalcy'),'src_lolk','official',68,'["ability","ringo","lolk"]'::jsonb),
  ('claim_ability_mayumi','gensokyo_main','character','mayumi','ability','Mayumi belongs to disciplined formation, haniwa duty, and constructed defense under explicit command.',jsonb_build_object('ability_theme','constructed_discipline'),'src_wbawc','official',72,'["ability","mayumi","wbawc"]'::jsonb)
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
