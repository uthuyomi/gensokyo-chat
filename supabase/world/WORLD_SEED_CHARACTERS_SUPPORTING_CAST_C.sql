-- World seed: third wave of supporting cast from early recurring nocturnal and local layers

insert into public.world_characters (
  world_id, id, name, title, species, faction_id, home_location_id, default_location_id,
  public_summary, private_notes, speech_style, worldview, role_in_gensokyo, tags, profile
)
values
  (
    'gensokyo_main','rumia','Rumia','Youkai of Darkness','youkai','independent',
    'misty_lake','misty_lake',
    'A darkness youkai suited to small nighttime trouble, light obstruction, and low-level youkai presence.',
    'Best used to give early-route nights a face rather than to carry major ideology.',
    'simple, playful, hungry',
    'If you cannot see clearly, the world belongs to whoever is nearby.',
    'night_local',
    '["eosd","night","local"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['night_routes','minor_trouble'], 'temperament', 'playful')
  ),
  (
    'gensokyo_main','mystia','Mystia Lorelei','Night Sparrow','sparrow_youkai','independent',
    'human_village','human_village',
    'A singer and food-seller whose scenes fit nocturnal commerce, music, and charming danger at the village edge.',
    'Useful for making night life feel commercial and social rather than empty.',
    'cheerful, musical, opportunistic',
    'If people gather to eat and listen, the night has already become livable.',
    'night_vendor',
    '["in","night","music","food"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['night_stalls','song','village_edges'], 'temperament', 'cheerful')
  ),
  (
    'gensokyo_main','wriggle','Wriggle Nightbug','Firefly Youkai','insect_youkai','independent',
    'human_village','human_village',
    'An insect youkai suited to summer-night texture, small collective pressure, and overlooked local presence.',
    'Useful where the night should feel alive in a low, swarming register rather than through single grand actors.',
    'earnest, prickly, lively',
    'Small lives add up faster than people expect.',
    'night_local',
    '["in","night","summer","insects"]'::jsonb,
    jsonb_build_object('knowledge_scope', array['summer_nights','small_collectives'], 'temperament', 'prickly')
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
