import { NextRequest, NextResponse } from "next/server";
import { extractUrls } from "@/lib/server/session-message-v2/retrieval";
import type { ParsedSessionMessageRequestBody } from "@/lib/server/session-message-v2/types";

export function buildImplicitAttachmentMessage(files: File[]): string {
    const visible = files
        .slice(0, 3)
        .map((file) => String(file.name || "").trim())
        .filter(Boolean);
    const fileList = visible.length > 0 ? ` (${visible.join(", ")})` : "";
    return `添付ファイル${fileList}を確認して、内容を説明してください。`;
}

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
    const files = formData.getAll("files").filter((f): f is File => f instanceof File);

    if (
        typeof characterId !== "string" ||
        typeof text !== "string" ||
        !characterId ||
        (!text.trim() && files.length === 0)
    ) { 
        return NextResponse.json({ error: "Invalid request body" }, { status: 400 });
    }

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
