// @ts-nocheck TODO fix types

import { Gtk, Variable, bind, exec } from "astal";
import { Sway, WorkspaceEvent } from "../library/Sway";

export const Workspaces = () => {
  let names: Variable<Gtk.Widget[]> = Variable([]);
  const sway = Sway.get_default();
  const workspaces = bind(sway, "workspaces");
  const activeWorkspace = Variable("");
  const urgentWorkspace = Variable("");

  sway.connect("workspace", (data: Sway) => {
    const output: WorkspaceEvent = data.stream;
    if (output.change === "focus") {
      const currentActive = output.current?.name || "";
      activeWorkspace.set(currentActive);
      urgentWorkspace.set("");
      redrawWorkspaces();
    } else if (output.change === "urgent") {
      const urgent = output.current?.name || "";
      if (urgent !== activeWorkspace.get()) {
        // no need to highlight if it's the same workspace
        urgentWorkspace.set(urgent);
        redrawWorkspaces();
      }
    }
  });

  const redrawWorkspaces = () =>
    names.set(
      workspaces.get().map((workspace) => {
        let isActive = false;
        if (activeWorkspace.get() === "") {
          isActive = workspace.focused;
        } else {
          isActive = workspace.name === activeWorkspace.get();
        }
        const isUrgent = urgentWorkspace.get() === workspace.name;
        return (
          <button
            onClicked={() => {
              exec(`swaymsg workspace ${workspace.name}`);
            }}
            className={`${isActive ? "active" : ""} ${isUrgent ? "urgent" : ""}`}
            cursor="pointer"
            hexpand={true}
          >
            {workspace.name}
          </button>
        );
      }),
    );

  redrawWorkspaces();

  return (
    <box>{bind(names)}</box>
  );
};
