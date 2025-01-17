import { Gtk } from 'astal/gtk4';
import { bind } from 'astal';
import AstalHyprland from 'gi://AstalHyprland';

const hyprland = AstalHyprland.get_default();

export const Workspaces = () =>
  <box 
    vertical
    cssClasses={["workspaceList"]}
    onScroll={(_, __, y) => hyprland.dispatch('workspace', (y > 0) ? '+1' : '-1')}
  >
    {[...Array(8).keys()].map((id) => id + 1).map((id) =>
      <box cssClasses={bind(hyprland, 'focusedWorkspace').as((focused) => {
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
