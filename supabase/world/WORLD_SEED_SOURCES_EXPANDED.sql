-- World seed: expanded official source index

insert into public.world_source_index (
  id, world_id, source_kind, source_code, title, short_label, notes, metadata
)
values
  ('src_poFV','gensokyo_main','official_game','pofv','Phantasmagoria of Flower View','PoFV','Official game source for flower incident-era cast and setting.','{}'::jsonb),
  ('src_ds','gensokyo_main','official_game','ds','Double Spoiler','DS','Official game source for Aya and Hatate-focused incident reporting and challenge framing.','{}'::jsonb),
  ('src_gfw','gensokyo_main','official_game','gfw','Great Fairy Wars','GFW','Official game source for Cirno-centered fairy conflict framing.','{}'::jsonb),
  ('src_swl','gensokyo_main','official_game','swl','Scarlet Weather Rhapsody','SWR','Official game source for weather anomaly and related cast.','{}'::jsonb),
  ('src_hm','gensokyo_main','official_game','hm','Hopeless Masquerade','HM','Official game source for religious popularity conflict and mask-era public mood.','{}'::jsonb),
  ('src_ulil','gensokyo_main','official_game','ulil','Urban Legend in Limbo','ULiL','Official game source for urban legend rumors and outside-world narrative bleed.','{}'::jsonb),
  ('src_aocf','gensokyo_main','official_game','aocf','Antinomy of Common Flowers','AoCF','Official game source for possession incidents and pair-driven conflict.','{}'::jsonb),
  ('src_ufo','gensokyo_main','official_game','ufo','Undefined Fantastic Object','UFO','Official game source for Myouren Temple and related cast.','{}'::jsonb),
  ('src_td','gensokyo_main','official_game','td','Ten Desires','TD','Official game source for saint, hermit, and divine spirit-era cast.','{}'::jsonb),
  ('src_ddc','gensokyo_main','official_game','ddc','Double Dealing Character','DDC','Official game source for inchling incident and related cast.','{}'::jsonb),
  ('src_lolk','gensokyo_main','official_game','lolk','Legacy of Lunatic Kingdom','LoLK','Official game source for lunar crisis-era cast and context.','{}'::jsonb),
  ('src_hsifs','gensokyo_main','official_game','hsifs','Hidden Star in Four Seasons','HSiFS','Official game source for season-backdoor incident cast.','{}'::jsonb),
  ('src_wbawc','gensokyo_main','official_game','wbawc','Wily Beast and Weakest Creature','WBaWC','Official game source for animal spirit and beast realm-linked cast.','{}'::jsonb),
  ('src_17_5','gensokyo_main','official_game','17_5','100th Black Market / Gouyoku Ibun-era underworld cluster','17.5','Official fighting-action side source for greed-linked underworld pressure and Yuuma-related setting.','{}'::jsonb),
  ('src_um','gensokyo_main','official_game','um','Unconnected Marketeers','UM','Official game source for card-market incident and mountain market cast.','{}'::jsonb),
  ('src_uDoALG','gensokyo_main','official_game','udoalg','Unfinished Dream of All Living Ghost','UDoALG','Official game source for all-living-ghost conflict and newest mainline additions.','{}'::jsonb),
  ('src_boaFW','gensokyo_main','official_book','boafw','Bohemian Archive in Japanese Red','BAiJR','Print work focused on articles, interviews, and Aya-framed coverage.','{}'::jsonb),
  ('src_sixty_years','gensokyo_main','official_book','sixty_years','Perfect Memento in Strict Sense / Symposium-era reference cluster','PMiSS+SoPM','Reference cluster for setting encyclopedia style coverage and public-facing lore statements.','{}'::jsonb),
  ('src_ssib','gensokyo_main','official_book','ssib','Silent Sinner in Blue','SSiB','Print work source for moon expedition and lunar court context.','{}'::jsonb),
  ('src_ciLR','gensokyo_main','official_book','cilr','Cage in Lunatic Runagate','CiLR','Print work source for reflective lunar-side perspectives.','{}'::jsonb),
  ('src_wahh','gensokyo_main','official_book','wahh','Wild and Horned Hermit','WaHH','Print work source for Kasen, shrine-side developments, and broader daily Gensokyo.','{}'::jsonb),
  ('src_fs','gensokyo_main','official_book','fs','Forbidden Scrollery','FS','Print work source for village book culture, kosuzu, and incident-laced daily life.','{}'::jsonb),
  ('src_cds','gensokyo_main','official_book','cds','Cheating Detective Satori','CDS','Print work source for Satori-led mystery framing and later-era investigative texture.','{}'::jsonb),
  ('src_osp','gensokyo_main','official_book','osp','Oriental Sacred Place','OSP','Print work source for fairies and shrine-adjacent recurring life.','{}'::jsonb),
  ('src_vfi','gensokyo_main','official_book','vfi','Visionary Fairies in Shrine','VFiS','Print work source for fairy activity and shrine-linked daily atmosphere.','{}'::jsonb),
  ('src_lotus_asia','gensokyo_main','official_book','lotus_asia','Curiosities of Lotus Asia','CoLA','Print work source for Rinnosuke and object-centered Gensokyo detail.','{}'::jsonb),
  ('src_grimoire_marisa','gensokyo_main','official_book','grimoire_marisa','The Grimoire of Marisa','GoM','Print work source emphasizing spell card observation and Marisa''s framing.','{}'::jsonb),
  ('src_alt_truth','gensokyo_main','official_book','alt_truth','Alternative Facts in Eastern Utopia','AFiEU','Print work source for tengu-framed reportage, public narrative, and bias-aware lore.', '{}'::jsonb)
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_code = excluded.source_code,
    title = excluded.title,
    short_label = excluded.short_label,
    notes = excluded.notes,
    metadata = excluded.metadata,
    updated_at = now();
