-- World seed: late-mainline political and market systems glossary

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_term_hidden_seasons','term','Hidden Seasons','Hidden seasons should be treated as latent power layers revealed through selective access rather than weather alone.',jsonb_build_object('domain','seasonal_hidden_power'),'["term","hidden_seasons","hsifs"]'::jsonb,78),
  ('gensokyo_main','lore_term_beast_realm_politics','term','Beast Realm Politics','The Beast Realm should read as factional power struggle, proxy conflict, and organized predation rather than simple chaos.',jsonb_build_object('domain','beast_realm_governance'),'["term","beast_realm","politics"]'::jsonb,80),
  ('gensokyo_main','lore_term_market_competition','term','Market Competition','Market competition in Gensokyo should be understood as a struggle over routes, value, ownership, and circulation of power itself.',jsonb_build_object('domain','market_systems'),'["term","market","competition"]'::jsonb,80)
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
  ('claim_term_hidden_seasons','gensokyo_main','term','hidden_seasons','definition','Hidden seasons are best read as selective latent power revealed through access and orchestration rather than surface climate alone.',jsonb_build_object('related_characters',array['okina','satono','mai']),'src_hsifs','official',78,'["term","hidden_seasons","definition"]'::jsonb),
  ('claim_term_beast_realm_politics','gensokyo_main','term','beast_realm_politics','definition','Beast Realm politics are structured by factional rivalry, proxy struggle, and predatory strategy rather than mere savagery.',jsonb_build_object('related_characters',array['yachie','saki','keiki']),'src_wbawc','official',80,'["term","beast_realm","definition"]'::jsonb),
  ('claim_term_market_competition','gensokyo_main','term','market_competition','definition','Market competition in Gensokyo concerns ownership, routes, cards, and the circulation of useful power.',jsonb_build_object('related_characters',array['chimata','takane','tsukasa','mike']),'src_um','official',80,'["term","market","definition"]'::jsonb)
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
