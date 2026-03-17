{ lib, stdenv, fetchFromGitHub, kernel }:

stdenv.mkDerivation {
  pname = "rocknix-joypad";
  version = "unstable-2024-12-17";

  src = fetchFromGitHub {
    owner = "ROCKNIX";
    repo = "rocknix-joypad";
    rev = "7647fdb0fc89cd69b284903bf7707e861df5dc7e";
    hash = "sha256-6gskpAYxnxygMxm3+mrg24XbZmV1X40wC3/7EGwXUqQ=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    runHook preBuild
    make DEVICE=H700 -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/modules/${kernel.modDirVersion}/misc
    cp *.ko $out/lib/modules/${kernel.modDirVersion}/misc/
    runHook postInstall
  '';

  meta = {
    #description = "ROCKNIX joypad driver";
    license = lib.licenses.gpl2Only;
  };
}
