-- World seed: wiki support for late-mainline system terms

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_term_hidden_seasons','gensokyo_main','terms/hidden-seasons','Hidden Seasons','glossary','term','hidden_seasons','A glossary page for selective seasonal power and hidden access layers.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_beast_realm_politics','gensokyo_main','terms/beast-realm-politics','Beast Realm Politics','glossary','term','beast_realm_politics','A glossary page for factional rivalry and proxy conflict in the Beast Realm.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_term_market_competition','gensokyo_main','terms/market-competition','Market Competition','glossary','term','market_competition','A glossary page for routes, ownership, and value competition around cards and exchange.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_term_hidden_seasons:section:definition','wiki_term_hidden_seasons','definition',1,'Definition','Hidden seasons as latent power layers.','Hidden seasons work as selectively revealed power layers linked to access, orchestration, and offstage control rather than plain seasonal weather.', '["claim_term_hidden_seasons","lore_term_hidden_seasons"]'::jsonb,'{}'::jsonb),
  ('wiki_term_beast_realm_politics:section:definition','wiki_term_beast_realm_politics','definition',1,'Definition','Beast Realm as factional politics.','The Beast Realm should be read through organized rivalry, proxy struggle, and strategic predation rather than undifferentiated chaos.', '["claim_term_beast_realm_politics","lore_term_beast_realm_politics"]'::jsonb,'{}'::jsonb),
  ('wiki_term_market_competition:section:definition','wiki_term_market_competition','definition',1,'Definition','Market competition as power circulation.','Market competition in Gensokyo concerns ownership, value, routes, and the circulation of useful power, not just ordinary commerce.', '["claim_term_market_competition","lore_term_market_competition"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
