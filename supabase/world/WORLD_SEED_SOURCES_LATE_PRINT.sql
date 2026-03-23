-- World seed: additional late print-work sources

insert into public.world_source_index (
  id, world_id, source_kind, source_code, title, short_label, notes, metadata
)
values
  ('src_le','gensokyo_main','official_book','le','Lotus Eaters','LE','Print work source for Miyoi, tavern culture, and after-hours social texture in Gensokyo.','{}'::jsonb),
  ('src_fds','gensokyo_main','official_book','fds','Foul Detective Satori','FDS','Print work source for Mizuchi, possession-linked mystery structure, and later-era incident investigation.','{}'::jsonb)
on conflict (id) do update
set source_kind = excluded.source_kind,
    source_code = excluded.source_code,
    title = excluded.title,
    short_label = excluded.short_label,
    notes = excluded.notes,
    metadata = excluded.metadata,
    updated_at = now();
