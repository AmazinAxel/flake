import { Gtk } from "ags/gtk4";
import ChatMessageContent from "./chat-message-content";
import { MessageState, Role } from "../chat";

export default (role: Role, message: MessageState): Gtk.Box => {
  const isUser = (role == Role.USER);

  return <box orientation={Gtk.Orientation.VERTICAL} halign={isUser ? Gtk.Align.START : Gtk.Align.END} hexpand cssClasses={[(isUser ? 'user' : 'bot'), 'message']}>
    {ChatMessageContent(message)}
  </box>
};
