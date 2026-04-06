import OpenAI from "openai";

let readingClient: OpenAI | null | undefined;

function getReadingClient(): OpenAI | null {
  if (readingClient !== undefined) return readingClient;
  const apiKey = String(process.env.OPENAI_API_KEY ?? "").trim();
  if (!apiKey) {
    readingClient = null;
    return readingClient;
  }
  readingClient = new OpenAI({ apiKey });
  return readingClient;
}

export async function generateTtsReadingText(params: {
  characterId: string;
  replyText: string;
}): Promise<{ readingText: string | null; model: string | null }> {
  const replyText = String(params.replyText ?? "").trim();
  if (!replyText) return { readingText: null, model: null };

  const client = getReadingClient();
  const model = String(process.env.SIGMARIS_PERSONA_MODEL ?? "gpt-5.2").trim() || "gpt-5.2";
  if (!client) return { readingText: null, model };

  try {
    const completion = await client.chat.completions.create(
      {
        model,
        temperature: 0.1,
        max_completion_tokens: 220,
        messages: [
          {
            role: "system",
            content:
              "You rewrite Japanese dialogue into TTS-friendly reading text. Preserve meaning and tone, but optimize pronunciation for speech synthesis.",
          },
          {
            role: "developer",
            content: [
              "Return only the reading text. No JSON, no quotes, no commentary.",
              "Keep the wording as close as possible to the displayed reply, but change kanji, symbols, spacing, and punctuation when that improves TTS pronunciation.",
              "Prefer hiragana or simple Japanese readings for proper nouns, difficult kanji, fantasy terms, English words, numbers, symbols, and abbreviations when needed.",
              "Do not add new information. Do not summarize. Do not change the character's intent or attitude.",
              "Keep short pauses natural for speech synthesis. Avoid awkward repeated punctuation.",
              "If the original text is already easy to read aloud, return something very close to it.",
              `character_id=${params.characterId}`,
            ].join("\n"),
          },
          {
            role: "user",
            content: replyText,
          },
        ],
      },
      {
        signal: AbortSignal.timeout(8000),
      }
    );

    const readingText = String(completion.choices[0]?.message?.content ?? "").trim();
    if (!readingText) return { readingText: null, model };
    return { readingText, model };
  } catch (error) {
    console.warn("[touhou] tts reading generation failed:", error);
    return { readingText: null, model };
  }
}
