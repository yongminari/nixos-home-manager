{
  description = "Unified NixOS and Home Manager Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zsh-patina = {
      url = "github:michel-kraemer/zsh-patina";
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
  };

  outputs = { self, nixpkgs, home-manager, noctalia, sops-nix, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "yongminari"; # 중앙화된 유저명 설정. 다른 아이디로 변경하려면 이곳만 수정하면 됩니다.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      # NixOS 시스템 설정 (sudo nixos-rebuild switch --flake .#galaxy-book)
      nixosConfigurations."galaxy-book" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username; };
        modules = [
          ./hosts/galaxy-book/configuration.nix
          sops-nix.nixosModules.sops
          
          # Home Manager를 NixOS 모듈로 통합
          home-manager.nixosModules.home-manager
          ({ config, ... }: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs username; };
            home-manager.users.${username} = import ./home.nix;
          })
        ];
      };

      nixosConfigurations."ai-x1-pro" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username; };
        modules = [
          ./hosts/ai-x1-pro/configuration.nix
          sops-nix.nixosModules.sops
          
          # Home Manager를 NixOS 모듈로 통합
          home-manager.nixosModules.home-manager
          ({ config, ... }: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs username; };
            home-manager.users.${username} = import ./home.nix;
          })
        ];
      };

      nixosConfigurations."nxtp-office-desktop" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username; };
        modules = [
          ./hosts/nxtp-office-desktop/configuration.nix
          sops-nix.nixosModules.sops
          
          # Home Manager를 NixOS 모듈로 통합
          home-manager.nixosModules.home-manager
          ({ config, ... }: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs username; };
            home-manager.users.${username} = import ./home.nix;
          })
        ];
      };

      # 독립 실행형 Home Manager 설정 (기존 방식 유지용: home-manager switch --flake .#yongminari)
      homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs username;
          osConfig = {
            modules.core.vertexAI.enable = false;
            networking.hostName = "";
          };
        };
        modules = [ ./home.nix ];
      };
    };
}
