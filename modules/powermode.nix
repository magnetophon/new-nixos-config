# powermode.nix — three power modes for a 12th-gen Framework 13, where each mode
# is defined by WHICH actuator yields first:
#
#   quiet        CPU target LOW  (52 C)  -> the CPU throttles to stay cool; fan idles.
#   balanced     setpoints close (78 C)  -> CPU and fan share the work.
#   performance  CPU target HIGH (92 C)  -> the fan ramps early/hard; CPU runs free.
#
# Hardening for worst-case (hung software, hot enclosed backpack):
#   * the CPU regulator heartbeats systemd's WatchdogSec, so a hung loop is
#     killed and restarted (and ExecStopPost frees the CPU). TimeoutStopSec keeps
#     the SIGKILL escalation fast if a wedged process ignores the stop signal.
#   * an independent, temperature-keyed fan guard trips near TjMax regardless of
#     why cooling failed (fw-fanctrl hang, wedged ectool, dead regulator).
#   * underneath all of this, the silicon TjMax/THERMTRIP throttle-and-cutoff
#     still protects the hardware with no software running at all.

{ pkgs, ... }:

let
  user = "bart";

  readTemp = ''
    read_temp() {            # echo package temperature in millidegrees C
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
  '';

  # --- CPU regulator: hold die temp at the current mode's target by capping freq ---
  regulator = pkgs.writeShellScript "cpu-thermal-regulator" ''
    export PATH=${pkgs.coreutils}/bin:${pkgs.systemd}/bin:$PATH

    pct=/sys/devices/system/cpu/intel_pstate/max_perf_pct
    modefile=/var/lib/powermode/mode

    tick=2; band=2000; k_up=2; k_down=3; step_max=40; floor=20; ceil=100

    ${readTemp}

    systemd-notify --ready          # tell systemd we're up (Type=notify)

    while true; do
      case "$(cat "$modefile" 2>/dev/null || echo balanced)" in
        quiet)       target=52000 ;;
        performance) target=92000 ;;
        *)           target=78000 ;;
      esac

      t=$(read_temp); t=''${t:-0}
      cur=$(cat "$pct" 2>/dev/null || echo 100)
      err=$(( target - t ))

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

      systemd-notify WATCHDOG=1     # heartbeat: a hung loop misses this -> restart
      sleep "$tick"
    done
  '';

  # --- fan guard: independent thermal breaker, keyed on temperature, not liveness --
  fanGuard = pkgs.writeShellScript "fan-thermal-guard" ''
    export PATH=${pkgs.coreutils}/bin:${pkgs.fw-ectool}/bin:${pkgs.systemd}/bin:$PATH

    guard=96000     # trip point in millidegrees (~4 C below the 100 C TjMax)
    need=3          # consecutive over-temp reads (x tick) before tripping
    tick=10
    hot=0

    ${readTemp}

    while true; do
      t=$(read_temp); t=''${t:-0}
      if [ "$t" -ge "$guard" ]; then hot=$(( hot + 1 )); else hot=0; fi

      if [ "$hot" -ge "$need" ]; then
        echo "THERMAL GUARD TRIPPED: package $(( t / 1000 ))C sustained >= $(( guard / 1000 ))C — forcing fan to max and stopping fw-fanctrl" >&2
        ectool fanduty 100 || true                  # instant max airflow
        systemctl stop fw-fanctrl.service || true   # stop it re-commanding the fan
        ectool fanduty 100 || true                  # re-assert max after EC revert
        hot=0
        sleep 60                                    # stay tripped; recheck after a minute
      fi

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
      echo "$mode" > /var/lib/powermode/mode
      fw-fanctrl use "$mode" > /dev/null
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
        quiet = {
          fanSpeedUpdateFrequency = 5;
          movingAverageInterval = 30;
          speedCurve = [
            {
              temp = 0;
              speed = 0;
            }
            {
              temp = 54; # one degree under the minimum speed, otherwise it interpollates and the fan stalls
              speed = 0;
            }
            {
              temp = 55;
              speed = 10; # 10 seems to be the minimum, lower it stops
            }
            {
              temp = 57;
              speed = 30;
            }
            {
              temp = 64;
              speed = 34;
            }
            {
              temp = 70;
              speed = 60;
            }
            {
              temp = 80;
              speed = 100;
            }
          ];
        };
        balanced = {
          fanSpeedUpdateFrequency = 5;
          movingAverageInterval = 25;
          speedCurve = [
            {
              temp = 0;
              speed = 10; # 10 seems to be the minimum, lower it stops
            }
            {
              temp = 40;
              speed = 25;
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

  # --- CPU: temperature-regulated cap, with a systemd watchdog --------------------
  systemd.services.cpu-thermal-regulator = {
    description = "Per-mode temperature-regulated CPU cap (powermode)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "notify";
      NotifyAccess = "all"; # allow the systemd-notify child to feed the watchdog
      WatchdogSec = 15; # no heartbeat for 15 s -> systemd kills + restarts it
      TimeoutStopSec = 10; # SIGKILL escalation if a wedged process ignores stop
      Restart = "always";
      RestartSec = 2;
      ExecStart = "${regulator}";
      # fail safe: if the regulator stops for any reason, give the CPU its full range
      ExecStopPost = "${pkgs.bash}/bin/bash -c 'echo 100 > /sys/devices/system/cpu/intel_pstate/max_perf_pct'";
    };
  };

  # --- fan safety guard: trips near TjMax no matter what failed -------------------
  systemd.services.fan-thermal-guard = {
    description = "Force max fan if the die approaches TjMax (cooling-failure breaker)";
    after = [ "fw-fanctrl.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 2;
      ExecStart = "${fanGuard}";
    };
  };
  # re-apply the stored mode's fan strategy whenever fw-fanctrl (re)starts —
  # at boot, and after a rebuild, where fw-fanctrl comes back on its defaultStrategy
  systemd.services.powermode-boot = {
    description = "Apply stored powermode fan strategy when fw-fanctrl (re)starts";
    after = [ "fw-fanctrl.service" ];
    wantedBy = [ "fw-fanctrl.service" ];
    partOf = [ "fw-fanctrl.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2"; # let fw-fanctrl's control socket come up
      ExecStart = "${powermode}/bin/powermode"; # no arg -> re-applies the stored mode
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
