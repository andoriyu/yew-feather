{
  description = "Minimal Rust Development Environment";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    andoriyu = {
      url = "github:andoriyu/flakes";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        fenix.follows = "fenix";
      };
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    fenix,
    flake-utils,
    andoriyu,
    naersk,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      cwd = builtins.toString ./.;
      overlays = [ fenix.overlays.default ];
      pkgs = import nixpkgs {inherit system overlays;};
      control-plane = pkgs.callPackage ./nix/control-plane {inherit nixpkgs system naersk fenix andoriyu;};
    in
      with pkgs; {
        packages = {
          coordinator = control-plane.coordinator-server;
          webui = control-plane.webui;
        };
        formatter = nixpkgs.legacyPackages.${system}.alejandra;
        devShell = clangStdenv.mkDerivation rec {
          name = "rust";
          nativeBuildInputs = [
            (with fenix.packages.${system};
              combine [
                (stable.withComponents [
                  "cargo"
                  "clippy"
                  "rust-src"
                  "rustc"
                  "rustfmt"
                ])
                targets.wasm32-unknown-unknown.stable.rust-std
              ])
            andoriyu.packages.${system}.atlas
            andoriyu.packages.${system}.cargo-expand-nightly
            andoriyu.packages.${system}.dart-sass-1_57_1
            bacon
            binaryen
            binutils
            cargo-cache
            cargo-deny
            cargo-diet
            cargo-nextest
            cargo-outdated
            cargo-sort
            cargo-sweep
            cargo-wipe
            cmake
            curl
            gnumake
            grpcui
            grpcurl
            jq
            just
            nodePackages.node2nix
            nodejs-16_x
            pkg-config
            protobuf
            rust-analyzer-nightly
            rusty-man
            sqlite
            sqlx-cli
            trunk
            wasm-bindgen-cli
            zlib
          ];
          PROTOC = "${protobuf}/bin/protoc";
          PROTOC_INCLUDE = "${protobuf}/include";
        };
      });
}
