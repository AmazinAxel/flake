import IdleNotify from 'gi://AstalIdleNotify';
import { brightness, setBrightness } from './brightness';
import { lockScreen } from '../widgets/lockscreen/lockscreen';

const DIM_MS = 4 * 60 * 1000;
const LOCK_MS = 5 * 60 * 1000;
const DIM_LEVEL = 0.1;

export const monitorIdle = () => {
    if (!IdleNotify.is_supported()) return;
    const notifier = IdleNotify.get_default();

    let restore: number | null = null;

    const dim = notifier.get_input_idle_notification(DIM_MS);
    dim.connect('idled', () => {
        const current = brightness.peek();
        if (current <= DIM_LEVEL) return;
        restore = current;
        setBrightness(DIM_LEVEL);
    });
    dim.connect('resumed', () => {
        if (restore === null) return;
        setBrightness(restore);
        restore = null;
    });

    const lock = notifier.get_input_idle_notification(LOCK_MS);
    lock.connect('idled', lockScreen); // keep `restore` so brightness returns after unlock
};
