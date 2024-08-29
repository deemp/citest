{
  description = "citest";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
  };

  outputs = inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; }
    ({ moduleWithSystem, withSystem, ... }: {
      imports = [ inputs.devshell.flakeModule ];
      systems =
        [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        let
          pname = "citest";
          version = "0.0.1";
          tailwindCss = pkgs.nodePackages.tailwindcss.overrideAttrs (oa: {
            plugins = [ pkgs.nodePackages."@tailwindcss/forms" ];
            version = "3.4.1";
          });
          beam_pkgs = pkgs.beam.packagesWith pkgs.beam.interpreters.erlang;
          mixFodDeps = pkgs.beamPackages.fetchMixDeps {
            pname = "${pname}-deps";
            inherit version;
            src = pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = pkgs.lib.fileset.unions [
                ./mix.exs
                ./mix.lock
              ];
            };
            hash = "sha256-sfzH3J5nUy4wDCbztvVAN+wYPcQzmAxNsioYcrrKlGk=";
          };
          elixir = beam_pkgs.elixir_1_16;
          citest = beam_pkgs.mixRelease {
            inherit pname version mixFodDeps elixir;
            nativeBuildInputs = [pkgs.libgcc];
            src = pkgs.lib.fileset.toSource {
              root = ./.;
              fileset = pkgs.lib.fileset.unions [
                ./assets
                ./config
                ./lib
                ./priv
                ./test
                ./.formatter.exs
                ./mix.exs
                ./mix.lock
              ];
            };

            ELIXIR_MAKE_CACHE_DIR = "/tmp/";

            postBuild = ''
              # Consult https://nixos.org/manual/nixpkgs/unstable/#mix-release-example if node dependencies are needed
              # For external task you need a workaround for the no deps check flag
              # https://github.com/phoenixframework/phoenix/issues/2690
              mix do deps.loadpaths --no-deps-check, phx.digest

              mkdir -p tmp/deps
              cp -r ${mixFodDeps}/phoenix tmp/deps/phoenix
              cp -r ${mixFodDeps}/phoenix_html tmp/deps/phoenix_html

              mix deps.compile
              MIX_ESBUILD_NODE_PATH="${mixFodDeps}/" MIX_TAILWIND_PATH="${tailwindCss}/bin/tailwind" MIX_ESBUILD_PATH="${pkgs.esbuild}/bin/esbuild" mix assets.deploy

              mix phx.digest --no-deps-check
            '';
          };
        in {

          packages.citest = citest;
          packages.citestDeps = mixFodDeps;
          packages.default = self'.packages.citest;
        };
    });
}
