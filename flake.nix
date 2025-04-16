{
  description = "A Casino Roulette simulator";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.default = pkgs.stdenvNoCC.mkDerivation rec {
        pname = "physical-roulette";
        version = "0.1.0";
        src = pkgs.lib.cleanSource ./.;
        nativeBuildInputs = with pkgs; [
          makeWrapper
          (pkgs.makeSetupHook
            {
              name = "pre-fixup-hook";
              propagatedBuildInputs = [
                makeWrapper
              ];
              substitutions = {
                shell = "${bash}/bin/bash";
              };
            }
            (
              pkgs.writeScript "pre-fixup-hook.sh" ''
                #!@shell@

                _wrapRoulette() {
                    mkdir -p $out/bin
                    makeWrapper ${love}/bin/love $out/bin/${pname} --argv0 ${pname} --append-flags $out/lib/${pname}.love
                }

                preFixupHooks+=(_wrapRoulette)
              ''
            )
          )
        ];
        buildInputs = with pkgs; [
          zip
          love
        ];
        installPhase = ''
          mkdir -p $out/lib
          zip $out/lib/${pname}.love *
        '';
      };
      devShells.${system}.try = pkgs.mkShell {
        buildInputs = [
          pkgs.busybox
          self.packages.${system}.default
        ];
      };
    };
}
