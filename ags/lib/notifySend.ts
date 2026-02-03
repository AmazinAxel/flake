import { subprocess, execAsync } from 'ags/process';

interface NotifyAction {
    id: number,
    label: string,
    command: string
}

interface NotifySendProps {
    title: string,
    body?: string,
    appName?: string,
    category?: string,
    actions?: NotifyAction[]
}

const escapeShellArg = (arg: string): string => `'${arg?.replace(/'/g, '\'\\\'\'')}'`;

export const notifySend = ({
    title,
    body,
    appName,
    category,
    actions = []
}: NotifySendProps) => new Promise<number>((resolve) => {
    let printedId = false;

    const cmd = [
        'notify-send',
        '--print-id',
        escapeShellArg(title),
        escapeShellArg(body ?? ''),

        // Optional params
        appName && '--app-name=' + escapeShellArg(appName),
        category && '--category=' + escapeShellArg(category)
    ].concat(
        actions.map(({ id, label }) => `--action=${id}=${escapeShellArg(label)}`),
    ).join(' ');

    subprocess(
        cmd,
        (out) => {
            if (!printedId) {
                resolve(parseInt(out));
                printedId = true;
            } else {
                execAsync(actions.find((a) => String(a.id) == out)?.command ?? '');
            };
        },
        (err) => console.error('[Notify] ' + err)
    );
});