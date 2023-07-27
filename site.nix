{ lib
, stdenv
, fetchFromGitHub
, hugo
}:

let
  hugo-theme-stack = fetchFromGitHub {
    owner = "CaiJimmy";
    repo = "hugo-theme-stack";
    rev = "v3.17.0";
    hash = "sha256-KYBBx9Np2qGQ8GcB4Ou+fr2mJjRZm2VKa4UUAPVEYaY=";
  };

  externalSetup = ''
    rm -f themes/*
    mkdir -p themes
    ln -s ${hugo-theme-stack} themes/stack
  '';
in
stdenv.mkDerivation {
  pname = "blog";
  version = "git";

  src = lib.cleanSource ./.;

  nativeBuildInputs = [ hugo ];

  postUnpack = ''
    ${externalSetup}
  '';

  buildPhase = ''
    runHook preBuild

    hugo

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/blog"
    cp -r public "$out/share/blog/www"

    runHook postInstall
  '';

  shellHook = ''
    ${externalSetup}
  '';
}
