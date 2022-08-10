FROM ubuntu:18.04

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
RUN apt update --fix-missing \
    && apt -y install vim patchelf netcat socat strace ltrace curl wget git gdb \
    && apt -y install man sudo inetutils-ping gnupg locate ftp p7zip traceroute \
    && apt -y install libgmp-dev libmpfr-dev libmpc-dev dnsutils tree \
    && apt clean

#####################################################
# Languages
#####################################################

# Install python2/python3
RUN apt update \
    && apt -y install python-dev python-pip \
    && apt -y install python3-dev python3-pip python3-venv \
    && apt clean

RUN python3 -m pip install --upgrade pip setuptools wheel
RUN python -m pip install --upgrade pip setuptools wheel
#RUN pip install --upgrade setuptools

# Install ruby
RUN apt update \
    && apt install -y ruby-full \
    && apt clean

# Install powershell
RUN apt update \
    && apt install -y liblttng-ust0 \
    && apt clean

RUN cd /dev/shm \
    && wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.1/powershell_6.2.1-1.ubuntu.18.04_amd64.deb \
	&& dpkg -i powershell_6.2.1-1.ubuntu.18.04_amd64.deb \
    && apt install -f \
    && apt clean

# JavaScript
RUN apt update \
    && apt install -y npm \
    && npm cache clean -f \
    && npm install -g n \
    && n stable \
    && apt clean

# Install Go
# This is taken from: https://github.com/docker-library/golang/blob/master/1.19/buster/Dockerfile
ENV PATH /usr/local/go/bin:$PATH

ENV GOLANG_VERSION 1.19

RUN set -eux; \
    arch="$(dpkg --print-architecture)"; arch="${arch##*-}"; \
    url=; \
    case "$arch" in \
        'amd64') \
            url='https://dl.google.com/go/go1.19.linux-amd64.tar.gz'; \
            sha256='464b6b66591f6cf055bc5df90a9750bf5fbc9d038722bb84a9d56a2bea974be6'; \
            ;; \
        'armel') \
            export GOARCH='arm' GOARM='5' GOOS='linux'; \
            ;; \
        'armhf') \
            url='https://dl.google.com/go/go1.19.linux-armv6l.tar.gz'; \
            sha256='25197c7d70c6bf2b34d7d7c29a2ff92ba1c393f0fb395218f1147aac2948fb93'; \
            ;; \
        'arm64') \
            url='https://dl.google.com/go/go1.19.linux-arm64.tar.gz'; \
            sha256='efa97fac9574fc6ef6c9ff3e3758fb85f1439b046573bf434cccb5e012bd00c8'; \
            ;; \
        'i386') \
            url='https://dl.google.com/go/go1.19.linux-386.tar.gz'; \
            sha256='6f721fa3e8f823827b875b73579d8ceadd9053ad1db8eaa2393c084865fb4873'; \
            ;; \
        'mips64el') \
            export GOARCH='mips64le' GOOS='linux'; \
            ;; \
        'ppc64el') \
            url='https://dl.google.com/go/go1.19.linux-ppc64le.tar.gz'; \
            sha256='92bf5aa598a01b279d03847c32788a3a7e0a247a029dedb7c759811c2a4241fc'; \
            ;; \
        's390x') \
            url='https://dl.google.com/go/go1.19.linux-s390x.tar.gz'; \
            sha256='58723eb8e3c7b9e8f5e97b2d38ace8fd62d9e5423eaa6cdb7ffe5f881cb11875'; \
            ;; \
        *) echo >&2 "error: unsupported architecture '$arch' (likely packaging update needed)"; exit 1 ;; \
    esac; \
    build=; \
    if [ -z "$url" ]; then \
# https://github.com/golang/go/issues/38536#issuecomment-616897960
        build=1; \
        url='https://dl.google.com/go/go1.19.src.tar.gz'; \
        sha256='9419cc70dc5a2523f29a77053cafff658ed21ef3561d9b6b020280ebceab28b9'; \
        echo >&2; \
        echo >&2 "warning: current architecture ($arch) does not have a compatible Go binary release; will be building from source"; \
        echo >&2; \
    fi; \
    \
    wget -O go.tgz.asc "$url.asc"; \
    wget -O go.tgz "$url" --progress=dot:giga; \
    echo "$sha256 *go.tgz" | sha256sum -c -; \
    \
# https://github.com/golang/go/issues/14739#issuecomment-324767697
    GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
# https://www.google.com/linuxrepositories/
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 'EB4C 1BFD 4F04 2F6D DDCC  EC91 7721 F63B D38B 4796'; \
# let's also fetch the specific subkey of that key explicitly that we expect "go.tgz.asc" to be signed by, just to make sure we definitely have it
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys '2F52 8D36 D67B 69ED F998  D857 78BD 6547 3CB3 BD13'; \
    gpg --batch --verify go.tgz.asc go.tgz; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" go.tgz.asc; \
    \
    tar -C /usr/local -xzf go.tgz; \
    rm go.tgz; \
    \
    if [ -n "$build" ]; then \
        savedAptMark="$(apt-mark showmanual)"; \
        apt-get update; \
        apt-get install -y --no-install-recommends golang-go; \
        \
        export GOCACHE='/tmp/gocache'; \
        \
        ( \
            cd /usr/local/go/src; \
# set GOROOT_BOOTSTRAP + GOHOST* such that we can build Go successfully
            export GOROOT_BOOTSTRAP="$(go env GOROOT)" GOHOSTOS="$GOOS" GOHOSTARCH="$GOARCH"; \
            ./make.bash; \
        ); \
        \
        apt-mark auto '.*' > /dev/null; \
        apt-mark manual $savedAptMark > /dev/null; \
        apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
        rm -rf /var/lib/apt/lists/*; \
        \
# remove a few intermediate / bootstrapping files the official binary release tarballs do not contain
        rm -rf \
            /usr/local/go/pkg/*/cmd \
            /usr/local/go/pkg/bootstrap \
            /usr/local/go/pkg/obj \
            /usr/local/go/pkg/tool/*/api \
            /usr/local/go/pkg/tool/*/go_bootstrap \
            /usr/local/go/src/cmd/dist/dist \
            "$GOCACHE" \
        ; \
    fi; \
    \
    go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

# Install Rust
# This is taken from: https://github.com/rust-lang/docker-rust/blob/master/1.62.1/buster/Dockerfile
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.62.1

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='67777ac3bc17277102f2ed73fd5f14c51f4ca5963adadf7f174adf4ebc38747b' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='32a1532f7cef072a667bac53f1a5542c99666c4071af0c9549795bbdb2069ec1' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='e50d1deb99048bc5782a0200aa33e4eea70747d49dffdc9d06812fd22a372515' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.24.3/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

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
# Keystone + bindings
RUN cd /tmp \
    && git clone --quiet https://github.com/keystone-engine/keystone.git \
    && mkdir -p keystone/build && cd keystone/build \
    && ../make-share.sh \
    && make install \
    && cd ../bindings/python \
    && make install install3

# Capstone + bindings
RUN cd /tmp \
    && git clone --quiet https://github.com/aquynh/capstone.git \
    && cd capstone \
    && ./make.sh default \
    && sudo ./make.sh install \
    && cd ./bindings/python \
    && make install install3

# Unicorn + bindings
RUN cd /tmp \
    && git clone --quiet https://github.com/unicorn-engine/unicorn.git \
    && mkdir -p unicorn/build \
    && cd unicorn/build \
    && cmake .. -DCMAKE_BUILD_TYPE=Release \
    && make

RUN rm -fr -- /tmp/{keystone,capstone,unicorn}
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
    && git clone --recursive https://github.com/drtychai/wordlists.git /usr/share/wordlists \
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
    && python3 -m pip install -r ./dnsrecon/requirements.txt \
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
    && python3 -m pip install .

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
RUN apt install -y gtk-doc-tools libpcre3-dev libidn11-dev libssl1.0-dev zlib1g-dev \
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
RUN go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest

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

# Oh-my-ZSH
RUN apt update --fix-missing \
    && apt install -y postgresql python3-psycopg2 systemd llvm-dev libclang-dev libssl-dev

RUN cargo install -j`nproc` exa fd-find du-dust bat procs bottom sd tokei ripgrep zoxide starship bottom

# Work env
WORKDIR /root/
