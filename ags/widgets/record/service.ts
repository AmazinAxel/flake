
import { Gtk } from 'ags/gtk4';
import { createState } from 'ags';
import { exec, execAsync } from 'ags/process';
import AstalIO from 'gi://AstalIO';
import GLib from 'gi://GLib';
import Hyprland from 'gi://AstalHyprland';

import { notifySend } from '../../services/notifySend';

const hypr = Hyprland.get_default();
const captureDir = '/home/alec/Videos/Captures';

const now = () => GLib.DateTime.new_now_local().format('%Y-%m-%d_%H-%M-%S');

export const [ isRec, setIsRec ] = createState(false);
export const [ recMic, setRecMic ] = createState(false);
export const [ recQuality, setRecQuality ] = createState('ultra');

let rec: AstalIO.Process | null = null;
let file: string;

export const startClippingService = () =>
	execAsync(`gpu-screen-recorder -a 'default_output|default_input' -q medium -w ${hypr.get_monitors()[0]?.name} -o /home/alec/Videos/Clips/ -f 30 -r 30 -c mp4`)

export const startRec = () => {
	execAsync("pkill -SIGINT -f gpu-screen-recorder") // Stops screen clipping, otherwise exits

	exec("hyprctl keyword decoration:screen_shader ''"); // Disable blue light shader

	file = `${captureDir}/${now()}.mp4`;
	const monitor = hypr.get_focused_monitor().name;
	const audio = (recMic.get() == true) ? "default_output|default_input" : "default_output";

	rec = AstalIO.Process.subprocess(`gpu-screen-recorder -a ${audio} -q ${recQuality.get()} -w ${monitor} -o ${file}`);

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

	// Re-enable blue light shader
	exec('hyprctl keyword decoration:screen_shader /home/alec/Projects/flake/home-manager/hypr/blue-light-filter.glsl');

	startClippingService(); // Restart screen clipping
};
