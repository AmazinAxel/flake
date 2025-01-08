// Stolen from https://github.com/rice-cracker-dev/nixos-config/blob/main/modules/extends/candy/home/desktop/shell/ags/config/widgets/HyprlandWidget/index.tsx
import { Gtk } from 'astal/gtk4';
import { bind, Variable } from 'astal';
import AstalHyprland from 'gi://AstalHyprland';

const hyprland = AstalHyprland.get_default();

export const Workspaces = () =>
  <box 
    hexpand
    vertical
    cssClasses={["workspaceList"]}
    onScroll={(_, __, y) => hyprland.dispatch('workspace', (y > 0) ? '+1' : '-1')}
  >
    {[...Array(8).keys()].map((i) => 
      <WorkspaceBtn id={i + 1}/>
    )}
  </box>
  
const WorkspaceBtn = ({ id }: { id: number }) => {

  // TODO can we clean this up by removing an unused bind?
  const className = Variable.derive(
    [bind(hyprland, 'workspaces'), bind(hyprland, 'focusedWorkspace')],
    (workspaces, focused) => {
      const workspace = workspaces.find((w) => w.id === id);

      // Empty workspace or monitor was reconnected
      if (!workspace || !focused)
        return ['workspaceBtn'];

      const isOccupied = workspace.get_clients().length > 0;
      const active = focused.id == id;
      
      return (active) 
          ? ['workspaceBtn', 'active']
          : isOccupied ? ['workspaceBtn', 'occupied']
          : ['workspaceBtn']
      }
  );

  return <box hexpand vexpand cssClasses={className()}/>
};