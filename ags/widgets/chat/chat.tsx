import app from "ags/gtk4/app";
import { createState } from "ags";
import sideWindow from "../../lib/sideWindow";

const [ width, setWidth ] = createState(400);

export const toggleChatSize = () => {
  const next = (width.peek() == 400) ? 700 : 400;
  setWidth(next);
  app.get_window('chat')?.set_default_size(next, -1);
};

export default sideWindow("chat", "https://claude.ai/new", width);
