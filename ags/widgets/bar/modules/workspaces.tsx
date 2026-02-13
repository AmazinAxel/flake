import { Gtk } from 'ags/gtk4';
import { createState, For } from "ags"
import { createSubprocess, exec } from 'ags/process';

export const [ workspaces, setWorkspaces ] = createState(
  [{ id: 1, focused: true }]
);

const updateWorkspaces = () =>
  setWorkspaces(
    JSON.parse(exec(['swaymsg', '-t', 'get_workspaces'])).slice()
      .sort((a: { output: string, id: number }, b: { output: string, id: number }) =>
        a.output.localeCompare(b.output) || a.id - b.id) // Sort by monitor name then by id
      .slice(0, 8) // Dont show more than 8 workspaces
  );

const eventStream = createSubprocess('', ['swaymsg', '-t', 'subscribe', '-m', '["workspace"]']);
eventStream.subscribe(() => updateWorkspaces());
updateWorkspaces();

function switchWorkspace(direction: number) {
  const ws = JSON.parse(exec(['swaymsg', '-t', 'get_workspaces']));
  const current = ws.find((w: { focused: boolean }) => w.focused);
  if (!current) return;
  let target = current.num + direction;
  if (target > 10) target = 1;
  if (target < 1) target = 10; // todo better logic
  exec(['swaymsg', 'workspace', 'number', String(target)]);
};

export const Workspaces = () =>
  <box
    orientation={Gtk.Orientation.VERTICAL}
    name={'workspaceList'}
  >
    <Gtk.EventControllerScroll
      flags={Gtk.EventControllerScrollFlags.VERTICAL}
      onScroll={(_, __, y) => { switchWorkspace(y > 0 ? 1 : -1) }}
    />
    <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['barElement']}>
      <For each={workspaces}>
        {(workspace) => {
          const classes = (workspace["focused"])
            ? ['workspaceBtn', 'active']
            : ['workspaceBtn'];

          return <box cssClasses={classes}/>
        }}
      </For>
    </box>
  </box>
