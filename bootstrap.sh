#!/bin/bash

#################
# CONFIGURATION #
#################

gitMinVersion="1:2.25.1-1ubuntu3.6"
gitRepositoryUrl="https://bitbucket.dormakaba.net/scm/cccdev/developer-workplace-ubuntu-ansible.git"
gitRepositoryFolder="/tmp/dwp"

#############
# FUNCTIONS #
#############

# --------------------------------------------------------
# Function for creating log entries on the console
# --------------------------------------------------------
# $1 - Log level
# $2 - Log text
# --------------------------------------------------------
function log() {

    # read parameters
    local level="$1"
    local text="$2"

    # create log message
    local now=$(date +"%d-%m-%Y %H:%M:%S")
    echo -e "\n$now [$level] $text\n"
}

# --------------------------------------------------------
# Function for checking if a tool min version is installed
# --------------------------------------------------------
# $1 - Tool name
# $2 - Min version
# --------------------------------------------------------
function toolInstalled() {

    local tool="$1"
    local minVersion="$2"

    log "INFO" "Checking installation of min version $minVersion for tool $tool"

    local installed="$(dpkg -s $tool | grep "Status: install ok installed")"
    if [ "$installed" != "" ]
    then
        local version="$(dpkg -s $tool | grep "Version:" | awk '{print $2}')"
        return $(dpkg --compare-versions "$version" "ge" "$minVersion")
    fi

    return 1
}

# --------------------------------------------------------
# Function for installing dependencies for the script
# --------------------------------------------------------
function installDependencies() {

    log "INFO" "Installing dependencies for script execution"

    if ! toolInstalled "git" "$gitMinVersion"
    then

        log "INFO" "Installing git package"

        sudo apt-get update
        sudo apt-get install -y git
    fi
}

# ---------------------------------------------------------------
# Function for printing the usage of this script
# ---------------------------------------------------------------
function usage() {

    # print help text
    cat <<USAGE
Usage:
  $scriptName [Options] <Args>
Not required options:
  -h                    Show this help text
  -d                    Execute script in dev mode
  -t <task name>        Start at task with specified name
USAGE

    # exit with error
    exit -1
}


##########
# SCRIPT #
##########

# echo script banner
echo ""
echo "###########################################"
echo "# Ubuntu Developer Workplace Bootstrapper #"
echo "###########################################"
echo ""

# get script name
scriptPath="$(readlink -f $0)"
scriptFolder="$(dirname $scriptPath)"
scriptName="$(basename $scriptPath)"

# set variable defaults
playbookFile="$scriptFolder/$playbookFileName"
devMode="false"

# get command line args
while getopts hdt: opt
do
    case $opt in
        h)
            usage
        ;;
        d)
            devMode="true"
        ;;
        \?)
            log "ERROR" "Invalid option: -$OPTARG"
            exit -1
        ;;
    esac
done

# install dependencies for the script usage
installDependencies

# clone git repository
git clone "$gitRepositoryUrl" "$gitRepositoryFolder"

# execute local setup script
if [ "$devMode" == "true" ]
then
    sudo "$gitRepositoryFolder/local-setup.sh" -d
else
    sudo "$gitRepositoryFolder/local-setup.sh"
fi

# remove temporary files
if [ -d "$gitRepositoryFolder" ]
then
    rm -rf "$gitRepositoryFolder"
fi
