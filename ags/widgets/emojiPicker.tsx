import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { execAsync } from 'ags/process';
import inputControl from '../lib/inputControl';

const hide = () => app.get_window('emojiPicker')?.hide();

export default () => inputControl('emojiPicker', () =>
  <entry
    enableEmojiCompletion
    showEmojiIcon
    halign={Gtk.Align.CENTER}
    valign={Gtk.Align.CENTER}
    $={(self) =>
      app.connect('window-toggled', () => {
        if (app.get_window('emojiPicker')?.visible == true) {
          self.grab_focus();
          self.text = '';
        };
      })
    }
    onNotifyText={async (self) => {
      if (self.text != '' && !self.text.match(/[:a-z]/)) {
        hide();
        await execAsync('wl-copy ' + self.text);
      };
    }}
  >
    <Gtk.EventControllerKey onKeyPressed={(_, key) => (key == 65307) && hide()} />
  </entry>
);
