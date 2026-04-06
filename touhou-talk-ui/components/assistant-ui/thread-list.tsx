import { TooltipIconButton } from "@/components/assistant-ui/tooltip-icon-button";
import { useTouhouUi } from "@/components/assistant-ui/touhou-ui-context";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { useLanguage } from "@/components/i18n/LanguageProvider";
import { Skeleton } from "@/components/ui/skeleton";
import { useSidebar } from "@/components/ui/sidebar";
import { cn } from "@/lib/utils";
import { getAiParticipants } from "@/lib/rooms/participants";
import { supabaseBrowser } from "@/lib/supabaseClient";
import {
  AssistantIf,
  ThreadListItemMorePrimitive,
  ThreadListItemPrimitive,
  ThreadListPrimitive,
  useThreadListItem,
  useThreadListItemRuntime,
} from "@assistant-ui/react";
import type { User } from "@supabase/supabase-js";
import {
  CogIcon,
  MoreHorizontalIcon,
  PencilIcon,
  PlusIcon,
  SparklesIcon,
  TrashIcon,
  UserIcon,
} from "lucide-react";
import Link from "next/link";
import type { FC } from "react";
import { useEffect, useMemo, useState } from "react";

export const ThreadList: FC = () => {
  return (
    <ThreadListPrimitive.Root className="aui-root aui-thread-list-root flex min-w-0 flex-col gap-2">
      <ThreadListNew />
      <AssistantIf condition={({ threads }) => threads.isLoading}>
        <ThreadListSkeleton />
      </AssistantIf>
      <AssistantIf condition={({ threads }) => !threads.isLoading}>
        <ThreadListPrimitive.Items components={{ ThreadListItem }} />
      </AssistantIf>
    </ThreadListPrimitive.Root>
  );
};

export const UserBlock: FC<{ className?: string }> = ({ className }) => {
  const { lang } = useLanguage();
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    const fetchUser = async () => {
      const { data } = await supabaseBrowser().auth.getUser();
      setUser(data.user ?? null);
    };

    fetchUser();
    const { data: listener } = supabaseBrowser().auth.onAuthStateChange(() => {
      fetchUser();
    });

    return () => {
      listener.subscription.unsubscribe();
    };
  }, []);

  const avatarUrl = useMemo(() => {
    const u = user;
    if (!u) return null;
    const md = u.user_metadata as Record<string, unknown> | null;
    return md && typeof md.avatar_url === "string" ? md.avatar_url : null;
  }, [user]);

  const displayName = useMemo(() => {
    const u = user;
    if (!u) return "";
    const md = u.user_metadata as Record<string, unknown> | null;
    const v = md && typeof md.full_name === "string" ? md.full_name : u.email ?? "";
    return String(v ?? "");
  }, [user]);

  const email = user?.email ?? "";
  const copy = useMemo(
    () =>
      lang === "ja"
        ? { avatarAlt: "ユーザーアバター", fallbackName: "ユーザー", settings: "設定" }
        : { avatarAlt: "User avatar", fallbackName: "User", settings: "Settings" },
    [lang],
  );

  return (
    <div
      className={cn(
        "rounded-2xl border bg-background/65 px-3 py-3 text-foreground shadow-sm backdrop-blur",
        className,
      )}
    >
      <div className="flex items-center gap-3">
        <Avatar className="size-10 border border-border/60">
          <AvatarImage src={avatarUrl ?? undefined} alt={copy.avatarAlt} />
          <AvatarFallback>
            <UserIcon className="size-4" />
          </AvatarFallback>
        </Avatar>

        <div className="min-w-0 flex-1">
          <div className="truncate text-sm font-medium">{displayName || copy.fallbackName}</div>
          <div className="truncate text-xs text-muted-foreground">{email}</div>
        </div>

        <TooltipIconButton tooltip={copy.settings} asChild variant="outline" size="icon-sm" className="rounded-xl">
          <Link href="/settings" aria-label={copy.settings}>
            <CogIcon className="size-4" />
          </Link>
        </TooltipIconButton>
      </div>
    </div>
  );
};

const ThreadListNew: FC = () => {
  const { lang } = useLanguage();
  const { openCreateThreadDialog } = useTouhouUi();

  return (
    <Button
      type="button"
      variant="outline"
      onClick={openCreateThreadDialog}
      className="aui-thread-list-new h-10 justify-start gap-2 rounded-xl border-dashed px-3 text-sm hover:bg-muted data-active:bg-muted"
    >
      <PlusIcon className="size-4" />
      <span>{lang === "ja" ? "新しい会話" : "New chat"}</span>
    </Button>
  );
};

const ThreadListSkeleton: FC = () => {
  const { lang } = useLanguage();
  return (
    <div className="flex flex-col gap-2">
      {Array.from({ length: 5 }, (_, i) => (
        <div
          key={i}
          role="status"
          aria-label={lang === "ja" ? "会話一覧を読み込み中" : "Loading conversations"}
          className="aui-thread-list-skeleton-wrapper flex h-12 items-center rounded-xl border border-border/60 px-3"
        >
          <Skeleton className="aui-thread-list-skeleton h-4 w-full" />
        </div>
      ))}
    </div>
  );
};

const ThreadListItem: FC = () => {
  const { lang } = useLanguage();
  const { activeSessionId, sessions, characters } = useTouhouUi();
  const { isMobile, setOpen, setOpenMobile } = useSidebar();
  const threadId = useThreadListItem((s: { id: string }) => s.id);

  const session = useMemo(() => sessions.find((s) => s.id === threadId) ?? null, [sessions, threadId]);
  const accent = useMemo(() => {
    if (!session) return null;
    const ch = characters[session.characterId];
    return ch?.color?.accent ?? null;
  }, [characters, session]);

  const aiParticipants = useMemo(
    () => (session?.participants ? getAiParticipants(session.participants) : []),
    [session],
  );

  const avatars = useMemo(() => {
    if (!session) return [];
    const ids =
      aiParticipants.length > 0
        ? aiParticipants.map((participant) => participant.characterId)
        : [session.characterId];
    return ids
      .map((id) => ({
        id,
        avatar: characters[id]?.ui?.avatar ?? null,
        name: characters[id]?.name ?? id,
      }))
      .slice(0, 3);
  }, [aiParticipants, characters, session]);

  const characterName = useMemo(() => {
    if (!session) return lang === "ja" ? "不明" : "Unknown";
    const ids =
      aiParticipants.length > 0
        ? aiParticipants.map((participant) => participant.characterId)
        : [session.characterId];
    return ids.map((id) => characters[id]?.name ?? id).join(" / ");
  }, [aiParticipants, characters, lang, session]);

  const isActive = threadId === activeSessionId;
  const handleSelectThread = () => {
    if (isMobile) setOpenMobile(false);
    else setOpen(false);
  };

  return (
    <ThreadListItemPrimitive.Root
      className={cn(
        "aui-thread-list-item group relative flex min-h-12 min-w-0 items-center gap-2 rounded-2xl border px-2 transition-all hover:bg-muted focus-visible:bg-muted focus-visible:outline-none",
        isActive ? "border-transparent shadow-sm" : "border-border/60 bg-background/35",
        isActive && accent ? `bg-gradient-to-r ${accent} text-white` : "",
      )}
    >
      <ThreadListItemPrimitive.Trigger
        onClick={handleSelectThread}
        className="aui-thread-list-item-trigger flex h-full min-w-0 flex-1 items-center gap-3 overflow-hidden px-1.5 py-2 text-start text-sm"
      >
        <div className="flex shrink-0 items-center">
          {avatars.map((avatar, index) => (
            <Avatar
              key={avatar.id}
              className={cn("size-8 border border-border/60 bg-background/40", index > 0 && "-ml-2")}
            >
              <AvatarImage src={avatar.avatar ?? undefined} alt={avatar.name} />
              <AvatarFallback className="text-[10px]">{avatar.name.slice(0, 1)}</AvatarFallback>
            </Avatar>
          ))}
        </div>

        <div className="min-w-0 flex-1">
          <div className="truncate font-medium">
            <ThreadListItemPrimitive.Title fallback={lang === "ja" ? "新しい会話" : "New chat"} />
          </div>
          <div className={cn("mt-0.5 flex items-center gap-1 text-[11px]", isActive ? "text-white/80" : "text-muted-foreground")}>
            <SparklesIcon className="size-3" />
            <span className="truncate">
              {session?.mode === "group" ? (lang === "ja" ? `ルーム / ${characterName}` : `Room / ${characterName}`) : characterName}
            </span>
          </div>
        </div>
      </ThreadListItemPrimitive.Trigger>
      <ThreadListItemMore />
    </ThreadListItemPrimitive.Root>
  );
};

const ThreadListItemMore: FC = () => {
  const { lang } = useLanguage();
  const itemRuntime = useThreadListItemRuntime({ optional: true });
  const title = useThreadListItem({ optional: true, selector: (s: { title?: string }) => s.title });

  return (
    <ThreadListItemMorePrimitive.Root>
      <ThreadListItemMorePrimitive.Trigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="aui-thread-list-item-more mr-1 size-8 rounded-xl p-0 opacity-0 transition-opacity group-hover:opacity-100 data-[state=open]:bg-accent data-[state=open]:opacity-100 group-data-active:opacity-100"
        >
          <MoreHorizontalIcon className="size-4" />
          <span className="sr-only">{lang === "ja" ? "その他の操作" : "More options"}</span>
        </Button>
      </ThreadListItemMorePrimitive.Trigger>
      <ThreadListItemMorePrimitive.Content
        side="bottom"
        align="start"
        className="aui-thread-list-item-more-content z-50 min-w-32 overflow-hidden rounded-xl border bg-popover p-1 text-popover-foreground shadow-md"
      >
        <ThreadListItemMorePrimitive.Item
          className="aui-thread-list-item-more-item flex cursor-pointer select-none items-center gap-2 rounded-lg px-2 py-1.5 text-sm outline-none hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground"
          onSelect={() => {
            if (!itemRuntime) return;
            const next = prompt(lang === "ja" ? "会話名を変更する" : "Rename conversation", title ?? "");
            if (!next) return;
            itemRuntime.rename(next);
          }}
        >
          <PencilIcon className="size-4" />
          {lang === "ja" ? "名前を変更" : "Rename"}
        </ThreadListItemMorePrimitive.Item>

        <ThreadListItemPrimitive.Delete asChild>
          <ThreadListItemMorePrimitive.Item className="aui-thread-list-item-more-item flex cursor-pointer select-none items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-destructive outline-none hover:bg-accent focus:bg-accent">
            <TrashIcon className="size-4" />
            {lang === "ja" ? "削除" : "Delete"}
          </ThreadListItemMorePrimitive.Item>
        </ThreadListItemPrimitive.Delete>
      </ThreadListItemMorePrimitive.Content>
    </ThreadListItemMorePrimitive.Root>
  );
};
