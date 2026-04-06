"use client";

import * as React from "react";
import {
  Check,
  ChevronLeft,
  ChevronRight,
  Download,
  ImageUp,
  MessageSquareText,
  Search,
  Sparkles,
  UserRoundPlus,
  Users,
  X,
} from "lucide-react";

import { TooltipIconButton } from "@/components/assistant-ui/tooltip-icon-button";
import { ThreadList, UserBlock } from "@/components/assistant-ui/thread-list";
import { useTouhouUi } from "@/components/assistant-ui/touhou-ui-context";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Sidebar, SidebarContent, SidebarHeader, SidebarRail, useSidebar } from "@/components/ui/sidebar";
import { useLanguage } from "@/components/i18n/LanguageProvider";
import { cn } from "@/lib/utils";

type Character = {
  id: string;
  name: string;
  title: string;
  promptVersion?: string;
  ui?: { avatar?: string };
};

type Props = React.ComponentProps<typeof Sidebar> & {
  visibleCharacters: Character[];
  activeCharacterId: string | null;
  onSelectCharacter: (id: string) => void;
  activeSessionId: string | null;
  onImportArtifactFile: (file: File) => void | Promise<void>;
  onExportActiveSession: () => void;
  artifactBusy?: boolean;
  charactersCollapsed: boolean;
  onCharactersCollapsedChange: (next: boolean) => void;
  createThreadDialogOpen: boolean;
  onCreateThreadDialogOpenChange: (next: boolean) => void;
  recentCharacterIds: string[];
};

const copyFor = (lang: string) =>
  lang === "ja"
    ? {
        conversation: "会話",
        character: "キャラクター",
        settings: "設定",
        top: "トップページ",
        conversations: "会話一覧",
        createConversation: "新しい会話を作成",
        importLabel: "ログを読み込む",
        importTip: "run.jsonl / JSON を読み込みます",
        importDisabled: "先に会話を選択してください",
        exportLabel: "会話をエクスポート",
        exportTip: "現在の会話を JSONL で書き出します",
        exportDisabled: "選択中の会話がありません",
        close: "閉じる",
        titleSingle: "会話を作成",
        titleRoom: "ルームを作成",
        descSingle: "案内に沿って相手を選ぶと、そのまま会話を始められます。",
        descRoom: "形式、参加者、確認の順でルームを作成できます。",
        single: "1対1",
        room: "ルーム",
        step1: "形式を選ぶ",
        step2: "相手を選ぶ",
        step3: "確認して作成",
        searchSingle: "キャラクターを検索",
        searchRoom: "追加するキャラクターを検索",
        current: "選択中",
        recent: "最近",
        recommended: "おすすめ",
        allCharacters: "選択できるキャラクター",
        addAi: "AI キャラクターを追加",
        noResults: "条件に一致するキャラクターが見つかりませんでした。",
        back: "戻る",
        next: "次へ",
        start: "会話を開始",
        createRoomFinal: "ルームを作成",
        summarySingle: "選択した相手",
        summaryRoom: "ルーム構成",
        roomMembers: "ルーム参加者",
        inviteUsers: "ユーザーを招待",
        inviteHint: "メールアドレスはカンマまたは改行で区切ってください。",
        emptySingle: "キャラクターを 1 人選ぶと、ここに表示されます。",
        emptyRoom: "参加者を選ぶと、ここにルーム構成が表示されます。",
        selectSingle: "会話したい相手を 1 人選んでください。",
        selectRoom: "ルームに参加させたい AI キャラクターを複数選べます。",
        you: "あなた",
        selectAi: "AI キャラクターを選択",
        aiCharacters: "人の AI キャラクター",
        invitedUsers: "人の招待ユーザー",
      }
    : {
        conversation: "Conversation",
        character: "Character",
        settings: "Prompt",
        top: "Top page",
        conversations: "Conversations",
        createConversation: "Create conversation",
        importLabel: "Import artifact",
        importTip: "Import run.jsonl / JSON",
        importDisabled: "Select a conversation first",
        exportLabel: "Export session",
        exportTip: "Export active session JSONL",
        exportDisabled: "No active session",
        close: "Close",
        titleSingle: "Create conversation",
        titleRoom: "Create room",
        descSingle: "Follow the steps, pick a character, and start a conversation.",
        descRoom: "Choose a format, pick participants, and confirm the room.",
        single: "Single",
        room: "Room",
        step1: "Choose format",
        step2: "Pick participants",
        step3: "Confirm and create",
        searchSingle: "Search character",
        searchRoom: "Search characters to add",
        current: "Current",
        recent: "Recent",
        recommended: "Recommended",
        allCharacters: "All available characters",
        addAi: "Add AI participants",
        noResults: "No characters matched that search.",
        back: "Back",
        next: "Next",
        start: "Start conversation",
        createRoomFinal: "Create room",
        summarySingle: "Selected character",
        summaryRoom: "Room summary",
        roomMembers: "Room members",
        inviteUsers: "Invite human users",
        inviteHint: "Separate emails with commas or line breaks.",
        emptySingle: "Choose one character to show the summary here.",
        emptyRoom: "Choose participants to show the room summary here.",
        selectSingle: "Pick one character for this conversation.",
        selectRoom: "You can select multiple AI characters for the room.",
        you: "You",
        selectAi: "select AI characters",
        aiCharacters: "AI characters",
        invitedUsers: "invited users",
      };

function SectionChip(props: { icon: React.ReactNode; label: string }) {
  return (
    <span className="inline-flex items-center gap-1 rounded-full border border-sidebar-border/80 bg-sidebar-accent/35 px-2 py-1 text-[10px] font-medium text-sidebar-foreground/75">
      {props.icon}
      <span>{props.label}</span>
    </span>
  );
}

function CharacterPickerDialog(props: {
  open: boolean;
  onOpenChange: (next: boolean) => void;
  characters: Character[];
  activeCharacterId: string | null;
  recentCharacterIds: string[];
}) {
  const { lang } = useLanguage();
  const copy = React.useMemo(() => copyFor(lang), [lang]);
  const { createThreadForCharacter, createThreadForCharacters } = useTouhouUi();
  const [mode, setMode] = React.useState<"single" | "room">("single");
  const [step, setStep] = React.useState<1 | 2 | 3>(1);
  const [query, setQuery] = React.useState("");
  const [selectedIds, setSelectedIds] = React.useState<string[]>([]);
  const [inviteInput, setInviteInput] = React.useState("");
  React.useEffect(() => {
    if (!props.open) {
      setMode("single");
      setStep(1);
      setQuery("");
      setSelectedIds([]);
      setInviteInput("");
      return;
    }
    setSelectedIds(props.activeCharacterId ? [props.activeCharacterId] : []);
  }, [props.activeCharacterId, props.open]);

  React.useEffect(() => {
    if (mode === "single" && selectedIds.length > 1) setSelectedIds((prev) => prev.slice(0, 1));
  }, [mode, selectedIds.length]);

  const invitedHumans = React.useMemo(
    () => inviteInput.split(/[\n,;]+/).map((v) => v.trim()).filter(Boolean).map((email) => ({ email })),
    [inviteInput],
  );

  const normalizedQuery = query.trim().toLowerCase();
  const filteredCharacters = React.useMemo(() => {
    if (!normalizedQuery) return props.characters;
    return props.characters.filter((ch) => [ch.name, ch.title, ch.id, ch.promptVersion ?? ""].join(" ").toLowerCase().includes(normalizedQuery));
  }, [normalizedQuery, props.characters]);

  const recentSet = React.useMemo(() => new Set(props.recentCharacterIds), [props.recentCharacterIds]);
  const recommendedCharacters = React.useMemo(() => {
    const seen = new Set<string>();
    return filteredCharacters.filter((ch) => {
      const ok = ch.id === props.activeCharacterId || recentSet.has(ch.id);
      if (!ok || seen.has(ch.id)) return false;
      seen.add(ch.id);
      return true;
    });
  }, [filteredCharacters, props.activeCharacterId, recentSet]);
  const recommendedIds = React.useMemo(() => new Set(recommendedCharacters.map((ch) => ch.id)), [recommendedCharacters]);
  const remainingCharacters = React.useMemo(() => filteredCharacters.filter((ch) => !recommendedIds.has(ch.id)), [filteredCharacters, recommendedIds]);
  const recentCharacters = React.useMemo(() => {
    const map = new Map(props.characters.map((ch) => [ch.id, ch]));
    return props.recentCharacterIds.map((id) => map.get(id)).filter((v): v is Character => !!v);
  }, [props.characters, props.recentCharacterIds]);
  const selectedCharacters = React.useMemo(() => {
    const map = new Map(props.characters.map((ch) => [ch.id, ch]));
    return selectedIds.map((id) => map.get(id)).filter((v): v is Character => !!v);
  }, [props.characters, selectedIds]);

  const toggleSelected = (characterId: string) => {
    if (mode === "single") {
      setSelectedIds([characterId]);
      return;
    }
    setSelectedIds((prev) => (prev.includes(characterId) ? prev.filter((id) => id !== characterId) : [...prev, characterId]));
  };

  const complete = () => {
    const ids = Array.from(new Set(selectedIds));
    if (ids.length === 0) return;
    if (mode === "single") {
      void createThreadForCharacter(ids[0]);
      return;
    }
    if ((ids.length === 1 && invitedHumans.length === 0) || !createThreadForCharacters) {
      void createThreadForCharacter(ids[0]);
      return;
    }
    void createThreadForCharacters(ids, invitedHumans);
  };

  const roomSummary =
    lang === "ja"
      ? `${copy.you} + ${selectedIds.length > 0 ? `${selectedIds.length} ${copy.aiCharacters}` : copy.selectAi}${invitedHumans.length > 0 ? ` + ${invitedHumans.length} ${copy.invitedUsers}` : ""}`
      : `${copy.you} + ${selectedIds.length > 0 ? `${selectedIds.length} AI character${selectedIds.length > 1 ? "s" : ""}` : copy.selectAi}${invitedHumans.length > 0 ? ` + ${invitedHumans.length} invited user${invitedHumans.length > 1 ? "s" : ""}` : ""}`;

  const stepLabels = [copy.step1, copy.step2, copy.step3];

  const renderCard = (ch: Character, tone: "recommended" | "default") => {
    const selected = selectedIds.includes(ch.id);
    return (
      <button
        key={ch.id}
        type="button"
        onClick={() => toggleSelected(ch.id)}
        className={cn(
          "group relative flex min-h-[132px] w-full items-center gap-4 rounded-3xl border px-5 py-4 text-left transition hover:border-ring/60 hover:bg-accent/40",
          tone === "recommended" ? "border-ring/30 bg-accent/25" : "border-border/70 bg-background/50",
          selected && "border-ring bg-accent/35 shadow-sm",
        )}
      >
        <span className={cn("absolute right-3 top-3 inline-flex size-6 items-center justify-center rounded-full border text-[10px]", selected ? "border-ring bg-ring text-white" : "border-border/70 bg-background/80 text-muted-foreground")}>
          {selected ? <Check className="size-3.5" /> : null}
        </span>
        <Avatar className="size-16 shrink-0 rounded-2xl border border-border/60">
          <AvatarImage src={ch.ui?.avatar} alt={ch.name} />
          <AvatarFallback className="text-base">{String(ch.name ?? "?").slice(0, 1)}</AvatarFallback>
        </Avatar>
        <div className="min-w-0 flex-1 pr-7">
          <div className="flex flex-wrap items-center gap-2">
            <div className="truncate font-gensou text-base text-foreground">{ch.name}</div>
            {ch.id === props.activeCharacterId ? <span className="rounded-full border border-border/70 bg-muted/45 px-2 py-0.5 text-[10px] font-medium text-muted-foreground">{copy.current}</span> : null}
            {ch.id !== props.activeCharacterId && recentSet.has(ch.id) ? <span className="rounded-full border border-border/70 bg-muted/45 px-2 py-0.5 text-[10px] font-medium text-muted-foreground">{copy.recent}</span> : null}
          </div>
          <div className="mt-1 line-clamp-2 text-sm leading-6 text-muted-foreground">{ch.title}</div>
          {ch.promptVersion ? <div className="mt-3 inline-flex items-center gap-1 rounded-full border border-border/70 bg-muted/45 px-2.5 py-1 text-[11px] font-medium text-muted-foreground"><Sparkles className="size-3" /><span>{ch.promptVersion}</span></div> : null}
        </div>
      </button>
    );
  };
  return (
    <Dialog open={props.open} onOpenChange={props.onOpenChange}>
      <DialogContent className="max-w-[min(1280px,96vw)] rounded-[28px] border-border/70 bg-background/95 p-0 shadow-2xl backdrop-blur">
        <DialogHeader className="border-b border-border/60 px-6 pb-4 pt-6">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div className="min-w-0 flex-1 pr-4">
              <DialogTitle className="flex items-center gap-2 text-xl"><UserRoundPlus className="size-5" /><span>{mode === "room" ? copy.titleRoom : copy.titleSingle}</span></DialogTitle>
              <DialogDescription className="max-w-3xl leading-6">{mode === "room" ? copy.descRoom : copy.descSingle}</DialogDescription>
            </div>
            <div className="inline-flex rounded-2xl border border-border/70 bg-muted/35 p-1">
              <button type="button" onClick={() => setMode("single")} className={cn("inline-flex min-w-[120px] items-center justify-center rounded-xl px-4 py-2 text-sm transition", mode === "single" ? "bg-background shadow-sm" : "text-muted-foreground")}>{copy.single}</button>
              <button type="button" onClick={() => setMode("room")} className={cn("inline-flex min-w-[120px] items-center justify-center gap-1 rounded-xl px-4 py-2 text-sm transition", mode === "room" ? "bg-background shadow-sm" : "text-muted-foreground")}><Users className="size-4" /><span>{copy.room}</span></button>
            </div>
          </div>
        </DialogHeader>

        <div className="max-h-[78vh] overflow-auto px-6 py-5">
          <div className="mx-auto w-full max-w-[1160px]">
          <div className="mb-5 grid gap-3 md:grid-cols-3">
            {stepLabels.map((label, index) => {
              const current = index + 1;
              const active = current === step;
              const done = current < step;
              return (
                <div key={label} className={cn("flex min-h-[76px] items-center rounded-2xl border px-4 py-3", active ? "border-ring bg-accent/30" : "border-border/70 bg-background/70", done && "border-emerald-400/40")}>
                  <div className="flex items-center gap-2">
                    <span className={cn("inline-flex size-6 items-center justify-center rounded-full border text-xs font-semibold", active ? "border-ring bg-ring text-white" : "border-border/70 text-muted-foreground", done && "border-emerald-500 bg-emerald-500 text-white")}>
                      {done ? <Check className="size-3.5" /> : current}
                    </span>
                    <span className="text-sm font-medium text-foreground">{label}</span>
                  </div>
                </div>
              );
            })}
          </div>

          {step === 1 ? (
            <div className="grid gap-4 lg:grid-cols-2">
              <button type="button" onClick={() => { setMode("single"); setStep(2); }} className={cn("min-h-[180px] rounded-3xl border px-6 py-6 text-left transition hover:border-ring/60 hover:bg-accent/35", mode === "single" ? "border-ring bg-accent/30 shadow-sm" : "border-border/70 bg-background/70")}>
                <div className="flex items-center gap-2 text-base font-semibold text-foreground"><UserRoundPlus className="size-5" /><span>{copy.single}</span></div>
                <div className="mt-2 text-sm leading-6 text-muted-foreground">{copy.descSingle}</div>
              </button>
              <button type="button" onClick={() => { setMode("room"); setStep(2); }} className={cn("min-h-[180px] rounded-3xl border px-6 py-6 text-left transition hover:border-ring/60 hover:bg-accent/35", mode === "room" ? "border-ring bg-accent/30 shadow-sm" : "border-border/70 bg-background/70")}>
                <div className="flex items-center gap-2 text-base font-semibold text-foreground"><Users className="size-5" /><span>{copy.room}</span></div>
                <div className="mt-2 text-sm leading-6 text-muted-foreground">{copy.descRoom}</div>
              </button>
            </div>
          ) : null}

          {step === 2 ? (
            <div className="flex flex-col gap-5">
              <div className="rounded-2xl border border-border/70 bg-background/70 px-4 py-3 text-sm leading-6 text-foreground">{mode === "single" ? copy.selectSingle : copy.selectRoom}</div>
              <div className="flex items-center gap-2 rounded-2xl border border-border/70 bg-background/70 px-3 py-2"><Search className="size-4 text-muted-foreground" /><input value={query} onChange={(e) => setQuery(e.target.value)} placeholder={mode === "room" ? copy.searchRoom : copy.searchSingle} className="w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground" /></div>
              {filteredCharacters.length === 0 ? (
                <div className="rounded-2xl border border-dashed border-border/70 bg-muted/30 px-4 py-8 text-center text-sm text-muted-foreground">{copy.noResults}</div>
              ) : (
                <div className="flex flex-col gap-6">
                  {recommendedCharacters.length > 0 ? <section><div className="mb-3 flex items-center gap-2 text-xs font-medium uppercase tracking-[0.14em] text-muted-foreground"><Sparkles className="size-3.5" /><span>{copy.recommended}</span></div><div className="grid gap-4 xl:grid-cols-2">{recommendedCharacters.map((ch) => renderCard(ch, "recommended"))}</div></section> : null}
                  {recentCharacters.length > 0 && !normalizedQuery ? <section><div className="mb-3 flex items-center gap-2 text-xs font-medium uppercase tracking-[0.14em] text-muted-foreground"><MessageSquareText className="size-3.5" /><span>{copy.recent}</span></div><div className="flex flex-wrap gap-2">{recentCharacters.map((ch) => <button key={ch.id} type="button" onClick={() => toggleSelected(ch.id)} className={cn("inline-flex items-center gap-2 rounded-full border border-border/70 bg-background/65 px-3 py-2 text-sm hover:bg-accent/40", selectedIds.includes(ch.id) && "border-ring bg-accent/35")}><Avatar className="size-6 border border-border/60"><AvatarImage src={ch.ui?.avatar} alt={ch.name} /><AvatarFallback className="text-[10px]">{String(ch.name ?? "?").slice(0, 1)}</AvatarFallback></Avatar><span>{ch.name}</span></button>)}</div></section> : null}
                  <section><div className="mb-3 flex items-center gap-2 text-xs font-medium uppercase tracking-[0.14em] text-muted-foreground"><UserRoundPlus className="size-3.5" /><span>{mode === "room" ? copy.addAi : copy.allCharacters}</span></div><div className="grid gap-4 xl:grid-cols-2">{remainingCharacters.map((ch) => renderCard(ch, "default"))}</div></section>
                </div>
              )}
            </div>
          ) : null}

          {step === 3 ? (
            mode === "single" ? (
              <div className="mx-auto max-w-4xl">
                <div className="rounded-3xl border border-border/70 bg-background/70 px-6 py-6">
                  <div className="text-sm font-medium text-foreground">{copy.summarySingle}</div>
                  {selectedCharacters.length === 0 ? (
                    <div className="mt-3 text-sm text-muted-foreground">{copy.emptySingle}</div>
                  ) : (
                    <div className="mt-4">
                      {selectedCharacters.map((ch) => (
                        <div
                          key={ch.id}
                          className="flex items-center gap-5 rounded-3xl border border-border/70 bg-background/80 px-5 py-5"
                        >
                          <Avatar className="size-20 rounded-3xl border border-border/60">
                            <AvatarImage src={ch.ui?.avatar} alt={ch.name} />
                            <AvatarFallback className="text-xl">{String(ch.name ?? "?").slice(0, 1)}</AvatarFallback>
                          </Avatar>
                          <div className="min-w-0 flex-1">
                            <div className="truncate font-gensou text-xl text-foreground">{ch.name}</div>
                            <div className="mt-2 text-sm leading-6 text-muted-foreground">{ch.title}</div>
                            {ch.promptVersion ? (
                              <div className="mt-3 inline-flex items-center gap-1 rounded-full border border-border/70 bg-muted/45 px-3 py-1.5 text-xs font-medium text-muted-foreground">
                                <Sparkles className="size-3.5" />
                                <span>{ch.promptVersion}</span>
                              </div>
                            ) : null}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            ) : (
              <div className="grid items-start gap-5 xl:grid-cols-[minmax(0,1fr)_380px]">
                <div className="rounded-3xl border border-border/70 bg-background/70 px-6 py-6">
                  <div className="text-sm font-medium text-foreground">{copy.summaryRoom}</div>
                  {selectedCharacters.length === 0 ? <div className="mt-3 text-sm text-muted-foreground">{copy.emptyRoom}</div> : <div className="mt-4 flex flex-col gap-3">{selectedCharacters.map((ch) => <div key={ch.id} className="flex items-center gap-3 rounded-2xl border border-border/70 bg-background/80 px-3 py-3"><Avatar className="size-12 rounded-xl border border-border/60"><AvatarImage src={ch.ui?.avatar} alt={ch.name} /><AvatarFallback className="text-sm">{String(ch.name ?? "?").slice(0, 1)}</AvatarFallback></Avatar><div className="min-w-0 flex-1"><div className="truncate font-gensou text-sm text-foreground">{ch.name}</div><div className="mt-1 truncate text-xs text-muted-foreground">{ch.title}</div></div></div>)}</div>}
                  <div className="mt-4 rounded-2xl border border-border/70 bg-background/80 px-4 py-4"><div className="mb-2 text-xs font-medium uppercase tracking-[0.14em] text-muted-foreground">{copy.inviteUsers}</div><textarea value={inviteInput} onChange={(e) => setInviteInput(e.target.value)} placeholder="friend@example.com, ally@example.com" className="min-h-24 w-full resize-y rounded-xl border border-border/70 bg-background px-3 py-2 text-sm outline-none placeholder:text-muted-foreground" /><div className="mt-2 text-xs text-muted-foreground">{copy.inviteHint}</div></div>
                </div>
                <div className="rounded-3xl border border-border/70 bg-muted/25 px-5 py-5 xl:sticky xl:top-0"><div className="text-xs font-medium uppercase tracking-[0.14em] text-muted-foreground">{copy.roomMembers}</div><div className="mt-2 text-sm leading-6 text-foreground">{roomSummary}</div></div>
              </div>
            )
          ) : null}
          </div>
        </div>

        <div className="flex items-center justify-between border-t border-border/60 px-6 py-4">
          <button type="button" onClick={() => setStep((prev) => (prev > 1 ? ((prev - 1) as 1 | 2 | 3) : prev))} disabled={step === 1} className="inline-flex items-center gap-2 rounded-xl border border-border/70 bg-background px-4 py-2 text-sm font-medium disabled:cursor-not-allowed disabled:opacity-50"><ChevronLeft className="size-4" /><span>{copy.back}</span></button>
          {step < 3 ? <button type="button" onClick={() => setStep((prev) => (prev < 3 ? ((prev + 1) as 1 | 2 | 3) : prev))} disabled={step === 2 && selectedIds.length === 0} className="inline-flex items-center gap-2 rounded-xl border border-ring/40 bg-accent px-4 py-2 text-sm font-medium disabled:cursor-not-allowed disabled:opacity-50"><span>{copy.next}</span><ChevronRight className="size-4" /></button> : <button type="button" onClick={complete} disabled={selectedIds.length === 0} className="inline-flex items-center gap-2 rounded-xl border border-ring/40 bg-accent px-4 py-2 text-sm font-medium disabled:cursor-not-allowed disabled:opacity-50">{mode === "room" ? <Users className="size-4" /> : <UserRoundPlus className="size-4" />}<span>{mode === "single" ? copy.start : copy.createRoomFinal}</span></button>}
        </div>
      </DialogContent>
    </Dialog>
  );
}
export function TouhouSidebar({
  visibleCharacters,
  activeCharacterId,
  onSelectCharacter,
  activeSessionId,
  onImportArtifactFile,
  onExportActiveSession,
  artifactBusy,
  createThreadDialogOpen,
  onCreateThreadDialogOpenChange,
  recentCharacterIds,
  className,
  ...props
}: Props) {
  const { lang } = useLanguage();
  const copy = React.useMemo(() => copyFor(lang), [lang]);
  const { setOpen, setOpenMobile, isMobile } = useSidebar();
  const fileRef = React.useRef<HTMLInputElement | null>(null);

  const handleClose = () => {
    if (isMobile) setOpenMobile(false);
    else setOpen(false);
  };

  const canImport = !!activeCharacterId && !artifactBusy;
  const canExport = !!activeSessionId && !artifactBusy;

  return (
    <>
      <Sidebar className={cn(className)} {...props}>
        <SidebarHeader className="border-b px-3 py-3">
          <div className="mb-2 flex items-center justify-end gap-2">
            {isMobile ? <button type="button" onClick={handleClose} className="flex size-8 items-center justify-center rounded-xl transition hover:bg-sidebar-accent" aria-label={copy.close}><X className="size-4" /></button> : null}
          </div>
          <div className="rounded-2xl border border-sidebar-border/70 bg-sidebar-accent/20 px-3 py-3">
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0">
                <h1 className="font-gensou text-lg tracking-wide text-sidebar-foreground">Gensokyo Chat</h1>
              </div>

            </div>
          </div>
        </SidebarHeader>

        <SidebarContent className="flex min-h-0 flex-col p-0">
          <div className="border-b border-sidebar-border px-3 py-2.5">
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-2 text-xs text-sidebar-foreground/60"><MessageSquareText className="size-4" /><span>{copy.conversations}</span></div>
              <div className="flex items-center gap-2">
                <input ref={fileRef} type="file" accept=".jsonl,.json,application/json,text/plain" className="hidden" onChange={(e) => { const f = e.currentTarget.files?.[0] ?? null; e.currentTarget.value = ""; if (!f) return; void onImportArtifactFile(f); }} />
                <TooltipIconButton tooltip={canImport ? copy.importTip : copy.importDisabled} type="button" disabled={!canImport} onClick={() => fileRef.current?.click()} variant="outline" size="icon-sm" className={cn("rounded-xl border-sidebar-border bg-sidebar-accent/35 hover:bg-sidebar-accent", !canImport && "cursor-not-allowed opacity-60")} aria-label={copy.importLabel}><ImageUp className="size-4" /></TooltipIconButton>
                <TooltipIconButton tooltip={canExport ? copy.exportTip : copy.exportDisabled} type="button" disabled={!canExport} onClick={onExportActiveSession} variant="outline" size="icon-sm" className={cn("rounded-xl border-sidebar-border bg-sidebar-accent/35 hover:bg-sidebar-accent", !canExport && "cursor-not-allowed opacity-60")} aria-label={copy.exportLabel}><Download className="size-4" /></TooltipIconButton>
              </div>
            </div>
          </div>

          <div className="min-h-0 flex-1 overflow-auto px-3 py-3"><ThreadList /></div>
          <div className="border-t border-sidebar-border p-3"><div className="ml-auto w-full"><UserBlock /></div></div>
        </SidebarContent>
        <SidebarRail />
      </Sidebar>

      <CharacterPickerDialog open={createThreadDialogOpen} onOpenChange={onCreateThreadDialogOpenChange} characters={visibleCharacters} activeCharacterId={activeCharacterId} recentCharacterIds={recentCharacterIds} />
    </>
  );
}
