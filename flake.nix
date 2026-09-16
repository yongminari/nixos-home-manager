{
  description = "Unified NixOS and Home Manager Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      # 공식 바이너리 캐시(Cachix)를 사용하기 위해 nixpkgs follows 관계를 끊습니다.
      # 이렇게 해야 빌드 해시가 개발팀의 빌드와 일치하여 컴파일 없이 즉시 바이너리를 다운로드합니다.
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty-aurora = {
      url = "github:cmmichael/ghostty-aurora";
      flake = false;
    };

    ghostty-shaders = {
      url = "github:0xhckr/ghostty-shaders";
      flake = false;
    };

    niri-shaders = {
      url = "github:liixini/shaders";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, noctalia, sops-nix, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "yongminari"; # 중앙화된 유저명 설정. 다른 아이디로 변경하려면 이곳만 수정하면 됩니다.
      hostNames = [
        "galaxy-book"
        "ai-x1-pro"
        "nxtp-office-desktop"
      ];
      mkNixosConfiguration = hostName:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs username; };
          modules = [
            (./hosts + "/${hostName}/configuration.nix")
            sops-nix.nixosModules.sops

            # Home Manager를 NixOS 모듈로 통합
            home-manager.nixosModules.home-manager
            ({ ... }: {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { inherit inputs username; };
              home-manager.users.${username} = import ./home.nix;
            })
          ];
        };
      mkHomeConfiguration = hostName:
        home-manager.lib.homeManagerConfiguration {
          pkgs = self.nixosConfigurations.${hostName}.pkgs;
          extraSpecialArgs = {
            inherit inputs username;
            osConfig = self.nixosConfigurations.${hostName}.config;
          };
          modules = [ ./home.nix ];
        };
    in {
      # NixOS 시스템 설정 (sudo nixos-rebuild switch --flake .#galaxy-book)
      nixosConfigurations = builtins.listToAttrs (map (hostName: {
        name = hostName;
        value = mkNixosConfiguration hostName;
      }) hostNames);

      # nh home switch가 현재 hostname에 맞는 NixOS 정보를 사용하도록 호스트별 출력 제공
      homeConfigurations = builtins.listToAttrs (map (hostName: {
        name = "${username}@${hostName}";
        value = mkHomeConfiguration hostName;
      }) hostNames);
    };
}
