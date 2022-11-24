#!/bin/bash

#################
# CONFIGURATION #
#################

gitMinVersion="1:2.25.1-1ubuntu3.6"
gitLfsMinVersion="2.9.2-1"
gitHostname="bitbucket.dormakaba.net"
gitRepositoryUrl="https://$gitHostname/scm/cccdev/developer-workplace-ubuntu-ansible.git"
gitRepositoryFolder="/tmp/dwp-$(date +%s%N)"
gitCredentialsFile="$HOME/.netrc"
localSetupScript="$gitRepositoryFolder/local-setup.sh"

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

    if ! toolInstalled "git-lfs" "$gitLfsMinVersion"
    then

        log "INFO" "Installing git lfs package"

        sudo apt-get update
        sudo apt-get install -y git-lfs
    fi
}

# --------------------------------------------------------
# Function for creating temporary git credentials file
# --------------------------------------------------------
function createGitTempCredentialsFile() {

    log "INFO" "Creating temporary git credentials file"

    # read git credentials
    read -p "Please enter git username: " gitUsername
    read -s -p "Please enter git password: " gitPassword

    # remove old git credentials file if exists
    if [ -f "$gitCredentialsFile" ]
    then
        rm "$gitCredentialsFile"
    fi

    # create git credentials file
    touch "$gitCredentialsFile"
    echo "machine $gitHostname" >> "$gitCredentialsFile"
    echo "login $gitUsername" >> "$gitCredentialsFile"
    echo "password $gitPassword" >> "$gitCredentialsFile"
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
scriptName="$(basename $scriptPath)"

# get command line args
while getopts h opt
do
    case $opt in
        h)
            usage
        ;;
        \?)
            log "ERROR" "Invalid option: -$OPTARG"
            exit -1
        ;;
    esac
done

# execute dummy sudo command
sudo echo "Starting system provisioning" >> /dev/null
if [ "$?" != "0" ]
then
    log "ERROR" "Please enter a correct sudo password"
    exit -1
fi

# create temporary git credentials file
createGitTempCredentialsFile

# install dependencies for the script usage
installDependencies

# clone git repository
git clone "$gitRepositoryUrl" "$gitRepositoryFolder"

# execute local setup script
if [ -f "$localSetupScript" ]
then
    sudo "$localSetupScript"
else
    log "ERROR" "Local setup script $localSetupScript not found"
fi

# remove temporary files
if [ -d "$gitRepositoryFolder" ]
then
    rm -rf "$gitRepositoryFolder"
fi
if [ -f "$gitCredentialsFile" ]
then
    rm "$gitCredentialsFile"
fi