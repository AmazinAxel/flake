import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
const { TOP, BOTTOM, RIGHT } = Astal.WindowAnchor;
import { createState, For } from "ags";

import { sendMessage } from "./chat";

const [ input, setInput ] = createState("")

export const [ chatContent, setChatContent ] = createState(
  new Array<Gtk.Widget>()
)

const sendMessageReturn = () => {
  sendMessage(input.peek());
  setInput("");
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
        <button onClicked={() => setChatContent([])} hexpand halign={Gtk.Align.END}>
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
            {(w) => w}
          </For>
        </box>
      </Gtk.ScrolledWindow>
      <box cssClasses={["messageArea"]}>
        <entry
          placeholderText="Type here"
          text={input}
          onNotifyText={(self) => setInput(self.text)}
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
        <button onClicked={sendMessageReturn}>
          <image iconName="mail-reply-sender-symbolic"/>
        </button>
      </box>
    </box>
  </window>
