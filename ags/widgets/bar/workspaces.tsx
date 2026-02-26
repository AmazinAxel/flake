import { Astal, Gtk } from 'ags/gtk4';
import { createBinding, createState, For, This } from "ags"
import { createSubprocess, exec } from 'ags/process';
import { timeout } from 'ags/time';
const { TOP, LEFT } = Astal.WindowAnchor;
import app from 'ags/gtk4/app';
const monitors = createBinding(app, "monitors");

export const [ workspaces, setWorkspaces ] = createState(
  [...Array(9).keys()].map((i) => ({ id: i + 1, focused: false, occupied: false })) // Starting state
);
let workspaceWindow: Gtk.Window;
let count = 0;
const [ isVisible, setIsVisible ] = createState(false);

const updateWorkspaces = () => {
  const active = JSON.parse(exec(['swaymsg', '-t', 'get_workspaces']));
  setWorkspaces(
    [...Array(9).keys()].map((i) => {
      const id = i + 1;
      const ws = active.find((w: { num: number }) => w.num === id);
      return { id, focused: ws?.focused ?? false, occupied: !!ws?.representation };
    })
  );
};

const eventStream = createSubprocess('', ['swaymsg', '-t', 'subscribe', '-m', '["workspace"]']);
eventStream.subscribe(() => { // Show workspaces on workspace change
  updateWorkspaces();
  showWorkspaces();
});
updateWorkspaces();

function switchWorkspace(direction: number) {
  const ws = JSON.parse(exec(['swaymsg', '-t', 'get_workspaces']));
  const current = ws.find((w: { focused: boolean }) => w.focused);
  const target = Math.min(9, Math.max(1, current.num + direction));
  if (target === current.id) return; // Don't switch to 0 or 10th workspace
  exec(['swaymsg', 'workspace', 'number', String(target)]);
};

const showWorkspaces = () => {
  setIsVisible(true);
  count++;
  timeout(500, () => {
    count--;
    if (count === 0)
      setIsVisible(false);
  });
};

export default () =>
  <For each={monitors}>
    {(monitor) => <This this={app}>
      <window
        name="workspaces"
        anchor={TOP | LEFT}
        layer={Astal.Layer.OVERLAY}
        gdkmonitor={monitor}
        application={app}
        visible={isVisible}
        $={(self) => workspaceWindow = self }
      >
        <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['barElement']}>
          <Gtk.EventControllerScroll
            flags={Gtk.EventControllerScrollFlags.VERTICAL}
            onScroll={(_, __, y) => switchWorkspace(y > 0 ? 1 : -1)}
          />
          {[...Array(9).keys()].map((i) => i + 1).map((id) =>
            <box cssClasses={workspaces((ws) => {
              const w = ws.find((w) => w.id === id);
              if (!w)
                return ['workspaceBtn'];

              return w.focused
                ? ['workspaceBtn', 'active']
                : w.occupied
                  ? ['workspaceBtn', 'occupied']
                  : ['workspaceBtn'];
            })}/>
          )}
        </box>
      </window>
    </This>}
  </For>;
