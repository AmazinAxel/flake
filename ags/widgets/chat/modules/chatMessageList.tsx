import { messages } from "../chat";
import { For } from "ags";
import ChatMessage from "./chatMessage";
import { Gtk } from "ags/gtk4";

export default () => 
  <box orientation={Gtk.Orientation.VERTICAL} vexpand hexpand>
    <For each={messages}>
      {(msg) => <ChatMessage role={msg.role} message={msg} />}
    </For>
  </box>
