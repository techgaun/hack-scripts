#!/bin/bash

# runs set of setup commands to customize the system
# default directory for custom tools is $HOME/pentest/tools
# which you can override by passing the directory you want as 2nd argument

TOOLS_ROOT_DIR=${1:$HOME/pentest/tools}

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
  apt install -y build-essential git vim silversearcher-ag axel aircrack-ng pyrit reaver wifite zenmap thc-ipv6 \
    nbtscan wireshark-qt tshark tcpdump vlan yersinia ettercap-text-only dsniff arp-scan ghex shutter whois \
    lft gnupg medusa hydra hydra-gtk libstrongswan p7zip-full forensics-all steghide dmitry ophcrack nginx-full \
    socat swftools ruby-dev libpcap-dev
elif is_rhel; then
  yum update
  yum groupinstall -y "Development Tools"
  # todo: add packages just like debian versions
  yum install -y the_silver_searcher git vim
else
  echo "Unsupported distro but will continue installing other packages"
fi

gem install bettercap
gem install hacker-gems

pip install percol # https://github.com/mooz/percol
pip install thefuck # https://github.com/nvbn/thefuck
echo 'eval "$(thefuck --alias)"' >> ~/.bashrc

echo "Installing custom "
if [[ ! -e "${TOOLS_ROOT_DIR}" ]]; then
  mkdir -p "${TOOLS_ROOT_DIR}"
fi

git clone https://github.com/nepalihackers/apk2gold-reloaded.git "${TOOLS_ROOT_DIR}/apk2gold"
echo "export PATH=$PATH:${TOOLS_ROOT_DIR}/apk2gold" >> ~/.bashrc

git clone https://github.com/xmendez/wfuzz.git "${TOOLS_ROOT_DIR}/wfuzz"

git clone https://github.com/1N3/Sn1per.git "${TOOLS_ROOT_DIR}/sniper"
(cd "${TOOLS_ROOT_DIR}/sniper" && bash install.sh)

git clone https://github.com/techgaun/github-dorks.git "${TOOLS_ROOT_DIR}/github-dorks"
(cd "${TOOLS_ROOT_DIR}/github-dorks" && pip install -r requirements.txt)
