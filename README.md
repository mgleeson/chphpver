# chphpver

`chphpver` is a small Bash helper I created to help switching an Apache host from one PHP version to another for development servers (on Debian/Ubuntu-style systems).

The script updates apt, installs the target PHP version and the common PHP modules I normally need (mostly for the Moodle LMS), disables the old Apache PHP module, enables the new one, restarts Apache, and updates the PHP CLI alternatives.

## Requirements

This script is intended for Ubuntu/Debian (or derivative) servers.

Required commands:

* `apt-get`
* `apt-cache`
* `a2dismod`
* `a2enmod`
* `dpkg`
* `service`
* `update-alternatives`
* `sudo`, when not running as root

The PHP packages must already be available from the configured apt repositories. If the target version is provided by a third-party repository such as Ondřej Surý's PHP packages, enable that repository before running this script.

## Usage

```bash
./chphpver.sh --old-version=7.4 --new-version=8.3
```

Short options are also supported:

```bash
./chphpver.sh -o 7.4 -n 8.3
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

Optional PHP modules are installed only when the package exists in apt. This keeps the version switch from failing on modules that are no longer packaged for newer PHP versions.

## Changelog

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
