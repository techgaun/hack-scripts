#!/bin/bash

# runs set of setup commands to customize the system

is_debian() {
    [[ -f "/usr/bin/apt-get" ]]
}

is_rhel() {
    [[ -f "/usr/bin/yum" ]]
}

is_root() {
    [[ "$(id -u)" == "0" ]]
}

error() {
    msg="${1:-$default_err}"
    echo -e "${red}${msg}${nc}"
    exit 1
}

msg() {
    msg="${1:-nothing}"
    echo -e "${green}${msg}${nc}"
}

is_root || error "Please run this script as a root user"

if is_debian; then
  apt update
  apt install -y silversearcher-ag
elif is_rhel; then
  yum update
  yum install -y the_silver_searcher
else
  echo "Unsupported distro"
fi

pip install percol # https://github.com/mooz/percol
pip install thefuck # https://github.com/nvbn/thefuck
echo 'eval "$(thefuck --alias)"' >> ~/.bashrc
