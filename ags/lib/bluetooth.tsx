import AstalBluetooth from 'gi://AstalBluetooth';
import Gio from 'gi://Gio';
import { createState, With } from 'ags';

const [ btPowered, setBtPowered ] = createState(false);
const [ menu, setMenu ] = createState<{ Menu: () => JSX.Element } | null>(null);

Gio.DBus.system.call('org.bluez', '/', 'org.freedesktop.DBus.ObjectManager', 'GetManagedObjects',
    null, null, Gio.DBusCallFlags.NONE, -1, null, (conn, res) => {
        try { conn!.call_finish(res); } catch {}
        const bt = AstalBluetooth.get_default();
        setBtPowered(bt.isPowered);
        bt.connect('notify::is-powered', () => setBtPowered(bt.isPowered));
        import('../widgets/status/bluetooth').then(m => setMenu({ Menu: m.default }));
    });

export { btPowered };

export default () =>
    <With value={menu}>
        {(m) => m ? <m.Menu/> : <box/>}
    </With>;
