#!/bin/bash
##############################################################################   
## Change PHP Version
## chphpver
## @author: Matt Gleeson <https://github.com/mgleeson/chphpver>
## @build: 20260530
## @version: 3.2.0
##############################################################################   

set -o pipefail
PATH="${PATH}:/usr/local/sbin:/usr/sbin:/sbin"

main=1

##########################################################################
##### PARAMETERS/ARGUMENTS PRE-CHECKER
versionno="version: 3.2.0"
usage="Usage: 	chphpver [-h] [--help] [--dry-run]
        [-o VERSION|--old-version=VERSION] -n VERSION|--new-version=VERSION [--version]"

#####
##########################################################################

##########################################################################
## ERR HANDLING & GENERAL PURPOSE GOODNESS
## ...for the night is dark and full of errors
_date=$(date +%Y-%m-%d)

err_exit () 
{
	echo ""
	echo "$@" 1>&2
	echo -e "[\033[01;31m error \033[00m] at line: ${LINENO}"
	exit 1
}

bail () 
{
	echo ""
	echo "$@" 1>&2
	echo -e "[\033[01;31m exited \033[00m] "
	exit 0
} 

OLDVERSION=""
NEWVERSION=""
DRY_RUN="false"

while [ "$#" -gt 0 ]
do
case "$1" in
    -o=*|--old-version=*)
    OLDVERSION="${1#*=}"
	OLDVERSION="${OLDVERSION%/}"
    shift
    ;;
    -o|--old-version)
    if [ "$#" -lt 2 ]; then
        echo "${usage}" 1>&2
        err_exit "missing old PHP version"
    fi
    OLDVERSION="${2%/}"
    shift 2
    ;;
    -n=*|--new-version=*)
    NEWVERSION="${1#*=}"
	NEWVERSION="${NEWVERSION%/}"
    shift
    ;;
    -n|--new-version)
    if [ "$#" -lt 2 ]; then
        echo "${usage}" 1>&2
        err_exit "missing new PHP version"
    fi
    NEWVERSION="${2%/}"
    shift 2
    ;;
    --dry-run)
         DRY_RUN="true"; shift ;;
    --version|-v)
         echo "${versionno}"; exit 0 ;;
    --help|-h)
         echo "${usage}"; exit 0 ;;
      -- )     # Stop option processing
        shift; break ;;
      - )	# Use stdin as input.
        break ;;
      -* )
        echo "${usage}" 1>&2; exit 1 ;;
      * )
        echo "${usage}" 1>&2; exit 1 ;;
esac
done

validate_php_version ()
{
	version="$1"
	label="$2"

	if [ -z "${version}" ]; then
		echo "${usage}" 1>&2
		err_exit "${label} is required"
	fi

	if ! [[ "${version}" =~ ^[0-9]+[.][0-9]+$ ]]; then
		err_exit "${label} must be a PHP version number such as 7.4, 8.1 or 8.3"
	fi
}

if [ -n "${OLDVERSION}" ]; then
	validate_php_version "${OLDVERSION}" "old PHP version"
fi
validate_php_version "${NEWVERSION}" "new PHP version"

#### where are we?
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${DIR}" ]]; then DIR="${PWD}"; fi

#### include for error checker function and output colouring
load_checkerr ()
{

## is checkerr here?
if [ -e "${DIR}/checkerr.inc.sh" ]; then
	echo -e "[\033[01;32m  OK  \033[00m]     checkerr found"
	. "${DIR}/checkerr.inc.sh"
else
	echo -e "[\033[01;31m  ERROR  \033[00m]      checkerr not found"
	err_exit "required dependency missing: ${DIR}/checkerr.inc.sh"
fi
}
load_checkerr
## TODO: make checker universal and pass script name via argument

## END ERR HANDLING
##########################################################################


##########################################################################
## LOAD COMMON FUNCS
load_commonfuncs ()
{
if [ -e "${DIR}/common_funcs.inc.sh" ]; then
	echo -e "[\033[01;32m  OK  \033[00m]     common_funcs found"
	. "${DIR}/common_funcs.inc.sh"
else
	echo -e "${err} common_funcs not found"
	err_exit "required dependency missing: ${DIR}/common_funcs.inc.sh"
fi
}
load_commonfuncs
## END LOAD COMMON FUNCS
##########################################################################

if [ "$(id -u)" -ne 0 ]; then
	err_exit "must be run as root"
fi

toolsneeded=(
	"apt-cache"
	"apt-get"
	"a2dismod"
	"a2enmod"
	"dpkg"
	"grep"
	"service"
	"update-alternatives"
)

check_externals toolsneeded[@]

php_modules=(
	"php${NEWVERSION}-cli"
	"php${NEWVERSION}-common"
	"libapache2-mod-php${NEWVERSION}"
	"php${NEWVERSION}-opcache"
	"php${NEWVERSION}-mysql"
	"php${NEWVERSION}-mbstring"
	"php${NEWVERSION}-zip"
	"php${NEWVERSION}-fpm"
	"php${NEWVERSION}-intl"
	"php${NEWVERSION}-dev"
	"php${NEWVERSION}-curl"
	"php${NEWVERSION}-gd"
	"php${NEWVERSION}-soap"
	"php${NEWVERSION}-xml"
)

required_php_packages=("php${NEWVERSION}" "${php_modules[@]}")
missing_php_packages=()
OS_ID=""
OS_VERSION=""
OS_CODENAME=""
REPO_TYPE=""

package_available ()
{
	apt-cache show "$1" >/dev/null 2>&1
}

detect_current_php_version ()
{
	detected_version=""
	detected_count=0

	for module in /etc/apache2/mods-enabled/php*.load
	do
		[ -e "${module}" ] || [ -L "${module}" ] || continue
		module_name="${module##*/}"
		module_version="${module_name#php}"
		module_version="${module_version%.load}"

		if [[ "${module_version}" =~ ^[0-9]+[.][0-9]+$ ]]; then
			detected_version="${module_version}"
			detected_count=$((detected_count+1))
		fi
	done

	if [ "${detected_count}" -eq 1 ]; then
		OLDVERSION="${detected_version}"
		echo -e "${ok} detected active Apache PHP version ${OLDVERSION}"
		return 0
	fi

	if [ "${detected_count}" -gt 1 ]; then
		err_exit "multiple active Apache PHP modules found; specify --old-version explicitly"
	fi

	if cmdexist php; then
		detected_version="$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;' 2>/dev/null || true)"
		if [[ "${detected_version}" =~ ^[0-9]+[.][0-9]+$ ]]; then
			OLDVERSION="${detected_version}"
			echo -e "${warn} active Apache PHP module not found; using current PHP CLI version ${OLDVERSION}"
			return 0
		fi
	fi

	err_exit "unable to detect current PHP version; specify --old-version explicitly"
}

ensure_old_php_version ()
{
	if [ -z "${OLDVERSION}" ]; then
		detect_current_php_version
	fi

	validate_php_version "${OLDVERSION}" "old PHP version"

	if [ "${OLDVERSION}" = "${NEWVERSION}" ]; then
		err_exit "old PHP version and new PHP version must be different"
	fi
}

get_missing_required_php_packages ()
{
	missing_php_packages=()

	for package in "${required_php_packages[@]}"
	do
		if ! package_available "${package}"; then
			missing_php_packages+=("${package}")
		fi
	done

	[ "${#missing_php_packages[@]}" -eq 0 ]
}

detect_distro ()
{
	if [ ! -r /etc/os-release ]; then
		err_exit "unable to detect distribution: /etc/os-release not found"
	fi

	# shellcheck disable=SC1091
	. /etc/os-release

	OS_ID="${ID:-}"
	OS_VERSION="${VERSION:-}"
	OS_CODENAME="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"

	if [ -z "${OS_ID}" ]; then
		err_exit "unable to detect distribution ID from /etc/os-release"
	fi

	if [ -z "${OS_CODENAME}" ]; then
		err_exit "unable to detect distribution codename from /etc/os-release"
	fi

	case "${OS_ID}" in
		ubuntu)
			REPO_TYPE="ubuntu"
			if [[ "${OS_VERSION}" != *"LTS"* ]]; then
				err_exit "Ondrej PHP PPA support is limited to current Ubuntu LTS releases"
			fi
			;;
		debian)
			REPO_TYPE="debian"
			;;
		*)
			err_exit "unsupported distribution for automatic PHP repository setup: ${OS_ID}"
			;;
	esac

	echo -e "${ok} detected ${OS_ID} ${OS_CODENAME}"
}

php_repository_configured ()
{
	case "${REPO_TYPE}" in
		ubuntu)
			grep -R -Eqs 'ppa[.]launchpad(content)?[.]net/ondrej/php|ppa:ondrej/php|ondrej/php' /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null
			;;
		debian)
			grep -R -Eqs 'packages[.]sury[.]org/php' /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null
			;;
		*)
			return 1
			;;
	esac
}

repository_label ()
{
	case "${REPO_TYPE}" in
		ubuntu)
			echo "ppa:ondrej/php"
			;;
		debian)
			echo "packages.sury.org/php"
			;;
		*)
			echo "Ondrej PHP repository"
			;;
	esac
}

show_repository_bootstrap_status ()
{
	case "${REPO_TYPE}" in
		ubuntu)
			if cmdexist add-apt-repository; then
				echo -e "${ok} add-apt-repository found"
			else
				echo -e "${warn} add-apt-repository not found; software-properties-common would be installed before adding the PPA"
			fi
			;;
		debian)
			if cmdexist curl; then
				echo -e "${ok} curl found"
			else
				echo -e "${warn} curl not found; ca-certificates and curl would be installed before adding the repository"
			fi
			;;
	esac

	if [ -d /etc/apt/sources.list.d ] && [ -w /etc/apt/sources.list.d ]; then
		echo -e "${ok} apt sources directory is writable"
	else
		echo -e "${warn} apt sources directory is not writable or not present"
	fi
}

add_php_repository ()
{
	case "${REPO_TYPE}" in
		ubuntu)
			if ! cmdexist add-apt-repository; then
				echo -e "${info} installing repository helper package... "
				apt-get -qq -y install software-properties-common
				checkerr "install software-properties-common" "$?"
			fi

			echo -e "${info} adding PHP repository ppa:ondrej/php... "
			add-apt-repository -y ppa:ondrej/php
			checkerr "add ppa:ondrej/php" "$?"
			;;
		debian)
			echo -e "${info} installing repository helper packages... "
			apt-get -qq -y install ca-certificates curl
			checkerr "install repository helper packages" "$?"

			if ! cmdexist curl; then
				err_exit "curl is required to add the Debian PHP repository"
			fi

			echo -e "${info} adding PHP repository packages.sury.org/php... "
			curl -fsSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
			checkerr "download deb.sury.org keyring" "$?"
			dpkg -i /tmp/debsuryorg-archive-keyring.deb
			checkerr "install deb.sury.org keyring" "$?"
			printf 'deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ %s main\n' "${OS_CODENAME}" > /etc/apt/sources.list.d/sury-php.list
			checkerr "write Sury PHP apt source" "$?"
			;;
		*)
			err_exit "unsupported repository type"
			;;
	esac
}

check_apache_layout ()
{
	if [ ! -d /etc/apache2/mods-available ]; then
		err_exit "Apache mods-available directory not found"
	fi

	if [ ! -d /etc/apache2/mods-enabled ]; then
		err_exit "Apache mods-enabled directory not found"
	fi

	echo -e "${ok} Apache module directories found"
}

show_php_package_status ()
{
	for package in "${required_php_packages[@]}"
	do
		if package_available "${package}"; then
			echo -e "${ok} ${package} available in apt cache"
		else
			echo -e "${warn} ${package} not available in apt cache"
		fi
	done
}

ensure_required_php_packages_available ()
{
	if get_missing_required_php_packages; then
		echo -e "${ok} required PHP packages are available"
		return 0
	fi

	echo -e "${warn} required PHP packages unavailable: ${missing_php_packages[*]}"
	detect_distro

	if php_repository_configured; then
		err_exit "required PHP packages are unavailable even though $(repository_label) appears configured: ${missing_php_packages[*]}"
	fi

	echo -e "${info} $(repository_label) is not configured; adding it now"
	add_php_repository

	echo -e "${info} Please wait, updating apt after repository setup... "
	apt-get -qq update
	checkerr "apt-get update after PHP repository setup" "$?"

	if ! get_missing_required_php_packages; then
		err_exit "required PHP packages are still unavailable after adding $(repository_label): ${missing_php_packages[*]}"
	fi

	echo -e "${ok} required PHP packages are available"
}

run_dry_run ()
{
	echo -e "${info} dry run only, no system changes will be made"
	check_apache_layout
	detect_distro
	show_php_package_status

	if get_missing_required_php_packages; then
		echo -e "${ok} required PHP packages are available"
	else
		echo -e "${warn} required PHP packages unavailable in current apt cache: ${missing_php_packages[*]}"

		if php_repository_configured; then
			echo -e "${warn} $(repository_label) appears to be configured; apt metadata may need to be updated"
		else
			echo -e "${info} $(repository_label) is not configured and would be added before installing PHP ${NEWVERSION}"
			show_repository_bootstrap_status
		fi
	fi

	if [ -e "/etc/apache2/mods-available/php${OLDVERSION}.load" ] || [ -e "/etc/apache2/mods-enabled/php${OLDVERSION}.load" ]; then
		echo -e "${ok} old Apache PHP module php${OLDVERSION} found"
	else
		echo -e "${warn} old Apache PHP module php${OLDVERSION} not found; disable step would be skipped"
	fi

	echo -e "${info} would run apt-get update"
	echo -e "${info} would install PHP ${NEWVERSION} and required modules"
	echo -e "${info} would enable Apache PHP module php${NEWVERSION}, restart Apache, and update CLI alternatives"
	echo && echo "Dry run complete. No changes made." && echo
	exit 0
}

ensure_old_php_version

echo && echo
echo "Old PHP version   = ${OLDVERSION}"
echo "New PHP version   = ${NEWVERSION}"
echo "Dry run           = ${DRY_RUN}"
echo && echo

if [ "${DRY_RUN}" = "true" ]; then
	run_dry_run
fi

check_apache_layout

echo -e "${info} Please wait, updating apt... "
apt-get -qq update
checkerr "apt-get update" "$?"

ensure_required_php_packages_available

echo -e "${info} Please wait, installing PHP version ${NEWVERSION}... "
apt-get -qq -y install "php${NEWVERSION}"
checkerr "install php${NEWVERSION}" "$?"

echo -e "${info} Please wait, installing PHP modules.. "
apt-get install -qq -y "${php_modules[@]}"
checkerr "install PHP ${NEWVERSION} modules" "$?"

install_optional_php_package ()
{
	package="$1"

	if apt-cache show "${package}" >/dev/null 2>&1; then
		echo -e "${info} Please wait, installing optional PHP module ${package}... "
		apt-get -qq -y install "${package}"
		checkerr "install ${package}" "$?"
	else
		echo -e "${warn} optional PHP module ${package} is not available, skipping"
	fi
}

install_phpjson() {
	if dpkg --compare-versions "${NEWVERSION}" lt "8.0"; then
		install_optional_php_package "php${NEWVERSION}-json"
	fi
}
install_phpjson
install_optional_php_package "php${NEWVERSION}-xmlrpc"

# a2dismod disables the php${OLDVERSION} module by removing those symlinks.
echo -e "${info} disabling old PHP version ${OLDVERSION} "
if [ -e "/etc/apache2/mods-available/php${OLDVERSION}.load" ] || [ -e "/etc/apache2/mods-enabled/php${OLDVERSION}.load" ]; then
	a2dismod "php${OLDVERSION}"
	checkerr "disable Apache PHP ${OLDVERSION} module" "$?"
else
	echo -e "${warn} Apache module php${OLDVERSION} not found, skipping disable"
fi

# a2enmod enables php${NEWVERSION} module within the apache2 configuration.
echo -e "${info} enabling new PHP version ${NEWVERSION} "
a2enmod "php${NEWVERSION}"
checkerr "enable Apache PHP ${NEWVERSION} module" "$?"

# Restart apache2 service.
echo -e "${info} restarting Apache"
service apache2 restart
checkerr "restart Apache" "$?"

set_php_alternative ()
{
	name="$1"
	target="$2"
	required="${3:-true}"

	if [ ! -e "${target}" ]; then
		if [ "${required}" = "true" ]; then
			err_exit "required alternative target not found: ${target}"
		fi

		echo -e "${warn} ${target} not found, skipping ${name} alternative"
		return 0
	fi

	update-alternatives --set "${name}" "${target}"
	checkerr "update ${name} alternative" "$?"
}

# Set alternative name path.
set_php_alternative "php" "/usr/bin/php${NEWVERSION}"
set_php_alternative "phar" "/usr/bin/phar${NEWVERSION}" "false"
set_php_alternative "phar.phar" "/usr/bin/phar.phar${NEWVERSION}" "false"
set_php_alternative "phpize" "/usr/bin/phpize${NEWVERSION}"
set_php_alternative "php-config" "/usr/bin/php-config${NEWVERSION}"

echo && echo
echo "PHP ${NEWVERSION} now enabled"
echo && echo
