{
  # stop ALLL bluetooth earbuds from sending any input
  services.udev.extraRules = ''
    ACTION!="remove", SUBSYSTEM=="input", DEVPATH=="/devices/virtual/input/*", ATTR{id/bustype}=="0005", ATTR{capabilities/rel}=="0", ATTR{capabilities/abs}=="0", ATTR{inhibited}="1"
  '';

  services.pipewire = {
    extraConfig.pipewire = {
      "99-combine-bt"."context.objects" = [{
        factory = "adapter";
        args = {
          "factory.name" = "support.null-audio-sink";
          "node.name" = "combined-bt-sink";
          "node.description" = "Bluetooth combined output";
          "media.class" = "Audio/Sink";
          "monitor.channel-volumes" = true;
          "audio.position" = [ "FL" "FR" ];
          "audio.rate" = 48000;

          "priority.driver" = 2000;
          "clock.name" = "clock.combined-bt";
        };
      }];
      "92-rates"."context.properties"."default.clock.allowed-rates" = [ 48000 44100 ];
    };

    wireplumber.extraConfig."51-bluetooth-hifi" = {
      # never use earbud mic
      # wpctl set-profile <card> headset-head-unit
      "wireplumber.settings"."bluetooth.autoswitch-to-headset-profile" = false;
      "monitor.bluez.properties" = {
        "bluez5.codecs" = [ "sbc_xq" "sbc" ];
        "bluez5.enable-sbc-xq" = true;
        "bluez5.hw-volume" = [ "a2dp-sink" ];
      };

      "device.profile.priority.rules" = [
        { # higher quality
          matches = [{ "device.name" = "~bluez_card.*"; }];
          actions.update-props.priorities = [ "a2dp-sink-sbc_xq" "a2dp-sink" ];
        }
        { # K38 drops packets on 452kbps!!! :p
          matches = [{ "device.name" = "bluez_card.67_10_1D_B6_4C_E2"; }];
          actions.update-props.priorities = [ "a2dp-sink-sbc" ];
        }
      ];

      "monitor.bluez.rules" = [
        { # BLUETOOTH SPEAKER
          matches = [{ "device.name" = "bluez_card.67_10_1D_B6_4C_E2"; }];
          actions.update-props."device.description" = "Bluetooth Speaker";
        } { # BLUETOOTH EARBUDS
          matches = [{ "device.name" = "bluez_card.D6_1F_21_FC_F9_C7"; }];
          actions.update-props."device.description" = "Bluetooth Earbuds";
        } { # better bluetooth absorbtion
          matches = [{ "node.name" = "~bluez_output.*"; }];
          actions.update-props."node.latency" = "2048/48000";
        }
      ];
    };
  };
}
