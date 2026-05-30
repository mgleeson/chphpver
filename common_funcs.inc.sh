##############################################################################   
## Common functions
## common_funcs.inc.sh
## @author: Matt Gleeson <matt@mattgleeson.net>
## @version: 20170605
##############################################################################

##### for when stuff go wrong and we have nowhere else to go
##### for the night is dark and full of errors
cf_err_exit () 
{
	echo ""
	echo "$@" 1>&2
	echo -e "[\033[01;31m error \033[00m] at line: ${LINENO}"
	exit 1
}

## discourage running of this file directly - requires a var main to be set to 1 in including script
if [ "${main:-0}" -ne 1 ]; then
	echo -e "[\033[01;31m error \033[00m]      This is an include file - do not run directly"
	cf_err_exit
fi

# function debug() {
    # if [[ $DEBUG ]]
    # then
        # echo ">>> $*"
    # fi
# }


## check for other include files that this script depends on
if [[ "${checkerr_loaded}" == "true" ]] 
then
	echo -e "${ok} common_funcs.inc.sh dependencies loaded"
else
	echo -e "[\033[01;31m error \033[00m]      common_funcs.inc.sh dependencies not loaded: checkerr.inc.sh"
	cf_err_exit
fi


check_if_root ()
{
if [ "$(id -u)" != "0" ]; then
    echo "current UID = $(id -u) -- Root UID = 0"
     echo -e "[\033[01;31m error \033[00m]     Must be root to run this script."
     err_exit
  fi
}


cmdexist () {
    type "$1" &> /dev/null ;
}


exists () {
    item="$1"
    if [ -e "${item}" ]
    then
        if [ -d "${item}" ]
        then
            echo -e "${ok} Directory ${item} exists."
            return 0
        elif [ -f "${item}" ]
        then
            echo -e "${ok} File ${item} exists."
            return 0
        else
            echo -e "${ok} Filesystem object exists."
            return 0
        fi
    else
        echo -e "${err} The file or directory ${item} does not exist!"
        return 1
    fi
}


isset () {
    VAR="$1"
    if [ -z "${!VAR+x}" ] || [ -z "${!VAR}" ]
    then
        echo -e "${warn} the var $VAR is not set or is empty"
        return 1
    else
        VALUE="${!VAR}"
        echo -e "${ok} the var $VAR is set to $VALUE"
        return 0
    fi
}


option_enabled () {

    _var="$1"
    var_value=$(eval echo \$$_var)
    if [[ "${var_value}" == "y" ]] || [[ "${var_value}" == "yes" ]] || [[ "${var_value}" == "true" ]] || [[ "${var_value}" == "TRUE" ]] || [[ "${var_value}" == "1" ]]
    then
		echo -e "${ok} Option ${_var} is enabled (value set to ${var_value})"
        return 0
    else
		echo -e "${warn} Option ${_var} is not enabled (value set to ${var_value})"
        return 1
    fi
}


has_internet () {
externalIp=`curl -4s icanhazip.com`
exitCode=$?
# echo "has internet? ${exitCode}"
# echo "${externalIp}"

return "${externalIp}"
}

distro=""


whatOS () {
UNAME=$(uname | tr "[:upper:]" "[:lower:]")
if [ "$UNAME" == "linux" ]; then
    if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
        distro=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
    else
        export distro=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
    fi
fi
if [ "$distro" == "" ]; then 
 distro=$UNAME
fi
unset UNAME
# return distro
}


  

## Check required tools exist
check_externals () {

## This function takes an array as parameters
## example:
##
##  toolsneeded=(
##			"git"
##			"unzip"
##			"tar"
##			"mysql"
##			"curl"
##			"expect"
##			"locate"
##			"composer"
##			"php"
## )

## check_externals toolsneeded[@]

declare -a extNeeded=("${!1}")


missingExt=0


echo
echo -e "${info} Checking required tools installed..."
echo
echo -e "${info} externals needed: ${extNeeded[@]}"
echo


for t in "${extNeeded[@]}"
do
		cmdexist "${t}" 
	if [ $? -eq 0 ]; then
	echo -e "${ok} ${yellow}${t}${rst} found"
	else
	echo -e "${warn} command/tool ${red}${t}${rst} not found"
	missingExt=$((missingExt+1))
	fi
done 

if [ ${missingExt} -gt 0 ]; then
	echo -e "${err} There are ${missingExt} tools/commands missing, check above for details"
	exit 1
else
	echo ""
	echo -e "${ok} all required external tools/commands appear to be present"
	echo -e "${info} end toolcheck\n\n"
	
	
fi

}



common_funcs_loaded="true"
echo -e "${ok} common_funcs.inc.sh loaded"
## 
## END Common functions
##############################################################################
