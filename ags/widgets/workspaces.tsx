import { Astal, Gtk } from 'ags/gtk4';
import { createComputed, createState, For, This } from "ags"
import { execAsync } from 'ags/process';
import { timeout } from 'ags/time';
const { TOP, LEFT } = Astal.WindowAnchor;
import app from 'ags/gtk4/app';
import Workspace from 'gi://AstalWorkspace';
import { monitors } from '../lib/monitors';
import OutTransition from '../lib/outTransition';

const IDS = [...Array(9).keys()].map((i) => i + 1);

const [ focused, setFocused ] = createState(0);
const [ occupied, setOccupied ] = createState(new Set<number>());
const [ scratchpad, setScratchpad ] = createState(0);
const [ windowVisible, setWindowVisible ] = createState(false);
const [ reveal, setReveal ] = createState(false);

let count = 0;
const showWorkspaces = () => {
  setWindowVisible(true);
  setReveal(true);
  count++;
  timeout(400, () => {
    count--;
    if (count === 0) setReveal(false);
  });
};

const manager = Workspace.get_default();

const updateWorkspaces = () => {
  const ids = new Set<number>();
  let active = 0;

  for (let i = 0; i < manager.get_n_items(); i++) {
    const ws = manager.get_item(i) as Workspace.Workspace | null;
    const id = Number(ws?.name);
    if (!ws || !IDS.includes(id)) continue;

    ids.add(id);
    if (ws.state & Workspace.WorkspaceState.ACTIVE) active = id;
  };

  setOccupied(ids);
  return active;
};

const updateScratchpad = () =>
  execAsync(['swaymsg', '-t', 'get_tree', '-r'])
    .then((out) => {
      const scratch = JSON.parse(out).nodes
        ?.find((o: any) => o.name === '__i3')
        ?.nodes?.find((w: any) => w.name === '__i3_scratch');
      setScratchpad(scratch?.floating_nodes?.length ?? 0);
    })
    .catch(() => {});

manager.connect('updated', () => { // Show workspaces on workspace change
  const active = updateWorkspaces();
  updateScratchpad();

  if (active === focused.peek()) return;
  const startup = focused.peek() === 0;
  setFocused(active);
  if (!startup) showWorkspaces(); // don't flash the popup on launch
});
updateWorkspaces();
updateScratchpad();

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
        <OutTransition duration={150} reveal={reveal} onHidden={() => (count === 0) && setWindowVisible(false)} type={Gtk.RevealerTransitionType.SLIDE_RIGHT}>
          <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['statusElement']}>
            {IDS.map((id) =>
              <box cssClasses={createComputed((track) => track(focused) === id
                ? ['workspace', 'active']
                : track(occupied).has(id)
                  ? ['workspace', 'occupied']
                  : ['workspace'])}/>
            )}
            <label
              cssClasses={['scratchpad']}
              visible={scratchpad((c) => c > 0)}
              label={scratchpad(String)}
            />
          </box>
        </OutTransition>
      </window>
    </This>}
  </For>;
