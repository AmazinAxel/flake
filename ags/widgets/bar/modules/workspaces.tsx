import { Gtk } from 'ags/gtk4';
import { createState, For } from "ags"
import { createSubprocess, exec } from 'ags/process';

export const [ workspaces, setWorkspaces ] = createState([]);

const eventStream = createSubprocess('', ['niri', 'msg', '-j', 'event-stream']);
eventStream.subscribe(() => {
  const recentEvent = JSON.parse(eventStream.peek());
  let workspaceJSON;
  if (recentEvent["WorkspacesChanged"]) {
    workspaceJSON = recentEvent["WorkspacesChanged"]["workspaces"];
  } else if (
    recentEvent["WorkspaceActivated"] ||
    recentEvent["WorkspaceActiveWindowChanged"] ||
    recentEvent["WorkspaceUrgencyChanged"]
  ) {
    workspaceJSON = JSON.parse(exec(["niri", "msg", "-j", "workspaces"]));
  } else {
    return;
  };
  setWorkspaces(workspaceJSON.slice().sort(
    (a: { id: number }, b: { id: number }) => a.id - b.id) // sort workspaces by id
    .slice(0, Math.min((workspaceJSON.length - 1), 8)) // dont show more than 8 workspaces
  );
});

export const Workspaces = () =>
  <box
    orientation={Gtk.Orientation.VERTICAL}
    name={'workspaceList'}
  >
    <Gtk.EventControllerScroll
      flags={Gtk.EventControllerScrollFlags.VERTICAL}
      onScroll={(_, __, y) => { console.log(['niri', 'msg', 'action', ('move-workspace-' + (y < 0) ? 'up' : 'down')]) }}
    />
    <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['barElement']}>
      <For each={workspaces}>
        {(workspace) => {
          const classes = (workspace["is_active"]) // is_focused is_urgent ouptut
            ? ['workspaceBtn', 'active']
            : ['workspaceBtn'];

          return <box cssClasses={classes}/>
        }}
      </For>
    </box>
  </box>
