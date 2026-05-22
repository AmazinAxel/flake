import { createState } from "ags"
import { Astal, Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import { statusMargin } from "../widgets/status/status"
const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

export const [ currentAsideWindow, setCurrentAsideWindow ] = createState<string | null>(null);

export const setAsideWindow = (name: string) => setCurrentAsideWindow(currentAsideWindow.peek() === name ? null : name);

export const closeAsideWindow = () => setCurrentAsideWindow(null); // null hides

// todo hardcode menus here instead of passing it here
export default (menus: Record<string, () => JSX.Element>) =>
    <window
        name="asideStatus"
        namespace="asideStatus"
        keymode={Astal.Keymode.EXCLUSIVE}
        anchor={TOP | BOTTOM | LEFT | RIGHT}
        application={app}
        layer={Astal.Layer.OVERLAY}
        visible={currentAsideWindow((a) => a !== null)}
        class="backgroundDim"
    >
        <Gtk.EventControllerKey onKeyPressed={(_, key) => (key == 65307) && closeAsideWindow()}/>
        <box
            halign={Gtk.Align.START}
            valign={Gtk.Align.END}
            marginStart={statusMargin}
            cssClasses={['asideStatusWidget']}
        >
            {Object.entries(menus).map(([name, Content]) =>
                <box visible={currentAsideWindow((a) => a === name)}>
                    <Content/>
                </box>
            )}
        </box>
    </window>
