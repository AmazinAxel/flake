import { createState } from 'ags';
import { execAsync } from 'ags/process';
import AstalIO from 'gi://AstalIO';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';

import { notifySend } from '../../lib/notifySend';
const captureDir = '/home/alec/Videos/Captures';
const clipsDir = '/home/alec/Videos/Clips';

const copyFileUri = (path: string) =>
	execAsync([ 'bash', '-c',
		`printf '%s\\r\\n' '${GLib.filename_to_uri(path, null)}' | wl-copy -t text/uri-list 2>/dev/null` ]);

const now = () => GLib.DateTime.new_now_local().format('%Y-%m-%d_%H-%M-%S');

export const [ isRec, setIsRec ] = createState(false);
export const [ recMic, setRecMic ] = createState(false);
export const [ recQuality, setRecQuality ] = createState('Ultra');

let rec: AstalIO.Process | null = null;
let file: string;

const getFocusedMonitor = () => execAsync(['swaymsg', '-t', 'get_outputs', '-r'])
	.then((out) => JSON.parse(out).find((o: any) => o.focused).name as string);

let clipper: AstalIO.Process | null = null;
let clipperGen = 0;

const stopClipper = () => {
	clipperGen++;
	clipper?.signal(2);
	clipper = null;
};

export const startClippingService = (): Promise<void> => {
	stopClipper();
	const gen = clipperGen;

	return getFocusedMonitor().then((monitor) => {
		if (gen !== clipperGen || isRec.peek()) return;
		const p = AstalIO.Process.subprocess(
			`gpu-screen-recorder -a 'default_output|default_input' -q medium -w ${monitor} -o ${clipsDir}/ -f 30 -r 30 -c mp4`);
		clipper = p;
		p.connect('exit', () => {
			if (clipper !== p) return;
			clipper = null;
			GLib.timeout_add(GLib.PRIORITY_DEFAULT, 5000, () => {
				if (gen === clipperGen && !isRec.peek()) startClippingService();
				return GLib.SOURCE_REMOVE;
			});
		});
	}).catch(() => {});
};

export const startRec = () => {
	stopClipper(); // Stops screen clipping, otherwise exits

	file = `${captureDir}/${now()}.mp4`;
	const audio = (recMic.peek() == true) ? "default_output|default_input" : "default_output";

	setIsRec(true);

	getFocusedMonitor().then((monitor) => {
		if (!isRec.peek()) return;
		rec = AstalIO.Process.subprocess(`gpu-screen-recorder -a ${audio} -q ${recQuality.peek().toLowerCase()} -w ${monitor} -o ${file}`);
	}).catch(() => setIsRec(false));
};

const newestClip = (): string | null => {
	let best: string | null = null;
	let bestTime = -1;
	try {
		const e = Gio.File.new_for_path(clipsDir)
			.enumerate_children('standard::name,time::modified', Gio.FileQueryInfoFlags.NONE, null);
		for (let i = e.next_file(null); i; i = e.next_file(null)) {
			const name = i.get_name();
			if (!name.endsWith('.mp4')) continue;
			const mtime = i.get_modification_date_time()?.to_unix() ?? 0;
			if (mtime > bestTime) [ best, bestTime ] = [ `${clipsDir}/${name}`, mtime ];
		}
	} catch {};
	return best;
};

export const saveClip = () => {
	if (!clipper) return startClippingService();

	const before = newestClip();
	clipper.signal(10);

	let waited = 0;
	GLib.timeout_add(GLib.PRIORITY_DEFAULT, 250, () => {
		const latest = newestClip();
		if (latest && latest !== before) {
			copyFileUri(latest);
			return GLib.SOURCE_REMOVE;
		}
		return (waited += 250) >= 10000 ? GLib.SOURCE_REMOVE : GLib.SOURCE_CONTINUE;
	});
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

	copyFileUri(file);

	startClippingService(); // Restart screen clipping
};
