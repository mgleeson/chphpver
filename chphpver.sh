#!/bin/bash
##############################################################################   
## Change PHP Version
## chphpver.sh
## @author: Matt Gleeson <https://github.com/mgleeson/chphpver>
## @build: 20260530
## @version: 3.0.0
##############################################################################   

set -o pipefail
PATH="${PATH}:/usr/local/sbin:/usr/sbin:/sbin"

main=1

##########################################################################
##### PARAMETERS/ARGUMENTS PRE-CHECKER
versionno="version: 3.0.0"
usage="Usage: 	chphpver [-h] [--help]
        -o VERSION|--old-version=VERSION -n VERSION|--new-version=VERSION [--version]"

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

validate_php_version "${OLDVERSION}" "old PHP version"
validate_php_version "${NEWVERSION}" "new PHP version"

if [ "${OLDVERSION}" = "${NEWVERSION}" ]; then
	err_exit "old PHP version and new PHP version must be different"
fi

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

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
	SUDO="sudo"
fi

run_privileged ()
{
	if [ -n "${SUDO}" ]; then
		"${SUDO}" "$@"
	else
		"$@"
	fi
}

toolsneeded=(
	"apt-cache"
	"apt-get"
	"a2dismod"
	"a2enmod"
	"dpkg"
	"service"
	"update-alternatives"
)

if [ -n "${SUDO}" ]; then
	toolsneeded+=("sudo")
fi

check_externals toolsneeded[@]

echo && echo 
echo "Old PHP version   = ${OLDVERSION}"
echo "New PHP version   = ${NEWVERSION}"
echo && echo


# Enable PPA for PHP ${NEWVERSION} in your system and install it.
# sudo add-apt-repository ppa:ondrej/php
# wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
# echo "deb https://packages.sury.org/php/ buster main" | sudo tee /etc/apt/sources.list.d/php.list

echo -e "${info} Please wait, updating apt... "
run_privileged apt-get -qq update
checkerr "apt-get update" "$?"

echo -e "${info} Please wait, installing PHP version ${NEWVERSION}... "
run_privileged apt-get -qq -y install "php${NEWVERSION}"
checkerr "install php${NEWVERSION}" "$?"

php_modules=(
	"php${NEWVERSION}-cli"
	"php${NEWVERSION}-common"
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

echo -e "${info} Please wait, installing PHP modules.. "
run_privileged apt-get install -qq -y "${php_modules[@]}"
checkerr "install PHP ${NEWVERSION} modules" "$?"

install_optional_php_package ()
{
	package="$1"

	if apt-cache show "${package}" >/dev/null 2>&1; then
		echo -e "${info} Please wait, installing optional PHP module ${package}... "
		run_privileged apt-get -qq -y install "${package}"
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
	run_privileged a2dismod "php${OLDVERSION}"
	checkerr "disable Apache PHP ${OLDVERSION} module" "$?"
else
	echo -e "${warn} Apache module php${OLDVERSION} not found, skipping disable"
fi

# a2enmod enables php${NEWVERSION} module within the apache2 configuration.
echo -e "${info} enabling new PHP version ${NEWVERSION} "
run_privileged a2enmod "php${NEWVERSION}"
checkerr "enable Apache PHP ${NEWVERSION} module" "$?"

# Restart apache2 service.
echo -e "${info} restarting Apache"
run_privileged service apache2 restart
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

	run_privileged update-alternatives --set "${name}" "${target}"
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
