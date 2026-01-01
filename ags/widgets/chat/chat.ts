import Gio from "gi://Gio";
import GLib from "gi://GLib";
import Soup from "gi://Soup?version=3.0";
import { createState, Accessor } from "ags";
import { readFile } from "ags/file";

export enum Role {
  USER = "user",
  ASSISTANT = "assistant"
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

export const [ messages, setMessages ] = createState<MessageState[]>([]);
const ENV_KEY = readFile('/home/alec/GroqAIKey').trim();
const temperature = 0.3; // Lower = more deterministic

const newMessage = (role: Role, initialContent: string, thinking = true, done = false) => {
  const [ content, setContent ] = createState(initialContent);
  const [ thinkingState, setThinking ] = createState(thinking);
  const [ doneState, setDone ] = createState(done);
  const [ rawData, setRawData ] = createState("");

  const msg: MessageState = {
    role,
    content,
    setContent: (v) => setContent(typeof v === "function" ? v(content.peek()) : v),
    thinking: thinkingState,
    setThinking,
    done: doneState,
    setDone,
    rawData,
    setRawData,
  };

  setMessages([...messages.peek(), msg]);
  return msg;
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
                aiMsg.setContent((self) => self + ' '); // Update content once more to apply formatting
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

export const sendMessage = (msg: string) => {
  if (msg === '')
    return

  newMessage(Role.USER, msg);

  const body = {
    model: "openai/gpt-oss-120b",
    messages: messages.peek()
      .map((m) => ({ role: m.role, content: m.content.peek() })),
    temperature,
    citation_options: 'disabled',
    include_reasoning: true,
    max_completion_tokens: 2048, // 1024
    stream: true
  };

  const aiResponseMessage = newMessage(Role.ASSISTANT, "", true, false);

  const session = new Soup.Session();
  const message = new Soup.Message({
    method: "POST",
    uri: GLib.Uri.parse("https://api.groq.com/openai/v1/chat/completions", GLib.UriFlags.NONE),
  });

  message.request_headers.append("Authorization", `Bearer ${ENV_KEY}`);
  message.request_headers.append("Content-Type", "application/json");

  message.set_request_body_from_bytes(
    "application/json",
    new GLib.Bytes(JSON.stringify(body) as unknown as Uint8Array),
  );

  session.send_async(message, GLib.PRIORITY_DEFAULT, null, (_, result) => {
    try {
      const stream = session.send_finish(result);

      if (message.status_code !== 200) {
        const bytes = stream.read_bytes(8192, null);
        const errorText = bytes ? decoder.decode(bytes.toArray()) : "Unknown error";
        aiResponseMessage.setDone(true);
        aiResponseMessage.setThinking(false);
        aiResponseMessage.setContent(`API Error (${message.status_code}): ${message.reason_phrase}\n${errorText}`);
        return;
      }

      readResponse(
        new Gio.DataInputStream({ close_base_stream: true, base_stream: stream }),
        aiResponseMessage,
      );
    } catch (err) {
      aiResponseMessage.setDone(true);
      aiResponseMessage.setThinking(false);
      aiResponseMessage.setContent(`Failed to connect to API: ${err}`);
    }
  });
};
