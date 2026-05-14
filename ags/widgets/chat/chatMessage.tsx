import Gtk from "gi://Gtk?version=4.0";
import Pango from "gi://Pango";
import { With } from "ags";
import md2pango from "../../lib/md2pango";
import { MessageState, Role } from "./chatService";

const RE_TABLE_SEP = /^\|?(\s*:?-+:?\s*\|)+\s*:?-+:?\s*\|?\s*$/;

function splitBlocks(markdown: string): Array<{isTable: boolean; content: string}> {
  const lines = markdown.split('\n');
  const blocks: Array<{isTable: boolean; content: string}> = [];
  let i = 0;
  let textLines: string[] = [];

  while (i < lines.length) {
    if (lines[i].includes('|') && i + 1 < lines.length && RE_TABLE_SEP.test(lines[i + 1])) {
      if (textLines.length > 0) {
        blocks.push({isTable: false, content: textLines.join('\n')});
        textLines = [];
      }
      const tableLines: string[] = [];
      while (i < lines.length && lines[i].includes('|')) {
        tableLines.push(lines[i]);
        i++;
      }
      blocks.push({isTable: true, content: tableLines.join('\n')});
    } else {
      textLines.push(lines[i]);
      i++;
    }
  }

  if (textLines.length > 0)
    blocks.push({isTable: false, content: textLines.join('\n')});

  return blocks;
}

const textLabel = (text: string, useMarkup: boolean) =>
  <label
    label={text}
    useMarkup={useMarkup}
    wrap
    wrapMode={Pango.WrapMode.WORD_CHAR}
    selectable
    xalign={0}
  />;

export default ({ role, message }: { role: Role; message: MessageState }) => {
  if (role === Role.SYSTEM)
    return <box/>;

  const isUser = role === Role.USER;

  return (
    <box
      halign={isUser ? Gtk.Align.START : Gtk.Align.FILL}
      hexpand={!isUser}
      cssClasses={[(isUser ? 'user' : 'bot'), 'message']}
      orientation={Gtk.Orientation.VERTICAL}
    >
      <With value={message.content}>
        {(content) => {
          if (!message.done.peek())
            return textLabel(content, false);

          const blocks = splitBlocks(content);
          if (blocks.length === 1 && !blocks[0].isTable)
            return textLabel(md2pango(blocks[0].content), true);

          return <box orientation={Gtk.Orientation.VERTICAL}>
            {blocks.map(block =>
              block.isTable
                ? <Gtk.ScrolledWindow
                    vscrollbarPolicy={Gtk.PolicyType.NEVER}
                    hscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
                    hexpand
                  >
                    <label label={md2pango(block.content)} useMarkup selectable xalign={0}/>
                  </Gtk.ScrolledWindow>
                : textLabel(md2pango(block.content), true)
            )}
          </box>;
        }}
      </With>
    </box>
  );
};
