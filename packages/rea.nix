{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
  makeWrapper,
  nodejs_24,
  ghidra,
  openjdk21,
  withGhidra ? true,
}:

buildNpmPackage (finalAttrs: {
  pname = "rea";
  version = "6.10.1";

  src = fetchurl {
    url = "https://registry.npmjs.org/rea-agents/-/rea-agents-${finalAttrs.version}.tgz";
    hash = "sha256-6M8IyfqVTpmPyIaMI/qOX1GM25VTSI7CJ7MaO7aQMVA=";
  };

  nodejs = nodejs_24;
  npmDepsHash = "sha256-pBWP/SRZ+NiKc0bMOT06Q/AXhpUhUUfrhryZe9NYB3o=";

  nativeBuildInputs = [ makeWrapper ];

  # Regenerate the published shrinkwrap for our dependency set. Frida is
  # an optional dependency whose install script downloads prebuilt binaries,
  # which the sandbox cannot do, so it is dropped; Frida-backed tools report
  # the missing runtime. devDependencies only serve the upstream source build.
  postPatch = ''
    rm -f npm-shrinkwrap.json
    rm -rf node_modules
    ${lib.getExe jq} 'del(.optionalDependencies, .devDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
    cp ${./rea-package-lock.json} package-lock.json
  '';

  # The tarball already contains the compiled runtime in dist/.
  dontNpmBuild = true;
  npmFlags = [ "--ignore-scripts" ];

  # Point native analysis at the nixpkgs Ghidra unless the caller overrides it.
  postInstall = lib.optionalString withGhidra ''
    for program in rea rea-agents; do
      wrapProgram "$out/bin/$program" \
        --set-default GHIDRA_INSTALL_DIR "${ghidra}/lib/ghidra" \
        --set-default JAVA_HOME "${openjdk21.home}"
    done
  '';

  meta = {
    description = "Reverse engineer anything with agents, from app behavior down to native binaries";
    homepage = "https://github.com/morluto/rea";
    changelog = "https://github.com/morluto/rea/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "rea";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
