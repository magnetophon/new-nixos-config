# Claude Code in a bubblewrap jail (mrquentin/claude-sandbox).
# Imported only by the laptop hosts; pronix (server) deliberately omits it.
#
# `claude-sandbox` is available as a module argument because the laptop
# hosts pass `specialArgs = inputs // { inherit self; }` in flake.nix.
{ claude-sandbox, pkgs, ... }:
{
  imports = [ claude-sandbox.nixosModules.default ];

  programs.claude-sandbox = {
    enable = true;

    # The module default is `true`, which forwards SSH_AUTH_SOCK into the
    # sandbox. The agent socket stays fully functional in there, so the
    # agent could sign with your keys (git push, ssh to your servers).
    # Keep it off: commit inside the sandbox, push from a normal shell.
    forwardSSHAgent = false;

    # extraBindMounts is read-WRITE; leave it empty for the paranoid setup.
    # Use extraReadOnlyMounts for anything the agent only needs to read:
    # extraReadOnlyMounts = [ "/opt/datasets" ];

    # profile = "default";  # minimal | default | full

    extraPackages = [ pkgs.claude-code ]; # puts `claude` on the sandbox PATH

  };
}
