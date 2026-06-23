# powermode.nix — three power modes for a 12th-gen Framework 13, where each mode
# is defined by WHICH actuator yields first:
#
#   quiet        CPU target LOW  (62 C)  -> the CPU throttles to stay cool, so the
#                                           die rarely reaches the fan's ramp; fan idles.
#   balanced     setpoints close (78 C)  -> CPU and fan share the work.
#   performance  CPU target HIGH (92 C)  -> the fan ramps early/hard to hold the die
#                                           well below 92 C, leaving the CPU at full speed.
#
# The fan side is fw-fanctrl (one curve per mode). The CPU side is a small
# proportional regulator that nudges intel_pstate max_perf_pct toward the
# current mode's target temperature. `powermode <mode>` records the mode and
# switches the fan curve; the regulator picks up the new target within one tick.

{ pkgs, ... }:

let
  user = "bart";

  # --- CPU regulator: hold die temp at the current mode's target by capping freq ---
  regulator = pkgs.writeShellScript "cpu-thermal-regulator" ''
    export PATH=${pkgs.coreutils}/bin:$PATH

    pct=/sys/devices/system/cpu/intel_pstate/max_perf_pct
    modefile=/var/lib/powermode/mode

    tick=2          # seconds between adjustments
    band=2000       # +/-2 C deadband (millidegrees): do nothing inside it
    k_up=2          # gain (pct per C) when cooler than target: ramp up gently
    k_down=3        # gain when hotter than target: throttle harder (bias to cool/quiet)
    step_max=40     # clamp change per tick: fast mode-switches, no violent swings
    floor=20        # never cap the CPU below this %
    ceil=100

    read_temp() {   # echo package temperature in millidegrees C
      local h z
      for h in /sys/class/hwmon/hwmon*; do
        if [ "$(cat "$h/name" 2>/dev/null)" = coretemp ]; then
          cat "$h/temp1_input" 2>/dev/null && return
        fi
      done
      for z in /sys/class/thermal/thermal_zone*; do
        if [ "$(cat "$z/type" 2>/dev/null)" = x86_pkg_temp ]; then
          cat "$z/temp" 2>/dev/null && return
        fi
      done
      echo 0
    }

    while true; do
      case "$(cat "$modefile" 2>/dev/null || echo balanced)" in
        quiet)       target=62000 ;;
        performance) target=92000 ;;
        *)           target=78000 ;;   # balanced / unknown
      esac

      t=$(read_temp); t=''${t:-0}
      cur=$(cat "$pct" 2>/dev/null || echo 100)
      err=$(( target - t ))            # >0: cooler than target   <0: hotter

      if   [ "$err" -gt "$band" ];      then adj=$(( err * k_up   / 1000 ))
      elif [ "$err" -lt $(( -band )) ]; then adj=$(( err * k_down / 1000 ))
      else adj=0
      fi

      if [ "$adj" -gt "$step_max" ];      then adj=$step_max; fi
      if [ "$adj" -lt $(( -step_max )) ]; then adj=$(( -step_max )); fi

      new=$(( cur + adj ))
      if [ "$new" -lt "$floor" ]; then new=$floor; fi
      if [ "$new" -gt "$ceil"  ]; then new=$ceil;  fi
      if [ "$new" != "$cur" ]; then echo "$new" > "$pct"; fi

      sleep "$tick"
    done
  '';

  # --- powermode CLI: record the mode + switch the fan curve ----------------------
  powermode = pkgs.writeShellApplication {
    name = "powermode";
    runtimeInputs = [
      pkgs.fw-fanctrl
      pkgs.coreutils
    ];
    text = ''
      mode="''${1:-$(cat /var/lib/powermode/mode 2>/dev/null || echo balanced)}"
      case "$mode" in
        quiet|balanced|performance) ;;
        *) echo "usage: powermode {quiet|balanced|performance}" >&2; exit 1 ;;
      esac
      mkdir -p /var/lib/powermode
      echo "$mode" > /var/lib/powermode/mode   # the regulator reads this every tick
      fw-fanctrl use "$mode"                    # switch the fan curve immediately
      echo "powermode -> $mode"
    '';
  };

in
{
  # --- fan: fw-fanctrl, one curve per mode ----------------------------------------
  hardware.fw-fanctrl = {
    enable = true;
    config = {
      defaultStrategy = "balanced";
      strategies = {
        # quiet: fan is only a BACKSTOP. The regulator holds the die ~62 C, so the
        # curve stays off until ~70 C and only then helps out.
        quiet = {
          fanSpeedUpdateFrequency = 5;
          movingAverageInterval = 30;
          speedCurve = [
            {
              temp = 0;
              speed = 0;
            }
            {
              temp = 70;
              speed = 20;
            }
            {
              temp = 80;
              speed = 55;
            }
            {
              temp = 90;
              speed = 100;
            }
          ];
        };
        # balanced: fan and CPU setpoints sit close; both contribute.
        balanced = {
          fanSpeedUpdateFrequency = 5;
          movingAverageInterval = 25;
          speedCurve = [
            {
              temp = 0;
              speed = 10;
            }
            {
              temp = 55;
              speed = 30;
            }
            {
              temp = 65;
              speed = 55;
            }
            {
              temp = 75;
              speed = 85;
            }
            {
              temp = 80;
              speed = 100;
            }
          ];
        };
        # performance: fan LEADS — ramps early and hard so the die never nears the
        # regulator's 92 C target, leaving the CPU at full speed.
        performance = {
          fanSpeedUpdateFrequency = 2;
          movingAverageInterval = 10;
          speedCurve = [
            {
              temp = 0;
              speed = 25;
            }
            {
              temp = 45;
              speed = 50;
            }
            {
              temp = 55;
              speed = 75;
            }
            {
              temp = 65;
              speed = 100;
            }
          ];
        };
      };
    };
  };

  # --- CPU: temperature-regulated cap, target chosen by the current mode ----------
  systemd.services.cpu-thermal-regulator = {
    description = "Per-mode temperature-regulated CPU cap (powermode)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 2;
      ExecStart = "${regulator}";
      # fail safe: if the regulator dies, hand the CPU back its full range
      ExecStopPost = "${pkgs.bash}/bin/bash -c 'echo 100 > /sys/devices/system/cpu/intel_pstate/max_perf_pct'";
    };
  };

  # apply the stored mode's fan curve at boot (CPU is handled by the daemon)
  systemd.services.powermode-boot = {
    description = "Apply stored powermode at boot";
    after = [ "fw-fanctrl.service" ];
    wants = [ "fw-fanctrl.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${powermode}/bin/powermode"; # no arg -> applies stored mode
    };
  };

  # reassert the fan curve after resume (the regulator self-heals on its own)
  powerManagement.resumeCommands = "${powermode}/bin/powermode";

  environment.systemPackages = [ powermode ];

  # flip modes without a password — handy for i3 keybindings
  security.sudo.extraRules = [
    {
      users = [ user ];
      commands = [
        {
          command = "/run/current-system/sw/bin/powermode";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
