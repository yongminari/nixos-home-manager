{ self, pkgs, hostNames, username }:

let
  lib = pkgs.lib;
  niriCheck = hostName:
    let
      home = self.homeConfigurations."${username}@${hostName}";
      integrated = self.nixosConfigurations.${hostName}.config.home-manager.users.${username};
      configText = home.config.xdg.configFile."niri/config.kdl".text;
      configFile = pkgs.writeText "niri-${hostName}.kdl" configText;
      genieClose = pkgs.writeText "genie-close-default.kdl"
        (import ../modules/desktop/niri/genie-close-template.nix "1.0");
    in
    # Force standalone Home Manager evaluation as well as NixOS evaluation.
    builtins.seq home.activationPackage.drvPath (
      assert configText == integrated.xdg.configFile."niri/config.kdl".text;
      pkgs.runCommand "niri-config-${hostName}" {
        nativeBuildInputs = [ pkgs.niri ];
      } ''
        mkdir -p config
        cp ${configFile} config/config.kdl
        cp ${home.config.xdg.configFile."niri/binds.kdl".source} config/binds.kdl
        ${lib.optionalString home.config.local.desktop.adaptiveGenieClose ''
          cp ${genieClose} config/genie-close.kdl
        ''}
        ${lib.optionalString home.config.local.desktop.isLaptop ''
          bash ${../scripts/initialize-niri-touchpad.sh} \
            config/touchpad-control.kdl ${../modules/desktop/niri/touchpad-default.kdl}
        ''}
        ${lib.optionalString home.config.local.desktop.monitorIdleRefresh.blur ''
          cp ${../modules/desktop/niri/blur-default.kdl} config/idle-blur.kdl
          chmod u+w config/idle-blur.kdl
        ''}
        niri validate --config config/config.kdl
        ${lib.optionalString home.config.local.desktop.monitorIdleRefresh.blur ''
          printf 'blur {\n passes 1\n offset 0.25\n}\n' > config/idle-blur.kdl
          niri validate --config config/config.kdl
        ''}
        touch "$out"
      ''
    );
in
builtins.listToAttrs (map (hostName: {
  name = "niri-${hostName}";
  value = niriCheck hostName;
}) hostNames) // {
  adaptive-close = pkgs.runCommand "adaptive-close" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    python3 ${./adaptive-close.py} ${../modules/desktop/niri/adaptive-close.py}
    touch "$out"
  '';

  evacuate-output = pkgs.runCommand "evacuate-output" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    python3 ${./evacuate-output.py} ${../modules/desktop/niri/evacuate-output.py}
    touch "$out"
  '';

  noctalia-wallpaper-sync = pkgs.runCommand "noctalia-wallpaper-sync" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    python3 ${./noctalia-wallpaper-sync.py} ${../modules/services/noctalia-wallpaper-sync.py}
    touch "$out"
  '';

  monitor-idle-refresh = pkgs.runCommand "monitor-idle-refresh" {
    nativeBuildInputs = [ pkgs.python3 ];
  } ''
    python3 ${./monitor-idle-refresh.py} ${../modules/desktop/monitor-idle-refresh.py}
    touch "$out"
  '';

  starship-profile-switch = pkgs.runCommand "starship-profile-switch" {
    nativeBuildInputs = [ pkgs.bash pkgs.zsh pkgs.nushell ];
    starshipPackage = self.homeConfigurations."${username}@nxtp-office-desktop".config.programs.starship.package;
    originalStarship = pkgs.starship;
  } ''
    bash ${./starship-profile-switch.sh}
    touch "$out"
  '';

  shell-scripts = pkgs.runCommand "shell-scripts" {
    nativeBuildInputs = [ pkgs.shellcheck ];
  } ''
    shellcheck ${../scripts}/*.sh
    touch "$out"
  '';

  touchpad-state = pkgs.runCommand "touchpad-state" {} ''
    target="$TMPDIR/fresh home/niri/touchpad-control.kdl"
    defaults=${../modules/desktop/niri/touchpad-default.kdl}
    bash ${../scripts/initialize-niri-touchpad.sh} "$target" "$defaults"
    cmp "$target" "$defaults"
    test -w "$target"
    test ! -L "$target"
    printf 'input { touchpad { off; }; }\n' > "$target"
    cp "$target" expected
    bash ${../scripts/initialize-niri-touchpad.sh} "$target" "$defaults"
    cmp "$target" expected
    touch "$out"
  '';
}
