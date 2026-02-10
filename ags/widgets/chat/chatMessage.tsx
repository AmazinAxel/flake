import Gtk from "gi://Gtk?version=4.0";
import { With } from "ags";
import { MessageState, Role } from "./chatService";

export default ({ role, message }: { role: Role; message: MessageState }) => {
  if (role === Role.SYSTEM)
    return <box/>;

  const isUser = role === Role.USER;

  return (
    <box
      halign={isUser ? Gtk.Align.START : Gtk.Align.FILL}
      hexpand={!isUser}
      cssClasses={[(isUser ? 'user' : 'bot'), 'message']}
    >
      <With value={message.content}>
        {(content) => (
          <label
            label={content.replace(/&(?!amp;)/g, '&amp;')}
            useMarkup={message.done.peek()}
            wrap
            selectable
          />
        )}
      </With>
    </box>
  );
};
