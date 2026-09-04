{
  services.pipewire = {
    extraConfig.pipewire = {
      "99-combine-bt"."context.modules" = [{
        name = "libpipewire-module-combine-stream";
        args = {
          "combine.mode" = "sink";
          "node.name" = "combined-bt-sink";
          "node.description" = "Bluetooth combined output";
          "node.latency" = "2048/48000"; # 42ms buffer to absorb jitter
          "combine.latency-compensate" = false; # less jitter
          "combine.props" = {
            "audio.position" = [ "FL" "FR" ];
            "audio.rate" = 48000;
          };
          "combine.on-demand-streams" = true;
          "combine.start-streams-on-load" = false;
          "stream.props"."audio.rate" = 48000;
          "stream.rules" = [{
            matches = [
              { "node.name" = "~bluez_output\\.00_00_AB_CF_DF_9C\\..*"; }
              { "node.name" = "~bluez_output\\.D6_1F_21_FC_F9_C7\\..*"; }
            ];
            actions.create-stream = { };
          }];
        };
        flags = [ "ifexists" "nofail" ];
      }];
    };

    wireplumber.extraConfig."51-bluetooth-hifi" = {
      # never use earbud mic
      # wpctl set-profile <card> headset-head-unit
      "wireplumber.settings"."bluetooth.autoswitch-to-headset-profile" = false;
      "monitor.bluez.properties"."bluez5.codecs" = [ "sbc_xq" "sbc" ];

      "device.profile.priority.rules" = [
        { # higher quality
          matches = [{ "device.name" = "~bluez_card.*"; }];
          actions.update-props.priorities = [ "a2dp-sink-sbc_xq" "a2dp-sink" ];
        }
        { # K38 can't sustain sbc_xq's 452kbps, drops packets
          matches = [{ "device.name" = "bluez_card.67_10_1D_B6_4C_E2"; }];
          actions.update-props.priorities = [ "a2dp-sink-sbc" ];
        }
      ];
    };
  };
}
