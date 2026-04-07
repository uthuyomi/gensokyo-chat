"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

import { supabaseBrowser } from "@/lib/supabaseClient";

export default function EntryAutoRedirect(props: { enabled?: boolean }) {
  const router = useRouter();

  useEffect(() => {
    if (!props.enabled) return;

    let alive = true;

    const run = async () => {
      const { data, error } = await supabaseBrowser().auth.getUser();
      if (!alive) return;
      if (error) return;
      if (data.user) {
        router.replace("/chat/session");
      }
    };

    void run();

    const { data: listener } = supabaseBrowser().auth.onAuthStateChange(
      (_event, session) => {
        if (!alive) return;
        if (session?.user) {
          router.replace("/chat/session");
        }
      },
    );

    return () => {
      alive = false;
      listener.subscription.unsubscribe();
    };
  }, [props.enabled, router]);

  return null;
}
