# chphpver

`chphpver` is a small Bash helper I created to help switch an Apache host from one PHP version to another for development servers on Debian/Ubuntu-style systems.

The script updates apt, installs the target PHP version and the common PHP modules I normally need (mostly for the Moodle LMS), disables the old Apache PHP module, enables the new one, restarts Apache, and updates the PHP CLI alternatives.

## Version: v3.2.0

## Requirements

This script is intended for Debian and current Ubuntu LTS servers running Apache with `mod_php`.

Run the script as root. The script checks for root directly and does not use `sudo` internally.

Required commands:

* `apt-get`
* `apt-cache`
* `a2dismod`
* `a2enmod`
* `dpkg`
* `grep`
* `service`
* `update-alternatives`

When the target PHP packages are not available from the current apt repositories, the script can add Ondřej Surý's PHP repository automatically:

* Ubuntu uses `ppa:ondrej/php`.
* Debian uses `packages.sury.org/php` with the packaged keyring and a signed apt source.

On Ubuntu, `software-properties-common` is installed if `add-apt-repository` is not already available. On Debian, `ca-certificates` and `curl` are installed if the Debian PHP repository needs to be added.

## Usage

Run a dry run first to check tools, Apache paths, package availability, and repository status without making changes. The current PHP version is detected automatically and used as the old version:

```bash
sudo ./chphpver.sh --new-version=8.3 --dry-run
```

Run the switch:

```bash
sudo ./chphpver.sh --new-version=8.3
```

Short options are also supported:

```bash
sudo ./chphpver.sh -n 8.3
```

The old PHP version can still be provided explicitly when needed:

```bash
sudo ./chphpver.sh --old-version=7.4 --new-version=8.3
```

Show help:

```bash
./chphpver.sh --help
```

Show the script version:

```bash
./chphpver.sh --version
```

## Notes

The script expects PHP version numbers in the package-name format used by Debian/Ubuntu, for example `7.4`, `8.1`, `8.2`, or `8.3`.

By default, the old PHP version is detected from the active Apache PHP module. If no active Apache PHP module is found, the script falls back to the current PHP CLI version. Use `--old-version` when the Apache module and CLI version do not match, or when the version needs to be forced explicitly.

Optional PHP modules are installed only when the package exists in apt. This keeps the version switch from failing on modules that are no longer packaged for newer PHP versions.

The repository setup is only attempted when required PHP packages are unavailable after the normal apt metadata update. If the target packages are already available, no repository changes are made.

This script is designed for Apache `mod_php`. It installs PHP-FPM because I commonly need it available, but it does not configure sites to use PHP-FPM.

## Changelog

### v3.2.0 - 2026-05-30

* Added automatic current PHP version detection so `--old-version` is no longer required for normal use.
* Prefer the active Apache PHP module when detecting the old version, with a PHP CLI fallback when no active Apache module is found.
* Kept `--old-version` available as an explicit override for hosts where Apache and CLI PHP versions intentionally differ.

### v3.1.0 - 2026-05-30

* Added `--dry-run` to check tools, Apache paths, package availability, and repository status without making changes.
* Added direct root checks and removed internal `sudo` usage.
* Added Debian/Ubuntu distro detection for automatic PHP repository setup.
* Added automatic setup for Ondřej Surý's PHP repositories when required PHP packages are unavailable from the current apt repositories.
* Added required PHP package checks before installation so missing packages fail earlier and with clearer output.
* Installed the matching Apache `mod_php` package explicitly before enabling the new Apache PHP module.
* Updated documentation for dry-run mode, root execution, and repository handling.

### v3.0.0 - 2026-05-30

* Added argument validation so the script no longer falls through to `php0` package/module names when required versions are missing.
* Added support for both `--old-version=7.4` and `--old-version 7.4` style arguments.
* Removed automatic remote downloading of local include files.
* Added command preflight checks before package and Apache changes are made.
* Fixed the PHP XML package name from `simplexml` to the distro `xml` package.
* Made optional modules such as `xmlrpc` and legacy `json` non-fatal when not available in apt.
* Fixed the legacy JSON module handling so it only applies before PHP 8.0.
* Allowed the script to run as root without requiring `sudo`.
* Skipped disabling the old Apache module when that module is not present.
* Added safer handling around update-alternatives targets.
* Hardened small helper functions used by the main script.
