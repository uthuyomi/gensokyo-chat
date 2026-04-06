-- World seed: supporting-cast claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_supporting_cast_texture','world_rule','Supporting Cast Texture','Supporting cast should make regions and incident families feel inhabited rather than merely expand the boss list.',jsonb_build_object('focus','supporting_cast'),'["supporting_cast","texture"]'::jsonb,70)
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
  ('claim_wakasagihime_local_lake','gensokyo_main','character','wakasagihime','role','Wakasagihime is best treated as a local lake presence rather than a broad incident architect.',jsonb_build_object('role','local_actor'),'src_ddc','official',64,'["wakasagihime","ddc","lake"]'::jsonb),
  ('claim_sekibanki_village_uncanny','gensokyo_main','character','sekibanki','role','Sekibanki works naturally in village-edge uncanny scenes with divided presence and guarded identity.',jsonb_build_object('role','urban_actor'),'src_ddc','official',67,'["sekibanki","ddc","village"]'::jsonb),
  ('claim_kagerou_bamboo_night','gensokyo_main','character','kagerou','role','Kagerou belongs in bamboo-forest and moon-condition scenes rather than broad public command.',jsonb_build_object('role','local_actor'),'src_ddc','official',66,'["kagerou","ddc","bamboo"]'::jsonb),
  ('claim_benben_performer','gensokyo_main','character','benben','role','Benben fits public performance and tsukumogami independence scenes.',jsonb_build_object('role','performer'),'src_ddc','official',65,'["benben","ddc","music"]'::jsonb),
  ('claim_yatsuhashi_performer','gensokyo_main','character','yatsuhashi','role','Yatsuhashi works naturally as a lively music-oriented tsukumogami in public or ensemble contexts.',jsonb_build_object('role','performer'),'src_ddc','official',65,'["yatsuhashi","ddc","music"]'::jsonb),
  ('claim_seiran_soldier','gensokyo_main','character','seiran','role','Seiran is useful as a grounded lunar enlisted perspective in high-level moon conflicts.',jsonb_build_object('role','soldier'),'src_lolk','official',68,'["seiran","lolk","moon"]'::jsonb),
  ('claim_ringo_daily_lunar','gensokyo_main','character','ringo','role','Ringo helps lunar settings feel inhabited through routine and appetite rather than pure command structure.',jsonb_build_object('role','support_actor'),'src_lolk','official',66,'["ringo","lolk","daily_life"]'::jsonb),
  ('claim_mike_trade_luck','gensokyo_main','character','mike','role','Mike belongs to small-scale trade and luck scenes that ground larger market stories in daily life.',jsonb_build_object('role','merchant_support'),'src_um','official',67,'["mike","um","luck"]'::jsonb)
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
