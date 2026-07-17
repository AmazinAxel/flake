{
  services = {
    upower.enable = true; # battery level for the astal shell

    tlp = { # Better battery life
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power"; # power?

        # no CPU boost on battery
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        # firmware platform profile
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "low-power";

        # pci active state power management
        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "powersupersave";

        # pci device sleep
        RUNTIME_PM_ON_AC = "on";
        RUNTIME_PM_ON_BAT = "auto";

        # USB autosuspend
        USB_AUTOSUSPEND = 1;
        USB_EXCLUDE_AUDIO = 1;
        USB_EXCLUDE_PRINTER = 1;

        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 0;
        SOUND_POWER_SAVE_CONTROLLER = "N";

        # Wake on LAN
        WOL_DISABLE = "Y";
      };
    };
  };
}
