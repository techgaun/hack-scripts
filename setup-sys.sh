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
  sudo add-apt-repository -y ppa:nathan-renniewaldock/flux
  sudo add-apt-repository -y ppa:neovim-ppa/stable
  sudo add-apt-repository -y ppa:hadret/fswatch
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  curl https://www.apache.org/dist/cassandra/KEYS | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  echo "deb http://www.apache.org/dist/cassandra/debian 311x main" | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list
  apt update
  # forensics-all metapackage installs most of the forensic tools ranging from extundelete to yara
  # you can see all details by typing: apt-cache show forensics-all
  apt install -y build-essential git vim silversearcher-ag axel aircrack-ng pyrit reaver wifite zenmap thc-ipv6 \
    nbtscan wireshark-qt tshark tcpdump vlan yersinia ettercap-text-only dsniff arp-scan ghex shutter whois \
    lft gnupg medusa hydra hydra-gtk libstrongswan p7zip-full forensics-all steghide dmitry ophcrack nginx-full \
    socat swftools ruby-dev libpcap-dev php7.0-cli php7.0-fpm mutt git-email esmtp sysdig inotify-tools \
    exif exifprobe fluxgui neovim yarn fortune cowsay mpd mpc dstat htop libevent-dev clang-4.0 global \
    python-pygments cassandra bison aspell aspell-en tig msr-tools gphoto2 gtkam \
    avr-libc avrdude binutils-avr gcc-avr srecord gdb-avr simulavr \
    pv ncdu moreutils pgbadger csvtool fswatch xmonad devilspie

  wget 'https://github.com/sharkdp/bat/releases/download/v0.7.1/bat_0.7.1_amd64.deb' -O /tmp/bat.deb && dpkg -i \
    /tmp/bat.deb && rm -f /tmp/bat.deb
elif is_rhel; then
  yum update
  yum groupinstall -y "Development Tools"
  # todo: add packages just like debian versions
  # help-wanted
  yum install -y the_silver_searcher git vim
else
  echo "Unsupported distro but will continue installing other packages"
fi

gem install bettercap
gem install hacker-gems
gem install tmuxinator
gem install neovim

pip install percol # https://github.com/mooz/percol
pip install thefuck # https://github.com/nvbn/thefuck
pip install httpie
pip install s3cmd
pip install asciinema
pip3 install yapf
pip3 install clang
pip install glances
pip install ansible
pip3 install powerline-status
powerline-config tmux setup

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

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash

wget -q -O - https://raw.githubusercontent.com/techgaun/extract/master/extract >> ~/.bashrc

wget -O ~/.bash_aliases https://raw.githubusercontent.com/techgaun/bash-aliases/master/.bash_aliases

npm i -g diff-so-fancy apidoc flow-bin git+https://github.com/ramitos/jsctags.git castnow \
  serverless ask-cli npx neovim yaspeller

cd /tmp
git clone https://github.com/facebook/watchman.git
cd watchman
git checkout v4.7.0
./autogen.sh
./configure
make && make install


cd /tmp
git clone https://github.com/tmux/tmux.git
cd tmux
git checkout 2.5
./configure
make && make install

cd /tmp
hg clone https://bitbucket.org/eradman/entr
cd entr
./configure
make test
make install

cd /tmp
git clone https://github.com/universal-ctags/ctags.git
cd ctags
./autogen.sh
./configure
make && make install

apt -y autoremove

bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

go get -u github.com/golang/dep/cmd/dep
curl -sL cli.openfaas.com | sudo sh

cd /tmp
wget 'https://github.com/BurntSushi/ripgrep/releases/download/0.7.1/ripgrep-0.7.1-x86_64-unknown-linux-musl.tar.gz'
tar xfz ripgrep-0.7.1-x86_64-unknown-linux-musl.tar.gz
cd ripgrep-0.7.1-x86_64-unknown-linux-musl/
sudo cp rg /usr/bin/rg
sudo cp complete/rg.bash-completion /etc/bash_completion.d/
sudo cp rg.1.gz /usr/share/man/man1/

curl https://beyondgrep.com/ack-2.18-single-file > ~/.bin/ack && chmod 0755 ~/.bin/ack

GENYMOTION_VERSION="2.11.0"
wget "https://dl.genymotion.com/releases/genymotion-${GENYMOTION_VERSION}/genymotion-${GENYMOTION_VERSION}-linux_x64.bin" -O /tmp/genymotion.bin
chmod +x /tmp/genymotion.bin
/tmp/genymotion.bin -d "${HOME}/"

curl -sSL https://get.haskellstack.org/ | sh
stack update
stack install unused

modprobe msr
