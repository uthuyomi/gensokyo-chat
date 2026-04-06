export type HelloAuth =
  | { mode: "supabase_jwt"; access_token: string }
  | undefined;

export type ClientMsg =
  | { type: "hello"; auth?: HelloAuth }
  | { type: "subscribe"; channel: string; lastSeq?: number }
  | { type: "unsubscribe"; channel: string };

export type ServerMsg =
  | { type: "ack"; hello?: boolean }
  | { type: "snapshot"; channel: string; fromSeq: number; events: unknown[] }
  | { type: "event"; channel: string; event: unknown }
  | { type: "error"; code: string; message: string };

export type WorldEventRow = {
  id: string;
  channel: string;
  seq: number;
  ts: string;
  world_id: string;
  layer_id: string;
  location_id: string | null;
  type: string;
  actor: unknown;
  payload: unknown;
};
