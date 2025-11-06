{
  description = "ctools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          shadowify = pkgs.writeShellApplication {
            name = "shadowify";
            runtimeInputs = with pkgs; [
              backgroundremover
              imagemagick
              potrace
            ];
            text = ''
              file="$1"

              if [[ ! -f "$file" ]]; then
                  echo "Error: '$file' is not a file" >&2
                  exit 1
              fi

              name="''${file%.*}"
              # ext="''${file##*.}"

              # TODO: pipe only supported in backgroundremover@0.3.5
              # if available in nixpkgs use it and pipe the script
              backgroundremover -i "$file" -o /tmp/shadowify.png

              magick /tmp/shadowify.png -fill black -colorize 100% \
              	   -background white -alpha remove -alpha off pbm:- |\
              	potrace -s -o "$name.svg"

              echo "Enjoy the shadow at: $name.svg"
            '';
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "ctools";
            shellHook = ''
              git rev-parse --is-inside-work-tree >/dev/null 2>&1 || git init
              git config pull.rebase true
              ${pkgs.neo-cowsay}/bin/cowsay -f sage "ctools"
            '';
            packages = with pkgs; [
              backgroundremover
              imagemagick
              potrace
              self.packages.${system}.shadowify
            ];
          };
        }
      );

      darwinModules.default =
        { config, pkgs, ... }:
        {
          environment.systemPackages = [ self.packages.${pkgs.system}.shadowify ];
        };

      nixosModules.default =
        { config, pkgs, ... }:
        {
          environment.systemPackages = [ self.packages.${pkgs.system}.shadowify ];
        };
    };
}
