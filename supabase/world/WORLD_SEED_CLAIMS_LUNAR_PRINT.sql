-- World seed: lunar and late print-work support claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_lunar_nobility_texture','world_rule','Lunar Nobility Texture','The moon should feel politically stratified, ceremonially confident, and structurally separate from ordinary Gensokyo life.',jsonb_build_object('focus','lunar_elite'),'["moon","nobility","texture"]'::jsonb,82),
  ('gensokyo_main','lore_village_afterhours_texture','daily_life_texture','Village After-Hours Texture','The village after dark should include drink, relief, gossip, and lowered guard rather than simply closing down.',jsonb_build_object('focus','night_hospitality'),'["village","night","tavern"]'::jsonb,78),
  ('gensokyo_main','lore_hidden_possession_texture','incident_pattern','Hidden Possession Texture','Some later incidents should work through hidden resentment and infiltration rather than immediate open confrontation.',jsonb_build_object('focus','hidden_possession'),'["mystery","possession","late_era"]'::jsonb,79)
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
  ('claim_toyohime_lunar_noble','gensokyo_main','character','toyohime','role','Toyohime should be treated as high lunar nobility whose ease and elegance come from structural superiority, not casual softness.',jsonb_build_object('role','lunar_elite'),'src_ssib','official',75,'["toyohime","moon","role"]'::jsonb),
  ('claim_yorihime_lunar_martial_elite','gensokyo_main','character','yorihime','role','Yorihime represents disciplined lunar force and standards that ordinary Gensokyo actors cannot casually equal.',jsonb_build_object('role','lunar_martial_elite'),'src_ssib','official',77,'["yorihime","moon","role"]'::jsonb),
  ('claim_miyoi_night_hospitality','gensokyo_main','character','miyoi','role','Miyoi is best used to show hospitality, drink, and after-hours social texture in the village rather than overt public power.',jsonb_build_object('role','night_hospitality'),'src_le','official',72,'["miyoi","night","village"]'::jsonb),
  ('claim_mizuchi_hidden_possession','gensokyo_main','character','mizuchi','role','Mizuchi belongs to hidden-possession and resentment-driven mystery structures rather than loud public declaration.',jsonb_build_object('role','hidden_threat'),'src_fds','official',74,'["mizuchi","mystery","possession"]'::jsonb),
  ('claim_lunar_nobility_culture','gensokyo_main','world','gensokyo_main','world_rule','Lunar nobility should be framed as a distinct political-cultural layer, not simply as stronger versions of ordinary locals.',jsonb_build_object('scope','lunar_capital'),'src_ciLR','official',80,'["moon","culture","rule"]'::jsonb)
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
