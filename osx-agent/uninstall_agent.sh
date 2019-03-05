#!/bin/bash
# ${copyright}
# ------------------------------------------------------------------------------
# # Install collectd 5.7.0 and some dependencies for plugins used in collectd.conf
# Run this script as root

trap "'echo: Uninstallation process cancelled by user.' && exit" SIGINT

KNOWN_DISTRIBUTION="(Debian|Ubuntu|RedHat|CentOS)"
DISTRIBUTION=$(lsb_release -d 2>/dev/null | grep -Eo $KNOWN_DISTRIBUTION)j

# Detect root user
if [ $(echo "$UID") = "0" ]; then
    _sudo=''
else
    _sudo='sudo'
fi

# All of the known constants that we have that we can set
SPLUNK_FORWARDER_PATH_LINUX='/opt/splunkforwarder'
SPLUNK_FORWARDER_PATH_DARWIN='/Applications/splunkforwarder'
GET_COLLECTD_STATUS_REDHAT="$_sudo systemctl status collectd.service"
GET_COLLECTD_STATUS_DEBIAN="$_sudo service collectd status"
GET_COLLECTD_STATUS_DARWIN="$_sudo brew services list"
COLLECTD_STATUS_COLUMN_KEY_DARWIN='collectd'
COLLECTD_STATUS_COLUMN_KEY_LINUX='Active:'
COLLECTD_STATUS_DARWIN='started'
COLLECTD_STATUS_LINUX='active'
STOP_COLLECTD_DEBIAN='service collectd stop'
STOP_COLLECTD_REDHAT='systemctl stop collectd.service'
STOP_COLLECTD_DARWIN='brew services stop collectd'
UNINSTALL_COLLECTD_DEBIAN="$_sudo apt-get purge --auto-remove collectd"
UNINSTALL_COLLECTD_REDHAT="$_sudo yum remove collectd"
UNINSTALL_COLLECTD_DARWIN="brew remove collectd"
UNINSTALL_SPLUNKFORWARDER_REDHAT="rpm -e splunkforwarder"
UNINSTALL_SPLUNKFORWARDER_DEBIAN="dpkg -P splunkforwarder"
GET_SPLUNK_PROCESSES_LINUX="`ps -ef | grep splunk | grep -v grep | awk '{print $2;}'`"
GET_SPLUNK_PROCESSES_MAC="`ps ax | grep splunk | grep -v grep | awk '{print $1;}'`"
COLLECTD_ASSET_PATH='/etc/collectd'

# Detect OS / Distribution
# We do not run this script to uninstall on EC2 instances, since we already have a separate configure
# page for it
if [ -f /etc/debian_version -o "$DISTRIBUTION" == "Debian" -o "$DISTRIBUTION" == "Ubuntu" ]; then
    OS="Debian"
    SPLUNK_FORWARDER_PATH=$SPLUNK_FORWARDER_PATH_LINUX
    UNINSTALL_COLLECTD=$UNINSTALL_COLLECTD_DEBIAN
    GET_COLLECTD_STATUS=$GET_COLLECTD_STATUS_DEBIAN
    COLLECTD_STATUS_COLUMN_KEY=$COLLECTD_STATUS_COLUMN_KEY_LINUX
    COLLECTD_STATUS=$COLLECTD_STATUS_LINUX
    STOP_COLLECTD=$STOP_COLLECTD_DEBIAN
    UNINSTALL_COLLECTD=$UNINSTALL_COLLECTD_DEBIAN
    GET_SPLUNK_PROCESSES=$GET_SPLUNK_PROCESSES_LINUX
    UNINSTALL_SPLUNKFORWARDER=$UNINSTALL_SPLUNKFORWARDER_DEBIAN
elif [ -f /etc/redhat-release -o "$DISTRIBUTION" == "RedHat" -o "$DISTRIBUTION" == "CentOS" ]; then
    OS="RedHat"
    SPLUNK_FORWARDER_PATH=$SPLUNK_FORWARDER_PATH_LINUX
    UNINSTALL_COLLECTD=$UNINSTALL_COLLECTD_REDHAT
    GET_COLLECTD_STATUS=$GET_COLLECTD_STATUS_REDHAT
    COLLECTD_STATUS_COLUMN_KEY=$COLLECTD_STATUS_COLUMN_KEY_LINUX
    COLLECTD_STATUS=$COLLECTD_STATUS_LINUX
    STOP_COLLECTD=$STOP_COLLECTD_REDHAT
    UNINSTALL_COLLECTD=$UNINSTALL_COLLECTD_REDHAT
    GET_SPLUNK_PROCESSES=$GET_SPLUNK_PROCESSES_LINUX
    UNINSTALL_SPLUNKFORWARDER=$UNINSTALL_SPLUNKFORWARDER_REDHAT
else
    OS=$(uname -s)
    SPLUNK_FORWARDER_PATH=$SPLUNK_FORWARDER_PATH_DARWIN
    UNINSTALL_COLLECTD=$UNINSTALL_COLLECTD_DARWIN
    GET_COLLECTD_STATUS=$GET_COLLECTD_STATUS_DARWIN
    COLLECTD_STATUS_COLUMN_KEY=$COLLECTD_STATUS_COLUMN_KEY_DARWIN
    COLLECTD_STATUS=$COLLECTD_STATUS_DARWIN
    STOP_COLLECTD=$STOP_COLLECTD_DARWIN
    UNINSTALL_COLLECTD=$UNINSTALL_COLLECTD_DARWIN
    GET_SPLUNK_PROCESSES=$GET_SPLUNK_PROCESSES_MAC
    UNINSTALL_SPLUNKFORWARDER=""
fi

function uninstall_collectd_and_remove_assets {
    echo -e "\033[32m\nStep: Uninstalling collectd and removing all assets...\n\033[0m"
    # This uninstalls collectd
    $(echo $UNINSTALL_COLLECTD)
    echo -e "\033[32mSuccessfully uninstalled collectd!\n\033[0m"
    # This removes all assets related to collectd
    $_sudo rm -vrf $COLLECTD_ASSET_PATH
    echo -e "\033[32mSuccessfully removed all collectd assets!\n\033[0m"
}

function uninstall_splunkforwarder_and_remove_assets {
    echo -e "\033[32m\nStep: Uninstalling Splunk Forwarder and removing all assets...\n\033[0m"
    # First, we kill all the lingering processes that contain "splunk" in them
    processes=$(echo $GET_SPLUNK_PROCESSES)
    # Kill all processes if there are any
    if [ ${#processes} -gt "0" ]; then
        echo -e "\033[32mKilling any processes associated with Splunk...\n\033[0m"
        $_sudo kill -9 $(echo $processes)
    fi
    # This removes the Splunk Forwarder if the command to do so has been set
    if [ ${#UNINSTALL_SPLUNKFORWARDER} -gt "0" ]; then
        echo $($_sudo $UNINSTALL_SPLUNKFORWARDER)
    fi
    $_sudo rm -vrf $SPLUNK_FORWARDER_PATH
    echo -e "\033[32mSuccessfully uninstalled Splunk Forwarder!\n\033[0m"
}

function stop_splunk_forwarder {
    echo -e "\033[32m\nStep: Stopping Splunk forwarder...\n\033[0m"
    if [ -d $SPLUNK_FORWARDER_PATH ]; then
        # This value is not needed, the next one is what we use
        status_message=$($_sudo /$SPLUNK_FORWARDER_PATH/bin/splunk status)
        status_value=$?
        if [ $status_value -eq "0" ]; then
            echo -e "\033[32mSplunk Forwarder is currently running.  Stopping...\n\033[0m"
            $_sudo /$SPLUNK_FORWARDER_PATH/bin/splunk stop
            echo -e "\033[32mSuccessfully stopped Splunk Forwarder!\n\033[0m"
        else
            echo -e "\033[32mSplunk Forwarder is already stopped. Skipping...\n\033[0m"
        fi
    else
        echo -e "\033[32mSplunk Forwarder does not exist or has already been uninstalled. Skipping...\n\033[0m"
    fi
}

function stop_collectd_service {
    echo -e "\033[32m\nStep: Stopping the collectd service...\n\033[0m"
    state=$($(echo $GET_COLLECTD_STATUS) | awk -v key="$COLLECTD_STATUS_COLUMN_KEY" '$1==key {print $2}')
    if [ "$state" = "$COLLECTD_STATUS" ]; then
        echo -e "\033[32m\nCollectd is currently running.  Stopping service...\n\033[0m"
        echo $($_sudo $STOP_COLLECTD)
        echo -e "\033[32m\nCollectd has been successfully stopped!\n\033[0m"
    else
        echo -e "\033[32m\nCollectd is already stopped.  Skipping...\n\033[0m"
    fi
}

stop_collectd_service
stop_splunk_forwarder
uninstall_collectd_and_remove_assets
uninstall_splunkforwarder_and_remove_assets