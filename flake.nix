{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-23.05;
    parts.url = github:hercules-ci/flake-parts;
  };

  outputs = inputs: inputs.parts.lib.mkFlake { inherit inputs; } {
    systems = ["x86_64-linux"];

    perSystem = {lib, pkgs, ...}: {
      packages = rec {
        default = fastcdc-c;

        fastcdc-c = lib.flip pkgs.callPackage {} (
          {
            lib,
            openssl,
            zlib,
            uthash ? null,
          }: pkgs.stdenv.mkDerivation {
            name = "fastcdc-c";
            src = ./.;

            propagatedBuildInputs = [openssl zlib] ++ lib.optional (uthash != null) uthash;

            outputs = ["out" "dev"];

            postConfigure = lib.optionalString (uthash != null) ''
              # Remove included uthash so that we use upstream.
              rm uthash.h
            '';

            postBuild = ''
              $CC -O3 -c -g fastcdc.c -o fastcdc64.o
              $CC -lcrypto -shared fastcdc64.o -o libfastcdc64.so
            '';

            installPhase = ''
              mkdir -p $out/{bin,lib}
              mv fastcdc64 $out/bin/
              mv libfastcdc64.so $out/lib/

              mkdir -p $dev/include/fastcdc
              cp fastcdc.h $dev/include/fastcdc/
            '' + lib.optionalString (uthash == null) ''
              # Provide included uthash because we did not use upstream.
              cp uthash.h $dev/include/fastcdc/
            '';

            meta = {
              mainProgram = "fastcdc64";
              maintainer = with lib.maintainers; [dermetfan];
              homepage = "https://github.com/dermetfan/FastCDC-c";
            };
          }
        );
      };
    };
  };
}
