FROM ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt update \
    && apt -y install locales
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create tools directory
RUN mkdir ~/tools

# Install base tools
RUN apt update \
    && apt -y install vim patchelf netcat socat strace ltrace curl wget git gdb \
    && apt -y install man sudo inetutils-ping gnupg locate ftp p7zip traceroute \
    && apt -y install libgmp-dev libmpfr-dev libmpc-dev dnsutils \
    && apt clean

#####################################################
# Languages
#####################################################

# Install python2/python3
RUN apt update \
    && apt -y install python-dev python-pip \
    && apt -y install python3-dev python3-pip python3-venv \
    && apt clean

RUN python3 -m pip install --upgrade pip
RUN python -m pip install --upgrade pip
RUN pip install --upgrade setuptools

# Install ruby
RUN apt update \
    && apt install -y ruby-full \
    && apt clean

# Install powershell
RUN apt update \
    && apt install -y liblttng-ust0 \
    && apt clean

RUN cd /dev/shm \
    && wget https://github.com/PowerShell/PowerShell/releases/download/v6.1.1/powershell_6.1.1-1.ubuntu.16.04_amd64.deb \
    && dpkg -i powershell_6.1.1-1.ubuntu.16.04_amd64.deb \
    && apt install -f \
    && apt clean

# JS
RUN apt update \
    && apt install -y npm \
    && npm cache clean -f \
    && npm install -g n \
    && n stable \
    && apt clean

# Install Go
# This is taken from https://raw.githubusercontent.com/docker-library/golang/master/1.11/stretch/Dockerfile
ENV GOLANG_VERSION 1.11

RUN set -eux; \
    \
# this "case" statement is generated via "update.sh"
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) goRelArch='linux-amd64'; goRelSha256='b3fcf280ff86558e0559e185b601c9eade0fd24c900b4c63cd14d1d38613e499' ;; \
        armhf) goRelArch='linux-armv6l'; goRelSha256='8ffeb3577d8ca5477064f1cb8739835973c866487f2bf81df1227eaa96826acd' ;; \
        arm64) goRelArch='linux-arm64'; goRelSha256='e4853168f41d0bea65e4d38f992a2d44b58552605f623640c5ead89d515c56c9' ;; \
        i386) goRelArch='linux-386'; goRelSha256='1a91932b65b4af2f84ef2dce10d790e6a0d3d22c9ea1bdf3d8c4d9279dfa680e' ;; \
        ppc64el) goRelArch='linux-ppc64le'; goRelSha256='e874d617f0e322f8c2dda8c23ea3a2ea21d5dfe7177abb1f8b6a0ac7cd653272' ;; \
        s390x) goRelArch='linux-s390x'; goRelSha256='c113495fbb175d6beb1b881750de1dd034c7ae8657c30b3de8808032c9af0a15' ;; \
        *) goRelArch='src'; goRelSha256='afc1e12f5fe49a471e3aae7d906c73e9d5b1fdd36d52d72652dde8f6250152fb'; \
            echo >&2; echo >&2 "warning: current architecture ($dpkgArch) does not have a corresponding Go binary release; will be building from source"; echo >&2 ;; \
    esac; \
    \
    url="https://golang.org/dl/go${GOLANG_VERSION}.${goRelArch}.tar.gz"; \
    wget -O go.tgz "$url"; \
    echo "${goRelSha256} *go.tgz" | sha256sum -c -; \
    tar -C /usr/local -xzf go.tgz; \
    rm go.tgz; \
    \
    if [ "$goRelArch" = 'src' ]; then \
        echo >&2; \
        echo >&2 'error: UNIMPLEMENTED'; \
        echo >&2 'TODO install golang-any from jessie-backports for GOROOT_BOOTSTRAP (and uninstall after build)'; \
        echo >&2; \
        exit 1; \
    fi; \
    \
    export PATH="/usr/local/go/bin:$PATH"; \
    go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

#####################################################
# Install pwn/RE tools
#####################################################
RUN apt update \
    && apt -y install gcc-multilib g++-multilib \
    && apt clean

# libc6-dbg & 32-bit libs
RUN dpkg --add-architecture i386 \
    && apt update \
    && apt -y install libc6-dbg libc6-dbg:i386 glibc-source \
    && apt clean \
    && tar -C /usr/src/glibc/ -xvf /usr/src/glibc/glibc-*.tar.xz

# Keystone, Capstone, and Unicorn
RUN apt -y install git cmake gcc g++ pkg-config libglib2.0-dev
RUN cd ~/tools \
    && wget https://raw.githubusercontent.com/hugsy/stuff/master/update-trinity.sh \
    && bash ./update-trinity.sh
RUN ldconfig

# Z3
RUN cd ~/tools \
    && git clone --depth 1 https://github.com/Z3Prover/z3.git && cd z3 \
    && python scripts/mk_make.py --python \
    && cd build; make && make install

# pwntools
RUN python -m pip install pwntools==3.12.1

# one_gadget
RUN gem install one_gadget

# arm_now
RUN python3 -m pip install arm_now

RUN apt update \
    && apt install -y e2tools qemu \
    && apt clean

# Install tmux from source
RUN apt update \
    && apt -y install libevent-dev libncurses-dev \
    && apt clean

RUN TMUX_VERSION=$(curl -s https://api.github.com/repos/tmux/tmux/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")') \
    && wget https://github.com/tmux/tmux/releases/download/$TMUX_VERSION/tmux-$TMUX_VERSION.tar.gz \
    && tar zxvf tmux-$TMUX_VERSION.tar.gz \
    && cd tmux-$TMUX_VERSION \
    && ./configure && make && make install \
    && cd .. \
    && rm -rf tmux-$TMUX_VERSION* \
    && echo "tmux hold" | dpkg --set-selections # disable tmux update from apt

# Install msf
RUN curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall \
    && chmod 755 msfinstall \
    && ./msfinstall

# Install exploit-db searchsploit
RUN git clone https://github.com/offensive-security/exploitdb.git /opt/exploitdb \
    && ln -sf /opt/exploitdb/searchsploit /usr/bin/searchsploit

# Clone wordlists
RUN cd /usr/share/ \
    && git clone https://github.com/drtychai/wordlists.git /usr/share/wordlists \
    && tar zxvf /usr/share/wordlists/rockyou.tar.gz -C /usr/share/wordlists/ \
    && rm /usr/share/wordlists/rockyou.tar.gz

#####################################################
# Install information gathering tools
#####################################################
RUN apt update \
    && apt -y install aircrack-ng arp-scan masscan nikto nmap snmp openvpn \
    && apt clean

# Grab lineum, linuxprivcheck, windows-priv-checker
RUN cd $HOME/tools \
    && git clone https://github.com/rebootuser/LinEnum \
    && git clone https://github.com/sleventyeleven/linuxprivchecker \
    && git clone https://github.com/pentestmonkey/windows-privesc-check

# Install and alias dnsrecon
RUN cd $HOME/tools \
    && git clone https://github.com/darkoperator/dnsrecon \
    && pip install -r ./dnsrecon/requirements.txt \
    && chmod +x ./dnsrecon/dnsrecon.py \
    && echo 'alias dnsrecon="~/tools/dnsrecon/dnsrecon.py"' >> $HOME/.bashrc

# Install dnscat2
RUN cd $HOME/tools \
    && git clone https://github.com/iagox86/dnscat2 \
    && cd dnscat2; make \
    && gem install bundler

# Install and alias enum4linux
RUN cd $HOME/tools \
    && git clone https://github.com/portcullislabs/enum4linux \
    && chmod +x ./enum4linux/enum4linux.pl \
    && echo 'alias enum4linux="~/tools/enum4linux/enum4linux.pl"' >> $HOME/.bashrc

# Install and alias sublist3r
RUN cd $HOME/tools \
    && git clone https://github.com/aboul3la/Sublist3r \
    && chmod +x ./Sublist3r/sublist3r.py \
    && echo 'alias sublist3r="~/tools/sublist3r/sublist3r.py"' >> $HOME/.bashrc

# Install aquatone
RUN gem install aquatone

# Install and alias dirsearch
RUN cd $HOME/tools \
    && git clone https://github.com/maurosoria/dirsearch \
    && chmod +x ./dirsearch/dirsearch.py \
    && echo 'alias dirsearch="~/tools/dirsearch/dirsearch.py"' >> $HOME/.bashrc

# Install gobuster
RUN cd $GOPATH/src \
    && git clone https://github.com/OJ/gobuster && cd ./gobuster \
    && go get && go build && go install

# Install wfuzz
RUN cd $HOME/tools \
    && git clone https://github.com/xmendez/wfuzz
    #&& apt install libcurl4-gnutls-dev \
    #&& pip install ./wfuzz \
	#&& apt clean

# Install impacket
RUN cd $HOME/tools \
    && git clone https://github.com/SecureAuthCorp/impacket && cd ./impacket \
    && pip install .

# Install SMBetray
RUN cd $HOME/tools \
    && git clone https://github.com/quickbreach/SMBetray && cd ./SMBetray \
    && chmod +x ./install.sh && echo 'y' - | ./install.sh

# Install SMBmap
RUN cd $HOME/tools \
    && git clone https://github.com/ShawnDEvans/smbmap \
    && cd smbmap; python2 -m pip install -r requirements.txt \
    && chmod +x smbmap.py \
    && echo 'alias smbmap="~/tools/smbmap/smbmap.py"' >> $HOME/.bashrc

# Install wpscan
RUN cd $HOME/tools \
    && git clone https://github.com/wpscanteam/wpscan && cd ./wpscan/ \
    && gem install bundle \
    && bundle install && rake install

# Install skipfish
RUN apt install -y gtk-doc-tools libpcre3-dev libidn11-dev libssl-dev zlib1g-dev \
    && apt clean
RUN cd $HOME/tools \
    && git clone https://github.com/spinkham/skipfish \
    && cd ./skipfish; make \
    && echo 'alias skipfish="~/tools/skipfish/skipfish"' >> $HOME/.bashrc

# Install Myrthril Classic
RUN cd $HOME/tools \
    && git clone https://github.com/ConsenSys/mythril-classic \
    && python3 -m pip install ./mythril-classic

# Install grpcurl
RUN go get github.com/fullstorydev/grpcurl \
    && go install github.com/fullstorydev/grpcurl/cmd/grpcurl

# Install reconnoitre
RUN cd $HOME/tools \
    && git clone https://github.com/codingo/Reconnoitre && cd ./Reconnoitre \
    && python3 setup.py install

# Install AWScli
RUN python3 -m pip install awscli

# Install Scout Suite
RUN cd $HOME/tools \
    && git clone https://github.com/nccgroup/ScoutSuite && cd ./ScoutSuite \
    && python3 -m pip install -r requirements.txt \
	&& echo 'alias scout="~/tools/ScoutSuite/Scout.py"' >> $HOME/.bashrc

#####################################################
# Exploitation tools
#####################################################
RUN apt update \
    && apt -y install afl john sqlmap \
    && apt clean

# Install ropper
RUN python3 -m pip install ropper

# Install ripgrep
RUN curl -LO https://github.com/BurntSushi/ripgrep/releases/download/0.9.0/ripgrep_0.9.0_amd64.deb \
    && dpkg -i ripgrep_0.9.0_amd64.deb \
    && rm ripgrep_0.9.0_amd64.deb

# Install binwalk
RUN cd ~/tools \
    && git clone --depth 1 https://github.com/devttys0/binwalk && cd ./binwalk \
    && python3 setup.py install

# Instal radare2
RUN cd ~/tools \
    && git clone --depth 1 https://github.com/radare/radare2 && cd ./radare2 \
    && ./sys/install.sh

# Install powershell empire
RUN cd ~/tools \
    && git clone https://github.com/EmpireProject/Empire && cd ./Empire \
    && ./setup/install.sh

# Clone powersploit
RUN cd ~/tools \
    && git clone https://github.com/PowerShellMafia/PowerSploit

# Alias RsaCtfTool
RUN python -m pip install gmpy2 Crypto pycryptodome \
    && python3 -m pip install gmpy2 Crypto pycryptodome \
    && cd ~/tools \
    && git clone https://github.com/Ganapati/RsaCtfTool \
    && echo 'alias rsactf="~/tools/RsaCtfTool/RsaCtfTool.py"' >> $HOME/.bashrc

#####################################################
# Tools to add
## hashcat
## merlin
## potentially add GUI support and tools
## make a global requirements.txt for all python pkgs
#####################################################

# Payloads
RUN cd \
    && git clone --recursive https://github.com/drtychai/payloads && cd ./payloads \
    && chmod +x ./init.sh \
    && ./init.sh

WORKDIR /root/
