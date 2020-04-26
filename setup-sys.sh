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
  apt install -y build-essential git curl automake
  add-apt-repository -y ppa:nathan-renniewaldock/flux
  add-apt-repository -y ppa:neovim-ppa/stable
  add-apt-repository -y ppa:hadret/fswatch
  add-apt-repository -y ppa:twodopeshaggy/jarun
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
  curl https://www.apache.org/dist/cassandra/KEYS | apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
  echo "deb http://www.apache.org/dist/cassandra/debian 311x main" | tee -a /etc/apt/sources.list.d/cassandra.sources.list
  apt update
  # forensics-all metapackage installs most of the forensic tools ranging from extundelete to yara
  # you can see all details by typing: apt-cache show forensics-all
  apt install -y build-essential git vim silversearcher-ag axel aircrack-ng pyrit reaver wifite zenmap thc-ipv6 \
    nbtscan wireshark-qt tshark tcpdump vlan yersinia ettercap-text-only dsniff arp-scan ghex shutter whois \
    lft gnupg medusa hydra hydra-gtk libstrongswan p7zip-full forensics-all steghide dmitry ophcrack nginx-full \
    socat swftools ruby-dev libpcap-dev php7.2-cli php7.2-fpm mutt git-email esmtp sysdig inotify-tools \
    exif exifprobe fluxgui neovim yarn fortune-mod cowsay mpd mpc dstat htop libevent-dev clang-4.0 global \
    python-pygments cassandra bison aspell aspell-en tig msr-tools gphoto2 gtkam \
    avr-libc avrdude binutils-avr gcc-avr srecord gdb-avr simulavr pkg-config libncursesw5-dev \
    pv ncdu moreutils pgbadger csvtool fswatch xmonad devilspie mkchromecast nnn cpulimit curl mercurial \
    chrome-gnome-shell bless unison unison-gtk xsel lmms

  wget 'https://github.com/sharkdp/bat/releases/download/v0.12.1/bat_0.12.1_amd64.deb' -O /tmp/bat.deb && dpkg -i \
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

pip install --user git+https://github.com/awslabs/aws-shell.git
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
pip3 install git+https://github.com/jeffkaufman/icdiff.git
powerline-config tmux setup

echo 'eval "$(thefuck --alias)"' >> ~/.bashrc

echo "Installing custom "
if [[ ! -e "${TOOLS_ROOT_DIR}" ]]; then
  mkdir -p "${TOOLS_ROOT_DIR}"
fi

git clone https://github.com/techgaun/apk2gold-reloaded.git "${TOOLS_ROOT_DIR}/apk2gold"
echo "export PATH=$PATH:${TOOLS_ROOT_DIR}/apk2gold" >> ~/.bashrc

git clone https://github.com/xmendez/wfuzz.git "${TOOLS_ROOT_DIR}/wfuzz"

git clone https://github.com/1N3/Sn1per.git "${TOOLS_ROOT_DIR}/sniper"
(cd "${TOOLS_ROOT_DIR}/sniper" && bash install.sh)

git clone https://github.com/techgaun/github-dorks.git "${TOOLS_ROOT_DIR}/github-dorks"
(cd "${TOOLS_ROOT_DIR}/github-dorks" && pip install -r requirements.txt)

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.1/install.sh | bash

wget -q -O - https://raw.githubusercontent.com/techgaun/extract/master/extract >> ~/.bashrc

wget -O ~/.bash_aliases https://raw.githubusercontent.com/techgaun/bash-aliases/master/.bash_aliases

npm i -g diff-so-fancy apidoc flow-bin git+https://github.com/ramitos/jsctags.git castnow \
  serverless ask-cli npx neovim yaspeller

cd /tmp
git clone https://github.com/facebook/watchman.git
cd watchman
git checkout v4.9.0
./autogen.sh
./configure
make && make install


cd /tmp
git clone https://github.com/tmux/tmux.git
cd tmux
git checkout 3.0
./autogen.sh
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
curl -sL cli.openfaas.com | sh

cd /tmp
wget 'https://github.com/BurntSushi/ripgrep/releases/download/11.0.2/ripgrep_11.0.2_amd64.deb' -O /tmp/rg.deb \
  && dpkg -i /tmp/rg.deb && rm -f /tmp/rg.deb

curl https://beyondgrep.com/ack-v3.2.0 > ~/bin/ack && chmod 0755 ~/bin/ack

GENYMOTION_VERSION="3.0.4"
wget "https://dl.genymotion.com/releases/genymotion-${GENYMOTION_VERSION}/genymotion-${GENYMOTION_VERSION}-linux_x64.bin" -O /tmp/genymotion.bin
chmod +x /tmp/genymotion.bin
/tmp/genymotion.bin -d "${HOME}/"

curl -sSL https://get.haskellstack.org/ | sh
stack update
stack install unused

modprobe msr

# heroku stuff
# commenting out until get it automated to install heroku cli as well
# heroku plugins:install heroku-pg-extras

curl -L https://bit.ly/glances | /bin/bash

wget 'https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64' -O /usr/local/bin/jq && chmod +x /usr/local/bin/jq
