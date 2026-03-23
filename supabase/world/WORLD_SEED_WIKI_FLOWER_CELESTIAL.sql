-- World seed: wiki pages for flower, celestial, dream, and seasonal cast

insert into public.world_wiki_pages (
  id, world_id, slug, title, page_type, subject_type, subject_id, summary, status, canonical_book_id, metadata
)
values
  ('wiki_character_eiki','gensokyo_main','characters/shikieiki-yamaxanadu','Shikieiki Yamaxanadu','character','character','eiki','A judge of moral weight and formal correction rather than casual social flow.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_tenshi','gensokyo_main','characters/tenshi-hinanawi','Tenshi Hinanawi','character','character','tenshi','A celestial instigator whose pride and boredom can scale into weather-sized trouble.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_kokoro','gensokyo_main','characters/hata-no-kokoro','Hata no Kokoro','character','character','kokoro','A mask-bearing performer suited to stories where emotion and public affect are active mechanics.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_doremy','gensokyo_main','characters/doremy-sweet','Doremy Sweet','character','character','doremy','A dream shepherd who gives dream-space scenes a real guide and caretaker.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_character_aunn','gensokyo_main','characters/aunn-komano','Aunn Komano','character','character','aunn','A shrine guardian who adds local warmth and watchfulness to sacred space.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_location_heaven','gensokyo_main','locations/heaven','Heaven','location','location','heaven','A celestial sphere of comfort, detachment, and large-scale unintended consequence.','published','chronicle_gensokyo_history','{}'::jsonb),
  ('wiki_location_dream_world','gensokyo_main','locations/dream-world','Dream World','location','location','dream_world','A symbolic dream-space that still benefits from mediation and structure.','published','chronicle_gensokyo_history','{}'::jsonb)
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
  ('wiki_character_eiki:section:overview','wiki_character_eiki','overview',1,'Overview','Eiki as judge and corrective force.','Shikieiki Yamaxanadu belongs in scenes where formal moral evaluation matters more than ordinary social tact or convenience.','["claim_eiki_judge","lore_muenzuka_judgment"]'::jsonb,'{}'::jsonb),
  ('wiki_character_tenshi:section:overview','wiki_character_tenshi','overview',1,'Overview','Tenshi as celestial-scale instigator.','Tenshi is best framed through arrogance, boredom, and enough distance from ground-level consequence to cause real trouble.','["claim_tenshi_celestial_instigator","lore_heaven_detachment"]'::jsonb,'{}'::jsonb),
  ('wiki_character_kokoro:section:overview','wiki_character_kokoro','overview',1,'Overview','Kokoro as emotion-bearing performer.','Kokoro should be used when masks, public feeling, and the instability of emotion display matter to the structure of the scene itself.','["claim_kokoro_mask_performer","lore_kokoro_public_affect"]'::jsonb,'{}'::jsonb),
  ('wiki_character_doremy:section:overview','wiki_character_doremy','overview',1,'Overview','Doremy as dream mediator.','Doremy Sweet is useful because dream-space can be navigated and tended, not just because dreams are strange.','["claim_doremy_dream_guide","lore_dream_world_mediator"]'::jsonb,'{}'::jsonb),
  ('wiki_character_aunn:section:overview','wiki_character_aunn','overview',1,'Overview','Aunn as shrine-ground guardian.','Aunn makes shrine-space feel inhabited, appreciated, and practically watched over in an everyday way.','["claim_aunn_guardian","lore_aunn_shrine_everyday"]'::jsonb,'{}'::jsonb),
  ('wiki_location_heaven:section:profile','wiki_location_heaven','profile',1,'Profile','Heaven as detached celestial sphere.','Heaven should feel luxurious and removed enough that celestial disturbance can emerge from misjudged comfort and scale.','["claim_heaven_profile","lore_heaven_detachment"]'::jsonb,'{}'::jsonb),
  ('wiki_location_dream_world:section:profile','wiki_location_dream_world','profile',1,'Profile','Dream World as symbolic mediated realm.','Dream World supports symbolic encounters and unstable logic, but scenes there become stronger when someone can actually navigate and frame them.','["claim_dream_world_profile","lore_dream_world_mediator"]'::jsonb,'{}'::jsonb)
on conflict (id) do update
set heading = excluded.heading,
    summary = excluded.summary,
    body = excluded.body,
    source_ref_ids = excluded.source_ref_ids,
    metadata = excluded.metadata,
    updated_at = now();
