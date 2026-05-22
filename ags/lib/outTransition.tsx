import { Gtk } from "ags/gtk4"
import type { Accessor } from "ags"

export default ({ reveal, duration, type, onHidden, children }: {
    reveal: Accessor<boolean>,
    duration: number,
    type: Gtk.RevealerTransitionType,
    onHidden?: () => void,
    children: JSX.Element
}) =>
    <revealer
        revealChild={reveal}
        transitionDuration={reveal((r) => r ? duration : 0)}
        transitionType={type}
        $={(self) =>
            self.connect('notify::child-revealed', () => (!self.childRevealed) && onHidden?.())
        }
    >
        {children}
    </revealer>
