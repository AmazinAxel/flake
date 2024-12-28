// Stolen from https://github.com/matt1432/nixos-configs/blob/master/modules/ags/config/widgets/corners/screen-corners.tsx

import { Gtk } from 'astal/gtk3';
import Cairo from 'cairo';

const radius = 10;

export default (place: string) => (
    <box
        css={`
            padding: 1px; margin:
                ${place.includes('top') ? '-1px' : '0'}
                ${place.includes('right') ? '-1px' : '0'}
                ${place.includes('bottom') ? '-1px' : '0'}
                ${place.includes('left') ? '-1px' : '0'};
        `}
    >
        <drawingarea
            css={`
                border-radius: ${radius}px;
                border-width: 0.06rem;
                background-color: @theme_bg_color
            `}

            setup={(widget) => {
                const styleContext = widget.get_style_context();

                widget.set_size_request(radius, radius);

                widget.connect('draw', (_, cairoContext: Cairo.Context) => {
                    const bgColor = styleContext.get_background_color(Gtk.StateFlags.NORMAL);
                    const borderColor = styleContext.get_color(Gtk.StateFlags.NORMAL);
                    const borderWidth = styleContext.get_border(Gtk.StateFlags.NORMAL).left;

                    widget.set_size_request(radius, radius);

                    switch (place) {
                        case 'topleft':
                            cairoContext.arc(radius, radius, radius, Math.PI, 3 * Math.PI / 2);
                            cairoContext.lineTo(0, 0);
                            break;

                        case 'topright':
                            cairoContext.arc(0, radius, radius, 3 * Math.PI / 2, 2 * Math.PI);
                            cairoContext.lineTo(radius, 0);
                            break;

                        case 'bottomleft':
                            cairoContext.arc(radius, 0, radius, Math.PI / 2, Math.PI);
                            cairoContext.lineTo(0, radius);
                            break;

                        case 'bottomright':
                            cairoContext.arc(0, 0, radius, 0, Math.PI / 2);
                            cairoContext.lineTo(radius, radius);
                            break;
                    }

                    cairoContext.closePath();
                    cairoContext.setSourceRGBA(bgColor.red, bgColor.green, bgColor.blue, bgColor.alpha);
                    cairoContext.fill();
                    cairoContext.setLineWidth(borderWidth);
                    cairoContext.setSourceRGBA(
                        borderColor.red,
                        borderColor.green,
                        borderColor.blue,
                        borderColor.alpha,
                    );
                    cairoContext.stroke();
                });
            }}
        />
    </box>
);