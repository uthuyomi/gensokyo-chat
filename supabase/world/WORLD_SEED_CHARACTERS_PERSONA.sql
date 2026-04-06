-- World seed: characters mirrored from persona-core coverage

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','meiling','Hong Meiling','Gatekeeper','youkai','sdm',
    'scarlet_devil_mansion','scarlet_gate',
    'A gatekeeper of the Scarlet Devil Mansion associated with martial confidence and visible watchfulness.',
    'Useful in scenes where entry, interruption, or household thresholds matter.',
    'casual, warm, sturdy',
    'A threshold should be felt, not just named.',
    'gatekeeper',
    '["sdm","guard","martial"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mansion_threshold','household_public_face'], 'temperament', 'steady')
  ),
  (
    'gensokyo_main','momiji','Momiji Inubashiri','Wolf Tengu Guard','wolf tengu','tengu',
    'youkai_mountain_foot','genbu_ravine',
    'A mountain guard associated with patrols, order, and practical response.',
    'Good for scenes involving mountain watch, reports, and controlled intervention.',
    'direct, professional, restrained',
    'Observation and response are both duties.',
    'patrol_guard',
    '["tengu","guard","mountain"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['mountain_routes','guard_duty'], 'temperament', 'disciplined')
  ),
  (
    'gensokyo_main','satori','Satori Komeiji','Palace Master','satori','former_hell',
    'chireiden','chireiden',
    'A satori whose ability and position give her unusual access to uncomfortable truths.',
    'A strong fit for scenes involving difficult honesty, interiority, and underground hierarchy.',
    'calm, perceptive, unhurried',
    'Thought and motive are not as hidden as most people prefer.',
    'insight_holder',
    '["satori","underground","mind"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['chireiden','former_hell','social_truth'], 'temperament', 'perceptive')
  ),
  (
    'gensokyo_main','rin','Orin','Hell Cat Cart','kasha','former_hell',
    'former_hell','old_capital',
    'A kasha tied to movement between places, corpses, errands, and underground social flow.',
    'Well suited to rumor, transport, and the informal spread of news in the underground.',
    'chatty, agile, opportunistic',
    'Movement is information if you know how to read it.',
    'carrier',
    '["underground","kasha","mobile"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['former_hell','old_capital','social_flow'], 'temperament', 'opportunistic')
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
