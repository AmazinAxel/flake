import { Gtk } from "ags/gtk4";
import GtkSource from "gi://GtkSource?version=5";

function substituteLang(str: string) {
  const subs = [
    { from: "javascript", to: "js" },
    { from: "typescript", to: "js" },
    { from: "ts", to: "js" },
    { from: "bash", to: "sh" },
    { from: "shell", to: "sh" },
    { from: "json", to: "json" },
    { from: "python", to: "python3" }
  ];
  for (const { from, to } of subs) {
    if (from === str) return to;
  }
  return str;
}

export const HighlightedCode = (content: string, lang: string) => {
  const contentStr = typeof content === 'string' ? content : String(content || '');

  const buffer = new GtkSource.Buffer();
  const sourceView = new GtkSource.View({
    buffer: buffer,
    wrap_mode: Gtk.WrapMode.NONE,
    editable: false,
    cursor_visible: false,
    monospace: true,
    show_line_numbers: true,
    show_line_marks: false,
    right_margin_position: 80,
    show_right_margin: false,
    tab_width: 2,
    indent_width: 2,
    highlight_current_line: false,
    background_pattern: GtkSource.BackgroundPatternType.NONE,
  });

  const langManager = GtkSource.LanguageManager.get_default();
  let displayLang = langManager.get_language(substituteLang(lang));
  if (displayLang) {
    buffer.set_language(displayLang);
  }

  const schemeManager = GtkSource.StyleSchemeManager.get_default();
  let scheme = schemeManager.get_scheme('Adwaita-dark');

  if (scheme) {
    buffer.set_style_scheme(scheme);
  }

  buffer.set_text(contentStr, -1);
  sourceView.set_left_margin(8);
  sourceView.set_right_margin(8);
  sourceView.set_top_margin(4);
  sourceView.set_bottom_margin(4);

  return sourceView;
};

interface ChatCodeBlockProps {
  content?: string;
  lang?: string;
}

export const ChatCodeBlock = (props: ChatCodeBlockProps) => {
  const { content = "", lang = "txt" } = props;

  // Ensure both content and lang are strings
  const contentStr = typeof content === 'string' ? content : String(content || '');
  const langStr = typeof lang === 'string' ? lang : String(lang || 'txt');


  const sourceView = HighlightedCode(contentStr, langStr);

  const updateText = (text: string) => {
    sourceView.get_buffer().set_text(text, -1);
  };

  const codeBlock = (
    <box cssName="sidebar-chat-codeblock" orientation={Gtk.Orientation.VERTICAL}>
      <box cssName="sidebar-chat-codeblock-topbar" hexpand>
        <label cssName="sidebar-chat-codeblock-topbar-txt" hexpand
          halign={Gtk.Align.START}
        >{langStr}</label>
      </box>
      <box cssName="sidebar-chat-codeblock-code" hexpand vexpand>
        <Gtk.ScrolledWindow
          vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
          hscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
          minContentHeight={75}
          maxContentHeight={500}
          minContentWidth={300}
          hexpand={true}
          child={sourceView as any}
        />
      </box>
    </box>
  );

  return codeBlock;
};

export default ChatCodeBlock;
