import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
const { TOP, BOTTOM, RIGHT } = Astal.WindowAnchor;
import { createState, For } from "ags";
import { instructions, messages, sendMessage, setMessages } from "./chatService";
import ChatMessage from "./chatMessage";
let inputBuffer = new Gtk.TextBuffer;

export const [ chatContent, setChatContent ] = createState(new Array<Gtk.Widget>());

const [ width, setWidth ] = createState(400);
const [ expandIcon, setExpandIcon ] = createState("view-fullscreen-symbolic");

const toggleSize = () => {
  setWidth((width.peek() == 400) ? 700 : 400)
  setExpandIcon((width.peek() == 400) ? 'view-fullscreen-symbolic' : 'view-restore-symbolic')
  app.get_window('chat')?.set_default_size(width.peek(), -1)
};

const clearChat = () => {
  setChatContent([])
  setMessages([instructions]);
  app.get_window('chat')?.set_default_size(width.peek(), -1)
};

// Check for enter key but allow newlines
const handleKeyPress = (keyval: number, state: Gdk.ModifierType) => {
  const shiftHeld = (state & Gdk.ModifierType.SHIFT_MASK) !== 0;

  const isEnter = keyval === Gdk.KEY_Return || keyval === Gdk.KEY_KP_Enter;

  if (isEnter && !shiftHeld) {
    const start = inputBuffer.get_start_iter();
    const end = inputBuffer.get_end_iter();

    sendMessage(inputBuffer.get_text(start, end, true));
    inputBuffer.delete(start, end);
    return true; // block newline
  }

  if (isEnter && shiftHeld)
    return false; // let GTK insert newline

  return false;
};

export default () =>
  <window
    name="chat"
    exclusivity={Astal.Exclusivity.EXCLUSIVE}
    keymode={Astal.Keymode.EXCLUSIVE}
    anchor={TOP | BOTTOM | RIGHT}
    application={app}
    layer={Astal.Layer.OVERLAY}
    widthRequest={width}
  >
    <box orientation={Gtk.Orientation.VERTICAL} vexpand>
      <box cssClasses={["header"]}>
        <button onClicked={() => toggleSize()}>
          <image iconName={expandIcon}/>
        </button>

        <label label="Chat" hexpand halign={Gtk.Align.CENTER}/>
        <button onClicked={() => clearChat()} halign={Gtk.Align.END}>
          <image iconName="user-trash-symbolic"/>
        </button>
      </box>

      <Gtk.ScrolledWindow
        vscrollbar_policy={Gtk.PolicyType.AUTOMATIC}
        hscrollbar_policy={Gtk.PolicyType.NEVER}
        vexpand
      >
        <box orientation={Gtk.Orientation.VERTICAL} vexpand hexpand>
          <For each={messages}>
            {(msg) => <ChatMessage role={msg.role} message={msg}/>}
          </For>
        </box>
      </Gtk.ScrolledWindow>
      <Gtk.TextView
        hexpand
        buffer={inputBuffer}
        cssClasses={['input']}
        $={(self) => {
          app.connect("window-toggled", () =>
            (app.get_window("launcher")?.visible == true)
              && self.grab_focus()
          );

          const key = new Gtk.EventControllerKey();
          self.add_controller(key);
          key.connect("key-pressed", (_, keyval, __, state) => handleKeyPress(keyval, state))
        }}
      />
    </box>
  </window>
