-- World seed: lore and claims for early Windows-era cast

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_cirno_local_trouble','character_role','Cirno as Local Disturbance','Cirno works best as a loud, local force rather than a stable organizer of wider events.',jsonb_build_object('character_id','cirno'),'["cirno","fairy","local"]'::jsonb,68),
  ('gensokyo_main','lore_lily_seasonal_marker','character_role','Lily White as Seasonal Marker','Lily White is most useful as a sign of spring''s arrival and public seasonal change.',jsonb_build_object('character_id','lily_white'),'["lily_white","spring","seasonal"]'::jsonb,67),
  ('gensokyo_main','lore_prismriver_ensemble','character_role','Prismriver Ensemble Logic','The Prismriver sisters are best treated as a coordinated musical presence rather than isolated solo actors.',jsonb_build_object('group','prismriver'),'["prismriver","music","group"]'::jsonb,71),
  ('gensokyo_main','lore_aki_seasonality','character_role','Aki Sisters and Autumn','The Aki sisters are strongest in stories that care about autumn as atmosphere, harvest, and public seasonal feeling.',jsonb_build_object('group','aki_sisters'),'["aki","autumn","seasonal"]'::jsonb,69),
  ('gensokyo_main','lore_tewi_detours','character_role','Tewi and Productive Detours','Tewi works naturally in scenes of luck, detours, trickery, and side-route guidance around Eientei.',jsonb_build_object('character_id','tewi'),'["tewi","luck","detour"]'::jsonb,72)
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
  ('claim_cirno_fairy_local','gensokyo_main','character','cirno','role','Cirno is better understood as a strong local fairy presence than as a broad political actor.',jsonb_build_object('role','local_troublemaker'),'src_eosd','official',66,'["cirno","fairy"]'::jsonb),
  ('claim_lily_spring_marker','gensokyo_main','character','lily_white','role','Lily White strongly signals the arrival of spring and is most natural in seasonal-transition scenes.',jsonb_build_object('role','seasonal_marker'),'src_pcb','official',68,'["lily_white","spring"]'::jsonb),
  ('claim_prismriver_ensemble','gensokyo_main','character','lunasa','group_role','The Prismriver sisters are fundamentally an ensemble presence.',jsonb_build_object('group','prismriver'),'src_pcb','official',74,'["prismriver","ensemble"]'::jsonb),
  ('claim_hina_mountain_warning','gensokyo_main','character','hina','role','Hina belongs naturally to mountain-approach scenes involving caution, deflection, or ominous warning.',jsonb_build_object('role','warning_actor'),'src_mofa','official',70,'["hina","mountain"]'::jsonb),
  ('claim_tewi_eientei_trickster','gensokyo_main','character','tewi','role','Tewi is strongly tied to Eientei-adjacent trickery, local luck, and detouring guidance.',jsonb_build_object('role','trickster'),'src_imperishable_night','official',73,'["tewi","eientei","luck"]'::jsonb)
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
