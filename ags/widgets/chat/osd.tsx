import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
const { TOP, BOTTOM, RIGHT } = Astal.WindowAnchor;
import ChatMessage from "./modules/chat-message";
import { createState, For, State } from "ags";

import gptService from "./chat";

const [input, setInput] = createState("")

const [chatContent, setChatContent] = createState<[number, Gtk.Widget][]>([]);

gptService.connect("new-msg", (source: any, id: number) => {
  console.log("GPT service new message", { messageId: id });
  setChatContent([
    ...chatContent.peek(),
    [id,
    ChatMessage('user', 'e')]
  ]);
});

const appendChatContent = (newContent: Gtk.Widget) => {
  console.log("Appending chat content");
  const maxKey = Math.max(...chatContent.peek().map(([k]) => k));
  console.log("Chat content", { lastKey: maxKey });
  setChatContent([
    ...chatContent.peek(),
    [maxKey + 1, newContent]
  ]);

  console.log("Chat content updated", { size: chatContent.peek().length });
};

const clearChat = () => {
  setChatContent([]);
};

const sendMessage = (message: string) => {
  const trimmedMessage = message.trim();
  console.log("Sending message", { message: trimmedMessage });
  setInput("");
  gptService.send(trimmedMessage);
};

const sendMessageReturn = () => {
  sendMessage(input.peek());
};

const sendMessageClick = () => {
  sendMessage(input.peek());
};

// Allow for newlines
const handleKeyPress = (self: Gtk.Entry, keyval: number) => {
  if (keyval === Gdk.KEY_Return || keyval === Gdk.KEY_KP_Enter) {
    if (self.get_text().trim().length > 0)
      sendMessageReturn?.();
    return true;
  }
  return false;
};


export default () =>
  <window
    name="chat"
    exclusivity={Astal.Exclusivity.EXCLUSIVE}
    keymode={Astal.Keymode.ON_DEMAND}
    anchor={TOP | BOTTOM | RIGHT}
    application={app}
    widthRequest={450}
  >
    <box orientation={Gtk.Orientation.VERTICAL} vexpand>
      <box cssClasses={["header"]}>
        <label label="Chat Agent"/>
        <button onClicked={clearChat} hexpand halign={Gtk.Align.END}>
          <image iconName="user-trash-symbolic"/>
        </button>
      </box>

      <Gtk.ScrolledWindow
        vscrollbar_policy={Gtk.PolicyType.AUTOMATIC}
        hscrollbar_policy={Gtk.PolicyType.NEVER}
        vexpand
      >
        <box orientation={Gtk.Orientation.VERTICAL} vexpand hexpand>
          <For each={chatContent}>
            {([_, widget]) => widget}
          </For>
        </box>
      </Gtk.ScrolledWindow>
      <box cssClasses={["messageArea"]}>
        <entry
          placeholderText="Type here"
          hexpand
          onActivate={(self) => {
            if (self.text.length > 0) 
              sendMessageReturn?.();
          }}
          $={(self) => {
            self.grab_focus();

            const keyController = new Gtk.EventControllerKey();
            keyController.connect("key-pressed", (_, keyval, __, ___) => handleKeyPress(self, keyval));
            self.add_controller(keyController);
          }}
        />
        <button onClicked={sendMessageClick}>
          <image iconName="mail-reply-sender-symbolic"/>
        </button>
      </box>
    </box>
  </window>
