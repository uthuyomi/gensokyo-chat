-- World seed: temple, Eientei, and river-threshold role claims

insert into public.world_canon_claims (
  id, world_id, subject_type, subject_id, claim_type, summary, details, source_id, confidence, priority, tags
)
values
  ('claim_ichirin_temple_strength','gensokyo_main','character','ichirin','role','Ichirin works best as visible temple-side strength and loyalty rather than as an isolated doctrinal speaker.',jsonb_build_object('role','temple_support_strength'),'src_ufo','official',72,'["ichirin","ufo","temple"]'::jsonb),
  ('claim_reisen_eientei_operator','gensokyo_main','character','reisen','role','Reisen is especially useful as a practical operator within Eientei''s disciplined, medically informed, lunar-shadowed structure.',jsonb_build_object('role','eientei_operator'),'src_imperishable_night','official',77,'["reisen","in","eientei"]'::jsonb),
  ('claim_eika_riverbank_persistence','gensokyo_main','character','eika','role','Eika gives the riverbank and afterlife threshold a small-scale persistence that prevents it from feeling abstract.',jsonb_build_object('role','riverbank_persistence'),'src_wbawc','official',68,'["eika","wbawc","riverbank"]'::jsonb),
  ('claim_urumi_threshold_guard','gensokyo_main','character','urumi','role','Urumi is best used as a steady threshold guardian at river and ferry-adjacent crossings.',jsonb_build_object('role','threshold_guard'),'src_wbawc','official',69,'["urumi","wbawc","threshold"]'::jsonb),
  ('claim_kutaka_checkpoint_guard','gensokyo_main','character','kutaka','role','Kutaka works naturally as a checkpoint authority whose value lies in regulated passage and avian order.',jsonb_build_object('role','checkpoint_guard'),'src_wbawc','official',71,'["kutaka","wbawc","checkpoint"]'::jsonb)
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
