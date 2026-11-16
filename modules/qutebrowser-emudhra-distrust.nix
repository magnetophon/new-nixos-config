# QtWebEngine trusts the compromised eMudhra intermediate CAs. This module
# marks each of them as distrusted (p,p,p) in the per-user NSS database
# ~/.pki/nssdb, which QtWebEngine reads on Linux. This is the mitigation from
# https://github.com/qutebrowser/qutebrowser/issues/9032
#
# Without home-manager, a systemd user service re-applies the entries at each
# login. It makes no network calls.
{ pkgs, lib, ... }:
let
  # Byte-identical copy of
  # https://emudhra.we-have-a-problem.com/impacted-intermediates.json
  # Use the full set: the 8-hash Chromium blocklist subset does not block all
  # of the certificates.
  intermediatesFile = ./qutebrowser-emudhra-impacted-intermediates.json;
  intermediatesSha256 = "f67b3abe9b4879f4e91874ed041beccd71257f1db41c588c724ccf12aa90c59e";
  intermediates =
    lib.throwIfNot (builtins.hashFile "sha256" intermediatesFile == intermediatesSha256)
      "qutebrowser-emudhra-impacted-intermediates.json does not match the pinned sha256. Keep the file byte-identical to the upstream copy."
      (builtins.fromJSON (builtins.readFile intermediatesFile));

  # For a certificate that is already in the database, certutil -A sets the
  # trust again and adds no duplicate entry.
  addDistrust =
    cert:
    let
      sha256 = lib.toLower cert.sha256;
    in
    ''
      certutil -A -d "sql:$db" -t p,p,p \
        -n ${lib.escapeShellArg "eMudhra ${sha256}"} \
        -i ${pkgs.writeText "emudhra-${sha256}.pem" cert.pem}
    '';

  distrustScript = pkgs.writeShellApplication {
    name = "qutebrowser-distrust-emudhra";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.nssTools
    ];
    text = ''
      db="$HOME/.pki/nssdb"
      mkdir -p "$db"
      chmod 700 "$HOME/.pki" "$db"
      if [ ! -f "$db/cert9.db" ]; then
        certutil -N -d "sql:$db" --empty-password
      fi
      ${lib.concatMapStrings addDistrust intermediates}
    '';
  };
in
{
  # nixpkgs marks qutebrowser insecure because QtWebEngine accepts the
  # compromised eMudhra intermediates. The distrust entries are the mitigation.
  # - https://github.com/NixOS/nixpkgs/pull/584791
  # - https://github.com/NixOS/nixpkgs/issues/576544
  # - https://github.com/qutebrowser/qutebrowser/issues/9032
  # Remove this module when nixpkgs fixes qtwebengine or drops the insecure
  # flag from qutebrowser. The name must match the pkgs.qutebrowser version.
  nixpkgs.config.permittedInsecurePackages = [ "qutebrowser-3.7.0" ];

  assertions = [
    {
      # Evaluation fails once nixpkgs drops the insecure flag, as a reminder
      # to delete this module. `or [ ]` covers a package without the attribute.
      assertion = (pkgs.qutebrowser.meta.knownVulnerabilities or [ ]) != [ ];
      message = ''
        qutebrowser no longer has meta.knownVulnerabilities in nixpkgs, so the
        eMudhra workaround is probably obsolete. Check NixOS/nixpkgs#584791,
        then delete modules/qutebrowser-emudhra-distrust.nix, its JSON file and
        the import in modules/laptop.nix.
      '';
    }
  ];
  systemd.user.services.qutebrowser-distrust-emudhra = {
    description = "Distrust compromised eMudhra intermediates in ~/.pki/nssdb";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = lib.getExe distrustScript;
    };
  };
}
