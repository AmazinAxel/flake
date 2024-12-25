
// Stolen from https://github.com/Fjoggs/ags-topbar/blob/main/library/Sway.ts

import { GObject, exec, property, register, signal, subprocess } from "astal";

interface WorkspaceOutput {
  id: number;
  type: "workspace";
  name: string;
  focused: boolean;
  visible: boolean;
}

type SwayChangeEvent = "empty" | "init" | "focus" | "urgent";

export type WorkspaceEvent = {
  change?: SwayChangeEvent;
  old?: WorkspaceOutput;
  current?: WorkspaceOutput;
};

const cmd = "swaymsg -t get_workspaces";
const parseResponse = (output: string) =>
  JSON.parse(output) as WorkspaceOutput[];

@register({ GTypeName: "Sway" })
export class Sway extends GObject.Object {
  static instance: Sway;
  static get_default() {
    if (!this.instance)
      this.instance = new Sway();
    
    return this.instance;
  }

  @signal()
  declare workspace: () => void;

  #workspaces = parseResponse(exec(cmd));

  #stream = {};

  #proc = subprocess(
    `swaymsg -m -t subscribe '["workspace"]'`,
    (out) => {
      const data: WorkspaceEvent = JSON.parse(out);
      this.#stream = data;
      this.updateWorkspaces();

      this.emit("workspace");
    },
    (err) => console.error(err),
  );

  @property(Object)
  get workspaces() {
    return this.#workspaces;
  }

  updateWorkspaces() {
    this.#workspaces = parseResponse(exec(cmd));
  }

  @property(Object)
  get stream() {
    return this.#stream;
  }
  constructor() {
    super();
  }
}
