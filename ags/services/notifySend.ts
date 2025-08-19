// Stolen from https://github.com/matt1432/nixos-configs/blob/master/modules/ags/config/lib/notify.ts

import { subprocess, execAsync } from 'ags/process';

interface NotifyAction {
    id: number,
    label: string,
    command: string
}

interface NotifySendProps {
    actions?: NotifyAction[],
    appName?: string,
    body?: string,
    category?: string,
    iconName: string,
    title: string,
    image?: string
}

const escapeShellArg = (arg: string): string => `'${arg?.replace(/'/g, '\'\\\'\'')}'`;

export const notifySend = ({
    actions = [],
    appName,
    body,
    category,
    iconName,
    title,
    image
}: NotifySendProps) => new Promise<number>((resolve) => {
    let printedId = false;

    const cmd = [
        'notify-send',
        '--print-id',
        escapeShellArg(title),
        escapeShellArg(body ?? ''),

        // Optional params
        appName && '--app-name=' + escapeShellArg(appName),
        category && '--category=' + escapeShellArg(category),
        iconName && '--icon=' + escapeShellArg(iconName),
        image && '--hint=string:ags-internal-image:' + escapeShellArg(image)
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