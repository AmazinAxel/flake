// Adapted from https://github.com/matt1432/nixos-configs/blob/9a24d7308bb3adf88da54c480c35b44e1aa4f132/modules/ags/config/widgets/corners/screen-corners.tsx

import { Gtk } from 'ags/gtk4';
import Cairo from 'cairo';
const radius = 10;

export const Corner = (place: string) => {
    const drawingArea = new Gtk.DrawingArea();
    drawingArea.set_size_request(radius, radius);
    drawingArea.set_draw_func((_, cr) => {
        const cairoContext = cr as Cairo.Context;

        switch (place) {
            case 'top':
                cairoContext.arc(radius, radius, radius, Math.PI, 3 * Math.PI / 2);
                cairoContext.lineTo(0, 0);
                break;

            case 'bottom':
                cairoContext.arc(radius, 0, radius, Math.PI / 2, Math.PI);
                cairoContext.lineTo(0, radius);
                break;
        };
        cairoContext.setSourceRGB(0.19215686274509805, 0.21568627450980393, 0.26666666666666666); // #2E3440
        cairoContext.fill();
    });
    return drawingArea;
};
