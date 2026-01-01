import app from "ags/gtk4/app"
import { Astal, Gdk, Gtk } from "ags/gtk4"
const { TOP, BOTTOM, RIGHT } = Astal.WindowAnchor;
import { createState, For } from "ags";
import { sendMessage, setMessages } from "./chat";
import ChatMessageList from "./modules/chatMessageList";
let inputBuffer = new Gtk.TextBuffer;

export const [ chatContent, setChatContent ] = createState(new Array<Gtk.Widget>())

const clearChat = () => {
  setChatContent([])
  setMessages([])
}

const toggleSize = () => app.get_window('chat')?.set_default_size(700, -1)

const sendMessageReturn = () => {
  const start = inputBuffer.get_start_iter();
  const end = inputBuffer.get_end_iter();

  sendMessage(inputBuffer.get_text(start, end, true));
  inputBuffer.delete(start, end);
};

// Allow newlines
const handleKeyPress = (keyval: number, state: Gdk.ModifierType) => {
  const shiftHeld = (state & Gdk.ModifierType.SHIFT_MASK) !== 0;

  const isEnter = keyval === Gdk.KEY_Return || keyval === Gdk.KEY_KP_Enter;

  if (isEnter && !shiftHeld) {
    sendMessageReturn();
    return true; // block newline
  }

  if (isEnter && shiftHeld) {
    return false; // let GTK insert newline
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
        <button onClicked={() => toggleSize()}>
          <image iconName="view-fullscreen-symbolic"/>
        </button>

        <label label="Chat Agent" hexpand halign={Gtk.Align.CENTER}/>
        <button onClicked={() => clearChat()} halign={Gtk.Align.END}>
          <image iconName="user-trash-symbolic"/>
        </button>
      </box>

      <Gtk.ScrolledWindow
        vscrollbar_policy={Gtk.PolicyType.AUTOMATIC}
        hscrollbar_policy={Gtk.PolicyType.NEVER}
        vexpand
      >
        <ChatMessageList/>
      </Gtk.ScrolledWindow>
      <Gtk.TextView
        hexpand
        buffer={inputBuffer}
        $={(self) => {
          self.grab_focus();
          const key = new Gtk.EventControllerKey();
          self.add_controller(key);
          key.connect("key-pressed", (_, keyval, __, state) => handleKeyPress(keyval, state))
        }}
      />
    </box>
  </window>
