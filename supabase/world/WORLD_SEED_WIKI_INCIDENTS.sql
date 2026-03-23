-- World seed: wiki pages for major canonical incidents

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_incident_scarlet_mist','gensokyo_main','incidents/scarlet-mist-incident','Scarlet Mist Incident','incident','incident','incident_scarlet_mist','A mansion-centered atmospheric abnormality that helped define the public scale of incident response.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_incident_eternal_night','gensokyo_main','incidents/imperishable-night','Imperishable Night Incident','incident','incident','incident_eternal_night','A false-night incident marked by lunar implication, secrecy, and delayed dawn.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_incident_faith_shift','gensokyo_main','incidents/mountain-faith-shift','Mountain Faith Shift','incident','incident','incident_faith_shift','A faith-centered public shift driven by shrine competition and Moriya expansion.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_incident_little_rebellion','gensokyo_main','incidents/little-people-rebellion','Little People Rebellion','incident','incident','incident_little_rebellion','A reversal-driven disturbance of grievance, symbolic power, and unstable hierarchy.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_incident_lunar_crisis','gensokyo_main','incidents/lunar-crisis','Lunar Crisis','incident','incident','incident_lunar_crisis','A high-scale moon crisis involving purification, dream mediation, and lunar political distance.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_incident_market_cards','gensokyo_main','incidents/card-market-incident','Card Market Incident','incident','incident','incident_market_cards','A market-structured disturbance driven by cards, circulation, and distributed exchange power.','published','chronicle_gensokyo_history','{}'::jsonb)
on conflict (id) do update
set slug = excluded.slug,
    title = excluded.title,
    page_type = excluded.page_type,
    subject_type = excluded.subject_type,
    subject_id = excluded.subject_id,
    summary = excluded.summary,
    status = excluded.status,
    canonical_book_id = excluded.canonical_book_id,
    metadata = excluded.metadata,
    updated_at = now();

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  ('wiki_incident_scarlet_mist:section:overview','wiki_incident_scarlet_mist','overview',1,'Overview','A public atmospheric crisis centered on scarlet mist and mansion power.','The Scarlet Mist Incident is important not only because of its immediate abnormality, but because it helped define the public scale on which Gensokyo learns to recognize and answer large disturbances.', '["claim_incident_scarlet_mist","lore_incident_scarlet_mist"]'::jsonb,'{}'::jsonb),
  ('wiki_incident_eternal_night:section:overview','wiki_incident_eternal_night','overview',1,'Overview','A false-night incident with deep lunar ties.','Imperishable Night should be understood as a night-delaying, dawn-deferring incident in which secrecy, moon-linked actors, and highly personal history all overlap.', '["claim_incident_eternal_night","lore_incident_eternal_night"]'::jsonb,'{}'::jsonb),
  ('wiki_incident_faith_shift:section:overview','wiki_incident_faith_shift','overview',1,'Overview','A faith and institutional influence shift around the mountain shrines.','The mountain faith shift is less about one explosion and more about how shrine competition and proactive institutional behavior altered public balance.', '["claim_incident_faith_shift","lore_incident_moriya_faith"]'::jsonb,'{}'::jsonb),
  ('wiki_incident_little_rebellion:section:overview','wiki_incident_little_rebellion','overview',1,'Overview','A reversal-structured rebellion driven by grievance and unstable legitimacy.','The little people rebellion belongs to stories where imbalance, resentment, and symbolic power overturn settled expectation without producing lasting stable order.', '["claim_incident_little_rebellion","lore_incident_little_rebellion"]'::jsonb,'{}'::jsonb),
  ('wiki_incident_lunar_crisis:section:overview','wiki_incident_lunar_crisis','overview',1,'Overview','A moon crisis of purification and dream-linked mediation.','The lunar crisis is a high-scale conflict in which moon politics, purified hostility, and dream-space mediation all become necessary to understanding the shape of the threat.', '["claim_incident_lunar_crisis","lore_incident_lunar_crisis"]'::jsonb,'{}'::jsonb),
  ('wiki_incident_market_cards:section:overview','wiki_incident_market_cards','overview',1,'Overview','A market-structured incident of cards, exchange, and distributed value.','The card market incident matters because it makes circulation, ownership, and exchange into the grammar of disruption itself rather than background economics.', '["claim_incident_market_cards","lore_incident_market_cards"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
