import { createBinding, createState } from 'ags';
import app from 'ags/gtk4/app';
import { timeout } from 'ags/time';

const rawMonitors = createBinding(app, "monitors");
export const [ monitors, setMonitors ] = createState([...app.monitors]);

rawMonitors.subscribe(() => {
    const monitorList = rawMonitors.peek();
    const current = monitors.peek();
    if (current.some(m => !monitorList.includes(m))) {
        setMonitors([...monitorList]);
    } else {
        // debounce monitor additions to fix bug
        timeout(1000, () => setMonitors([...rawMonitors.peek()]));
    }
});
