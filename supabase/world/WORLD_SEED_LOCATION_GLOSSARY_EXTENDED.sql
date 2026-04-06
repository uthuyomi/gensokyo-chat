-- World seed: extended location glossary and profiles

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_glossary_forest_of_magic','location_trait','Forest of Magic Glossary','Forest of Magic should feel private, hazardous, and craft-oriented rather than merely mysterious wallpaper.',jsonb_build_object('location_id','forest_of_magic'),'["glossary","location","forest_of_magic"]'::jsonb,82),
  ('gensokyo_main','lore_glossary_misty_lake','location_trait','Misty Lake Glossary','Misty Lake scenes work best when local trouble, fairy energy, and the mansion approach overlap.',jsonb_build_object('location_id','misty_lake'),'["glossary","location","misty_lake"]'::jsonb,76),
  ('gensokyo_main','lore_glossary_bamboo_forest','location_trait','Bamboo Forest Glossary','Bamboo Forest should be treated as a maze of hidden routes, local guides, and unreliable orientation.',jsonb_build_object('location_id','bamboo_forest'),'["glossary","location","bamboo_forest"]'::jsonb,81),
  ('gensokyo_main','lore_glossary_netherworld','location_trait','Netherworld Glossary','The Netherworld is an elegant death-adjacent realm where etiquette and boundary-aesthetics matter.',jsonb_build_object('location_id','netherworld'),'["glossary","location","netherworld"]'::jsonb,80),
  ('gensokyo_main','lore_glossary_former_hell','location_trait','Former Hell Glossary','Former Hell and the Old Capital should feel rowdy, rule-bound, and socially forceful rather than chaotic at random.',jsonb_build_object('location_id','former_hell'),'["glossary","location","former_hell"]'::jsonb,80),
  ('gensokyo_main','lore_glossary_muenzuka','location_trait','Muenzuka Glossary','Muenzuka belongs to border-field logic, abandoned things, and difficult crossings near the outside.',jsonb_build_object('location_id','muenzuka'),'["glossary","location","muenzuka"]'::jsonb,79),
  ('gensokyo_main','lore_glossary_rainbow_dragon_cave','location_trait','Rainbow Dragon Cave Glossary','Rainbow Dragon Cave should be treated as a market-resource cave where hidden value and trade routes converge.',jsonb_build_object('location_id','rainbow_dragon_cave'),'["glossary","location","rainbow_dragon_cave"]'::jsonb,77),
  ('gensokyo_main','lore_glossary_chireiden','location_trait','Chireiden Glossary','Chireiden should feel psychologically pressurized, intimate, and controlled by uncomfortable clarity.',jsonb_build_object('location_id','chireiden'),'["glossary","location","chireiden"]'::jsonb,79),
  ('gensokyo_main','lore_glossary_divine_spirit_mausoleum','location_trait','Divine Spirit Mausoleum Glossary','The mausoleum is best read as a stage of return, legitimacy, and ritual authority.',jsonb_build_object('location_id','divine_spirit_mausoleum'),'["glossary","location","mausoleum"]'::jsonb,79),
  ('gensokyo_main','lore_glossary_backdoor_realm','location_trait','Backdoor Realm Glossary','The Backdoor Realm should feel like controlled hidden access, not a generic magical side-space.',jsonb_build_object('location_id','backdoor_realm'),'["glossary","location","backdoor_realm"]'::jsonb,78)
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
  ('claim_glossary_forest_of_magic','gensokyo_main','location','forest_of_magic','glossary','Forest of Magic is a private and dangerous craft-space rather than a neutral travel zone.',jsonb_build_object('linked_characters',array['marisa','alice','narumi']),'src_pcb','official',82,'["glossary","forest_of_magic","location"]'::jsonb),
  ('claim_glossary_misty_lake','gensokyo_main','location','misty_lake','glossary','Misty Lake is a local-energy area where fairy movement and mansion approach overlap.',jsonb_build_object('linked_characters',array['cirno','wakasagihime','meiling']),'src_eosd','official',76,'["glossary","misty_lake","location"]'::jsonb),
  ('claim_glossary_bamboo_forest','gensokyo_main','location','bamboo_forest','glossary','Bamboo Forest is a maze of hidden routes, local knowledge, and unreliable orientation.',jsonb_build_object('linked_characters',array['tewi','mokou','kagerou']),'src_imperishable_night','official',82,'["glossary","bamboo_forest","location"]'::jsonb),
  ('claim_glossary_netherworld','gensokyo_main','location','netherworld','glossary','The Netherworld should feel elegant, death-adjacent, and boundary-sensitive.',jsonb_build_object('linked_characters',array['yuyuko','youmu']),'src_pcb','official',81,'["glossary","netherworld","location"]'::jsonb),
  ('claim_glossary_former_hell','gensokyo_main','location','former_hell','glossary','Former Hell is a socially forceful underworld region with rowdy but real local rules.',jsonb_build_object('linked_characters',array['suika','utsuho','rin','satori']),'src_subterranean_animism','official',81,'["glossary","former_hell","location"]'::jsonb),
  ('claim_glossary_muenzuka','gensokyo_main','location','muenzuka','glossary','Muenzuka should be read as a border field of abandonment, crossing, and near-outside tension.',jsonb_build_object('linked_characters',array['komachi','eiki','yukari']),'src_poFV','official',80,'["glossary","muenzuka","location"]'::jsonb),
  ('claim_glossary_rainbow_dragon_cave','gensokyo_main','location','rainbow_dragon_cave','glossary','Rainbow Dragon Cave is a hidden-value and market-route cave tied to mountain commerce.',jsonb_build_object('linked_characters',array['takane','sannyo','momoyo','misumaru']),'src_um','official',78,'["glossary","rainbow_dragon_cave","location"]'::jsonb),
  ('claim_glossary_chireiden','gensokyo_main','location','chireiden','glossary','Chireiden is an underground palace of close interior pressure, pets, and uncomfortable mental clarity.',jsonb_build_object('linked_characters',array['satori','koishi','rin','utsuho']),'src_subterranean_animism','official',80,'["glossary","chireiden","location"]'::jsonb),
  ('claim_glossary_divine_spirit_mausoleum','gensokyo_main','location','divine_spirit_mausoleum','glossary','The Divine Spirit Mausoleum is a return-of-authority stage built around legitimacy and ritual display.',jsonb_build_object('linked_characters',array['miko','futo','tojiko','seiga']),'src_td','official',80,'["glossary","mausoleum","location"]'::jsonb),
  ('claim_glossary_backdoor_realm','gensokyo_main','location','backdoor_realm','glossary','The Backdoor Realm is a hidden-access space of selected passage and backstage intervention.',jsonb_build_object('linked_characters',array['okina','satono','mai']),'src_hsifs','official',79,'["glossary","backdoor_realm","location"]'::jsonb)
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
