import { Gtk } from "ags/gtk4";
import GLib from "gi://GLib";
import ChatMessageContent from "./chat-message-content";
import { createState, State } from "ags";


const ChatMessageLoadingSkeleton = () => (
  <box
    orientation={Gtk.Orientation.VERTICAL}
    cssName="spacing-v-5"
    children={Array.from({ length: 3 }, () => <box cssName={`aiSkeleton`}/> )}
  />
);

export const ChatMessage = (role: string, message: string): Gtk.Box => {
  const isUser = role === "user";

  const [ displayMessage, setDisplayMessage ] = createState(message);

  return <box orientation={Gtk.Orientation.VERTICAL} halign={isUser ? Gtk.Align.START : Gtk.Align.END} hexpand cssClasses={[(isUser ? 'user' : 'bot'), 'message']}>
    <ChatMessageLoadingSkeleton/>
    {ChatMessageContent(displayMessage)}
    <label label={message}/>
  </box>
};

export default ChatMessage;
