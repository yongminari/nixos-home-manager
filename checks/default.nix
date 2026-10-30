{ self, pkgs, hostNames, username }:

let
  lib = pkgs.lib;
  niriCheck = hostName:
    let
      home = self.homeConfigurations."${username}@${hostName}";
      integrated = self.nixosConfigurations.${hostName}.config.home-manager.users.${username};
      configText = home.config.xdg.configFile."niri/config.kdl".text;
      configFile = pkgs.writeText "niri-${hostName}.kdl" configText;
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
        ${lib.optionalString home.config.local.desktop.isLaptop ''
          bash ${../scripts/initialize-niri-touchpad.sh} \
            config/touchpad-control.kdl ${../modules/desktop/niri/touchpad-default.kdl}
        ''}
        niri validate --config config/config.kdl
        touch "$out"
      ''
    );
in
builtins.listToAttrs (map (hostName: {
  name = "niri-${hostName}";
  value = niriCheck hostName;
}) hostNames) // {
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
