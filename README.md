<p align="center">
  <img src="assets/logo.svg" alt="REA plus Nix" width="480" />
</p>

<h1 align="center">rea-flake</h1>

<p align="center">
  <a href="flake.nix"><img src="https://img.shields.io/badge/Nix-flake-5277C3?logo=nixos&logoColor=white" alt="Nix flake" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT license" /></a>
  <a href="https://github.com/morluto/rea/releases/tag/v6.5.0"><img src="https://img.shields.io/badge/rea-6.5.0-20252b" alt="REA 6.5.0" /></a>
</p>

[REA (Reverse Engineer Anything)](https://github.com/morluto/rea) is a reverse engineering CLI and MCP server for AI agents. It covers native binaries, JavaScript and Electron apps, .NET assemblies, Android packages, firmware and websites.

This flake packages the published `rea-agents` npm release with a pinned lockfile and wires in Ghidra from nixpkgs, so native decompilation works out of the box. There is no `npx`, global npm install or `rea setup` download. It supports x86_64 and ARM64 Linux.

```sh
nix run github:Fractal-Tess/rea-flake -- doctor --provider ghidra
```

## Install in a Nix configuration

Add the flake input:

```nix
inputs.rea-flake.url = "github:Fractal-Tess/rea-flake";
```

Use the NixOS or Home Manager module:

```nix
# NixOS
{
  imports = [ inputs.rea-flake.nixosModules.default ];
  programs.rea.enable = true;
}

# Home Manager
{
  imports = [ inputs.rea-flake.homeManagerModules.default ];
  programs.rea.enable = true;
}
```

The module defaults to the flake package. Override `programs.rea.package` if needed, or use `overlays.default` to expose `pkgs.rea`.

## Register with an agent

The package installs `rea` on your `PATH`. Register its MCP server with your agent, for example:

```sh
claude mcp add --scope user rea -- rea mcp
```

`rea mcp add` and `rea setup` can register other clients too. Skip setup's Hopper install, since the Ghidra provider is already configured.

## Notes

- `GHIDRA_INSTALL_DIR` and `JAVA_HOME` default to nixpkgs Ghidra and JDK 21. Set either variable to use another installation, or build with `rea.override { withGhidra = false; }` to leave Ghidra out.
- Frida is left out because its install script downloads prebuilt binaries. Frida-backed tools report it as unavailable.
- `rea doctor` reports NixOS as an unsupported host. That check only affects automated Hopper setup.
- Other optional tools such as JADX, apktool, binwalk, rizin and tshark are found on `PATH` or through their `REA_*_COMMAND` variables.

Because the package is immutable, update it through the flake rather than with `npm update`.

## Update

The daily [update workflow](.github/workflows/update.yml) runs at 12:00 UTC, checks the latest npm release, regenerates the lockfile and both hashes, validates the package, and commits an update. Run the same process locally with:

```sh
./scripts/update.sh
```

Pass a stable version such as `./scripts/update.sh 6.5.0` to update to a specific release. The workflow can also be started manually from GitHub Actions.

## Credits

[GitHub](https://github.com/Fractal-Tess/rea-flake)

The flake packaging is [MIT](LICENSE). REA is [MIT licensed](https://github.com/morluto/rea/blob/main/LICENSE), © morluto.

The lockup combines the [REA mark](https://github.com/morluto/rea/blob/main/website/public/assets/favicon.svg) with the [Nix snowflake](https://github.com/NixOS/nixos-artwork/tree/master/logo) by Simon Frankau and Tim Cuthbertson ([CC BY 4.0](https://creativecommons.org/licenses/by/4.0)), resized and arranged here. REA's authors are not affiliated with or endorsing this flake.
