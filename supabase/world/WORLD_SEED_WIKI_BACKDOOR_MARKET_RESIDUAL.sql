-- World seed: residual wiki sections for backdoor and market cast

insert into public.world_wiki_page_sections (
  id, page_id, section_code, section_order, heading, summary, body, source_ref_ids, metadata
)
values
  (
    'wiki_character_satono:section:story_use',
    'wiki_character_satono',
    'story_use',
    2,
    'Story Use',
    'Satono as cheerful selective service.',
    'Satono is most effective when a scene needs visible obedience tied to hidden selection, invitation, and backstage permission.',
    '["claim_satono_selected_attendant","claim_backdoor_attendants_pairing","lore_satono_selected_service"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_mai:section:story_use',
    'wiki_character_mai',
    'story_use',
    2,
    'Story Use',
    'Mai as motion-driven backstage execution.',
    'Mai works best when hidden-stage authority is expressed through speed, choreography, and an almost playful execution of orders.',
    '["claim_mai_backstage_executor","claim_backdoor_attendants_pairing","lore_mai_backstage_motion"]'::jsonb,
    '{}'::jsonb
  ),
  (
    'wiki_character_sannyo:section:story_use',
    'wiki_character_sannyo',
    'story_use',
    2,
    'Story Use',
    'Sannyo as informal market rest and candor.',
    'Sannyo is strongest in scenes where markets become local and lived-in through pauses, smoke, and easy conversation rather than overt spectacle.',
    '["claim_sannyo_informal_merchant","claim_market_route_rest_stops","lore_sannyo_informal_market_rest"]'::jsonb,
    '{}'::jsonb
  )
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
