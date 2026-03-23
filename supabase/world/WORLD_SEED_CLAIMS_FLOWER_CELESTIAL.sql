-- World seed: flower, celestial, dream, and seasonal claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_muenzuka_judgment','location_trait','Muenzuka Border Logic','Muenzuka works best as a border field of crossings, judgment, and neglected edges rather than a generic empty field.',jsonb_build_object('location_id','muenzuka'),'["pofv","border","judgment"]'::jsonb,79),
  ('gensokyo_main','lore_heaven_detachment','location_trait','Heavenly Detachment','Heaven and Bhavaagra should feel insulated enough that disruption can be caused without ground-level urgency being understood.',jsonb_build_object('location_id','heaven'),'["swr","heaven","detachment"]'::jsonb,80),
  ('gensokyo_main','lore_kokoro_public_affect','character_role','Kokoro and Public Affect','Kokoro should be used when emotion, masks, and performed public mood are central to the scene.',jsonb_build_object('character_id','kokoro'),'["hm","emotion","masks"]'::jsonb,75),
  ('gensokyo_main','lore_dream_world_mediator','location_trait','Dream World Mediation','Dream World scenes benefit from a clear mediator and should not be treated as pure random nonsense.',jsonb_build_object('location_id','dream_world'),'["dream","structure"]'::jsonb,77),
  ('gensokyo_main','lore_aunn_shrine_everyday','character_role','Aunn Shrine Everydayness','Aunn is especially useful for making shrine-space feel inhabited, liked, and locally defended.',jsonb_build_object('character_id','aunn'),'["aunn","shrine"]'::jsonb,72),
  ('gensokyo_main','lore_nameless_hill_danger','location_trait','Nameless Hill Beauty and Hazard','Nameless Hill should feel lovely and threatening at the same time.',jsonb_build_object('location_id','nameless_hill'),'["flowers","poison","beauty"]'::jsonb,74)
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
  ('claim_komachi_border_worker','gensokyo_main','character','komachi','role','Komachi should be framed through crossings, delay, and border-side labor rather than generic underworld menace.',jsonb_build_object('role','border_worker'),'src_poFV','official',78,'["komachi","pofv","border"]'::jsonb),
  ('claim_eiki_judge','gensokyo_main','character','eiki','role','Eiki is a judge whose natural story value lies in moral evaluation, verdict, and formal correction.',jsonb_build_object('role','judge'),'src_poFV','official',84,'["eiki","pofv","judgment"]'::jsonb),
  ('claim_medicine_poison_actor','gensokyo_main','character','medicine','role','Medicine belongs in poison, resentment, and neglected-place scenes more than in broad social organization.',jsonb_build_object('role','poison_actor'),'src_poFV','official',72,'["medicine","pofv","poison"]'::jsonb),
  ('claim_yuuka_dangerous_beauty','gensokyo_main','character','yuuka','role','Yuuka should be treated as calm danger and overwhelming floral presence, not ordinary scene filler.',jsonb_build_object('role','high_impact_actor'),'src_poFV','official',86,'["yuuka","pofv","flowers"]'::jsonb),
  ('claim_iku_messenger','gensokyo_main','character','iku','role','Iku works naturally as a poised omen-bearer and heavenly messenger around weather-linked disturbance.',jsonb_build_object('role','messenger'),'src_swl','official',73,'["iku","swr","heaven"]'::jsonb),
  ('claim_tenshi_celestial_instigator','gensokyo_main','character','tenshi','role','Tenshi should be understood as a disruptive celestial whose arrogance and boredom can scale into public trouble.',jsonb_build_object('role','instigator'),'src_swl','official',81,'["tenshi","swr","celestial"]'::jsonb),
  ('claim_kokoro_mask_performer','gensokyo_main','character','kokoro','role','Kokoro belongs in stories where emotion display and performed identity are active mechanics.',jsonb_build_object('role','performer'),'src_hm','official',77,'["kokoro","hm","masks"]'::jsonb),
  ('claim_doremy_dream_guide','gensokyo_main','character','doremy','role','Doremy is a guide and caretaker of dream-space logic rather than a generic sleepy eccentric.',jsonb_build_object('role','guide'),'src_lolk','official',79,'["doremy","dream","lolk"]'::jsonb),
  ('claim_aunn_guardian','gensokyo_main','character','aunn','role','Aunn is a shrine guardian whose value lies in making sacred space feel watched, liked, and locally lived in.',jsonb_build_object('role','guardian'),'src_hsifs','official',74,'["aunn","hsifs","shrine"]'::jsonb),
  ('claim_eternity_seasonal_actor','gensokyo_main','character','eternity','role','Eternity is best used as a vivid seasonal actor associated with summer motion and visible atmosphere.',jsonb_build_object('role','seasonal_actor'),'src_hsifs','official',66,'["eternity","hsifs","summer"]'::jsonb),
  ('claim_nemuno_mountain_local','gensokyo_main','character','nemuno','role','Nemuno helps depict mountain life outside official or institutional mountain structures.',jsonb_build_object('role','local_guardian'),'src_hsifs','official',68,'["nemuno","hsifs","mountain"]'::jsonb),
  ('claim_heaven_profile','gensokyo_main','location','heaven','profile','Heaven is best treated as a detached celestial sphere where comfort and consequence do not naturally stay balanced.',jsonb_build_object('role','celestial_realm'),'src_swl','official',80,'["location","heaven","swr"]'::jsonb),
  ('claim_dream_world_profile','gensokyo_main','location','dream_world','profile','Dream World is a symbolic and unstable realm that still benefits from mediated structure and caretaking.',jsonb_build_object('role','dream_realm'),'src_lolk','official',78,'["location","dream","lolk"]'::jsonb),
  ('claim_nameless_hill_profile','gensokyo_main','location','nameless_hill','profile','Nameless Hill should feel beautiful, lonely, and hazardous rather than purely pastoral.',jsonb_build_object('role','flower_poison_field'),'src_poFV','official',74,'["location","flowers","poison"]'::jsonb)
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
