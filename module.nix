{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.hust-network-login;
  defaultPackage =
    # Prefer overlay-provided package if available; fall back to building from the local source.
    pkgs.rustPlatform.buildRustPackage {
      pname = "hust-network-login";
      version = "0.1.3";

      src = ./.;

      cargoLock = {
        lockFile = ./Cargo.lock;
      };

      meta = {
        description = "Minimalist HUST network authentication tool";
        homepage = "https://github.com/black-binary/hust-network-login";
        license = licenses.unlicense;
        maintainers = [ ];
        mainProgram = "hust-network-login";
      };
    };
in
{
  options.services.hust-network-login = {
    enable = mkEnableOption "HUST Network Login service";

    username = mkOption {
      type = types.str;
      description = "Username for HUST network authentication";
      example = "M2020123123";
    };

    password = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Password for HUST network authentication.

        WARNING: This option will store the password in the Nix store,
        which is world-readable. Use `passwordFile` instead for better security.
      '';
    };

    passwordFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to a file containing the password for HUST network authentication.
        This is the recommended way to provide the password, especially when
        using secrets management tools like agenix.

        The file should contain only the password, without any trailing newline.
      '';
      example = "/run/agenix/hust-network-login-password";
    };

    package = mkOption {
      type = types.package;
      default = defaultPackage;
      defaultText = literalExpression "pkgs.rustPlatform.buildRustPackage { ... }";
      description = "The hust-network-login package to use";
      example = literalExpression "pkgs.hust-network-login";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.password != null) || (cfg.passwordFile != null);
        message = "Either services.hust-network-login.password or services.hust-network-login.passwordFile must be set";
      }
      {
        assertion = !((cfg.password != null) && (cfg.passwordFile != null));
        message = "services.hust-network-login.password and services.hust-network-login.passwordFile are mutually exclusive";
      }
    ];

    systemd.services.hust-network-login = {
      description = "Login to HUST Network";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "1";
        DynamicUser = true;

        # Set username via environment variable
        Environment = [ "HUST_NETWORK_LOGIN_USERNAME=${cfg.username}" ];

        # Load password from file if passwordFile is specified, otherwise use password directly
        ExecStart =
          if cfg.passwordFile != null then
            pkgs.writeShellScript "hust-network-login-start" ''
              export HUST_NETWORK_LOGIN_PASSWORD="$(cat ${escapeShellArg cfg.passwordFile})"
              exec ${cfg.package}/bin/hust-network-login
            ''
          else
            "${cfg.package}/bin/hust-network-login";
      } // optionalAttrs (cfg.password != null) {
        # Set password via environment file (not recommended, but simpler than LoadCredential)
        EnvironmentFile = pkgs.writeText "hust-network-login-env" ''
          HUST_NETWORK_LOGIN_PASSWORD=${cfg.password}
        '';
      };
    };
  };
}
