#!/bin/bash
# ${copyright}
# ------------------------------------------------------------------------------
# # Install Splunk Universal Forwarder with specified configurations
# Run this script as root

# Get SPLUNK URL
if [ -n "$SPLUNK_URL" ]; then
    splunk_url=$SPLUNK_URL
fi

if [ ! $splunk_url ]; then
    printf "\033[31mMissing required arguments - SPLUNK_URL.\033[0m\n"
    exit 1;
fi

# Detect OS / Distribution
KNOWN_DISTRIBUTION="(Debian|Ubuntu|RedHat|CentOS)"
DISTRIBUTION=$(lsb_release -d 2>/dev/null | grep -Eo $KNOWN_DISTRIBUTION)

if [ -f /etc/debian_version -o "$DISTRIBUTION" == "Debian" -o "$DISTRIBUTION" == "Ubuntu" ]; then
    OS="Debian"
elif [ -f /etc/redhat-release -o "$DISTRIBUTION" == "RedHat" -o "$DISTRIBUTION" == "CentOS" ]; then
    OS="RedHat"
elif [[ -f /etc/os-release && $(grep "^NAME" /etc/os-release | grep -Eo '".*"' | tr -d \") == "Amazon Linux AMI" ]]; then
    OS="EC2"
elif [[ -f /etc/os-release && $(grep "^NAME" /etc/os-release | grep -Eo '".*"' | tr -d \") =~ "openSUSE" ]]; then
    OS="OpenSuse"
elif [[ -f /etc/os-release && $(grep "^PRETTY_NAME" /etc/os-release | grep -Eo '".*"' | tr -d \") =~ "SUSE Linux Enterprise" ]]; then
    OS="EnterpriseSuse"
else
    OS=$(uname -s)
fi

# Detect root user
if [ $(echo "$UID") = "0" ]; then
    _sudo=''
else
    _sudo='sudo'
fi

splunk_home="/opt/splunkforwarder"

function install_uf_debian {
    echo -e "\033[32m\nStep:Installing Splunk Universal Forwarder on Debian...\n\033[0m"
    if [ -d $splunk_home ]; then
        echo -e "\033[32m\nSplunk Universal Forwarder already exists, skipping installation...\n\033[0m"
    else
        if ! hash wget 2>/dev/null; then
            $_sudo apt-get install -y wget
        fi
        $_sudo wget -O splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-amd64.deb 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.1.0&product=universalforwarder&filename=splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-amd64.deb&wget=true'
        $_sudo dpkg -i splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-amd64.deb
        if [ $? -ne 0 ] ; then
            echo "Failed to install Splunk Universal Forwarder."
            exit 1
        fi
    fi
}

function install_uf_redhat {

    echo -e "\033[32m\nStep:Installing Splunk Universal Forwarder on Redhat...\n\033[0m"
    if [ -d $splunk_home ]; then
        echo -e "\033[32m\nSplunk Universal Forwarder already exists, skipping installation...\n\033[0m"
    else
        if ! hash wget 2>/dev/null; then
            $_sudo yum install -y wget
        fi
        $_sudo wget -O splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-x86_64.rpm 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.1.0&product=universalforwarder&filename=splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-x86_64.rpm&wget=true'
        $_sudo rpm -i splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-x86_64.rpm
        if [ $? -ne 0 ] ; then
            echo "Failed to install Splunk Universal Forwarder."
            exit 1
        fi
    fi
}

function install_uf_suse {

    echo -e "\033[32m\nStep:Installing Splunk Universal Forwarder on SUSE...\n\033[0m"
    if [ -d $splunk_home ]; then
        echo -e "\033[32m\nSplunk Universal Forwarder already exists, skipping installation...\n\033[0m"
    else
        if ! hash wget 2>/dev/null; then
            $_sudo zypper install -y wget
        fi
        $_sudo wget -O splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-x86_64.rpm 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=7.1.0&product=universalforwarder&filename=splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-x86_64.rpm&wget=true'
        $_sudo rpm -i splunkforwarder-7.1.0-2e75b3406c5b-linux-2.6-x86_64.rpm
        if [ $? -ne 0 ] ; then
            echo "Failed to install Splunk Universal Forwarder."
            exit 1
        fi
    fi
}

function install_uf_darwin {
    echo -e "\033[32m\nStep:Installing Splunk Universal Forwarder on Darwin...\n\033[0m"
    if [ -d $splunk_home ]; then
        echo -e "\033[32m\nSplunk Universal Forwarder already exists, skipping installation...\n\033[0m"
    else
        $_sudo curl -L -o splunkforwarder-7.1.0-2e75b3406c5b-darwin-64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86&platform=macos&version=7.1.0&product=universalforwarder&filename=splunkforwarder-7.1.0-2e75b3406c5b-darwin-64.tgz&wget=true'
        $_sudo tar xvzf splunkforwarder-7.1.0-2e75b3406c5b-darwin-64.tgz -C /Applications
        if [ $? -ne 0 ] ; then
            echo "Failed to install Splunk Universal Forwarder."
            exit 1
        fi
    fi
}

function install_uf_solaris {
    echo -e "\033[32m\nStep:Installing Splunk Universal Forwarder on Solaris x86...\n\033[0m"
    if [ -d $splunk_home ]; then
        echo -e "\033[32m\nSplunk Universal Forwarder already exists, skipping installation...\n\033[0m"
    else
        $_sudo wget -O splunkforwarder-7.1.0-2e75b3406c5b-solaris-10-intel.pkg.Z 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=Solaris&version=7.1.0&product=universalforwarder&filename=splunkforwarder-7.1.0-2e75b3406c5b-solaris-10-intel.pkg.Z&wget=true'
        uncompress splunkforwarder-7.1.0-2e75b3406c5b-solaris-10-intel.pkg.Z
        yes|$_sudo pkgadd -d splunkforwarder-7.1.0-2e75b3406c5b-solaris-10-intel.pkg all
        if [ $? -ne 0 ] ; then
            echo "Failed to install Splunk Universal Forwarder."
            exit 1
        fi
    fi
}

splunk_app_infra_uf_config="splunk_app_infra_uf_config"

function set_up_forward_server {
    if [ -n "$RECEIVER_PORT" ]; then
        receiver_port=$RECEIVER_PORT
    else
        receiver_port="9997"
    fi
    outputs_conf=$splunk_home/etc/apps/$splunk_app_infra_uf_config/local/outputs.conf
    $_sudo touch $outputs_conf
    $_sudo chmod a+w $outputs_conf

    echo -e "[tcpout]" >> $outputs_conf
    echo -e "defaultGroup = splunk-app-infra-autolb-group" >> $outputs_conf

    echo -e "\n[tcpout:splunk-app-infra-autolb-group]" >> $outputs_conf
    echo -e "disabled = false" >> $outputs_conf
    echo -e "server = $splunk_url:$receiver_port" >> $outputs_conf
}

function set_up_inputs {
    inputs_conf=$splunk_home/etc/apps/$splunk_app_infra_uf_config/local/inputs.conf

    $_sudo touch $inputs_conf
    $_sudo chmod a+w $inputs_conf

    # read in log types
    if [ -n "$LOG_SOURCES" ]; then
        log_source=$LOG_SOURCES
    fi
    if [ -n "$log_source" ]; then
        IFS=',' read -a log_sources <<< "$log_source"
    fi
    for l in "${log_sources[@]}"
    do
        source="$(cut -d '%' -f1 <<< "$l")"
        sourcetype="$(cut -d '%' -f2 <<< "$l")"
        echo -e "\n[monitor://$source]" >> $inputs_conf
        echo -e "disabled = false" >> $inputs_conf
        # Send to _intneral index for internal and collectd logs
        # System will decide the sourcetype 
        if [ $sourcetype = "collectd" ] || [ $sourcetype = "uf" ]; then
            echo -e "index = _internal" >> $inputs_conf
        elif [ ! -z $sourcetype ]; then
            echo -e "sourcetype = $sourcetype" >> $inputs_conf
        fi
    done
}

# overwrite default inputs.conf, not forwarding any logs
function clean_up_inputs {
    uf_inputs_conf=$splunk_home/etc/apps/SplunkUniversalForwarder/local/inputs.conf 
    
    if [ -d $splunk_home/etc/apps/SplunkUniversalForwarder/local ]; then
        $_sudo mv $splunk_home/etc/apps/SplunkUniversalForwarder/local $splunk_home/etc/apps/SplunkUniversalForwarder/local.$(date +'%Y%m%d-%H%M%S').bak 
    fi

    $_sudo mkdir -p $splunk_home/etc/apps/SplunkUniversalForwarder/local

    $_sudo touch $uf_inputs_conf
    $_sudo chmod a+w $uf_inputs_conf
    # overwrite default and etc/system/default and SplunkUniversalForwarder/default
    echo -e "[monitor://\$SPLUNK_HOME/var/log/splunk]" >> $uf_inputs_conf
    echo -e "disabled = true" >> $uf_inputs_conf
    echo -e "\n[monitor://\$SPLUNK_HOME/var/log/splunk/metrics.log]" >> $uf_inputs_conf
    echo -e "disabled = true" >> $uf_inputs_conf
    echo -e "\n[monitor://\$SPLUNK_HOME/var/log/splunk/splunkd.log]" >> $uf_inputs_conf
    echo -e "disabled = true" >> $uf_inputs_conf
}

function configure {
    echo -e "\033[32m\nStep:Configure Splunk Universal Forwarder...\n\033[0m"
    # backup uf config app if already exists
    if [ -d $splunk_home/etc/apps/$splunk_app_infra_uf_config ]; then
        $_sudo tar -zcvf $splunk_home/etc/apps/$splunk_app_infra_uf_config.$(date +'%Y%m%d-%H%M%S').tar.gz -C $splunk_home/etc/apps/ $splunk_app_infra_uf_config
        $_sudo rm -rf $splunk_home/etc/apps/$splunk_app_infra_uf_config
    fi
    $_sudo mkdir -p $splunk_home/etc/apps/$splunk_app_infra_uf_config/local
    # clean up default and exisiting inputs
    clean_up_inputs
    # set up
    set_up_forward_server
    set_up_inputs

    echo -e "\033[32m\nStep:Enabling boot start for Splunk Universal Forwarder...\n\033[0m"
    $_sudo $splunk_home/bin/splunk restart --answer-yes --auto-ports --no-prompt --accept-license
    $_sudo $splunk_home/bin/splunk enable boot-start
}


if [ "$OS" = "Debian" ]; then
    install_uf_debian
    configure
elif [ "$OS" = "RedHat" ]; then
    install_uf_redhat
    configure
elif [ "$OS" = "OpenSuse" -o "$OS" = "EnterpriseSuse" ]; then
    install_uf_suse
    configure
elif [ "$OS" = "Darwin" ]; then
    splunk_home="/Applications/splunkforwarder"
    install_uf_darwin
    configure
elif [ "$OS" = "EC2" ]; then
    install_uf_redhat
    configure
elif [ "$OS" = "SunOS" ]; then
    install_uf_solaris
    configure
else
    echo -e "\033[31m\nNot supported operating system: $OS. Nothing is installed.\n\033[0m"
fi
