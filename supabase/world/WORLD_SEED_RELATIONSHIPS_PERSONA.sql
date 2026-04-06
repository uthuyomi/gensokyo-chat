-- World seed: relationships for persona-covered cast

insert into public.world_relationship_edges (
  world_id, source_character_id, target_character_id, relation_type, summary, strength, metadata
)
values
  ('gensokyo_main','meiling','sakuya','household_colleague','Meiling and Sakuya both sustain the mansion, but from very different positions and rhythms.',0.66,'{}'::jsonb),
  ('gensokyo_main','sakuya','meiling','household_colleague','Sakuya relies on Meiling as part of the mansion''s visible perimeter and order.',0.66,'{}'::jsonb),
  ('gensokyo_main','meiling','remilia','household_loyalty','Meiling''s public gatekeeping ultimately serves Remilia''s authority.',0.72,'{}'::jsonb),
  ('gensokyo_main','momiji','aya','information_chain','Momiji and Aya both move along mountain information routes, though not for identical reasons.',0.53,'{}'::jsonb),
  ('gensokyo_main','aya','momiji','information_chain','Aya often intersects with the same mountain flow that Momiji patrols.',0.53,'{}'::jsonb),
  ('gensokyo_main','satori','koishi','family_bond','Satori''s relation to Koishi is inseparable from absence, concern, and irreversible change.',0.90,'{}'::jsonb),
  ('gensokyo_main','koishi','satori','family_bond','Koishi remains tied to Satori even when that tie does not look ordinary from the outside.',0.90,'{}'::jsonb),
  ('gensokyo_main','satori','rin','household_supervision','Rin works within the social world shaped by Satori''s palace and oversight.',0.71,'{}'::jsonb),
  ('gensokyo_main','rin','satori','household_loyalty','Rin''s movement and errands are still tied back to Satori''s house.',0.71,'{}'::jsonb),
  ('gensokyo_main','satori','okuu','household_supervision','Okuu''s scale and force exist within the sphere Satori has to manage.',0.76,'{}'::jsonb),
  ('gensokyo_main','okuu','satori','household_loyalty','Okuu''s place in the underground household remains anchored to Satori.',0.76,'{}'::jsonb),
  ('gensokyo_main','rin','okuu','close_companion','Rin and Okuu share strong everyday familiarity inside the underground household.',0.84,'{}'::jsonb),
  ('gensokyo_main','okuu','rin','close_companion','Okuu and Rin function as strongly connected companions within the underground.',0.84,'{}'::jsonb)
on conflict (world_id, source_character_id, target_character_id, relation_type) do update
set summary = excluded.summary,
    strength = excluded.strength,
    metadata = excluded.metadata,
    updated_at = now();
