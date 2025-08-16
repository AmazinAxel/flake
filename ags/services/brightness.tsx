import { monitorFile, readFileAsync } from 'ags/file';
import { exec, execAsync } from 'ags/process';
import { createState } from 'ags';

const get = (args: string) => Number(exec('brightnessctl ' + args));
const screen = exec('bash -c "ls -w1 /sys/class/backlight | head -1"');

const screenMax = get("max");
export const [brightness, setBrightnessValue] = createState(get("get") / (screenMax || 1)) 

const setBrightness = (percent: number) => {
    if (percent < 0)
        percent = 0;

    if (percent > 1)
        percent = 1;

    execAsync(`brightnessctl set ${Math.floor(percent * 100)}% -q`)
    .then(() => setBrightnessValue(percent));
};

export const monitorBrightness = () =>
    monitorFile(`/sys/class/backlight/${screen}/brightness`, async (file) => {
        const v = await readFileAsync(file);
        setBrightnessValue(Number(v) / screenMax);
    });

export const BrightnessSlider = () =>
    <box>
        <image iconName="display-brightness-symbolic"/>
        <slider
            hexpand
            value={brightness.as((v: number) => v)}
            onChangeValue={({ value }) => setBrightness(value)}
        />
    </box>
