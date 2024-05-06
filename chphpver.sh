#!/bin/bash
##############################################################################   
## Change PHP Version
## chphpver.sh
## @author: Matt Gleeson <matt@mattgleeson.net>
## @build: 20240422
## @version: 2.0.0 
##############################################################################   

# set -u
# set -e errexit

main=1

##########################################################################
##### PARAMETERS/ARGUMENTS PRE-CHECKER
versionno="version: 2.0.0"
usage="\
Usage: 	chphpver [-h] [--help] 
        [-o][--old-version=VERSION] [-n][--new-version=VERSION] [--version]"

# if [ "$#" -lt 2 ]
# then
#     echo "${usage}" 1>&2
#     exit 1
# fi

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

#### where are we?
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${DIR}" ]]; then DIR="${PWD}"; fi

## TODO: do check/download function for other dependencies also 

#### include for error checker function and output colouring
load_checkerr ()
{

## is checkerr here?
if [ -e ${DIR}/checkerr.inc.sh ]; then
	echo -e "[\033[01;32m  OK  \033[00m]     checkerr found"
	. "${DIR}/checkerr.inc.sh"
else
	echo -e "[\033[01;31m  WARNING  \033[00m]     checkerr not found"
	echo -e "${info} don't worry, I get it for you... getting..."
	wget -O checkerr.inc.sh http://bit.ly/checkerr-sh
	. "${DIR}/checkerr.inc.sh"
	if [[ "${checkerr_loaded}" == "true" ]] 
		then
		echo -e "${ok} checkerr downloaded and loaded"
	else
		echo -e "[\033[01;31m  ERROR  \033[00m]      dependency not downloaded and not loaded: checkerr.inc.sh"
		err_exit
	fi
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
if [ -e ${DIR}/common_funcs.inc.sh ]; then
	echo -e "[\033[01;32m  OK  \033[00m]     common_funcs found"
	. "${DIR}/common_funcs.inc.sh"
else
	echo -e "[\033[01;31m  WARNING  \033[00m]     common_funcs not found"
	echo -e "${info} don't worry, I get it for you... getting..."
	wget -O common_funcs.inc.sh https://gist.githubusercontent.com/mgleeson/5462af50483740d2c54f2249e9827191/raw/3d03024e535339bbac498d1e4bab347242c89fe6/common_funcs.inc.sh
	. "${DIR}/common_funcs.inc.sh"
	if [[ "${common_funcs_loaded}" == "true" ]] 
		then
		echo -e "${ok} common_funcs downloaded and loaded"
	else
		echo -e "[\033[01;31m  ERROR  \033[00m]      dependency not downloaded and not loaded: common_funcs.inc.sh"
		err_exit
	fi
fi
}
load_commonfuncs
## END LOAD COMMON FUNCS
##########################################################################

OLDVERSION=0
NEWVERSION=0

for PARAMS in "$@"
do
case $PARAMS in
    -o=*|--old-version=*)
    OLDVERSION="${PARAMS#*=}"
	OLDVERSION=${OLDVERSION%/}
    shift 
    ;;
    -n=*|--new-version=*)
    NEWVERSION="${PARAMS#*=}"
	NEWVERSION=${NEWVERSION%/}
    shift 
    ;;
    --version|-v*)
         echo ${versionno}; shift ;;
      -- )     # Stop option processing
        shift; break ;;
      - )	# Use stdin as input.
        break ;;
      -* )
        echo "${usage}" 1>&2; exit 1 ;;
      * )
        break ;;
esac
done

echo && echo 
echo "Old PHP version   = ${OLDVERSION}"
echo "New PHP version   = ${NEWVERSION}"
echo && echo


# Enable PPA for PHP ${NEWVERSION} in your system and install it.
# sudo add-apt-repository ppa:ondrej/php
# wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
# echo "deb https://packages.sury.org/php/ buster main" | sudo tee /etc/apt/sources.list.d/php.list

echo -e "${info} Please wait, updating apt... "
sudo apt-get -qq update
checkerr "$_" "$?"

echo -e "${info} Please wait, installing PHP version ${NEWVERSION}... "
sudo apt-get -qq -y install php${NEWVERSION}
checkerr "$_" "$?"

echo -e "${info} Please wait, installing PHP modules.. "
sudo apt-get install -qq -y php${NEWVERSION}-cli php${NEWVERSION}-common php${NEWVERSION}-opcache php${NEWVERSION}-mysql php${NEWVERSION}-mbstring  php${NEWVERSION}-zip php${NEWVERSION}-fpm php${NEWVERSION}-intl php${NEWVERSION}-simplexml php${NEWVERSION}-dev php${NEWVERSION}-curl php${NEWVERSION}-gd php${NEWVERSION}-soap php${NEWVERSION}-xmlrpc
checkerr "$_" "$?"

# function to ensure the variable $NEWVERSION is numberic, and convert it if it is not, then check if $NEWVERSION is 8.0 or less go ahead and apt-get install php${NEWVERSION}-json
install_phpjson() {
  threshold=8.0
  if [ -n "$NEWVERSION" -a -n "$threshold" ];then
    result=$(awk -vn1="$NEWVERSION" -vn2="$threshold" 'BEGIN{print (n1>n2)?1:0 }')
    if [ "$result" -eq 1 ];then
        apt-get -qq -y install php${NEWVERSION}-json
		checkerr "$_" "$?"  
    fi
  fi
}
install_phpjson
checkerr "$_" "$?"

# a2dismod disables the php${OLDVERSION} module by removing those symlinks.
echo -e "${info} disabling old PHP version ${OLDVERSION} "
sudo a2dismod php${OLDVERSION}
checkerr "$_" "$?"

# a2enmod enables php${NEWVERSION} module within the apache2 configuration.
echo -e "${info} enabling new PHP version ${NEWVERSION} "
sudo a2enmod php${NEWVERSION}
checkerr "$_" "$?"

# Restart apache2 service.
echo -e "${info} restarting Apache"
sudo service apache2 restart
checkerr "$_" "$?"

# Set alternative name path.
sudo update-alternatives --set php /usr/bin/php${NEWVERSION}
checkerr "$_" "$?"

sudo update-alternatives --set phar /usr/bin/phar${NEWVERSION}
checkerr "$_" "$?"

sudo update-alternatives --set phar.phar /usr/bin/phar.phar${NEWVERSION}
checkerr "$_" "$?"

sudo update-alternatives --set phpize /usr/bin/phpize${NEWVERSION}
checkerr "$_" "$?"

sudo update-alternatives --set php-config /usr/bin/php-config${NEWVERSION}
checkerr "$_" "$?"

echo && echo
echo "PHP ${NEWVERSION} now "
echo && echo
