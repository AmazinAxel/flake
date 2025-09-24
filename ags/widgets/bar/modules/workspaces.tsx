import AstalHyprland from 'gi://AstalHyprland';
import { Gtk } from 'ags/gtk4';
import { createBinding } from "ags"

const hyprland = AstalHyprland.get_default();
const focusedWorkspaceBind = createBinding(hyprland, 'focusedWorkspace');

export const Workspaces = () =>
  <box
    orientation={Gtk.Orientation.VERTICAL}
    name={'workspaceList'}
  >
    <Gtk.EventControllerScroll
      flags={Gtk.EventControllerScrollFlags.VERTICAL}
      onScroll={(_, __, y) => hyprland.dispatch('workspace', (y > 0) ? '+1' : '-1')}/>
      <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['barElement']}>
        {[...Array(9).keys()].map((id) => id + 1).map((id) =>
          <box cssClasses={focusedWorkspaceBind((focused) => {
            const workspace = hyprland.workspaces.find((w) => w.id == id);

            // Empty workspace or monitor was reconnected
            if (!workspace || !focused)
              return ['workspaceBtn'];

            const isOccupied = workspace.get_clients().length > 0;
            const active = focused.id == id;

            return (active)
              ? ['workspaceBtn', 'active']
              : isOccupied ? ['workspaceBtn', 'occupied']
              : ['workspaceBtn']
            })
          }/>
        )}
    </box>
  </box>
