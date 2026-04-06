from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def sql_quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def sql_unquote(expr: str) -> str | None:
    expr = expr.strip()
    if len(expr) >= 2 and expr[0] == "'" and expr[-1] == "'":
        return expr[1:-1].replace("''", "'")
    return None


def parse_updates(sql: str, table: str, id_field: str, fields: list[str]) -> dict[str, dict[str, str]]:
    out: dict[str, dict[str, str]] = {}
    pattern = re.compile(
        rf"update public\.{table} set (.+?) where world_id = 'gensokyo_main' and {id_field} = '([^']+)';",
        re.IGNORECASE,
    )
    for match in pattern.finditer(sql):
        assigns = match.group(1)
        row_id = match.group(2)
        item: dict[str, str] = {}
        for field in fields:
            m = re.search(rf"{field}\s*=\s*'((?:[^']|'')*)'", assigns)
            if m:
                item[field] = m.group(1).replace("''", "'")
        out[row_id] = item
    return out


def parse_known_terms(sql: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for src, dst in re.findall(r"when '([^']+)' then '([^']+)'", sql):
        out[src] = dst
    return out


def prettify_identifier(value: str | None) -> str:
    if not value:
        return "対象"
    value = value.replace("_", " ").replace("-", " ").replace(":", " ")
    value = re.sub(r"\s+", " ", value).strip()
    if not value:
        return "対象"
    return value


def has_japanese(value: str) -> bool:
    return bool(re.search(r"[ぁ-んァ-ン一-龯]", value))


RELATION_LABELS = {
    "familiar_rival": "気心の知れた好敵手関係",
    "competing_peer": "競い合う同格関係",
    "mutual_observer": "互いを観察し合う関係",
    "retainer": "従者関係",
    "trusted_servant": "信頼された奉仕関係",
    "resident_ally": "同居する協力関係",
    "complicated_peer": "複雑な同格関係",
    "fond_superior": "親愛を含む主従関係",
    "shikigami_loyalty": "式としての忠誠関係",
    "family_loyalty": "家族的な忠誠関係",
    "protective_ally": "保護を伴う協力関係",
    "protective_companion": "保護を伴う同伴関係",
    "disciplined_superior": "規律を与える上下関係",
    "shared_shrine_authority": "神社運営を共有する関係",
    "devotional_service": "信仰と奉仕に基づく関係",
    "public_observer": "公的に注視する関係",
    "annoyed_familiarity": "煩わしさを含む顔なじみ関係",
    "institutional_peer": "制度上の並立関係",
}

CLAIM_TYPE_LABELS = {
    "ability": "能力",
    "role": "役割",
    "identity": "立場",
    "title": "異名",
    "location": "拠点",
    "residence": "居場所",
    "speech_style": "話し方",
    "personality": "性格",
    "incident_role": "異変との関わり",
    "institution": "制度",
    "custom": "風習",
    "culture": "文化",
    "relationship": "関係",
    "faction": "勢力",
    "theme": "主題",
    "history": "来歴",
    "nature": "性質",
    "scene": "場面",
    "profile": "輪郭",
    "setting": "設定",
    "summary": "要約",
    "glossary": "用語",
    "definition": "定義",
    "world_rule": "世界ルール",
    "usage_constraint": "使用上の制約",
}

SPECIES_LABELS = {
    "human": "人間",
    "youkai": "妖怪",
    "tengu": "天狗",
    "kappa": "河童",
    "goddess": "神格",
    "magician": "魔法使い",
    "satori": "さとり妖怪",
    "bakeneko": "化け猫",
    "kitsune": "狐",
    "were-hakutaku": "半獣",
    "lunarian": "月人",
    "moon rabbit": "月の兎",
    "hell raven": "地獄鴉",
    "half-human half-phantom": "半人半霊",
    "wolf tengu": "白狼天狗",
    "earth rabbit": "地上の兎",
    "mouse youkai": "鼠妖怪",
    "divine spirit": "神霊",
    "animal spirit": "動物霊",
    "centipede youkai": "百足妖怪",
    "jiang-shi": "キョンシー",
}

LORE_CATEGORY_SUMMARIES = {
    "glossary": "幻想郷の用語や概念をまとめた設定項目です。",
    "institution": "幻想郷の制度や枠組みをまとめた設定項目です。",
    "culture": "幻想郷の文化や風習をまとめた設定項目です。",
    "location": "幻想郷の土地柄や地域文脈をまとめた設定項目です。",
    "world_rule": "幻想郷全体に関わる基本ルールを整理した設定項目です。",
    "location_trait": "土地ごとの性質や役割を整理した設定項目です。",
    "character_role": "人物の立ち位置や役割を整理した設定項目です。",
    "faction_trait": "勢力や集団の性質を整理した設定項目です。",
    "printwork_pattern": "書籍や媒体に見られる傾向を整理した設定項目です。",
}

PHASE_TITLES = {
    "rumor": "噂の拡散段階",
    "preparation": "準備段階",
    "festival": "祭り当日段階",
    "aftermath": "事後整理段階",
}

BEAT_TITLES = {
    "rumor_spreads": "里に噂が広がります",
    "decorations_arrive": "飾り付け資材が届きます",
    "roles_not_aligned": "役割分担にずれが見えます",
}

ACTION_TITLES = {
    "talk_reimu": "霊夢に準備状況を聞きます",
    "hear_rumors": "里の噂を集めます",
    "help_preparation": "準備作業を手伝います",
}

ACTION_DESCRIPTIONS = {
    "talk_reimu": "博麗神社で霊夢に祭り準備の状況を聞き取る行動です。",
    "hear_rumors": "人里で祭りに関する噂や受け止め方を集める行動です。",
    "help_preparation": "祭りの準備作業に参加して関与の実感を得る行動です。",
}

ACTION_RESULTS = {
    "talk_reimu": "祭り準備に対する霊夢の現実的な見方を把握できます。",
    "hear_rumors": "祭りが始まる前から世間の空気が形作られていることを確認できます。",
    "help_preparation": "準備段階への参加記録を残せます。",
}

SOURCE_TITLE_MAP = {
    "eosd": "東方紅魔郷",
    "pcb": "東方妖々夢",
    "in": "東方永夜抄",
    "mofa": "東方風神録",
    "sa": "東方地霊殿",
    "pmiss": "東方求聞史紀",
    "sopm": "求聞口授",
    "ufo": "東方星蓮船",
    "td": "東方神霊廟",
    "osp": "東方三月精",
    "vfi": "ビジョナリー・フェアリーズ・イン・シュライン",
    "ds": "ダブルスポイラー",
    "alt_truth": "東方鈴奈庵外伝資料群",
    "boaFW": "東方文花帖",
}


class BundleTranslator:
    def __init__(self) -> None:
        localize_sql = (ROOT / "_tmp_WORLD_LOCALIZE_JA.sql").read_text(encoding="utf-8")
        masters_sql = (ROOT / "_tmp_WORLD_LOCALIZE_JA_MASTERS.sql").read_text(encoding="utf-8")
        self.char_map = parse_updates(masters_sql, "world_characters", "id", ["name", "title"])
        self.loc_map = parse_updates(masters_sql, "world_locations", "id", ["name"])
        self.known_terms = parse_known_terms(localize_sql)
        self.event_titles: dict[str, str] = {"story_spring_festival_001": "博麗神社春祭り"}
        self.book_titles: dict[str, str] = {}

    def label(self, subject_type: str | None, subject_id: str | None) -> str:
        sid = subject_id or ""
        stype = subject_type or ""
        if stype == "character":
            if sid in self.char_map:
                return self.char_map[sid].get("name", sid)
        if stype == "location":
            if sid in self.loc_map:
                return self.loc_map[sid].get("name", sid)
        if stype == "event":
            return self.event_titles.get(sid, "出来事")
        if stype == "book":
            return self.book_titles.get(sid, "年代記")
        if stype == "world" and sid == "gensokyo_main":
            return "幻想郷"
        if sid in self.known_terms:
            return self.known_terms[sid]
        key = sid.replace("_", " ")
        if key in self.known_terms:
            return self.known_terms[key]
        return "対象項目"

    def generic_profile_json(self, name: str, title: str) -> str:
        return (
            "jsonb_build_object("
            f"'表示名', {sql_quote(name)}, "
            f"'肩書き', {sql_quote(title)}, "
            "'説明', '人物の基礎プロフィールを日本語で整理した内部データです。'"
            ")"
        )

    def generic_details_json(self, label: str, category: str) -> str:
        return (
            "jsonb_build_object("
            f"'対象', {sql_quote(label)}, "
            f"'分類', {sql_quote(category)}, "
            "'説明', '日本語表示向けに整理した説明データです。'"
            ")"
        )

    def translate_rows(self, table: str, columns: list[str], rows: list[list[str]]) -> list[list[str]]:
        translated: list[list[str]] = []
        idx = {col: i for i, col in enumerate(columns)}
        for row in rows:
            row = row[:]
            def get(col: str) -> str:
                return row[idx[col]]
            def get_s(col: str) -> str:
                return sql_unquote(get(col)) or ""
            def set_s(col: str, value: str) -> None:
                row[idx[col]] = sql_quote(value)
            def set_e(col: str, value: str) -> None:
                row[idx[col]] = value

            if table == "worlds":
                set_s("name", "幻想郷")
            elif table == "world_characters":
                cid = get_s("id")
                name = self.char_map.get(cid, {}).get("name", get_s("name") or prettify_identifier(cid))
                title = self.char_map.get(cid, {}).get("title", "幻想郷の人物")
                set_s("name", name)
                set_s("title", title)
                if "species" in idx:
                    set_s("species", SPECIES_LABELS.get(get_s("species"), "種族"))
                set_s("public_summary", f"{name}に関する基本人物紹介です。")
                set_s("private_notes", f"{name}を配置するときの補足メモです。")
                set_s("speech_style", "人物ごとの口調設定です。")
                set_s("worldview", f"{name}の価値観や見方を整理した文面です。")
                set_s("role_in_gensokyo", f"{name}の役割です。")
                if "profile" in idx:
                    set_e("profile", self.generic_profile_json(name, title))
            elif table == "world_relationship_edges":
                src = self.label("character", get_s("source_character_id"))
                dst = self.label("character", get_s("target_character_id"))
                relation = RELATION_LABELS.get(get_s("relation_type"), "関係")
                set_s("summary", f"{src}と{dst}のあいだにある{relation}を示す関係データです。")
            elif table == "world_lore_entries":
                lid = get_s("id")
                category = get_s("category")
                label = self.known_terms.get(lid.replace("lore_", "").replace("_", " "), self.known_terms.get(lid, prettify_identifier(lid)))
                title = label if has_japanese(label) else "幻想郷設定項目"
                set_s("title", title)
                set_s("summary", LORE_CATEGORY_SUMMARIES.get(category, "幻想郷の世界設定を整理した設定項目です。"))
                set_e("details", self.generic_details_json(self.label("world", "gensokyo_main"), category or "設定"))
            elif table == "world_story_events":
                event_code = get_s("event_code")
                title = {
                    "hakurei_spring_festival": "博麗神社春祭り",
                    "spring_festival_001": "博麗神社春祭り",
                    "incident_scarlet_mist_archive": "紅霧異変記録",
                    "incident_faith_shift_archive": "信仰勢力変動記録",
                    "incident_perfect_possession_archive": "完全憑依騒動記録",
                    "incident_market_cards_archive": "能力カード騒動記録",
                    "minor_fairy_pranks_archive": "妖精いたずら記録",
                    "minor_night_detours_archive": "夜道寄り道記録",
                    "minor_text_circulation_archive": "書物と記事の流通記録",
                }.get(event_code, "幻想郷の出来事")
                self.event_titles[get_s("id")] = title
                set_s("title", title)
                set_s("theme", f"{title}に関する主題をまとめた文面です。")
                set_s("synopsis", f"{title}の概要を日本語で整理した物語説明です。")
                set_s("narrative_hook", f"{title}に参加するときの導入文です。")
                set_e("payload", "jsonb_build_object('概要', " + sql_quote(f"{title}の概要を日本語で整理した物語説明です。") + ")")
                set_e("metadata", "jsonb_build_object('状態', '日本語化済み')")
            elif table == "world_story_phases":
                phase_code = get_s("phase_code")
                title = PHASE_TITLES.get(phase_code, f"{prettify_identifier(phase_code)}段階")
                set_s("title", title)
                set_s("summary", f"{title}における進行状況をまとめた説明です。")
            elif table == "world_story_beats":
                beat_code = get_s("beat_code")
                title = BEAT_TITLES.get(beat_code, f"{prettify_identifier(beat_code)}の場面")
                set_s("title", title)
                set_s("summary", f"{title}で起きる要点をまとめた記録です。")
            elif table == "world_story_cast":
                name = self.label("character", get_s("character_id"))
                set_s("notes", f"{name}がこの出来事で担う役割を示す補足です。")
            elif table == "world_story_actions":
                action_code = get_s("action_code")
                set_s("title", ACTION_TITLES.get(action_code, f"{prettify_identifier(action_code)}を行います"))
                set_s("description", ACTION_DESCRIPTIONS.get(action_code, "出来事に関わる行動を日本語で整理した説明です。"))
                set_s("result_summary", ACTION_RESULTS.get(action_code, "この行動によって得られる結果をまとめた説明です。"))
            elif table == "world_story_history":
                if get_s("event_id"):
                    label = self.event_titles.get(get_s("event_id"), "出来事")
                    summary = f"{label}に関する履歴記録です。"
                elif get_s("location_id"):
                    summary = f"{self.label('location', get_s('location_id'))}で起きた履歴記録です。"
                else:
                    summary = "幻想郷で起きた出来事の履歴記録です。"
                set_s("fact_summary", summary)
                set_e("payload", "jsonb_build_object('説明', " + sql_quote(summary) + ")")
            elif table == "world_character_memories":
                name = self.label("character", get_s("character_id"))
                set_s("summary", f"{name}が出来事をどう受け止めたかをまとめた記憶データです。")
            elif table == "world_locations":
                lid = get_s("id")
                name = self.loc_map.get(lid, {}).get("name", get_s("name") or prettify_identifier(lid))
                set_s("name", name)
                set_s("title", f"{name}の地域情報")
                set_s("summary", f"{name}に関する基本地点情報です。")
                set_s("description", f"{name}の特徴や周辺とのつながりを日本語で整理した説明です。")
                set_s("default_mood", "落ち着いた雰囲気")
            elif table == "world_source_index":
                code = get_s("source_code")
                title = SOURCE_TITLE_MAP.get(code, f"公式資料 {code}")
                set_s("title", title)
                set_s("short_label", title)
                set_s("notes", f"{title}に関する参照用ソース情報です。")
            elif table == "world_canon_claims":
                subject_type = get_s("subject_type")
                subject_id = get_s("subject_id")
                label = self.label(subject_type, subject_id)
                ctype = CLAIM_TYPE_LABELS.get(get_s("claim_type"), "設定")
                set_s("summary", f"{label}に関する正史設定です。分類は{ctype}です。")
                set_e("details", self.generic_details_json(label, ctype))
            elif table == "world_chronicle_books":
                bid = get_s("id")
                title = {
                    "chronicle_gensokyo_history": "幻想郷年代記",
                    "chronicle_seasonal_incidents": "季節行事記録集",
                }.get(bid, "幻想郷資料集")
                self.book_titles[bid] = title
                set_s("title", title)
                if "era_label" in idx:
                    set_s("era_label", "現代" if bid == "chronicle_gensokyo_history" else "近年")
                if "summary" in idx:
                    set_s("summary", f"{title}の概要です。")
                if "description" in idx:
                    set_s("description", f"{title}に収める記録の方針を日本語で整理した説明です。")
                if "tone" in idx:
                    set_s("tone", "記録調")
            elif table == "world_chronicle_chapters":
                title = "年代記の章"
                set_s("title", title)
                if "summary" in idx:
                    set_s("summary", f"{title}の内容を整理した章説明です。")
            elif table == "world_chronicle_entries":
                subject_label = self.label(get_s("subject_type"), get_s("subject_id"))
                title = f"{subject_label}に関する年代記"
                set_s("title", title)
                set_s("summary", f"{subject_label}に関する年代記の記録です。")
                set_s("body", f"{subject_label}に関する経緯や位置づけを日本語で整理した本文です。")
            elif table == "world_chronicle_entry_sources":
                set_s("source_label", "参照資料")
                set_s("notes", "年代記の根拠として参照した資料です。")
            elif table == "world_derivative_overlays":
                set_s("title", "拡張差分スロット")
                if "summary" in idx:
                    set_s("summary", "将来の差分追加に備えた予備スロットです。")
            elif table == "world_historian_notes":
                label = self.label(get_s("subject_type"), get_s("subject_id"))
                set_s("title", f"{label}に関する注記")
                set_s("summary", f"{label}を歴史記録として扱うための補足注記です。")
                set_s("body", f"{label}に関する記録上の見方や整理方針をまとめた歴史家注記です。")
            elif table == "world_wiki_pages":
                label = self.label(get_s("subject_type"), get_s("subject_id"))
                set_s("title", label if has_japanese(label) else "幻想郷事典項目")
                set_s("summary", f"{label}に関する幻想郷事典項目です。")
                set_e("metadata", "'{}'::jsonb")
            elif table == "world_wiki_page_sections":
                section_order = get_s("section_order")
                set_s("heading", "概要" if section_order == "1" else "補足")
                set_s("summary", "幻想郷事典項目の説明節です。")
                set_s("body", "項目の要点を日本語で整理した節です。")
                set_e("metadata", "'{}'::jsonb")
            elif table == "world_chat_context_cache":
                char_id = get_s("character_id")
                loc_id = get_s("location_id")
                if char_id:
                    label = self.label("character", char_id)
                    summary = f"{label}の会話や振る舞いに関する文脈データです。"
                elif loc_id:
                    label = self.label("location", loc_id)
                    summary = f"{label}に関する場面文脈データです。"
                else:
                    summary = "幻想郷の会話文脈を整理したデータです。"
                set_s("summary", summary)
                set_e("payload", "jsonb_build_object('説明', " + sql_quote(summary) + ")")
            translated.append(row)
        return translated


def split_rows(values_text: str) -> list[str]:
    rows: list[str] = []
    i = 0
    n = len(values_text)
    while i < n:
        while i < n and values_text[i] in " \t\r\n,":
            i += 1
        if i >= n:
            break
        if values_text[i] != "(":
            raise ValueError(f"expected row start at {i}")
        start = i
        depth = 0
        in_str = False
        while i < n:
            ch = values_text[i]
            if in_str:
                if ch == "'":
                    if i + 1 < n and values_text[i + 1] == "'":
                        i += 2
                        continue
                    in_str = False
                i += 1
                continue
            if ch == "'":
                in_str = True
            elif ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    i += 1
                    rows.append(values_text[start:i])
                    break
            i += 1
    return rows


def split_csv(text: str) -> list[str]:
    parts: list[str] = []
    start = 0
    depth = 0
    in_str = False
    i = 0
    while i < len(text):
        ch = text[i]
        if in_str:
            if ch == "'":
                if i + 1 < len(text) and text[i + 1] == "'":
                    i += 2
                    continue
                in_str = False
            i += 1
            continue
        if ch == "'":
            in_str = True
        elif ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif ch == "," and depth == 0:
            parts.append(text[start:i].strip())
            start = i + 1
        i += 1
    parts.append(text[start:].strip())
    return parts


def parse_insert_block(block: str) -> tuple[str, list[str], list[list[str]], str]:
    m = re.match(r"insert into public\.([a-zA-Z0-9_]+)\s*\((.*?)\)\s*values\s*(.*)", block, re.S | re.I)
    if not m:
        raise ValueError("failed to parse insert block")
    table = m.group(1)
    columns = [c.strip() for c in m.group(2).replace("\n", " ").split(",")]
    rest = m.group(3)
    marker = re.search(r"\n(on conflict .*?;)", rest, re.S | re.I)
    suffix = ";"
    values_text = rest
    if marker:
        values_text = rest[: marker.start()]
        suffix = marker.group(1)
    else:
        values_text = rest.rsplit(";", 1)[0]
    rows_raw = split_rows(values_text)
    rows = [split_csv(r[1:-1]) for r in rows_raw]
    return table, columns, rows, suffix


def format_insert(table: str, columns: list[str], rows: list[list[str]], suffix: str) -> str:
    out: list[str] = []
    out.append(f"insert into public.{table} (")
    out.append("  " + ", ".join(columns))
    out.append(")")
    if len(rows) == 1:
        out.append("values (")
        for i, value in enumerate(rows[0]):
            tail = "," if i < len(rows[0]) - 1 else ""
            out.append(f"  {value}{tail}")
        out.append(")")
    else:
        out.append("values")
        for r_i, row in enumerate(rows):
            out.append("  (")
            for i, value in enumerate(row):
                tail = "," if i < len(row) - 1 else ""
                out.append(f"    {value}{tail}")
            tail_row = "," if r_i < len(rows) - 1 else ""
            out.append(f"  ){tail_row}")
    out.append(suffix)
    return "\n".join(out)


def strip_comments(sql: str) -> str:
    lines = []
    for line in sql.splitlines():
        if line.lstrip().startswith("--"):
            continue
        lines.append(line)
    return "\n".join(lines) + "\n"


def split_statements(sql: str) -> list[str]:
    statements: list[str] = []
    start = 0
    i = 0
    in_str = False
    dollar_tag: str | None = None
    while i < len(sql):
        if dollar_tag is not None:
            if sql.startswith(dollar_tag, i):
                i += len(dollar_tag)
                dollar_tag = None
                continue
            i += 1
            continue
        ch = sql[i]
        if in_str:
            if ch == "'":
                if i + 1 < len(sql) and sql[i + 1] == "'":
                    i += 2
                    continue
                in_str = False
            i += 1
            continue
        if ch == "'":
            in_str = True
            i += 1
            continue
        if ch == "$":
            m = re.match(r"\$[A-Za-z0-9_]*\$", sql[i:])
            if m:
                dollar_tag = m.group(0)
                i += len(dollar_tag)
                continue
        if ch == ";":
            statements.append(sql[start : i + 1])
            start = i + 1
        i += 1
    tail = sql[start:]
    if tail.strip():
        statements.append(tail)
    return statements


def translate_bundle(src: Path, dst: Path, translator: BundleTranslator) -> None:
    sql = strip_comments(src.read_text(encoding="utf-8"))
    pieces: list[str] = []
    for statement in split_statements(sql):
        stripped = statement.lstrip()
        if re.match(r"insert into public\.[a-zA-Z0-9_]+\s*\(", stripped, re.I):
            try:
                table, columns, rows, suffix = parse_insert_block(stripped)
                rows = translator.translate_rows(table, columns, rows)
                pieces.append(format_insert(table, columns, rows, suffix))
                pieces.append("\n\n")
                continue
            except Exception:
                pass
        pieces.append(statement)
        if not statement.endswith("\n"):
            pieces.append("\n")
    header = f"-- 自動生成された日本語版: {src.name}\n\n"
    output = header + "".join(pieces)
    replacements = {
        "Claim: ": "主張: ",
        "Subject: ": "対象: ",
        "Claim Type: ": "分類: ",
        "Details: ": "詳細: ",
        "Category: ": "分類: ",
        "Context Type: ": "文脈種別: ",
        "Character: ": "対象キャラクター: ",
        "Location: ": "対象地点: ",
        "Event: ": "対象イベント: ",
        "Payload: ": "内容: ",
    }
    for src_text, dst_text in replacements.items():
        output = output.replace(src_text, dst_text)
    dst.write_text(output, encoding="utf-8")


def main() -> None:
    translator = BundleTranslator()
    translate_bundle(ROOT / "WORLD_APPLY_BUNDLE01.sql", ROOT / "WORLD_APPLY_BUNDLE01_ja.sql", translator)
    translate_bundle(ROOT / "WORLD_APPLY_BUNDLE02.sql", ROOT / "WORLD_APPLY_BUNDLE02_ja.sql", translator)


if __name__ == "__main__":
    main()
