"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import type { User } from "@supabase/supabase-js";
import { supabaseBrowser } from "@/lib/supabaseClient";
import Link from "next/link";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { TooltipIconButton } from "@/components/assistant-ui/tooltip-icon-button";
import { CogIcon, LogOutIcon, UserIcon } from "lucide-react";

export default function StatusHeader() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [authChecked, setAuthChecked] = useState(false);

  useEffect(() => {
    const fetchUser = async () => {
      const { data } = await supabaseBrowser().auth.getUser();
      setUser(data.user ?? null);
      setAuthChecked(true);
    };

    fetchUser();

    const { data: listener } = supabaseBrowser().auth.onAuthStateChange(() => {
      fetchUser();
    });

    return () => {
      listener.subscription.unsubscribe();
    };
  }, []);

  const logout = async () => {
    await supabaseBrowser().auth.signOut();
    router.push("/");
  };

  if (!authChecked) return null;
  if (!user) return null;

  const md = (user.user_metadata ?? {}) as Record<string, unknown>;
  const avatarUrl = typeof md.avatar_url === "string" ? md.avatar_url : null;
  const displayName =
    (typeof md.full_name === "string" && md.full_name) ||
    (typeof md.name === "string" && md.name) ||
    (typeof md.user_name === "string" && md.user_name) ||
    user.email ||
    "User";

  return (
    <header className="relative z-30 h-12">
      <div className="flex h-full items-center justify-end gap-3 px-4">
        <div className="flex min-w-0 items-center gap-2 rounded-2xl border border-white/10 bg-black/20 px-2 py-1.5 text-white/90 backdrop-blur">
          <Avatar className="size-8 border border-white/20 bg-black/20">
            <AvatarImage src={avatarUrl ?? undefined} alt="User avatar" />
            <AvatarFallback>
              <UserIcon className="size-4" />
            </AvatarFallback>
          </Avatar>
          <div className="min-w-0">
            <div className="truncate text-sm font-medium">{displayName}</div>
          </div>
        </div>

        <TooltipIconButton
          tooltip="Settings"
          asChild
          variant="secondary"
          size="icon-sm"
          className="rounded-xl bg-white/80 text-black hover:bg-white"
        >
          <Link href="/settings" aria-label="Settings">
            <CogIcon className="size-4" />
          </Link>
        </TooltipIconButton>

        <TooltipIconButton
          type="button"
          onClick={logout}
          tooltip="Log out"
          variant="secondary"
          size="icon-sm"
          className="rounded-xl bg-white/80 text-black hover:bg-white"
          aria-label="Log out"
        >
          <LogOutIcon className="size-4" />
        </TooltipIconButton>
      </div>
    </header>
  );
}
