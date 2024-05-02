###########################################################################################
## checkerr - check for error on previous execution & output colouring
##
## @author: Matt Gleeson <matt@mattgleeson.net>
## @description: for error checking of immediately previous command & output colouring
## @version: 20161115-20170605
## @usage: for output colouring eg.
##      echo -e "${err} error msg ${yellow}this will be yellow${rst} this will be normal"
##      echo -e "${warn} a warning ${red}this will be red${rst}"
##      echo -e "${ok} an OK message"
##  echo -e "${info} info message"
##  echo -e "${done} done message"
##
## for error checks for immediately previous executed commands, include the following
## after the command - more descriptive messages can be specified in place of $_ if needed:
##
## checkerr "$_" "$?"
##


red='\033[01;31m'
blue='\033[01;34m'
green='\033[01;32m'
yellow='\033[0;33m'
rst='\033[00m'
nonFatal="false"

space="     "
margin="         "
err="[ ${red}ERROR${rst} ]${space}"
info="[ ${blue}INFO${rst} ] ${space}"
warn="[ ${yellow}WARN${rst} ] ${space}"
ok="[  ${green}OK${rst}  ] ${space}"
done="[ ${blue}DONE${rst} ] ${space}"


checkerr () {
prog="$1"
status="$2"

nonFatal="$3"

if [ ! -n "${nonFatal+x}" ]; then
                         nonFatal="false"
fi

if [ ${status} -eq 0 ]; then
                echo -e "${ok} ${blue}${prog}${rst} ${green}success${rst}"

        else
                echo "" && echo ""
                echo -e "${err} execution of ${prog} ${red}failed${rst} with status: ${status}"
                echo "" && echo ""
                # if [ nonFatal = "false" ]; then
                        exit 1
                # else
                        # return 1
                # fi
fi
}

## set checkerr_loaded var to true to allow scritps or other includes that depend on it to check for it before running
checkerr_loaded="true"
echo -e "${ok} checkerr loaded" ; echo
##
## END CHECKERR
##############################################################################