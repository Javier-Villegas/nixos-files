{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.xrdp;
  confDir = pkgs.runCommand "xrdp.conf" { preferLocalBuild = true; } ''
    mkdir $out

    cp ${cfg.package}/etc/xrdp/{km-*,xrdp,sesman,xrdp_keyboard}.ini $out

    cat > $out/startwm.sh <<EOF
    #!/bin/sh
    . /etc/profile
    export \$(dbus-launch)
    ${cfg.defaultWindowManager}
    EOF
    chmod +x $out/startwm.sh

    substituteInPlace $out/xrdp.ini \
      --replace "#rsakeys_ini=" "rsakeys_ini=/run/xrdp/rsakeys.ini" \
      --replace "certificate=" "certificate=${cfg.sslCert}" \
      --replace "key_file=" "key_file=${cfg.sslKey}" \
      --replace LogFile=xrdp.log LogFile=/dev/null \
      --replace EnableSyslog=true EnableSyslog=false

    substituteInPlace $out/sesman.ini \
      --replace LogFile=xrdp-sesman.log LogFile=/dev/null \
      --replace EnableSyslog=1 EnableSyslog=0 \
      --replace Policy=Default Policy=UBDC

    # Ensure that clipboard works for non-ASCII characters
    sed -i -e '/.*SessionVariables.*/ a\
    LANG=${config.i18n.defaultLocale}\
    LOCALE_ARCHIVE=${config.i18n.glibcLocales}/lib/locale/locale-archive
    ' $out/sesman.ini
  '';
in
{


  config = mkIf cfg.enable {

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    # xrdp can run X11 program even if "services.xserver.enable = false"
    xdg = {
      autostart.enable = true;
      menus.enable = true;
      mime.enable = true;
      icons.enable = true;
    };

    fonts.enableDefaultFonts = mkDefault true;

    systemd = {
      services.xrdp= {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        description = "xrdp daemon";
        requires = [ "xrdp-sesman.service" ];
        preStart = ''
          # prepare directory for unix sockets (the sockets will be owned by loggedinuser:xrdp)
          mkdir -p /tmp/.xrdp || true
          chown xrdp:xrdp /tmp/.xrdp
          chmod 3777 /tmp/.xrdp

          # generate a self-signed certificate
          if [ ! -s ${cfg.sslCert} -o ! -s ${cfg.sslKey} ]; then
            mkdir -p $(dirname ${cfg.sslCert}) || true
            mkdir -p $(dirname ${cfg.sslKey}) || true
            ${pkgs.openssl.bin}/bin/openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 365 \
              -subj /C=US/ST=CA/L=Sunnyvale/O=xrdp/CN=www.xrdp.org \
              -config ${cfg.package}/share/xrdp/openssl.conf \
              -keyout ${cfg.sslKey} -out ${cfg.sslCert}
            chown root:xrdp ${cfg.sslKey} ${cfg.sslCert}
            chmod 440 ${cfg.sslKey} ${cfg.sslCert}
          fi
          if [ ! -s /run/xrdp/rsakeys.ini ]; then
            mkdir -p /run/xrdp
            ${cfg.package}/bin/xrdp-keygen xrdp /run/xrdp/rsakeys.ini
          fi
        '';
        serviceConfig = {
          User = "xrdp";
          Group = "xrdp";
          PermissionsStartOnly = true;
          ExecStart = mkForce "${cfg.package}/bin/xrdp --nodaemon --port ${toString cfg.port} --config ${confDir}/xrdp.ini";
        };
      };

      services.xrdp-sesman = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        description = "xrdp session manager";
        restartIfChanged = false; # do not restart on "nixos-rebuild switch". like "display-manager", it can have many interactive programs as children
        serviceConfig = {
          ExecStart = mkForce "${cfg.package}/bin/xrdp-sesman --nodaemon --config ${confDir}/sesman.ini";
          ExecStop  = mkForce "${pkgs.coreutils}/bin/kill -INT $MAINPID";
        };
      };

    };

    users.users.xrdp = {
      description   = "xrdp daemon user";
      isSystemUser  = true;
      group         = "xrdp";
    };
    users.groups.xrdp = {};

    security.pam.services.xrdp-sesman = { allowNullPassword = true; startSession = true; };
  };

}
