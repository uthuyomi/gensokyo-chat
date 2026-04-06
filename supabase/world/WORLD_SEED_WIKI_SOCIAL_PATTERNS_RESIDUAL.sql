-- World seed: residual social-pattern wiki pages

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  (
    'wiki_term_backdoor_service',
    'gensokyo_main',
    'terms/backdoor-service',
    'Backdoor Service',
    'glossary',
    'term',
    'backdoor_service',
    'A glossary page for hidden-stage service, selective invitation, and attendant choreography around the Backdoor Realm.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  ),
  (
    'wiki_term_market_rest_stops',
    'gensokyo_main',
    'terms/market-rest-stops',
    'Market Rest Stops',
    'glossary',
    'term',
    'market_rest_stops',
    'A glossary page for the low-pressure social spaces that keep Gensokyo market routes alive.',
    'published',
    'chronicle_gensokyo_history',
    '{}'::jsonb
  )
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
  (
    'wiki_term_backdoor_service:section:definition',
    'wiki_term_backdoor_service',
    'definition',
    1,
    'Definition',
    'Backdoor service as selective hidden-stage labor.',
    'Backdoor service should be read as a visible form of hidden-stage labor in which attendants turn invitation, selection, and staged access into a social mechanism.',
    '["claim_satono_selected_attendant","claim_mai_backstage_executor","claim_backdoor_attendants_pairing","claim_backdoor_realm_profile"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_term_market_rest_stops:section:definition',
    'wiki_term_market_rest_stops',
    'definition',
    1,
    'Definition',
    'Market rest stops as soft infrastructure.',
    'Market rest stops are the smoke breaks, pause points, and conversational shelters that make Gensokyo trade routes feel lived in rather than purely transactional.',
    '["claim_sannyo_informal_merchant","claim_market_route_rest_stops","claim_rainbow_dragon_cave_profile"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
