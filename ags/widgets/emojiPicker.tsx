import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { execAsync } from 'ags/process';
import inputControl from '../lib/inputControl';

const hide = () => app.get_window('emojiPicker')?.hide();

let textBox: Gtk.Entry;

export default () => inputControl('emojiPicker', () =>
  <entry
    enableEmojiCompletion
    showEmojiIcon
    halign={Gtk.Align.CENTER}
    valign={Gtk.Align.CENTER}
    $={(self) => { textBox = self; }}
    onNotifyText={async (self) => {
      if (self.text != '' && !self.text.match(/[:a-z]/)) {
        hide();
        await execAsync(['wl-copy', '-t', 'text/plain', self.text]);
      };
    }}
  >
  </entry>,
  () => { if (textBox) textBox.text = ''; },
  false, undefined, undefined, undefined, () => textBox
);
