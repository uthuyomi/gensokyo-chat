from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LABELS_PATH = ROOT / "_generated_world_ja_labels.json"
MASTERS_PATH = ROOT / "WORLD_LOCALIZE_JA_MASTERS.sql"
JA_BUNDLE01_PATH = ROOT / "WORLD_APPLY_BUNDLE01_ja.sql"
JA_BUNDLE02_PATH = ROOT / "WORLD_APPLY_BUNDLE02_ja.sql"


CHARACTER_NAME_OVERRIDES = {
    "akyuu": "稗田 阿求",
    "alice": "アリス・マーガトロイド",
    "aunn": "高麗野 あうん",
    "aya": "射命丸 文",
    "benben": "九十九 弁々",
    "biten": "孫 美天",
    "byakuren": "聖 白蓮",
    "chen": "橙",
    "chimata": "天弓 千亦",
    "chiyari": "天火人 ちやり",
    "cirno": "チルノ",
    "clownpiece": "クラウンピース",
    "doremy": "ドレミー・スイート",
    "eika": "戎 瓔花",
    "eiki": "四季映姫・ヤマザナドゥ",
    "eirin": "八意 永琳",
    "enoko": "三頭 慧ノ子",
    "eternity": "エタニティラルバ",
    "flandre": "フランドール・スカーレット",
    "futo": "物部 布都",
    "hatate": "姫海棠 はたて",
    "hecatia": "ヘカーティア・ラピスラズリ",
    "hina": "鍵山 雛",
    "hisami": "豫母都 日狭美",
    "ichirin": "雲居 一輪",
    "iku": "永江 衣玖",
    "joon": "依神 女苑",
    "junko": "純狐",
    "kagerou": "今泉 影狼",
    "kaguya": "蓬莱山 輝夜",
    "kanako": "八坂 神奈子",
    "kasen": "茨木 華扇",
    "keiki": "埴安神 袿姫",
    "keine": "上白沢 慧音",
    "kisume": "キスメ",
    "kogasa": "多々良 小傘",
    "koishi": "古明地 こいし",
    "kokoro": "秦 こころ",
    "komachi": "小野塚 小町",
    "kosuzu": "本居 小鈴",
    "kutaka": "庭渡 久侘歌",
    "kyouko": "幽谷 響子",
    "letty": "レティ・ホワイトロック",
    "lily_white": "リリーホワイト",
    "luna_child": "ルナチャイルド",
    "lunasa": "ルナサ・プリズムリバー",
    "lyrica": "リリカ・プリズムリバー",
    "mai": "丁礼田 舞",
    "mamizou": "二ッ岩 マミゾウ",
    "marisa": "霧雨 魔理沙",
    "mayumi": "杖刀偶 磨弓",
    "medicine": "メディスン・メランコリー",
    "megumu": "飯綱丸 龍",
    "meiling": "紅 美鈴",
    "merlin": "メルラン・プリズムリバー",
    "mike": "豪徳寺 ミケ",
    "miko": "豊聡耳 神子",
    "minoriko": "秋 穣子",
    "misumaru": "玉造 魅須丸",
    "miyoi": "奥野田 美宵",
    "mizuchi": "宮出口 瑞霊",
    "mokou": "藤原 妹紅",
    "momiji": "犬走 椛",
    "momoyo": "姫虫 百々世",
    "murasa": "村紗 水蜜",
    "mystia": "ミスティア・ローレライ",
    "narumi": "矢田寺 成美",
    "nazrin": "ナズーリン",
    "nemuno": "坂田 ネムノ",
    "nitori": "河城 にとり",
    "nue": "封獣 ぬえ",
    "okina": "摩多羅 隠岐奈",
    "parsee": "水橋 パルスィ",
    "patchouli": "パチュリー・ノーレッジ",
    "raiko": "堀川 雷鼓",
    "ran": "八雲 藍",
    "reimu": "博麗 霊夢",
    "reisen": "鈴仙・優曇華院・イナバ",
    "remilia": "レミリア・スカーレット",
    "rin": "火焔猫 燐",
    "ringo": "鈴瑚",
    "rinnosuke": "森近 霖之助",
    "rumia": "ルーミア",
    "sagume": "稀神 サグメ",
    "saki": "驪駒 早鬼",
    "sakuya": "十六夜 咲夜",
    "sanae": "東風谷 早苗",
    "sannyo": "駒草 山如",
    "satono": "爾子田 里乃",
    "satori": "古明地 さとり",
    "seiga": "霍 青娥",
    "seija": "鬼人 正邪",
    "seiran": "清蘭",
    "sekibanki": "赤蛮奇",
    "shinmyoumaru": "少名 針妙丸",
    "shion": "依神 紫苑",
    "shizuha": "秋 静葉",
    "shou": "寅丸 星",
    "star_sapphire": "スターサファイア",
    "suika": "伊吹 萃香",
    "sumireko": "宇佐見 菫子",
    "sunny_milk": "サニーミルク",
    "suwako": "洩矢 諏訪子",
    "takane": "山城 たかね",
    "tenshi": "比那名居 天子",
    "tewi": "因幡 てゐ",
    "tojiko": "蘇我 屠自古",
    "toyohime": "綿月 豊姫",
    "tsukasa": "菅牧 典",
    "urumi": "牛崎 潤美",
    "utsuho": "霊烏路 空",
    "wakasagihime": "わかさぎ姫",
    "wriggle": "リグル・ナイトバグ",
    "yachie": "吉弔 八千慧",
    "yamame": "黒谷 ヤマメ",
    "yatsuhashi": "九十九 八橋",
    "yorihime": "綿月 依姫",
    "yoshika": "宮古 芳香",
    "youmu": "魂魄 妖夢",
    "yukari": "八雲 紫",
    "yuugi": "星熊 勇儀",
    "yuuka": "風見 幽香",
    "yuuma": "饕餮 尤魔",
    "yuyuko": "西行寺 幽々子",
    "zanmu": "日白 残無",
}


CHARACTER_TITLE_OVERRIDES = {
    "akyuu": "御阿礼の子",
    "aunn": "神社を守る狛犬",
    "aya": "伝統の幻想ブン屋",
    "benben": "琵琶の付喪神",
    "biten": "花果子念報の闘士",
    "byakuren": "命蓮寺の住職",
    "chen": "凶兆の黒猫",
    "chimata": "市場を司る神",
    "chiyari": "血の池地獄の案内役",
    "cirno": "氷の妖精",
    "clownpiece": "地獄の妖精",
    "doremy": "夢の支配者",
    "eika": "積み石の河原の亡霊",
    "eiki": "楽園の最高裁判長",
    "eirin": "月の頭脳",
    "enoko": "狼組の頭領",
    "eternity": "真夏の蝶の妖精",
    "flandre": "紅魔館のもう一人の主",
    "futo": "古代の道士",
    "hatate": "流行を追う天狗記者",
    "hecatia": "多元世界の女神",
    "hina": "厄の女神",
    "hisami": "黄泉へ誘う案内人",
    "ichirin": "入道使いの尼僧",
    "iku": "竜宮の使い遊泳弾",
    "joon": "浪費を呼ぶ疫病神",
    "junko": "純化された怨念",
    "kagerou": "竹林の狼人",
    "kaguya": "永遠と須臾の姫君",
    "kanako": "山と湖の化身",
    "kasen": "片腕有角の仙人",
    "keiki": "偶像を創る神",
    "keine": "歴史を喰らう半獣",
    "kisume": "桶に潜む井戸妖怪",
    "kogasa": "愉快な忘れ傘",
    "koishi": "閉じた恋の瞳",
    "kokoro": "感情豊かなポーカーフェイス",
    "komachi": "三途の水先案内人",
    "kosuzu": "鈴奈庵の看板娘",
    "kutaka": "地獄の関所を守る神",
    "kyouko": "山彦の僧侶",
    "letty": "冬の忘れ物",
    "lily_white": "春を告げる妖精",
    "luna_child": "静寂の妖精",
    "lunasa": "騒霊ヴァイオリニスト",
    "lyrica": "騒霊キーボーディスト",
    "mai": "後戸で舞う従者",
    "mamizou": "古参の化け狸",
    "marisa": "普通の魔法使い",
    "mayumi": "埴輪の武人",
    "medicine": "小さなスイートポイズン",
    "megumu": "大天狗の長",
    "meiling": "華人小娘",
    "merlin": "騒霊トランペッター",
    "mike": "招福の白猫",
    "miko": "聖徳道士",
    "minoriko": "豊穣の神",
    "misumaru": "勾玉職人",
    "miyoi": "酔いどれの看板娘",
    "mizuchi": "祟りを秘めた怨霊",
    "mokou": "蓬莱の人の形",
    "momiji": "山の天狗の見張り番",
    "momoyo": "龍を食らう大百足",
    "murasa": "愉快な忘れ傘",
    "mystia": "夜雀の妖怪",
    "narumi": "魔法地蔵",
    "nazrin": "ダウザーの小さな大将",
    "nemuno": "近代の山姥",
    "nitori": "超妖怪弾頭",
    "nue": "正体不明の妖怪",
    "okina": "秘神",
    "parsee": "地殻の下の嫉妬心",
    "patchouli": "知識と日陰の少女",
    "raiko": "夢幻のパーカッショニスト",
    "ran": "すきま妖怪の式",
    "reimu": "楽園の巫女",
    "reisen": "狂気の月の兎",
    "remilia": "永遠に紅い幼き月",
    "rin": "地獄の輪禍",
    "ringo": "団子を食べる月の兎",
    "rinnosuke": "独自理論の道具屋",
    "rumia": "宵闇の妖怪",
    "sagume": "片翼の白鷺",
    "saki": "地獄の最高速ライダー",
    "sakuya": "完全で瀟洒な従者",
    "sanae": "祀られる風の人間",
    "sannyo": "山の煙草商",
    "satono": "後戸の扉を開く従者",
    "satori": "みんなの心を読む妖怪",
    "seiga": "壁抜けの邪仙",
    "seija": "逆襲のあまのじゃく",
    "seiran": "浅葱色のイーグルラヴィ",
    "sekibanki": "ろくろ首の怪奇",
    "shinmyoumaru": "小人の末裔",
    "shion": "最凶最悪の双子の妹",
    "shizuha": "寂しさと終焉の象徴",
    "shou": "毘沙門天の弟子",
    "star_sapphire": "星の光の妖精",
    "suika": "伊吹の萃香",
    "sumireko": "超能力を操る高校生",
    "sunny_milk": "日光の妖精",
    "suwako": "土着神の頂点",
    "takane": "山奥のビジネス妖怪",
    "tenshi": "非想非非想天の娘",
    "tewi": "幸運の素兎",
    "tojiko": "入鹿の雷",
    "toyohime": "山海の豊姫",
    "tsukasa": "高貴なる策謀家",
    "urumi": "水没した沈愁地獄",
    "utsuho": "熱かい悩む神の火",
    "wakasagihime": "秘境の人魚",
    "wriggle": "蠢く光の蟲",
    "yachie": "鬼傑組組長",
    "yamame": "暗い洞窟の明るい網",
    "yatsuhashi": "古びた琴の付喪神",
    "yorihime": "神霊に取り憑かれた月の姫",
    "yoshika": "忠実なキョンシー",
    "youmu": "半人半霊の庭師",
    "yukari": "神隠しの主犯",
    "yuugi": "語られる怪力乱神",
    "yuuka": "四季のフラワーマスター",
    "yuuma": "強欲な獣の霊",
    "yuyuko": "華胥の亡霊",
    "zanmu": "無の獄王",
}


LOCATION_NAME_OVERRIDES = {
    "backdoor_realm": "後戸の国",
    "bamboo_forest": "迷いの竹林",
    "bamboo_path": "竹林の小径",
    "beast_realm": "畜生界",
    "bhavaagra": "有頂天",
    "blood_pool_hell": "血の池地獄",
    "chireiden": "地霊殿",
    "divine_spirit_mausoleum": "神霊廟",
    "dream_world": "夢の世界",
    "eientei": "永遠亭",
    "forest_of_magic": "魔法の森",
    "former_hell": "旧地獄",
    "genbu_ravine": "玄武の沢",
    "hakugyokurou": "白玉楼",
    "hakurei_shrine": "博麗神社",
    "heaven": "天界",
    "human_village": "人里",
    "kappa_workshop": "河童工房",
    "kourindou": "香霖堂",
    "lunar_capital": "月の都",
    "mansion_library": "紅魔館図書館",
    "misty_lake": "霧の湖",
    "moriya_shrine": "守矢神社",
    "moriya_upper_precinct": "守矢神社 上社",
    "muenzuka": "無縁塚",
    "myouren_temple": "命蓮寺",
    "nameless_hill": "無名の丘",
    "netherworld": "冥界",
    "old_capital": "旧都",
    "rainbow_dragon_cave": "虹龍洞",
    "sanzu_river": "三途の川",
    "scarlet_devil_mansion": "紅魔館",
    "scarlet_gate": "紅魔館の門",
    "senkai": "仙界",
    "shining_needle_castle": "輝針城",
    "suzunaan": "鈴奈庵",
    "youkai_mountain_foot": "妖怪の山の麓",
}


def esc(value: str) -> str:
    return value.replace("'", "''")


def load_labels() -> tuple[dict[str, dict[str, str]], dict[str, dict[str, str]]]:
    payload = json.loads(LABELS_PATH.read_text(encoding="utf-8"))
    characters = {item["id"]: item for item in payload["characters"]}
    locations = {item["id"]: item for item in payload["locations"]}
    return characters, locations


def build_masters_sql() -> str:
    characters, locations = load_labels()

    for cid, name in CHARACTER_NAME_OVERRIDES.items():
        characters[cid]["name_ja"] = name
    for cid, title in CHARACTER_TITLE_OVERRIDES.items():
        characters[cid]["title_ja"] = title
    for lid, name in LOCATION_NAME_OVERRIDES.items():
        locations[lid]["name_ja"] = name

    lines = ["-- World localization patch: Japanese master labels (fully curated)", ""]
    for cid in sorted(characters):
        item = characters[cid]
        lines.append(
            "update public.world_characters "
            f"set name = '{esc(item['name_ja'])}', title = '{esc(item['title_ja'])}', updated_at = now() "
            f"where world_id = 'gensokyo_main' and id = '{cid}';"
        )

    lines.append("")
    for lid in sorted(locations):
        item = locations[lid]
        lines.append(
            "update public.world_locations "
            f"set name = '{esc(item['name_ja'])}', updated_at = now() "
            f"where world_id = 'gensokyo_main' and id = '{lid}';"
        )

    lines.append("")
    return "\n".join(lines)


def rebuild_ja_bundles() -> None:
    parts01 = [ROOT / "WORLD_APPLY_BUNDLE01.sql"]
    parts02 = [
        ROOT / "WORLD_APPLY_BUNDLE02.sql",
        ROOT / "WORLD_LOCALIZE_JA_MASTERS.sql",
        ROOT / "WORLD_LOCALIZE_JA.sql",
        ROOT / "WORLD_LOCALIZE_JA_DEEP.sql",
    ]
    for target, parts in ((JA_BUNDLE01_PATH, parts01), (JA_BUNDLE02_PATH, parts02)):
        chunks = [f"-- AUTO-GENERATED JA BUNDLE: {target.name}\n"]
        for part in parts:
            chunks.append(f"\n-- BEGIN {part.name}\n")
            chunks.append(part.read_text(encoding="utf-8"))
            chunks.append(f"\n-- END {part.name}\n")
        target.write_text("".join(chunks), encoding="utf-8")


def main() -> None:
    MASTERS_PATH.write_text(build_masters_sql(), encoding="utf-8")
    rebuild_ja_bundles()
    print(MASTERS_PATH)
    print(JA_BUNDLE01_PATH)
    print(JA_BUNDLE02_PATH)


if __name__ == "__main__":
    main()
