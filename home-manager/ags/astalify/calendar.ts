import { Gtk, astalify, type ConstructProps } from "astal/gtk3";
import { GObject } from "astal";

export class Calendar extends astalify(Gtk.Calendar) {
    static {
        GObject.registerClass(this);
    };

    constructor(props: ConstructProps<Calendar, Gtk.Calendar.ConstructorProps>) {
        super(props as any);
    };
};