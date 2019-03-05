#!/bin/bash
# ${copyright}
# ------------------------------------------------------------------------------
# # Install collectd 5.7.0 and some dependencies for plugins used in collectd.conf
# Run this script as root

trap "echo 'Installation process canceled by user.' && exit" SIGINT

if [ -n "$SPLUNK_URL" ]; then
    splunk_url=$SPLUNK_URL
fi

if [ -n "$HEC_PORT" ]; then
    hec_port=$HEC_PORT
fi

if [ -n "$HEC_TOKEN" ]; then
    hec_token=$HEC_TOKEN
fi

if [ -n "$DIMENSIONS" ]; then
    dimension=$DIMENSIONS
fi

if [ -n "$INTERVAL" ]; then
    interval=$INTERVAL
fi

if [ -n "$METRIC_TYPES" ]; then
    metric_type=$METRIC_TYPES
fi

if [ -n "$METRIC_OPTS" ]; then
    metric_opt=$METRIC_OPTS
fi

if [ ! $splunk_url ] || [ ! $hec_port ] || [ ! $hec_token ]; then
    printf "\033[31mMissing required arguments - SPLUNK_URL, HEC_PORT and HEC_TOKEN.\033[0m\n"
    exit 1;
fi

KNOWN_DISTRIBUTION="(Debian|Ubuntu|RedHat|CentOS)"
DISTRIBUTION=$(lsb_release -d 2>/dev/null | grep -Eo $KNOWN_DISTRIBUTION)
SII_VERSION="1.2.2"
COLLECTD_VERSION="5\\.[7-8]\\.[0-9]"

# Detect OS / Distribution
if [ -f /etc/debian_version -o "$DISTRIBUTION" == "Debian" -o "$DISTRIBUTION" == "Ubuntu" ]; then
    OS="Debian"
elif [ -f /etc/redhat-release -o "$DISTRIBUTION" == "RedHat" -o "$DISTRIBUTION" == "CentOS" ]; then
    OS="RedHat"
elif [[ -f /etc/os-release && $(grep "^NAME" /etc/os-release | grep -Eo '".*"' | tr -d \") =~ "Amazon Linux" ]]; then
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

# Get dimension list
if [ -n "$dimension" ]; then
    IFS=',' read -a dimensions <<< "$dimension"
fi

# Get metric sources list
if [ -n "$metric_type" ]; then
    IFS=',' read -a metric_types <<< "$metric_type"
fi

# Get metric options list
if [ -n "$metric_opt" ]; then
    IFS=',' read -a metric_opts <<< "$metric_opt"
fi

function print_info {
    echo -e "\033[32m\n $* \n\033[0m"
}

function print_warning {
    echo -e "\033[31m\n $* \n\033[0m"
}

function sed_inplace {
    if [ "$OS" = "Darwin" ]; then
        sed -i '' "$1" "$2"
    elif [ "$OS" = "SunOS" ]; then
        sed "$1" "$2" > "${2}.tmp" && mv "${2}.tmp" "$2"
    else
        sed -i "$1" "$2"
    fi
}

function configure {
  print_info "Step:Configure agent..."
  update_conf

  # configure collectd
  $_sudo mkdir -p /etc/collectd/
  # copy collectd.conf to collectd default configuration file location
  if [ "$OS" = "RedHat" -o "$OS" = "EC2" -o "$OS" = "OpenSuse" -o "$OS" = "EnterpriseSuse" ]; then
    $_sudo cp collectd.conf /etc/
  elif [ "$OS" = "Darwin" ]; then
    collectd_version_regex="5\\.[7-8]\\.[0-9]\\S*"
    collectd_version=$(brew ls --versions collectd | grep -Eo "$collectd_version_regex")
    $_sudo cp collectd.conf "/usr/local/Cellar/collectd/${collectd_version}/etc/"
  elif [ "$OS" = "SunOS" ]; then
    $_sudo cp collectd.conf /etc/opt/csw/
  else
    $_sudo cp collectd.conf /etc/collectd/
  fi
  # install write_splunk.so
  if [ "$OS" = "RedHat" -o "$OS" = "EC2" -o "$OS" = "OpenSuse" -o "$OS" = "EnterpriseSuse" ]; then
    $_sudo cp write_splunk.so /usr/lib64/collectd/
  elif [ "$OS" = "Darwin" ]; then
    $_sudo cp write_splunk.so "/usr/local/Cellar/collectd/${collectd_version}/lib/collectd/"
  elif [ "$OS" = "SunOS" ]; then
    $_sudo cp write_splunk-solaris.so "/opt/csw/lib/collectd/write_splunk.so"
  else
    $_sudo cp write_splunk.so /usr/lib/collectd/
  fi

  if [ "$OS" = "Darwin" ]; then
    $_sudo brew services restart collectd
  elif [ "$OS" = "SunOS" ]; then
    $_sudo svcadm enable cswcollectd
  else
    $_sudo service collectd restart
  fi

}

function check_selinux {
    # check if system is SELinux and if yes check if it is enabled
    if ! hash getenforce 2>/dev/null || [[ $(getenforce) != "Enforcing" ]]; then
        return
    else
        docs_link="http://docs.splunk.com/Documentation/Infrastructure/${SII_VERSION}/Admin/SELinux"
        print_info "SELinux is currently enabled and may cause data collection to fail."\
                "To update your settings to allow for data collection see: $docs_link"
    fi

    # SELinux is enabled. Check if --force continue or Ask if user wants to continue or not
    if [[ $1 = "--force-continue" ]]; then
        print_info "Continuing Force Installation..."
    else
        print_warning "Use \"./install_agent --force-continue\" to force installation without prompt."
        read -p "Continue Installation (y/n)? " yn
        case $yn in
            [Yy]* )
                print_info "Continuing Installation..."
                ;;
            * )
                print_warning "Cancelling Installation..."
                exit 1
                ;;
        esac
    fi
}

function get_splunk_hostname {
    splunk_hostname=$(hostname)
    splunk_home="/opt/splunkforwarder"
    if [ "$OS" = "Darwin" ]; then
        splunk_home="/Applications/splunkforwarder"
    fi

    inputs_conf=$splunk_home/etc/system/local/inputs.conf
    if [ -f $inputs_conf ]; then
        inputs_conf_host=$($_sudo cat $inputs_conf | grep 'host' | cut -d '=' -f2 | tr -d '[:space:]')
        if [ -n "$inputs_conf_host" ]; then
          splunk_hostname=$inputs_conf_host
        fi
    fi
    if [ -z $inputs_conf_host ]; then
        print_info "Could not find hostname used by Splunk - Using $splunk_hostname by default..."
    fi
}

function update_conf {
    for s in "${metric_types[@]}"
    do
        sed_inplace "s/#LoadPlugin $s/LoadPlugin $s/g" "collectd.conf"
    done
    for s in "${metric_opts[@]}"
    do
        if [ $s = "cpu.by_cpu" ]; then
            sed_inplace "s/ReportByCpu false/ReportByCpu true/g" "collectd.conf"
        fi
    done
    # Add custom plugin to collectd.conf
    echo -e "##############################################################################" >> collectd.conf
    echo -e "# Customization for Splunk                                                   #" >> collectd.conf
    echo -e "#----------------------------------------------------------------------------#" >> collectd.conf
    echo -e "# This plugin sends all metrics data from other plugins to Splunk via HEC.   #" >> collectd.conf
    echo -e "##############################################################################" >> collectd.conf
    echo -e "\n<Plugin write_splunk>" >> collectd.conf
    echo -e "           server \"$splunk_url\"" >> collectd.conf
    echo -e "           port \"$hec_port\"" >> collectd.conf
    echo -e "           token \"$hec_token\"" >> collectd.conf
    echo -e "           ssl true" >> collectd.conf
    echo -e "           verifyssl false" >> collectd.conf
    for i in "${dimensions[@]}"
    do
        echo -e "           Dimension \"$i\"" >> collectd.conf
    done
    if [ "$OS" = "EC2" ]; then
        ec2_instance_id=$(ec2-metadata -i | cut -d ":" -f2 | tr -d ' ')
        echo -e "           Dimension \"InstanceId:$ec2_instance_id\"" >> collectd.conf
    fi
    echo -e "</Plugin>" >> collectd.conf
    get_splunk_hostname

    sed_inplace "s/#Hostname    \"collectd.server.sample\"/Hostname    \"$splunk_hostname\"/g" "collectd.conf"
}

function download_deps_debian {
    print_info "Step:Downloading dependencies..."
    # install libcurl dependency
    $_sudo apt-get install -y libcurl3
}

function download_deps_suse {
    
    zypper search --installed-only libcurl
    if [ $? -eq 0 ] ; then
        # libcurl package already installed
        return
    fi

    # install libcurl dependency
    print_info "Step:Downloading dependencies..."
    $_sudo zypper install -y libcurl4
}

function add_collectd_source_debian {

    debian_distribution=$(cat /etc/os-release | grep -m1 -iEo 'wheezy|jessie|trusty|xenial' | tr '[:upper:]' '[:lower:]' | head -1)
    if [ -z "$debian_distribution" ]; then
        print_warning "Unsupported Debian version..."
        exit 1
    fi
    # Enforce apt-get to install collected-5.7.*
    if ! grep -Fxq "deb http://pkg.ci.collectd.org/deb ${debian_distribution} collectd-5.7" /etc/apt/sources.list; then
        echo "deb http://pkg.ci.collectd.org/deb ${debian_distribution} collectd-5.7" | $_sudo tee -a /etc/apt/sources.list
        $_sudo apt-get update
    fi
}

function download_deps_redhat {
    print_info "Step:Downloading dependencies..."
    # install libcurl dependency
    $_sudo yum install -y libcurl
}

function download_deps_solaris {
    print_info "Step:Downloading dependencies..."
    # install libcurl dependency
    $_sudo yes|pkgadd -d http://get.opencsw.org/now all
    $_sudo /opt/csw/bin/pkgutil -U
    $_sudo /opt/csw/bin/pkgutil -y -i libcurl4_feature
}

function install_collectd_suse {
    if hash collectd 2>/dev/null; then
        $_sudo service collectd stop

        # check for collectd version 5.7.* or 5.8.*
        is_version_ok=$(zypper -n search -s --installed-only collectd | grep -Eo "$COLLECTD_VERSION")

        # if collectd 5.7 or 5.8 not installed, error out
        if [ -z "$is_version_ok" ]; then
            print_warning "Unsupported version of collectd already installed. Supported versions: 5.7.* or 5.8.* ..."
            exit 1
        fi

        # Backup collectd.conf
        $_sudo mv /etc/collectd.conf "/etc/collectd/collectd.conf.old.$(date +'%Y%m%d-%H%M%S')"
        return
    fi

    # Extract SUSE version
    version=$(grep "^VERSION_ID" /etc/os-release | grep -Eo '".*"' | tr -d \")

    # check for openSUSE Tumbleweed
    if [ "$OS" = 'OpenSuse' ]; then
        grep "^PRETTY_NAME" /etc/os-release | grep -i 'Tumbleweed'
        if [ "$?" -eq 0 ]; then
            version='Tumbleweed'
        fi
    fi

    os_ver="${OS}${version}"

    case $os_ver in
        OpenSuse42.1|EnterpriseSuse12.1)
            $_sudo zypper -n addrepo 'https://download.opensuse.org/repositories/server:monitoring/openSUSE_Leap_42.1/server:monitoring.repo'
            $_sudo zypper -n --gpg-auto-import-keys refresh 'server_monitoring'
            ;;
        OpenSuse42.2|EnterpriseSuse12.2)
            $_sudo zypper -n addrepo 'https://download.opensuse.org/repositories/server:monitoring/openSUSE_Leap_42.2/server:monitoring.repo'
            $_sudo zypper -n --gpg-auto-import-keys refresh 'server_monitoring'
            ;;
        OpenSuse42.3|EnterpriseSuse12.3)
            $_sudo zypper -n addrepo 'https://download.opensuse.org/repositories/server:monitoring/openSUSE_Leap_42.3/server:monitoring.repo'
            $_sudo zypper -n --gpg-auto-import-keys refresh 'server_monitoring'
            ;;
        OpenSuse15.0)
            $_sudo zypper -n addrepo 'https://download.opensuse.org/repositories/server:monitoring/openSUSE_Leap_15.0/server:monitoring.repo'
            $_sudo zypper -n --gpg-auto-import-keys refresh 'server_monitoring'
            ;;
        OpenSuseTumbleweed)
            $_sudo zypper -n addrepo 'https://download.opensuse.org/repositories/server:monitoring/openSUSE_Tumbleweed/server:monitoring.repo'
            $_sudo zypper -n --gpg-auto-import-keys refresh 'server_monitoring'
            ;;
        EnterpriseSuse15)
            $_sudo zypper -n addrepo 'https://download.opensuse.org/repositories/server:monitoring/SLE_15/server:monitoring.repo'
            $_sudo zypper -n --gpg-auto-import-keys refresh 'server_monitoring'
            $_sudo zypper -n addrepo 'https://download.opensuse.org/repositories/openSUSE:/Backports:/SLE-15/standard/openSUSE:Backports:SLE-15.repo'
            $_sudo zypper -n --gpg-auto-import-keys refresh 'openSUSE_Backports_SLE-15'
            ;;
        *)
            print_warning "Unsupported SUSE version. Supported versions are SUSE Enterprise(12.1,12.2,12.3,15) & openSUSE(42.1,42.2,42.3,15,Tumbleweed)"
            exit 1
    esac

    # check for libcurl dependency
    download_deps_suse
    available_version_ok=$(zypper -n info collectd | grep -Eo "$COLLECTD_VERSION")

    # if collectd 5.7 or 5.8 not available
    if [ -z "$available_version_ok" ]; then
        print_warning "Failed to install supported version of collectd. Require collectd version 5.7.* or 5.8.*"
        exit 1
    fi

    # Install collectd
    $_sudo zypper install -y collectd
    if [ $? -ne 0 ] ; then
        print_warning "Failed to install collectd"
        exit 1
    fi
}

function install_collectd_debian {
    # Download dependency
    download_deps_debian
    print_info "Step:Installing collectd on Debian..."

    if hash collectd 2>/dev/null; then
        $_sudo service collectd stop

        # check for collectd version 5.7.* or 5.8.*
        is_version_ok=$(dpkg -l | grep "collectd" | grep -Eo "$COLLECTD_VERSION")

        # if collectd 5.7 or 5.8 not installed, upgrade collectd
        if [ -z "$is_version_ok" ]; then
            add_collectd_source_debian
            $_sudo apt-get --yes --allow-unauthenticated --only-upgrade install collectd-core collectd
        fi

        # Backup
        $_sudo mv /etc/collectd/collectd.conf "/etc/collectd/collectd.conf.old.$(date +'%Y%m%d-%H%M%S')"
    else
        # first check collectd version for install candidate
        available_version_ok=$(apt-cache policy collectd | grep -i 'candidate' | grep -Eo "$COLLECTD_VERSION")

        if [ -z "$available_version_ok" ]; then
            # add collectd source and install collectd
            add_collectd_source_debian
            $_sudo apt-get --yes --allow-unauthenticated install collectd
        else
            $_sudo apt-get --yes install collectd
        fi

        # Install missing dependencies
        print_info "Installing any missing dependency..."
        $_sudo apt-get -f install
    fi
}

function install_collectd_solaris {
    # Download dependency
    download_deps_solaris
    print_info "Step:Installing collectd on Solaris..."

    if hash collectd 2>/dev/null; then
        $_sudo svcadm disable cswcollectd

        # check for collectd version 5.7.* or 5.8.*
        is_version_ok=$(pkginfo -l CSWcollectd | grep -i "version" | egrep -e "$COLLECTD_VERSION")

        # if collectd 5.7 or 5.8 not installed, upgrade collectd
        if [ -z "$is_version_ok" ]; then
            print_warning "Unsupported version of collectd already installed. Supported versions: 5.7.* or 5.8.* ..."
            exit 1
        fi

        # Backup
        $_sudo mv /etc/opt/csw/collectd.conf "/etc/opt/csw/collectd.conf.old.$(date +'%Y%m%d-%H%M%S')"
    else
        # install collectd package for solaris
        $_sudo /opt/csw/bin/pkgutil -y -i collectd
    fi
}

function install_collectd_redhat {
    RHEL_7_VERSION="^3.10.0(.)+"
    RHEL_6_VERSION="^2.6.32(.)+"
    print_info "Step:Installing collectd on Redhat..."
    is_rhel_6=$(uname -r | grep -Eo "$RHEL_6_VERSION")
    is_rhel_7=$(uname -r | grep -Eo "$RHEL_7_VERSION")
    is_centos_6=false
    is_fedora=false
    if [[ -f /etc/centos-release && $( cat /etc/centos-release | grep -oP "[0-9]+" | head -1 ) -eq 6 ]]; then
        is_centos_6=true
    fi

    if [[ -f /etc/fedora-release ]]; then
        is_fedora=true
    fi

    if [ "$is_centos_6" = true ] || [ "$is_rhel_6" ] || [ "$is_fedora" = true ]; then
        # if Centos6 or RHEL6
        :
    elif [ "$is_rhel_7" ]; then
        # This install statement is taken from https://aws.amazon.com/premiumsupport/knowledge-center/ec2-enable-epel/
        $_sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    else
        $_sudo yum -y install epel-release
    fi

    # Install any missing dependency packages
    download_deps_redhat

    if hash collectd 2>/dev/null; then
        $_sudo service collectd stop
        # Backup
        $_sudo mv /etc/collectd.conf "/etc/collectd.conf.old.$(date +'%Y%m%d-%H%M%S')"
        # check for collectd version 5.7.* or 5.8.*
        is_version_ok=$(yum list installed | grep "collectd" | grep -Eo "$COLLECTD_VERSION")
        if [ -n "$is_version_ok" ]; then
            # correct version already installed..
            return 0
        else
            $_sudo yum -y remove collectd
            if [ $? -ne 0 ] ; then
                print_warning "Failed to remove old version of collectd"
                exit 1
            fi
        fi
    fi

    if [ "$is_centos_6" = true ] || [ "$is_rhel_6" ]; then
        # extract latest collectd rpm build number
        wget https://pkg.ci.collectd.org/rpm/collectd-5.7/epel-6-x86_64/status.json
        build_num=$(cat status.json | grep -Eo '5.7\.[^"]*')

        if [ $? -ne 0 ] ; then
            print_warning "Failed to find the collectd package"
            exit 1
        fi
        # install collectd and disk rpm
        $_sudo yum install -y "https://pkg.ci.collectd.org/rpm/collectd-5.7/epel-6-x86_64/collectd-${build_num}-3.el6.x86_64.rpm"
        $_sudo yum install -y "https://pkg.ci.collectd.org/rpm/collectd-5.7/epel-6-x86_64/collectd-disk-${build_num}-3.el6.x86_64.rpm"
    elif [ "$is_fedora" = true ]; then
         available_version=$(yum list available collectd | grep -Eo "$COLLECTD_VERSION")
        if [ -n "$available_version" ]; then
            # Install collectd
            $_sudo yum -y install collectd
        else
            print_warning "Failed to install supported version of collectd. Require collectd version 5.7.* or 5.8.*"
            exit 1
        fi
    else
        # check if the required collectd version 5.7.* or 5.8.* is available
        available_version=$(yum --enablerepo=epel list available collectd | grep -Eo "$COLLECTD_VERSION")
        if [ -n "$available_version" ]; then
            # Install collectd
            $_sudo yum -y --enablerepo=epel install collectd
        else
            print_warning "Failed to install supported version of collectd. Require collectd version 5.7.* or 5.8.*"
            exit 1
        fi
    fi

    # collectd's disk plugin is in seperate package
    if [ "$OS" = "EC2" ] || [ "$is_fedora" = true ]; then
        yum -y install collectd-disk
    fi

}

function install_collectd_darwin {
    print_info "Step:Installing collectd on Darwin..."
    current_working_dir=$(pwd)
    # Check if brew is installed
    which -s brew
    if [[ $? != 0 ]] ; then
      print_info "Homebrew is not installed. Start installing now..."
      # Use alternative way to install homebrew to avoid dependency on CLT for Xcode.
      # And it's recommended to install homebrew in /usr/local directory
      # https://docs.brew.sh/Installation.html
      if [ ! -d "/usr/local" ]; then
        $_sudo mkdir -p /usr/local
      fi

      cd /usr/local
      $_sudo mkdir homebrew && curl --fail -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
    fi
    cd $current_working_dir

    # Check if collectd is installed
    if brew ls --versions collectd > /dev/null; then
        # Check if installed version meets requirements
        installed_version=$(brew ls --versions collectd | grep -Eo "5\\.[7-8]\\.[0-9]\\S*")
        if [ -z "$installed_version" ]; then
          print_warning "Unsupported version of collectd already installed. Supported versions: 5.7.* or 5.8.* ..."
          exit 1
        fi
        # Backup
        $_sudo mv "/usr/local/Cellar/collectd/${installed_version}/etc/collectd.conf" "/usr/local/Cellar/collectd/${installed_version}/etc/collectd.conf.old.$(date +'%Y%m%d-%H%M%S')"
    else
        # Check collectd version on homebrew
        current_version_on_brew=$(brew info collectd | grep "collectd: " | grep -Eo "$COLLECTD_VERSION")
        if [ -z "$current_version_on_brew" ]; then
          print_warning "Homebrew formula: collectd version not met required version: 5.7.* or 5.8.* . Try updating brew..."
          exit 1
        fi
        # Install collectd
        brew install collectd
    fi
}

if [ "$OS" = "Debian" ]; then
    print_info "Installing Agents on Debian"
    check_selinux "$@"
    install_collectd_debian
    configure

elif [ "$OS" = "RedHat" ]; then
    print_info "Installing Agents on RedHat"
    check_selinux "$@"
    install_collectd_redhat
    configure
elif [ "$OS" = "Darwin" ]; then
    print_info "Installing Agents on Darwin"
    install_collectd_darwin
    configure
elif [ "$OS" = "EC2" ]; then
    print_info "Installing Agents on EC2 instance"
    check_selinux "$@"
    install_collectd_redhat
    configure
elif [ "$OS" = "OpenSuse" ]; then
    print_info "Installing Agents on openSUSE"
    check_selinux "$@"
    install_collectd_suse
    configure
elif [ "$OS" = "EnterpriseSuse" ]; then
    print_info "Installing Agents on SUSE Enterprise"
    check_selinux "$@"
    install_collectd_suse
    configure
elif [ "$OS" = "SunOS" ]; then
    print_info "Installing Agents on Solaris"
    install_collectd_solaris
    configure
else
    print_warning "Not supported operating system: $OS. Nothing is installed."
fi
