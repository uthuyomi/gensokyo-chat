-- World seed: second wave of recurring world terms

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_term_faith_economy','term','Faith Economy','Faith in Gensokyo is not only belief. It also functions as a practical resource tied to legitimacy, public support, and shrine-side competition.',jsonb_build_object('domain','religion_and_power'),'["term","faith","economy"]'::jsonb,80),
  ('gensokyo_main','lore_term_perfect_possession','term','Perfect Possession','Perfect possession should be treated as a destabilizing pairing logic that scrambles ordinary boundaries of agency and combat.',jsonb_build_object('domain','possession_incidents'),'["term","possession","incident"]'::jsonb,79),
  ('gensokyo_main','lore_term_outside_world_leakage','term','Outside-World Leakage','The Outside World affects Gensokyo less through direct replacement than through leakage of rumor forms, objects, and explanatory frames.',jsonb_build_object('domain','boundary_and_modernity'),'["term","outside_world","leakage"]'::jsonb,81),
  ('gensokyo_main','lore_term_animal_spirits','term','Animal Spirits','Animal spirits should be read as political and factional actors of the Beast Realm, not mere ambient monsters.',jsonb_build_object('domain','beast_realm_politics'),'["term","animal_spirits","beast_realm"]'::jsonb,78),
  ('gensokyo_main','lore_term_market_cards','term','Ability Cards','The ability-card economy turns power into circulation, collection, and market pressure rather than purely personal training.',jsonb_build_object('domain','market_incident'),'["term","ability_cards","market"]'::jsonb,80)
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
  ('claim_term_faith_economy','gensokyo_main','term','faith_economy','definition','Faith should be treated as a practical political resource in shrine-centered competition, not only as private devotion.',jsonb_build_object('related_locations',array['hakurei_shrine','moriya_shrine']),'src_mofa','official',81,'["term","faith","economy"]'::jsonb),
  ('claim_term_perfect_possession','gensokyo_main','term','perfect_possession','definition','Perfect possession destabilizes ordinary agency by forcing pair-logic and layered control into conflict and identity.',jsonb_build_object('related_incident','incident_perfect_possession'),'src_aocf','official',79,'["term","possession","aocf"]'::jsonb),
  ('claim_term_outside_world_leakage','gensokyo_main','term','outside_world_leakage','definition','Outside-world influence usually enters Gensokyo through leakage of forms, rumors, and objects rather than clean transplantation.',jsonb_build_object('related_incident','incident_urban_legends'),'src_ulil','official',82,'["term","outside_world","leakage"]'::jsonb),
  ('claim_term_animal_spirits','gensokyo_main','term','animal_spirits','definition','Animal spirits are factional political actors tied to the Beast Realm and its proxy conflicts.',jsonb_build_object('related_location','beast_realm'),'src_wbawc','official',78,'["term","animal_spirits","politics"]'::jsonb),
  ('claim_term_market_cards','gensokyo_main','term','ability_cards','definition','Ability cards convert power into a market-circulation problem, not just a combat option.',jsonb_build_object('related_incident','incident_market_cards'),'src_um','official',80,'["term","ability_cards","market"]'::jsonb)
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
