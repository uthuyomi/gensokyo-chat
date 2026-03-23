-- World seed: major relationship edges for late-mainline cast

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','nazrin','byakuren','subordinate_respect','Nazrin''s practical work often supports temple operations under Byakuren''s broader leadership.',0.67,'{}'::jsonb),
  ('gensokyo_main','ichirin','byakuren','devotional_service','Ichirin''s strength is aligned closely with temple protection and Byakuren''s cause.',0.81,'{}'::jsonb),
  ('gensokyo_main','murasa','byakuren','group_alignment','Murasa''s mobility and charisma support Myouren Temple''s collective momentum.',0.74,'{}'::jsonb),
  ('gensokyo_main','nue','byakuren','uneasy_affiliation','Nue is associated with the temple orbit but not with simple predictability.',0.46,'{}'::jsonb),
  ('gensokyo_main','kogasa','byakuren','friendly_affiliation','Kogasa fits the temple''s broad coexistence circle even when her own goals are lighter.',0.41,'{}'::jsonb),
  ('gensokyo_main','miko','futo','leader_retainer','Futo''s conduct and ritual role are tightly linked to Miko''s restored authority.',0.86,'{}'::jsonb),
  ('gensokyo_main','miko','tojiko','leader_retainer','Tojiko''s station remains strongly tied to Miko''s mausoleum-centered order.',0.82,'{}'::jsonb),
  ('gensokyo_main','seiga','miko','provocative_enabler','Seiga functions as a catalyst around Miko''s restoration rather than a neutral bystander.',0.61,'{}'::jsonb),
  ('gensokyo_main','mamizou','byakuren','institutional_ally','Mamizou can operate as a flexible ally around temple public life without becoming fully absorbed by it.',0.58,'{}'::jsonb),
  ('gensokyo_main','mamizou','reimu','experienced_peer','Mamizou works best as a socially aware peer rather than a simple subordinate to shrine logic.',0.39,'{}'::jsonb),
  ('gensokyo_main','seija','shinmyoumaru','rebel_alignment','Seija''s inversion politics overlap directly with Shinmyoumaru''s upheaval.',0.83,'{}'::jsonb),
  ('gensokyo_main','shinmyoumaru','seija','desperate_ally','Shinmyoumaru depends on Seija''s rebellious force when conventional standing fails.',0.79,'{}'::jsonb),
  ('gensokyo_main','raiko','shinmyoumaru','post_incident_affinity','Raiko belongs to the afterlife of the incident more than its core throne politics.',0.42,'{}'::jsonb),
  ('gensokyo_main','sagume','junko','crisis_opposition','Sagume''s lunar order and Junko''s purified hostility are structurally opposed.',0.92,'{}'::jsonb),
  ('gensokyo_main','clownpiece','junko','aligned_agent','Clownpiece works naturally as an agent of Junko''s disruptive campaign logic.',0.86,'{}'::jsonb),
  ('gensokyo_main','hecatia','clownpiece','patron_support','Hecatia''s backing amplifies Clownpiece''s value as a destabilizing actor.',0.74,'{}'::jsonb),
  ('gensokyo_main','okina','satono','master_attendant','Satono operates most naturally as one side of Okina''s chosen service apparatus.',0.88,'{}'::jsonb),
  ('gensokyo_main','okina','mai','master_attendant','Mai likewise belongs to Okina''s hidden-stage operating structure.',0.88,'{}'::jsonb),
  ('gensokyo_main','satono','mai','paired_service','Satono and Mai are best treated as paired attendants rather than isolated freelancers.',0.77,'{}'::jsonb),
  ('gensokyo_main','yachie','mayumi','strategic_use','Yachie''s style of rule naturally fits directing disciplined subordinates and ordered force.',0.49,'{}'::jsonb),
  ('gensokyo_main','keiki','mayumi','creator_creation','Mayumi''s role is tightly linked to Keiki''s constructive and protective design logic.',0.84,'{}'::jsonb),
  ('gensokyo_main','yachie','saki','factional_rival','Yachie and Saki represent distinct beast-realm power styles that cannot simply be merged.',0.73,'{}'::jsonb),
  ('gensokyo_main','takane','chimata','market_affinity','Takane''s mountain commerce naturally overlaps with Chimata''s market-centered domain.',0.66,'{}'::jsonb),
  ('gensokyo_main','sannyo','chimata','vendor_affinity','Sannyo fits market and exchange scenes that Chimata ideologically broadens.',0.62,'{}'::jsonb),
  ('gensokyo_main','misumaru','reimu','craft_support','Misumaru''s crafted tools and grounded care fit shrine-side support routes better than factional rivalry.',0.48,'{}'::jsonb),
  ('gensokyo_main','tsukasa','megumu','opportunistic_alignment','Tsukasa prefers power structures she can exploit rather than institutions she wholly believes in.',0.37,'{}'::jsonb),
  ('gensokyo_main','momoyo','takane','mountain_trade_overlap','Momoyo and Takane overlap where mountain resources become exchangeable value.',0.43,'{}'::jsonb),
  ('gensokyo_main','megumu','aya','institutional_tengu_peer','Megumu and Aya both belong to mountain authority structures, but not from identical vantage points.',0.57,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();
