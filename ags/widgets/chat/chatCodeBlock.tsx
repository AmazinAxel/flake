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
    if (from === str)
      return to;
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
    show_line_numbers: false,
    leftMargin: 10,
    margin_top: 10,
    margin_bottom: 10,
    tab_width: 2,
    indent_width: 2,
    highlight_current_line: false,
  });

  const langManager = GtkSource.LanguageManager.get_default();
  let displayLang = langManager.get_language(substituteLang(lang));
  if (displayLang)
    buffer.set_language(displayLang);

  const scheme = GtkSource.StyleSchemeManager.get_default().get_scheme('Adwaita-dark');
  buffer.set_style_scheme(scheme);

  buffer.set_text(contentStr, -1);
  return sourceView;
};

export default (content: string, lang: string) => {
  const sourceView = HighlightedCode(content, lang);
  const codeBlock = (sourceView);

  return codeBlock;
};
