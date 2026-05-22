import { Gtk } from "ags/gtk4"
import inputControl from "./inputControl"
import { statusMargin } from "../widgets/status/status"

export default (name: string, Child: () => JSX.Element) => inputControl(name, () =>
	<box
		halign={Gtk.Align.START}
		valign={Gtk.Align.END}
		marginStart={statusMargin}
		cssClasses={['asideStatusWidget']}
	>
		<Child/>
	</box>
);
