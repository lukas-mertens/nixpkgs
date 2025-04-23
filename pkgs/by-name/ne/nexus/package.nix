{ lib
, stdenv
, fetchurl
, makeWrapper
, jre_headless
, gawk
, nixosTests
, system ? stdenv.hostPlatform.system
,
}:

let
  systems = {
    "x86_64-linux" = {
      platform = "linux-x86_64";
      ext = "tar.gz";
      sha256 = "05a1flk8gxdq1vlqj1vbdd0774mmkzlgh73yyiv7acybixc5p2q4";
    };
    "aarch64-linux" = {
      platform = "linux-aarch_64";
      ext = "tar.gz";
      sha256 = "0wdn76nb34zaxgs4zif2j7kkfqbx2xzcr08ysiijkk6pqsdv79mg";
    };
    "x86_64-darwin" = {
      platform = "mac-x86_64";
      ext = "tar.gz";
      sha256 = "12f46zz94y9hshq8sma75s5r66mlqaiqw4dd0q0a4k0dn3wzjs7c";
    };
    "aarch64-darwin" = {
      platform = "mac-aarch_64";
      ext = "tar.gz";
      sha256 = "1k7fjmp8g970zm3x9y05qjpfbcxz8hni83d7p7ykrv8wsc7s2b79";
    };
    "x86_64-windows" = {
      platform = "win-x86_64";
      ext = "zip";
      sha256 = "1r0jma12nnj0yxr6gdph3gba6yabr635dr38jzl1gvg7vr91v70y";
    };
  };

  target = systems.${system};
in

stdenv.mkDerivation rec {
  pname = "nexus";
  version = "3.79.1-04";

  src = fetchurl {
    url = "https://download.sonatype.com/nexus/3/nexus-${version}-${target.platform}.${target.ext}";
    sha256 = target.sha256;
  };

  preferLocalBuild = true;
  sourceRoot = "${pname}-${version}";

  nativeBuildInputs = [ makeWrapper ];

  patches = [
    ./nexus-bin.patch
  ];

  postPatch = ''
    substituteInPlace bin/nexus.vmoptions \
      --replace-fail ../sonatype-work /var/lib/sonatype-work \
      --replace-fail etc/spring $out/etc/spring \
      --replace-fail =. =$out
    substituteInPlace bin/nexus \
      --replace-fail "realpath jdk/temurin_" "realpath $out/jdk/temurin_" \
      --replace-fail "ls -1 sonatype-nexus-repository-" "ls -1 $out/bin/sonatype-nexus-repository-"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -rfv * $out
    rm -fv $out/bin/nexus.bat

    wrapProgram $out/bin/nexus \
      --set APP_JAVA_HOME ${jre_headless} \
      --set ALTERNATIVE_NAME "nexus" \
      --prefix PATH "${lib.makeBinPath [ gawk ]}"

    runHook postInstall
  '';

  passthru.tests = {
    inherit (nixosTests) nexus;
  };

  meta = {
    description = "Repository manager for binary software components";
    homepage = "https://www.sonatype.com/products/sonatype-nexus-oss";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    license = lib.licenses.epl10;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [
      aespinosa
      ironpinguin
      luftmensch-luftmensch
      zaninime
    ];
  };
}
