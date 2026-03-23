-- World seed: lunar and late print-work support characters

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','toyohime','Watatsuki no Toyohime','Lunar Noble','lunarian','lunar_capital',
    'lunar_capital','lunar_capital',
    'A lunar noble suited to high-level moon politics, elegance, and strategic superiority framed as natural order.',
    'Best used when the lunar side needs composed authority rather than raw aggression.',
    'graceful, superior, composed',
    'Refinement and control are easiest to maintain when treated as normal.',
    'lunar_elite',
    '["ssib","moon","nobility"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['lunar_politics','moon_earth_relations'], 'temperament', 'composed')
  ),
  (
    'gensokyo_main','yorihime','Watatsuki no Yorihime','Lunar Noble and Divine Summoner','lunarian','lunar_capital',
    'lunar_capital','lunar_capital',
    'A lunar noble whose role fits martial authority, divine invocation, and uncompromising lunar standards.',
    'Useful where the moon needs force backed by legitimacy rather than mere temperament.',
    'formal, severe, disciplined',
    'Authority is easiest to respect when it never blinks first.',
    'lunar_martial_elite',
    '["ssib","moon","military"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['lunar_security','divine_authority'], 'temperament', 'severe')
  ),
  (
    'gensokyo_main','miyoi','Okunoda Miyoi','Geidontei Poster Girl','zashiki_warashi_like','independent',
    'human_village','human_village',
    'A tavern-linked hostess suited to after-hours village life, drinking culture, and the softer side of recurring social scenes.',
    'Best used where Gensokyo needs nightlife, hospitality, and gossip without turning everything into formal incident structure.',
    'gentle, attentive, warm',
    'People speak differently once they think the day is over.',
    'night_hospitality',
    '["le","village","tavern"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['village_nightlife','tavern_customs'], 'temperament', 'warm')
  ),
  (
    'gensokyo_main','mizuchi','Mizuchi Miyadeguchi','Vengeful Spirit in Hiding','vengeful_spirit','independent',
    'human_village','human_village',
    'A hidden vengeful spirit suited to possession, resentment, and the destabilization of ordinary social surfaces.',
    'Useful when later-era mysteries need a threat that moves through people rather than simply confronting them.',
    'cold, quiet, resentful',
    'A quiet grudge can travel farther than an open shout.',
    'hidden_threat',
    '["fds","vengeful_spirit","mystery"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['hidden_possession','resentment_routes'], 'temperament', 'cold')
  )
on conflict (world_id, id) do update
set name = excluded.name,
    title = excluded.title,
    species = excluded.species,
    faction_id = excluded.faction_id,
    home_location_id = excluded.home_location_id,
    default_location_id = excluded.default_location_id,
    public_summary = excluded.public_summary,
    private_notes = excluded.private_notes,
    speech_style = excluded.speech_style,
    worldview = excluded.worldview,
    role_in_gensokyo = excluded.role_in_gensokyo,
    tags = excluded.tags,
    profile = excluded.profile,
    updated_at = now();
