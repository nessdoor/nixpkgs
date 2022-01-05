{ lib
, stdenv
, fetchurl
, babashka
, cacert
, clojure
, git
, jdk
, callPackage
, fetchFromGitHub
, makeWrapper
, runCommand }:

stdenv.mkDerivation rec {
  pname = "obb";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "babashka";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-WxQjBg6el6XMiHTurmSo1GgZnTdaJjRmcV3+3X4yohc=";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ babashka cacert git jdk ];

  configurePhase = ''
    runHook preConfigure

    mkdir -p .m2
    substituteInPlace deps.edn --replace ':paths' ':mvn/local-repo "./.m2" :paths'
    substituteInPlace bb.edn --replace ':paths' ':mvn/local-repo "./.m2" :paths'
    echo deps.edn

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    export DEPS_CLJ_TOOLS_DIR=${clojure}
    export DEPS_CLJ_TOOLS_VERSION=${clojure.version}
    mkdir -p .gitlibs
    mkdir -p .cpcache
    export GITLIBS=.gitlibs
    export CLJ_CACHE=.cpcache

    bb build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    ln -s /usr/bin/osascript $out/bin/osascript

    install -Dm755 "out/bin/obb" "$out/bin/obb"
    wrapProgram $out/bin/obb --prefix PATH : $out/bin

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    [ $($out/bin/obb -e '(+ 1 2)') = '3' ]
  '';


  meta = with lib; {
    description = "Ad-hoc ClojureScript scripting of Mac applications via Apple's Open Scripting Architecture";
    homepage = "https://github.com/babashka/obb";
    license = licenses.epl10;
    maintainers = with maintainers; [
      willcohen
    ];
    platforms = platforms.darwin;
  };
}
