import { exec, execAsync } from 'ags/process';
import { createState } from 'ags';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

const get = (args: string) => Number(exec('brightnessctl ' + args));
const screen = exec('bash -c "ls -w1 /sys/class/backlight | head -1"');
const brightnessPath = `/sys/class/backlight/${screen}/brightness`;

const screenMax = get("max");
export const [ brightness, setBrightnessValue ] = createState(get("get") / (screenMax || 1))

const setBrightness = (percent: number) => {
    const steps = Math.max(0, Math.min(screenMax, Math.floor(percent * screenMax)));
    setBrightnessValue(steps / screenMax);
    execAsync(`brightnessctl set ${steps} -q`);
};

export const monitorBrightness = () => {
    const file = Gio.File.new_for_path(brightnessPath);
    const monitor = file.monitor(Gio.FileMonitorFlags.NONE, null);
    monitor.connect('changed', (_m: Gio.FileMonitor, _f: Gio.File, _o: Gio.File | null, eventType: Gio.FileMonitorEvent) => {
        if (eventType !== Gio.FileMonitorEvent.CHANGES_DONE_HINT) return;
        const [ok, contents] = GLib.file_get_contents(brightnessPath);
        if (!ok) return;
        const v = Number(new TextDecoder().decode(contents).trim()) / screenMax;
        if (v !== brightness.peek()) setBrightnessValue(v); // only updates for non internal changes
    });
    return monitor;
};

export const BrightnessSlider = () =>
    <box>
        <image iconName="display-brightness-symbolic"/>
        <slider
            hexpand
            value={brightness.as((v: number) => v)}
            onChangeValue={({ value }) => setBrightness(value)}
        />
    </box>
