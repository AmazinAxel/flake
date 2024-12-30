import Apps from "gi://AstalApps"
import { App, Astal, Gdk, Gtk } from "astal/gtk3"
import { Variable } from "astal"

const apps = new Apps.Apps()
const text = Variable("")
const list = text(text => apps.fuzzy_query(text).slice(0, 5)) // 5 max items

const hide = () => App.toggle_window("launcher");

const AppButton = ({ app }: { app: Apps.Application }) =>
    <button
        className="AppButton"
        onClicked={() => { app.launch(); hide(); }}
    >
        <box>
            <icon icon={app.iconName} />
            <box valign={Gtk.Align.CENTER} vertical>
                <label
                    className="name"
                    truncate
                    xalign={0}
                    label={app.name}
                />
                {app.description && <label
                    className="description"
                    wrap
                    xalign={0}
                    label={app.description}
                />}
            </box>
        </box>
    </button>


export const launcher = () =>
    <window
        name="launcher"
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM}
        exclusivity={Astal.Exclusivity.IGNORE}
        keymode={Astal.Keymode.ON_DEMAND}
        application={App}
        visible={false}
        onShow={() => text.set("")}
        onKeyPressEvent={function (self, event: Gdk.Event) {
            if (event.get_keyval()[1] === Gdk.KEY_Escape)
               self.hide()
        }}
    >
        <box>
            <box hexpand={false} vertical>
                <box widthRequest={500} className="launcher" vertical>
                    <entry
                        placeholderText="Search"
                        text={text()}
                        onChanged={self => text.set(self.text)}
                        onActivate={() => {
                            apps.fuzzy_query(text.get())?.[0].launch();
                            hide();
                        }}
                        setup={self => { // Auto-grab focus when launched
                            App.connect("window-toggled", () => {
                                const win = App.get_window("launcher");
                                if (win.visible == true)
                                    self.grab_focus()
                            })
                        }}
                    />
                    <box spacing={6} vertical>
                        {list.as(list => list.map(app => (
                            <AppButton app={app}/>
                        )))}
                    </box>
                </box>
            </box>
        </box>
    </window>
