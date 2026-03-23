-- World seed: lunar and late print-work support ability claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ability_toyohime','gensokyo_main','character','toyohime','ability','Toyohime is associated with high lunar mobility and composure-backed superiority rather than brute display.',jsonb_build_object('ability_theme','lunar_transport_and_grace'),'src_ssib','official',73,'["ability","toyohime","moon"]'::jsonb),
  ('claim_ability_yorihime','gensokyo_main','character','yorihime','ability','Yorihime is associated with divine invocation and overwhelming formal combat authority.',jsonb_build_object('ability_theme','divine_summoning'),'src_ssib','official',78,'["ability","yorihime","moon"]'::jsonb),
  ('claim_ability_miyoi','gensokyo_main','character','miyoi','ability','Miyoi is tied to the strange hospitality and soft unreality of after-hours tavern scenes.',jsonb_build_object('ability_theme','hospitality_and_night_unreality'),'src_le','official',69,'["ability","miyoi","nightlife"]'::jsonb),
  ('claim_ability_mizuchi','gensokyo_main','character','mizuchi','ability','Mizuchi is associated with hidden possession, grudge persistence, and indirect destabilization.',jsonb_build_object('ability_theme','possession_and_grudge'),'src_fds','official',75,'["ability","mizuchi","mystery"]'::jsonb)
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
