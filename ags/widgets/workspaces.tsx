import { Astal, Gtk } from 'ags/gtk4';
import { createState, For, This } from "ags"
import { createSubprocess, exec } from 'ags/process';
import { timeout } from 'ags/time';
const { TOP, LEFT } = Astal.WindowAnchor;
import app from 'ags/gtk4/app';
import { monitors } from '../lib/monitors';
import OutTransition from '../lib/outTransition';

export const [ workspaces, setWorkspaces ] = createState(
  [...Array(9).keys()].map((i) => ({ id: i + 1, focused: false, occupied: false })) // Starting state
);
let count = 0;
const [ windowVisible, setWindowVisible ] = createState(false);
const [ reveal, setReveal ] = createState(false);

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

const showWorkspaces = () => {
  setWindowVisible(true);
  setReveal(true);
  count++;
  timeout(400, () => {
    count--;
    if (count === 0) setReveal(false);
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
        visible={windowVisible}
        defaultHeight={1} // gtk layer shell glitch workaround
        defaultWidth={1}
      >
        <OutTransition reveal={reveal} onHidden={() => (count === 0) && setWindowVisible(false) }>
          <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['statusElement']}>
            {[...Array(9).keys()].map((i) => i + 1).map((id) =>
              <box cssClasses={workspaces((ws) => {
                const w = ws.find((w) => w.id === id);
                if (!w)
                  return ['workspace'];

                return w.focused
                  ? ['workspace', 'active']
                  : w.occupied
                    ? ['workspace', 'occupied']
                    : ['workspace'];
              })}/>
            )}
          </box>
        </OutTransition>
      </window>
    </This>}
  </For>;
