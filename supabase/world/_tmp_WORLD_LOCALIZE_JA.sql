-- World localization patch: Japanese-facing display text
-- Keeps original English-ish text in metadata/details/payload for fallback/reference.

create or replace function public.world_prettify_identifier_ja(value text)
returns text
language sql
immutable
as $$
  select trim(
    regexp_replace(
      replace(replace(coalesce(value, ''), '_', ' '), ':', ' '),
      '\s+',
      ' ',
      'g'
    )
  );
$$;

create or replace function public.world_known_term_label_ja(value text)
returns text
language sql
immutable
as $$
  select case lower(replace(replace(replace(coalesce(value, ''), '_', ' '), '-', ' '), '/', ' '))
    when 'characters three fairies of light' then '光の三妖精'
    when 'events hakurei spring festival' then '博麗神社春祭り'
    when 'groups prismriver ensemble' then 'プリズムリバー三姉妹'
    when 'world spell card rules' then 'スペルカードルール'
    when 'backdoor service' then '後戸の奉仕体系'
    when 'lunar nobility' then '月の貴族階層'
    when 'market rest stops' then '市場街道の休憩所'
    when 'minor incidents' then '小規模事件'
    when 'night detours' then '夜道の寄り道'
    when 'text circulation' then '文字と記録の流通'
    when 'beast realm defense' then '畜生界の防衛'
    when 'three fairies of light' then '光の三妖精'
    when 'lunar rank and file' then '月都の下級層'
    when 'hakurei spring festival' then '博麗神社春祭り'
    when 'the hakurei spring festival takes public shape' then '博麗神社春祭り'
    when 'bunbunmaru reporting' then '文々。新聞報道'
    when 'fairy everyday cluster' then '妖精の日常'
    when 'forbidden scrollery' then '鈴奈庵'
    when 'foul detective satori' then '智霊奇伝'
    when 'lotus asia' then '香霖堂'
    when 'lotus eaters' then '酔蝶華'
    when 'lunar expedition cluster' then '月都遠征記'
    when 'mountain watch cluster' then '妖怪の山の見張り'
    when 'public performance cluster' then '公演と演奏'
    when 'sdm threshold cluster' then '紅魔館門前'
    when 'split media cluster' then '報道分化'
    when 'tengu reporting cluster' then '天狗報道'
    when 'wild and horned hermit' then '茨歌仙'
    else null
  end;
$$;

create or replace function public.world_subject_label_ja(
  p_world_id text,
  p_subject_type text,
  p_subject_id text
)
returns text
language plpgsql
stable
as $$
declare
  label text;
begin
  if p_subject_type = 'character' then
    select c.name into label
    from public.world_characters c
    where c.world_id = p_world_id and c.id = p_subject_id
    limit 1;
  elsif p_subject_type = 'location' then
    select l.name into label
    from public.world_locations l
    where l.world_id = p_world_id and l.id = p_subject_id
    limit 1;
  elsif p_subject_type = 'event' then
    select e.title into label
    from public.world_story_events e
    where e.world_id = p_world_id and e.id = p_subject_id
    limit 1;
  elsif p_subject_type = 'book' then
    select b.title into label
    from public.world_chronicle_books b
    where b.id = p_subject_id
    limit 1;
  end if;

  if label is null or btrim(label) = '' then
    select c.name into label
    from public.world_characters c
    where c.world_id = p_world_id and c.id = p_subject_id
    limit 1;
  end if;

  if label is null or btrim(label) = '' then
    select l.name into label
    from public.world_locations l
    where l.world_id = p_world_id and l.id = p_subject_id
    limit 1;
  end if;

  if label is null or btrim(label) = '' then
    select l.title into label
    from public.world_lore_entries l
    where l.world_id = p_world_id and l.id = p_subject_id
    limit 1;
  end if;

  if label is null or btrim(label) = '' then
    label := case p_subject_type
      when 'faction' then case p_subject_id
        when 'eientei' then '永遠亭勢'
        when 'hakurei' then '博麗神社側'
        when 'kappa' then '河童勢'
        when 'moriya' then '守矢神社側'
        when 'sdm' then '紅魔館勢'
        when 'tengu' then '天狗勢'
        else null
      end
      when 'institution' then case p_subject_id
        when 'eientei' then '永遠亭'
        when 'hakurei_shrine' then '博麗神社'
        when 'human_village' then '人里'
        when 'moriya_shrine' then '守矢神社'
        when 'myouren_temple' then '命蓮寺'
        when 'scarlet_devil_mansion' then '紅魔館'
        when 'yakumo_household' then '八雲家'
        else null
      end
      when 'group' then case p_subject_id
        when 'satono_mai_pair' then '爾子田 里乃と丁礼田 舞'
        else null
      end
      when 'incident' then case p_subject_id
        when 'incident_beast_realm' then '畜生界異変'
        when 'incident_divine_spirits' then '神霊異変'
        when 'incident_eternal_night' then '永夜異変'
        when 'incident_faith_shift' then '信仰異変'
        when 'incident_floating_treasures' then '宝船異変'
        when 'incident_flower_anomaly' then '花異変'
        when 'incident_hidden_seasons' then '四季異変'
        when 'incident_little_rebellion' then '小人の反逆'
        when 'incident_living_ghost_conflict' then '生ける亡霊騒動'
        when 'incident_lunar_crisis' then '月都異変'
        when 'incident_market_cards' then '能力カード騒動'
        when 'incident_scarlet_mist' then '紅霧異変'
        when 'incident_spring_snow' then '春雪異変'
        when 'incident_subterranean_sun' then '地底太陽異変'
        when 'incident_weather_anomaly' then '天候異変'
        else null
      end
      when 'printwork' then case p_subject_id
        when 'bunbunmaru_reporting' then '文々。新聞報道'
        when 'fairy_everyday_cluster' then '妖精の日常記録'
        when 'forbidden_scrollery' then '鈴奈庵記録'
        when 'foul_detective_satori' then '智霊奇伝記録'
        when 'lotus_asia' then '香霖堂記録'
        when 'lotus_eaters' then '酔蝶華記録'
        when 'lunar_expedition_cluster' then '月都遠征記録'
        when 'mountain_watch_cluster' then '妖怪の山の見張り記録'
        when 'public_performance_cluster' then '公演と演奏の記録'
        when 'sdm_threshold_cluster' then '紅魔館門前記録'
        when 'split_media_cluster' then '報道分化の記録'
        when 'tengu_reporting_cluster' then '天狗報道記録'
        when 'wild_and_horned_hermit' then '茨歌仙記録'
        else null
      end
      when 'social_function' then case p_subject_id
        when 'festivals' then '祭礼'
        when 'rumor_network' then '噂網'
        when 'teaching' then '教育'
        when 'trade' then '交易'
        else null
      end
      when 'term' then case p_subject_id
        when 'ability_cards' then '能力カード'
        when 'animal_spirits' then '動物霊'
        when 'beast_realm' then '畜生界'
        when 'beast_realm_politics' then '畜生界の政'
        when 'book_circulation' then '書物流通'
        when 'boundary_spots' then '境界の要所'
        when 'buddhism' then '仏教'
        when 'dream_world' then '夢の世界'
        when 'faith_economy' then '信仰経済'
        when 'hidden_seasons' then '秘匿された四季'
        when 'kappa' then '河童'
        when 'lunarians' then '月人'
        when 'market_competition' then '市場競争'
        when 'outside_world_leakage' then '外界流入'
        when 'perfect_possession' then '完全憑依'
        when 'record_culture' then '記録文化'
        when 'shinto' then '神道'
        when 'taoism' then '道教'
        when 'tengu' then '天狗'
        when 'tsukumogami' then '付喪神'
        when 'urban_legends' then '都市伝説'
        else null
      end
      when 'theme' then case p_subject_id
        when 'market_route_rest_stops' then '市場街道の休息所'
        else null
      end
      when 'world' then case p_subject_id
        when 'gensokyo_main' then '幻想郷'
        else null
      end
      else null
    end;
  end if;

  if label is null or btrim(label) = '' then
    label := public.world_known_term_label_ja(p_subject_id);
  end if;

  if label is null or btrim(label) = '' then
    label := public.world_prettify_identifier_ja(p_subject_id);
  end if;
  return label;
end;
$$;

create or replace function public.world_claim_type_label_ja(p_claim_type text)
returns text
language sql
immutable
as $$
  select case coalesce(p_claim_type, '')
    when 'ability' then '能力'
    when 'role' then '役割'
    when 'identity' then '立場'
    when 'title' then '異名'
    when 'location' then '拠点'
    when 'residence' then '居場所'
    when 'speech_style' then '話し方'
    when 'personality' then '性格'
    when 'incident_role' then '異変との関わり'
    when 'institution' then '制度'
    when 'custom' then '風習'
    when 'culture' then '文化'
    when 'relationship' then '関係'
    when 'faction' then '勢力'
    when 'theme' then '主題'
    when 'history' then '来歴'
    when 'nature' then '性質'
    when 'scene' then '場面'
    when 'profile' then '輪郭'
    when 'setting' then '設定'
    when 'summary' then '要約'
    when 'glossary' then '用語'
    when 'definition' then '定義'
    when 'group_role' then '集団内の役目'
    when 'epithet' then '通り名'
    when 'usage_constraint' then '扱いの制約'
    when 'world_rule' then '世界の決まり'
    else public.world_prettify_identifier_ja(p_claim_type)
  end;
$$;

create or replace function public.world_lore_detail_category_label_ja(p_value text)
returns text
language sql
immutable
as $$
  select case coalesce(p_value, '')
    when 'printwork_pattern' then '書籍・報道の型'
    when 'regional_culture' then '地域文化'
    when 'character_role' then '人物の役割'
    when 'location_trait' then '場所の特性'
    when 'world_rule' then '世界の決まり'
    when 'glossary' then '用語'
    when 'institution' then '制度'
    when 'culture' then '文化'
    when 'location' then '土地柄'
    when 'ability' then '能力'
    else '設定'
  end;
$$;

create or replace function public.world_chronicle_entry_type_label_ja(p_value text)
returns text
language sql
immutable
as $$
  select case coalesce(p_value, '')
    when 'regional_note' then '地域記録'
    when 'essay' then '考証'
    when 'social_note' then '社会記録'
    when 'catalog' then '目録'
    when 'incident_record' then '事件記録'
    else '年代記'
  end;
$$;

create or replace function public.world_chat_context_summary_ja(
  p_world_id text,
  p_context_type text,
  p_character_id text,
  p_location_id text,
  p_source_summary text
)
returns text
language plpgsql
stable
as $$
declare
  character_label text := public.world_subject_label_ja(p_world_id, 'character', p_character_id);
  location_label text := public.world_subject_label_ja(p_world_id, 'location', p_location_id);
begin
  if p_context_type = 'character_voice' and coalesce(p_character_id, '') <> '' then
    return character_label || 'が会話するときの口調、温度感、立ち位置をまとめた会話文脈だよ。';
  elsif p_context_type = 'character_location_story' and coalesce(p_character_id, '') <> '' and coalesce(p_location_id, '') <> '' then
    return character_label || 'が' || location_label || 'にいる時の空気感や振る舞いを表す会話文脈だね。';
  elsif p_context_type = 'location_story' and coalesce(p_location_id, '') <> '' then
    return location_label || 'という場に漂う雰囲気や、そこで起こりやすい物語の流れをまとめた会話文脈さ。';
  elsif p_context_type = 'user_participation' then
    return 'ユーザー参加によって生まれた局所的な物語差分をまとめた会話文脈だよ。';
  end if;

  return '幻想郷の会話や物語に必要な背景文脈をまとめた知識ノードだよ。';
end;
$$;

create or replace function public.world_wiki_page_title_ja(
  p_world_id text,
  p_page_type text,
  p_subject_type text,
  p_subject_id text,
  p_slug text,
  p_original_title text
)
returns text
language plpgsql
stable
as $$
declare
  subject_label text := public.world_subject_label_ja(p_world_id, p_subject_type, p_subject_id);
  slug_label text := public.world_known_term_label_ja(coalesce(nullif(p_slug, ''), p_original_title));
begin
  if p_subject_type = 'character' and coalesce(p_subject_id, '') <> '' then
    return subject_label || 'の項目';
  elsif p_subject_type = 'location' and coalesce(p_subject_id, '') <> '' then
    return subject_label || 'の項目';
  elsif slug_label is not null and btrim(slug_label) <> '' then
    return slug_label || 'の項目';
  elsif p_page_type = 'glossary' then
    return '幻想郷用語: ' || coalesce(nullif(subject_label, ''), slug_label, public.world_prettify_identifier_ja(p_slug));
  elsif coalesce(p_original_title, '') <> '' and p_original_title ~ '[^ -~]' then
    return p_original_title;
  end if;
  return public.world_prettify_identifier_ja(coalesce(nullif(p_slug, ''), p_original_title));
end;
$$;

create or replace function public.world_wiki_page_summary_ja(
  p_world_id text,
  p_page_type text,
  p_subject_type text,
  p_subject_id text
)
returns text
language plpgsql
stable
as $$
declare
  subject_label text := public.world_subject_label_ja(p_world_id, p_subject_type, p_subject_id);
begin
  if p_subject_type = 'character' and coalesce(p_subject_id, '') <> '' then
    return subject_label || 'に関する幻想郷事典項目だよ。';
  elsif p_subject_type = 'location' and coalesce(p_subject_id, '') <> '' then
    return subject_label || 'に関する幻想郷事典項目だよ。';
  elsif p_page_type = 'glossary' then
    return '幻想郷の制度、用語、文化を引くための事典項目だね。';
  end if;
  return '幻想郷の設定や出来事を再編集した事典項目だよ。';
end;
$$;

create or replace function public.world_chronicle_entry_title_ja(
  p_book_id text,
  p_subject_type text,
  p_subject_id text,
  p_original_title text
)
returns text
language plpgsql
stable
as $$
declare
  world_key text := 'gensokyo_main';
  subject_label text := public.world_subject_label_ja(world_key, p_subject_type, p_subject_id);
  term_label text := public.world_known_term_label_ja(p_original_title);
begin
  if p_subject_type = 'character' and coalesce(p_subject_id, '') <> '' then
    return subject_label || 'の記録';
  elsif p_subject_type = 'location' and coalesce(p_subject_id, '') <> '' then
    return subject_label || 'の記録';
  elsif term_label is not null and btrim(term_label) <> '' then
    return term_label || 'の記録';
  elsif coalesce(p_original_title, '') <> '' and p_original_title ~ '[^ -~]' then
    return p_original_title;
  end if;
  return '幻想郷年代記';
end;
$$;

create or replace function public.world_chronicle_entry_summary_ja(
  p_subject_type text,
  p_subject_id text
)
returns text
language plpgsql
stable
as $$
declare
  subject_label text := public.world_subject_label_ja('gensokyo_main', p_subject_type, p_subject_id);
begin
  if coalesce(p_subject_id, '') <> '' then
    return subject_label || 'に関する年代記の記録だよ。';
  end if;
  return '幻想郷の出来事や空気の流れを記録した年代記だよ。';
end;
$$;

create or replace function public.world_lore_entry_title_ja(
  p_category text,
  p_id text,
  p_original_title text
)
returns text
language plpgsql
stable
as $$
declare
  extracted_id text;
  label text;
begin
  if coalesce(p_original_title, '') <> '' and p_original_title ~ '[^ -~]' then
    return p_original_title;
  end if;

  label := public.world_known_term_label_ja(replace(replace(coalesce(p_original_title, ''), '_', ' '), '-', ' '));
  if label is null or btrim(label) = '' then
    label := public.world_known_term_label_ja(replace(replace(coalesce(p_id, ''), '_', ' '), '-', ' '));
  end if;

  if p_id like 'lore_ability_%' then
    extracted_id := substring(p_id from '^lore_ability_(.+)$');
    label := public.world_subject_label_ja('gensokyo_main', 'character', extracted_id);
    return coalesce(nullif(label, ''), '人物') || 'の能力';
  elsif p_id like 'lore_role_%' then
    extracted_id := substring(p_id from '^lore_role_(.+)$');
    label := public.world_subject_label_ja('gensokyo_main', 'character', extracted_id);
    return coalesce(nullif(label, ''), '人物') || 'の役回り';
  elsif p_id like 'lore_voice_%' then
    extracted_id := substring(p_id from '^lore_voice_(.+)$');
    label := public.world_subject_label_ja('gensokyo_main', 'character', extracted_id);
    return coalesce(nullif(label, ''), '人物') || 'の話し方';
  elsif p_id like 'lore_location_%' then
    extracted_id := substring(p_id from '^lore_location_(.+)$');
    label := public.world_subject_label_ja('gensokyo_main', 'location', extracted_id);
    return coalesce(nullif(label, ''), '場所') || 'の土地柄';
  elsif label is not null and btrim(label) <> '' then
    if p_category = 'glossary' then
      return '幻想郷用語: ' || label;
    elsif p_category = 'institution' then
      return '幻想郷制度: ' || label;
    elsif p_category = 'culture' then
      return '幻想郷文化: ' || label;
    end if;
    return '世界設定: ' || label;
  elsif p_category = 'glossary' then
    return '幻想郷用語';
  elsif p_category = 'institution' then
    return '幻想郷制度';
  elsif p_category = 'culture' then
    return '幻想郷文化';
  end if;
  return '世界設定資料';
end;
$$;

create or replace function public.world_lore_entry_summary_ja(
  p_category text
)
returns text
language sql
immutable
as $$
  select case coalesce(p_category, '')
    when 'glossary' then '幻想郷の用語や概念をまとめた設定項目だよ。'
    when 'institution' then '幻想郷の制度や枠組みをまとめた設定項目だよ。'
    when 'culture' then '幻想郷の文化や風習をまとめた設定項目だよ。'
    when 'location' then '幻想郷の土地柄や地域文脈をまとめた設定項目だよ。'
    else '幻想郷の世界設定を整理した設定項目だね。'
  end;
$$;

update public.world_wiki_pages p
set
  metadata = '{}'::jsonb,
  title = public.world_wiki_page_title_ja(
    p.world_id,
    p.page_type,
    p.subject_type,
    p.subject_id,
    p.slug,
    coalesce(p.metadata->>'title_en_original', p.title)
  ),
  summary = public.world_wiki_page_summary_ja(p.world_id, p.page_type, p.subject_type, p.subject_id),
  updated_at = now()
where p.world_id = 'gensokyo_main';

update public.world_wiki_page_sections s
set
  metadata = '{}'::jsonb,
  heading = case
    when s.section_order = 1 then '概要'
    when s.section_order = 2 then '要点'
    else '補足'
  end,
  summary = case
    when p.subject_type = 'character' then public.world_subject_label_ja(p.world_id, p.subject_type, p.subject_id) || 'に関する説明節だよ。'
    when p.subject_type = 'location' then public.world_subject_label_ja(p.world_id, p.subject_type, p.subject_id) || 'に関する説明節だよ。'
    else '幻想郷Wikiの補足節だよ。'
  end,
  body = case
    when p.subject_type = 'character' then public.world_subject_label_ja(p.world_id, p.subject_type, p.subject_id) || 'についての要点をまとめた節だよ。'
    when p.subject_type = 'location' then public.world_subject_label_ja(p.world_id, p.subject_type, p.subject_id) || 'についての要点をまとめた節だよ。'
    else '幻想郷の設定を読みやすく整理した節だよ。'
  end,
  updated_at = now()
from public.world_wiki_pages p
where s.page_id = p.id
  and p.world_id = 'gensokyo_main';

update public.world_chat_context_cache c
set
  payload = jsonb_strip_nulls(
    jsonb_build_object(
      '文脈種別',
      case c.context_type
        when 'character_voice' then 'キャラクターの口調'
        when 'character_location_story' then 'キャラクターと場所の物語'
        when 'location_story' then '場所の物語'
        when 'user_participation' then 'ユーザー参加'
        else '会話文脈'
      end,
      '対象キャラクター',
      case when c.character_id is not null then public.world_subject_label_ja(c.world_id, 'character', c.character_id) else null end,
      '対象地点',
      case when c.location_id is not null then public.world_subject_label_ja(c.world_id, 'location', c.location_id) else null end,
      '説明',
      public.world_chat_context_summary_ja(c.world_id, c.context_type, c.character_id, c.location_id, c.summary)
    )
  ),
  summary = public.world_chat_context_summary_ja(c.world_id, c.context_type, c.character_id, c.location_id, c.summary),
  updated_at = now()
where c.world_id = 'gensokyo_main';

update public.world_canon_claims c
set
  details = jsonb_build_object(
    '対象',
    public.world_subject_label_ja(c.world_id, c.subject_type, c.subject_id),
    '分類',
    public.world_claim_type_label_ja(c.claim_type),
    '説明',
    public.world_subject_label_ja(c.world_id, c.subject_type, c.subject_id)
      || 'に関する正史設定だよ。'
  ),
  summary = public.world_subject_label_ja(c.world_id, c.subject_type, c.subject_id)
    || 'に関する正史設定。分類: '
    || public.world_claim_type_label_ja(c.claim_type)
    || '。',
  updated_at = now()
where c.world_id = 'gensokyo_main';

update public.world_lore_entries l
set
  details = jsonb_build_object(
    '分類', public.world_lore_detail_category_label_ja(coalesce(l.details->>'分類', l.category)),
    '説明', public.world_lore_entry_summary_ja(l.category)
  ),
  title = public.world_lore_entry_title_ja(l.category, l.id, coalesce(l.details->>'title_en_original', l.title)),
  summary = public.world_lore_entry_summary_ja(l.category),
  updated_at = now()
where l.world_id = 'gensokyo_main';

update public.world_chronicle_entries e
set
  metadata = jsonb_build_object(
    '記録種別', public.world_chronicle_entry_type_label_ja(e.entry_type),
    '説明', coalesce(
      nullif(
        case
          when public.world_known_term_label_ja(coalesce(e.metadata->>'title_en_original', e.title)) is not null
            then public.world_known_term_label_ja(coalesce(e.metadata->>'title_en_original', e.title)) || 'に関する年代記の記録だよ。'
          else null
        end,
        ''
      ),
      public.world_chronicle_entry_summary_ja(e.subject_type, e.subject_id)
    )
  ),
  title = public.world_chronicle_entry_title_ja(
    e.book_id,
    e.subject_type,
    e.subject_id,
    coalesce(e.metadata->>'title_en_original', e.title)
  ),
  summary = coalesce(
    nullif(
      case
        when public.world_known_term_label_ja(coalesce(e.metadata->>'title_en_original', e.title)) is not null
          then public.world_known_term_label_ja(coalesce(e.metadata->>'title_en_original', e.title)) || 'に関する年代記の記録だよ。'
        else null
      end,
      ''
    ),
    public.world_chronicle_entry_summary_ja(e.subject_type, e.subject_id)
  ),
  body = coalesce(
      nullif(
        case
          when public.world_known_term_label_ja(coalesce(e.metadata->>'title_en_original', e.title)) is not null
            then public.world_known_term_label_ja(coalesce(e.metadata->>'title_en_original', e.title)) || 'に関する年代記の記録だよ。'
          else null
        end,
        ''
      ),
      public.world_chronicle_entry_summary_ja(e.subject_type, e.subject_id)
    )
    || ' ここでは出来事の流れや立場の違いを読み取るための日本語化表示を優先しているよ。',
  updated_at = now()
where exists (
  select 1
  from public.world_chronicle_books b
  where b.id = e.book_id and b.world_id = 'gensokyo_main'
);

update public.world_story_events e
set
  title = case e.event_code
    when 'hakurei_spring_festival' then '博麗神社春祭り'
    when 'spring_festival_001' then '博麗神社春祭り'
    when 'incident_scarlet_mist_archive' then '紅霧異変記録'
    when 'incident_faith_shift_archive' then '信仰勢力変動記録'
    when 'incident_perfect_possession_archive' then '完全憑依騒動記録'
    when 'incident_market_cards_archive' then '能力カード騒動記録'
    when 'minor_fairy_pranks_archive' then '妖精いたずら記録'
    when 'minor_night_detours_archive' then '夜道寄り道記録'
    when 'minor_text_circulation_archive' then '書物と記事の流通記録'
    else e.title
  end,
  theme = case e.event_code
    when 'hakurei_spring_festival' then '春の賑わいと小さな不和'
    when 'spring_festival_001' then '春の賑わいと小さな不和'
    when 'incident_scarlet_mist_archive' then '紅霧異変の発生とその余波'
    when 'incident_faith_shift_archive' then '山の信仰と勢力均衡の変化'
    when 'incident_perfect_possession_archive' then '完全憑依がもたらした分身と混線'
    when 'incident_market_cards_archive' then '能力カード市場の膨張と流通の歪み'
    when 'minor_fairy_pranks_archive' then '妖精たちの小さないたずらと日常のゆらぎ'
    when 'minor_night_detours_archive' then '夜道、寄り道、歌声、そして小さな面倒'
    when 'minor_text_circulation_archive' then '書物と記事が広げる認識の波'
    else e.theme
  end,
  synopsis = case e.event_code
    when 'hakurei_spring_festival' then '博麗神社を中心に、幻想郷の住人たちが春祭りの準備と本番に関わっていく期間限定の物語だよ。'
    when 'spring_festival_001' then '博麗神社を中心に、幻想郷の住人たちが春祭りの準備と本番に関わっていく期間限定の物語だよ。'
    when 'incident_scarlet_mist_archive' then '紅霧異変に関する経過、関係者、余波を追うための正史記録だよ。'
    when 'incident_faith_shift_archive' then '山の信仰勢力がどう動き、誰に影響したかを辿るための正史記録だよ。'
    when 'incident_perfect_possession_archive' then '完全憑依騒動によって生じた関係の混線や後遺症を整理するための正史記録だよ。'
    when 'incident_market_cards_archive' then '能力カード騒動と市場の余波を整理するための正史記録だよ。'
    when 'minor_fairy_pranks_archive' then '神社や里の周辺で起きる妖精の小さないたずらを蓄積するための記録だよ。'
    when 'minor_night_detours_archive' then '夜道の寄り道、歌声、屋台、軽い騒ぎを蓄積するための記録だよ。'
    when 'minor_text_circulation_archive' then '書物や記事の流通から生まれる小さな出来事を追うための記録だよ。'
    else e.synopsis
  end,
  payload = jsonb_build_object(
    '概要',
    case e.event_code
      when 'hakurei_spring_festival' then '博麗神社を中心に、幻想郷の住人たちが春祭りの準備と本番に関わっていく期間限定の物語だよ。'
      when 'spring_festival_001' then '博麗神社を中心に、幻想郷の住人たちが春祭りの準備と本番に関わっていく期間限定の物語だよ。'
      when 'incident_scarlet_mist_archive' then '紅霧異変に関する経過、関係者、余波を追うための正史記録だよ。'
      when 'incident_faith_shift_archive' then '山の信仰勢力がどう動き、誰に影響したかを辿るための正史記録だよ。'
      when 'incident_perfect_possession_archive' then '完全憑依騒動によって生じた関係の混線や後遺症を整理するための正史記録だよ。'
      when 'incident_market_cards_archive' then '能力カード騒動と市場の余波を整理するための正史記録だよ。'
      when 'minor_fairy_pranks_archive' then '神社や里の周辺で起きる妖精の小さないたずらを蓄積するための記録だよ。'
      when 'minor_night_detours_archive' then '夜道の寄り道、歌声、屋台、軽い騒ぎを蓄積するための記録だよ。'
      when 'minor_text_circulation_archive' then '書物や記事の流通から生まれる小さな出来事を追うための記録だよ。'
      else e.synopsis
    end
  ),
  metadata = jsonb_build_object(
    '状態',
    case coalesce(e.status, '')
      when 'active' then '進行中'
      when 'resolved' then '解決済み'
      when 'draft' then '草稿'
      else '記録'
    end
  ),
  updated_at = now()
where e.world_id = 'gensokyo_main';

update public.world_story_history h
set
  fact_summary = coalesce(
    case
      when h.event_id is not null then public.world_subject_label_ja(h.world_id, 'event', h.event_id) || 'に関する履歴記録だよ。'
      when h.location_id is not null then public.world_subject_label_ja(h.world_id, 'location', h.location_id) || 'で起きた履歴記録だよ。'
      else '幻想郷で起きた出来事の履歴記録だよ。'
    end,
    '幻想郷で起きた出来事の履歴記録だよ。'
  ),
  payload = jsonb_build_object(
    '説明',
    coalesce(
      case
        when h.event_id is not null then public.world_subject_label_ja(h.world_id, 'event', h.event_id) || 'に関する履歴記録だよ。'
        when h.location_id is not null then public.world_subject_label_ja(h.world_id, 'location', h.location_id) || 'で起きた履歴記録だよ。'
        else '幻想郷で起きた出来事の履歴記録だよ。'
      end,
      '幻想郷で起きた出来事の履歴記録だよ。'
    )
  )
where h.world_id = 'gensokyo_main';

update public.world_story_history h
set payload = jsonb_build_object('説明', h.fact_summary)
where h.world_id = 'gensokyo_main';

delete from public.world_embeddings
where document_id in (
  select d.id
  from public.world_embedding_documents d
  where d.world_id = 'gensokyo_main'
);

delete from public.world_embedding_jobs
where world_id = 'gensokyo_main';

select public.world_refresh_embedding_documents('gensokyo_main');
select public.world_queue_embedding_refresh('gensokyo_main');
