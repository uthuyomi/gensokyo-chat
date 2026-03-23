-- World seed: core character abilities and epithet-style claims

insert into public.world_lore_entries (
  world_id, id, category, title, summary, details, tags, priority
)
values
  ('gensokyo_main','lore_ability_reimu','character_ability','Reimu Ability Frame','Reimu should be framed through floating, spiritual instinct, and incident-resolution authority rather than raw theory alone.',jsonb_build_object('character_id','reimu'),'["ability","reimu"]'::jsonb,88),
  ('gensokyo_main','lore_ability_marisa','character_ability','Marisa Ability Frame','Marisa belongs to scenes of magic use, theft-adjacent acquisition, and bold practical experimentation.',jsonb_build_object('character_id','marisa'),'["ability","marisa"]'::jsonb,87),
  ('gensokyo_main','lore_ability_sakuya','character_ability','Sakuya Ability Frame','Sakuya should be framed through precision, timing, and impossible control of the flow of action.',jsonb_build_object('character_id','sakuya'),'["ability","sakuya"]'::jsonb,84),
  ('gensokyo_main','lore_ability_yukari','character_ability','Yukari Ability Frame','Yukari is a boundary actor whose scenes should emphasize framing, transit, and high-order intervention.',jsonb_build_object('character_id','yukari'),'["ability","yukari"]'::jsonb,89),
  ('gensokyo_main','lore_ability_eirin','character_ability','Eirin Ability Frame','Eirin combines medicine, strategy, and technical superiority rather than simple mystical vagueness.',jsonb_build_object('character_id','eirin'),'["ability","eirin"]'::jsonb,86),
  ('gensokyo_main','lore_ability_aya','character_ability','Aya Ability Frame','Aya is strongly tied to speed, reporting, circulation, and turning motion into public narrative.',jsonb_build_object('character_id','aya'),'["ability","aya"]'::jsonb,82),
  ('gensokyo_main','lore_ability_satori','character_ability','Satori Ability Frame','Satori scenes should foreground mind-reading pressure and exposed motive rather than generic cleverness.',jsonb_build_object('character_id','satori'),'["ability","satori"]'::jsonb,83),
  ('gensokyo_main','lore_ability_utsuho','character_ability','Utsuho Ability Frame','Utsuho should be treated as dangerous scale and energy projection, not as a subtle local problem.',jsonb_build_object('character_id','utsuho'),'["ability","utsuho"]'::jsonb,82),
  ('gensokyo_main','lore_ability_byakuren','character_ability','Byakuren Ability Frame','Byakuren should read as magical power disciplined through principle and coexistence rhetoric.',jsonb_build_object('character_id','byakuren'),'["ability","byakuren"]'::jsonb,79),
  ('gensokyo_main','lore_ability_miko','character_ability','Miko Ability Frame','Miko scenes combine saintly charisma, hearing, and political shaping of an audience.',jsonb_build_object('character_id','miko'),'["ability","miko"]'::jsonb,81),
  ('gensokyo_main','lore_ability_seija','character_ability','Seija Ability Frame','Seija should be treated through inversion and contrarian reversal rather than plain mischief.',jsonb_build_object('character_id','seija'),'["ability","seija"]'::jsonb,78),
  ('gensokyo_main','lore_ability_shinmyoumaru','character_ability','Shinmyoumaru Ability Frame','Shinmyoumaru is tied to miracle-sized shifts emerging from smallness and symbolic imbalance.',jsonb_build_object('character_id','shinmyoumaru'),'["ability","shinmyoumaru"]'::jsonb,76),
  ('gensokyo_main','lore_ability_junko','character_ability','Junko Ability Frame','Junko should be framed through purified hostility and concentrated emotional reduction.',jsonb_build_object('character_id','junko'),'["ability","junko"]'::jsonb,86),
  ('gensokyo_main','lore_ability_okina','character_ability','Okina Ability Frame','Okina belongs to hidden doorways, backstage access, and the selective opening of routes and talent.',jsonb_build_object('character_id','okina'),'["ability","okina"]'::jsonb,84),
  ('gensokyo_main','lore_ability_keiki','character_ability','Keiki Ability Frame','Keiki is a creator of idols and systems, so her scenes should feel manufactured and intentional.',jsonb_build_object('character_id','keiki'),'["ability","keiki"]'::jsonb,78),
  ('gensokyo_main','lore_ability_chimata','character_ability','Chimata Ability Frame','Chimata scenes should tie value, markets, and social flow together as one mechanism.',jsonb_build_object('character_id','chimata'),'["ability","chimata"]'::jsonb,77)
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
  ('claim_ability_reimu','gensokyo_main','character','reimu','ability','Reimu is associated with spiritual intuition, floating, and direct incident-resolution competence.',jsonb_build_object('ability','float and spiritual response'),'src_sopm','official',90,'["ability","reimu"]'::jsonb),
  ('claim_ability_marisa','gensokyo_main','character','marisa','ability','Marisa is associated with practical magic, accumulation of tools, and forceful magical initiative.',jsonb_build_object('ability','magic and acquisitive improvisation'),'src_grimoire_marisa','official',88,'["ability","marisa"]'::jsonb),
  ('claim_ability_sakuya','gensokyo_main','character','sakuya','ability','Sakuya is strongly tied to impossible precision and control over timing.',jsonb_build_object('ability','time and precision control'),'src_eosd','official',85,'["ability","sakuya"]'::jsonb),
  ('claim_ability_yukari','gensokyo_main','character','yukari','ability','Yukari is fundamentally a boundary manipulator rather than an ordinary traveler or planner.',jsonb_build_object('ability','boundary manipulation'),'src_pcb','official',90,'["ability","yukari"]'::jsonb),
  ('claim_ability_eirin','gensokyo_main','character','eirin','ability','Eirin combines pharmaceutical mastery with strategic and technical superiority.',jsonb_build_object('ability','medicine and strategy'),'src_imperishable_night','official',87,'["ability","eirin"]'::jsonb),
  ('claim_ability_aya','gensokyo_main','character','aya','ability','Aya is associated with speed, wind, and the rapid circulation of information.',jsonb_build_object('ability','wind and speed'),'src_boaFW','official',83,'["ability","aya"]'::jsonb),
  ('claim_ability_satori','gensokyo_main','character','satori','ability','Satori''s defining power is reading minds and exposing motive.',jsonb_build_object('ability','mind reading'),'src_subterranean_animism','official',84,'["ability","satori"]'::jsonb),
  ('claim_ability_utsuho','gensokyo_main','character','utsuho','ability','Utsuho is tied to nuclear-scale energy and overwhelming output.',jsonb_build_object('ability','nuclear energy'),'src_subterranean_animism','official',84,'["ability","utsuho"]'::jsonb),
  ('claim_ability_byakuren','gensokyo_main','character','byakuren','ability','Byakuren is associated with powerful magic disciplined through religious and ethical orientation.',jsonb_build_object('ability','enhancing magic'),'src_ufo','official',80,'["ability","byakuren"]'::jsonb),
  ('claim_ability_miko','gensokyo_main','character','miko','ability','Miko is tied to saintly charisma and extraordinary hearing that supports leadership.',jsonb_build_object('ability','hearing and saintly authority'),'src_td','official',82,'["ability","miko"]'::jsonb),
  ('claim_ability_seija','gensokyo_main','character','seija','ability','Seija is defined by reversal and inversion of what should normally hold.',jsonb_build_object('ability','reversal'),'src_ddc','official',79,'["ability","seija"]'::jsonb),
  ('claim_ability_shinmyoumaru','gensokyo_main','character','shinmyoumaru','ability','Shinmyoumaru is tied to miracle and imbalance flowing from smallness and legendary tools.',jsonb_build_object('ability','miracle and small-folk power'),'src_ddc','official',77,'["ability","shinmyoumaru"]'::jsonb),
  ('claim_ability_junko','gensokyo_main','character','junko','ability','Junko is associated with purification into singular hostility and intent.',jsonb_build_object('ability','purification'),'src_lolk','official',87,'["ability","junko"]'::jsonb),
  ('claim_ability_okina','gensokyo_main','character','okina','ability','Okina is associated with backdoors, hidden access, and secret empowerment.',jsonb_build_object('ability','backdoor manipulation'),'src_hsifs','official',85,'["ability","okina"]'::jsonb),
  ('claim_ability_keiki','gensokyo_main','character','keiki','ability','Keiki is defined by the creation of idols and constructive counter-force.',jsonb_build_object('ability','create idols'),'src_wbawc','official',79,'["ability","keiki"]'::jsonb),
  ('claim_ability_chimata','gensokyo_main','character','chimata','ability','Chimata is tied to markets, ownership, and value as active social structure.',jsonb_build_object('ability','markets and value circulation'),'src_um','official',78,'["ability","chimata"]'::jsonb),
  ('claim_title_reimu','gensokyo_main','character','reimu','epithet','Reimu''s public image is anchored by the shrine maiden role and incident resolution.',jsonb_build_object('epithet','shrine maiden'),'src_sopm','official',88,'["title","reimu"]'::jsonb),
  ('claim_title_marisa','gensokyo_main','character','marisa','epithet','Marisa''s identity is anchored by ordinary-magician framing paired with extraordinary initiative.',jsonb_build_object('epithet','ordinary magician'),'src_grimoire_marisa','official',85,'["title","marisa"]'::jsonb),
  ('claim_title_yukari','gensokyo_main','character','yukari','epithet','Yukari''s image is anchored by boundary-youkai framing and high-order distance.',jsonb_build_object('epithet','boundary youkai'),'src_pcb','official',87,'["title","yukari"]'::jsonb),
  ('claim_title_miko','gensokyo_main','character','miko','epithet','Miko''s public role is strongly saintly and political rather than merely combative.',jsonb_build_object('epithet','saintly leader'),'src_td','official',81,'["title","miko"]'::jsonb)
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
