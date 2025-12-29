import { Gtk } from "ags/gtk4";

export interface ChatContentProps {
  content: Array<Gtk.Widget>;
  setUpdateCompleted: () => void;
}

export const ChatContent = (props: ChatContentProps) => {
  console.log("ChatContent component created", { contentCount: props.content.length });

  const updateContent = () => {
    props.setUpdateCompleted();
  };

  return (
    <box cssClasses={["spacing-v-5"]} orientation={Gtk.Orientation.VERTICAL}>
      {props.content}
    </box>
  );
}
