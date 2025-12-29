import Gio from "gi://Gio";
import GLib from "gi://GLib";
import Soup from "gi://Soup?version=3.0";
import AstalIO from "gi://AstalIO";
import { createState, Accessor } from "ags";

AstalIO.write_file(`/tmp/aiHistory.json`, "[ ]");

export enum Role {
  USER = "user",
  BOT = "bot"
}

export interface ServiceMessage {
  role: Role;
  content: string;
}

interface GPTStreamChunk {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: Array<{
    index: number;
    delta: {
      role?: string;
      content?: string;
    };
    finish_reason: string | null;
  }>;
}

export type MessageState = {
  id: number;
  role: Role;
  content: Accessor<string>;
  setContent: (v: string | ((prev: string) => string)) => void;
  thinking: Accessor<boolean>;
  setThinking: (v: boolean) => void;
  done: Accessor<boolean>;
  setDone: (v: boolean) => void;
  rawData: Accessor<string>;
  setRawData: (v: string) => void;
};

const [messages, setMessages] = createState<MessageState[]>([]);
const ENV_KEY = "" //GLib.getenv("OPENAI_API_KEY");
let _temperature = 0.3;

const listeners = new Map<string, ((...args: any[]) => void)[]>();
const emit = (event: string, ...args: any[]) => {
  const l = listeners.get(event) || [];
  l.forEach((cb) => cb(...args));
};
export const connect = (event: string, cb: (...args: any[]) => void) => {
  if (!listeners.has(event)) listeners.set(event, []);
  listeners.get(event)!.push(cb);
  return () => {
    const arr = listeners.get(event) || [];
    listeners.set(event, arr.filter((c) => c !== cb));
  };
};

const newMessage = (role: Role, initialContent: string, thinking = true, done = false) => {
  const id = messages.peek().length;
  const [content, setContent] = createState(initialContent);
  const [thinkingState, setThinking] = createState(thinking);
  const [doneState, setDone] = createState(done);
  const [rawData, setRawData] = createState("");
  const msg: MessageState = {
    id,
    role,
    content,
    setContent: (v: string | ((prev: string) => string)) => {
      setContent(typeof v === "function" ? v(content.peek()) : v);
    },
    thinking: thinkingState,
    setThinking,
    done: doneState,
    setDone,
    rawData,
    setRawData,
  };
  setMessages([...messages.peek(), msg]);
  emit("new-msg", id);
  return msg;
};

export const getMessages = () => messages; // Accessor
export const getMessage = (id: number) => messages.peek()[id];

export const saveHistory = () => {
  const toSave: ServiceMessage[] = messages.peek().map((m) => ({
    role: m.role,
    content: m.content.peek(),
  }));
  AstalIO.write_file("/tmp/aiHistory.json", JSON.stringify(toSave));
};

export const appendHistory = () => {
  try {
    const readfile = AstalIO.read_file("/tmp/aiHistory.json");
    const historyMessages: ServiceMessage[] = JSON.parse(readfile || "[]");
    historyMessages.forEach((h) => newMessage(h.role, h.content, false, false));
  } catch (e) {
    console.log("Failed to load history", { err: e });
  }
};

export const clear = () => {
  saveHistory();
  setMessages([]);
  emit("clear");
};

const decoder = new TextDecoder();

export const readResponse = (stream: Gio.DataInputStream, aiMsg: MessageState) => {
  let buffer = "";

  const readNextLine = () => {
    stream.read_line_async(0, null, (streamRef, res) => {
      try {
        if (!streamRef) return;
        const [bytes] = streamRef.read_line_finish(res);
        if (!bytes) return;

        const line = decoder.decode(bytes);
        buffer += line + "\n";

        const chunks = buffer.split("\n\n");
        buffer = chunks.pop() || "";

        for (const chunk of chunks) {
          if (chunk.trim() === "") continue;
          const lines = chunk.split("\n").filter((l) => l.trim() !== "");
          for (const l of lines) {
            if (l.startsWith("data: ")) {
              const data = l.slice(6);
              if (data === "[DONE]") {
                aiMsg.setDone(true);
                aiMsg.setThinking(false);
                emit("finished", aiMsg.id);
                return;
              }
              try {
                const parsed = JSON.parse(data) as GPTStreamChunk;
                const delta = parsed.choices[0]?.delta?.content;
                if (delta) {
                  aiMsg.setThinking(false);
                  aiMsg.setContent((prev) => prev + delta);
                }
              } catch (e) {
                console.log("Cant parse GPT res chunk", { e, data });
              }
            }
          }
        }
        readNextLine();
      } catch (e) {
        console.log("Error reading stream", { message: (e as Error).message });
      }
    });
  };

  readNextLine();
};

export const isKeySet = () => ENV_KEY.length > 0;

export const addMessage = (role: Role, content: string) => {
  return newMessage(role, content, role === Role.BOT, role === Role.USER);
};

export const send = (msg: string) => {
  addMessage(Role.USER, msg);

  const aiMsg = newMessage(Role.BOT, "Thinking...", true, false);

  const body = {
    model: "GPT-4",
    messages: messages
      .peek()
      .map((m) => ({ role: m.role.toLowerCase(), content: m.content.peek() })),
    temperature: _temperature,
    max_tokens: 1024,
    stream: true,
  };

  const currentKey = ENV_KEY || "";

  const session = new Soup.Session();
  const message = new Soup.Message({
    method: "POST",
    uri: GLib.Uri.parse("https://api.openai.com/v1/chat/completions", GLib.UriFlags.NONE),
  });

  message.request_headers.append("Content-Type", "application/json");
  message.request_headers.append("Authorization", `Bearer ${currentKey}`);
  message.set_request_body_from_bytes(
    "application/json",
    new GLib.Bytes(JSON.stringify(body) as unknown as Uint8Array),
  );

  session.send_async(message, GLib.PRIORITY_DEFAULT, null, (_, result) => {
    try {
      const stream = session.send_finish(result);
      if (message.status_code !== 200) {
        const bytes = stream.read_bytes(8192, null);
        const errorText = bytes ? new TextDecoder().decode(bytes.toArray()) : "Unknown error";
        aiMsg.setDone(true);
        aiMsg.setThinking(false);
        aiMsg.setContent(`API Error (${message.status_code}): ${message.reason_phrase}\n${errorText}`);
        emit("finished", aiMsg.id);
        return;
      }

      readResponse(
        new Gio.DataInputStream({ close_base_stream: true, base_stream: stream }),
        aiMsg,
      );
    } catch (err) {
      aiMsg.setDone(true);
      aiMsg.setThinking(false);
      aiMsg.setContent(`Failed to connect to OpenAI API: ${err}`);
      emit("finished", aiMsg.id);
    }
  });
};

export const init = () => {
  appendHistory();
  emit("initialized");
};

export default {
  messages, // Accessor
  getMessages,
  getMessage,
  addMessage,
  send,
  clear,
  connect,
  init
};