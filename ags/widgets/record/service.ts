import { createState } from 'ags';
import { exec, execAsync } from 'ags/process';
import AstalIO from 'gi://AstalIO';
import GLib from 'gi://GLib';

import { notifySend } from '../../lib/notifySend';
const captureDir = '/home/alec/Videos/Captures';

const now = () => GLib.DateTime.new_now_local().format('%Y-%m-%d_%H-%M-%S');

export const [ isRec, setIsRec ] = createState(false);
export const [ recMic, setRecMic ] = createState(false);
export const [ recQuality, setRecQuality ] = createState('Ultra');

let rec: AstalIO.Process | null = null;
let file: string;

const getFocusedMonitor = () => JSON.parse(exec(['swaymsg', '-t', 'get_outputs', '-r'])).find((o: any) => o.focused).name;

export const startClippingService = () =>
	execAsync(`gpu-screen-recorder -a 'default_output|default_input' -q medium -w ${getFocusedMonitor()} -o /home/alec/Videos/Clips/ -f 30 -r 30 -c mp4`)

export const startRec = () => {
	execAsync("pkill -SIGINT -f gpu-screen-recorder") // Stops screen clipping, otherwise exits

	file = `${captureDir}/${now()}.mp4`;
	const audio = (recMic.peek() == true) ? "default_output|default_input" : "default_output";

	rec = AstalIO.Process.subprocess(`gpu-screen-recorder -a ${audio} -q ${recQuality.peek()} -w ${getFocusedMonitor()} -o ${file}`);

	setIsRec(true);
};

export const stopRec = () => {
	rec?.signal(2); // Send SIGINT to stop recording
	rec = null;
	setIsRec(false);

	notifySend({
		appName: 'Recording',
		title: 'Screen recording saved',
		actions: [
			{
				id: 1,
				label: 'Open Captures',
				command: 'nemo ' + captureDir,
			},
			{
				id: 2,
				label: 'View',
				command: 'xdg-open ' + file
			}
		]
	});

	// Copy video to clipboard
	execAsync(`bash -c "echo -n file:/${file} | wl-copy -t text/uri-list"`);

	startClippingService(); // Restart screen clipping
};
