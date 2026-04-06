import { NextRequest, NextResponse } from "next/server";
import { extractUrls } from "@/lib/server/session-message-v2/retrieval";
import type { ParsedSessionMessageRequestBody } from "@/lib/server/session-message-v2/types";

export async function parseSessionMessageRequestBody(
    req: NextRequest,
): Promise<ParsedSessionMessageRequestBody | Response> { 
    const contentType = req.headers.get("content-type") ?? "";
    if (!contentType.includes("multipart/form-data")) { 
        return NextResponse.json(
            { error: "multipart/form-data required" },
            { status: 400 },
        );
    }

    const formData = await req.formData();

    const characterId = formData.get("characterId");
    const text = formData.get("text");
    const coreModeRaw = formData.get("coreMode");
    const sceneModeRaw = formData.get("sceneMode");
    const sceneTurnCountRaw = formData.get("sceneTurnCount");

    if (
        typeof characterId !== "string" ||
        typeof text !== "string" ||
        !characterId ||
        !text.trim()
    ) { 
        return NextResponse.json({ error: "Invalid request body" }, { status: 400 });
    }

    const files = formData.getAll("files").filter((f): f is File => f instanceof File);
    const urls = extractUrls(text);
    const sceneMode =
        sceneModeRaw === "continue" ? "continue" : "chat";
    const sceneTurnCountNumber =
        typeof sceneTurnCountRaw === "string" ? Number(sceneTurnCountRaw) : NaN;
    const sceneTurnCount =
        sceneMode === "continue" && Number.isFinite(sceneTurnCountNumber)
            ? Math.max(1, Math.min(4, Math.trunc(sceneTurnCountNumber)))
            : 1;

    return {
        characterId,
        text,
        coreModeRaw,
        sceneMode,
        sceneTurnCount,
        files,
        urls,
    };
}
