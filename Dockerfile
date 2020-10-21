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

# Install Rust
# This is taken from https://raw.githubusercontent.com/rust-lang/docker-rust/master/1.47.0/buster/Dockerfile
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.47.0

RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='49c96f3f74be82f4752b8bffcf81961dea5e6e94ce1ccba94435f12e871c3bdb' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='5a2be2919319e8778698fa9998002d1ec720efe7cb4f6ee4affb006b5e73f1be' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='d93ef6f91dab8299f46eef26a56c2d97c66271cea60bf004f2f088a86a697078' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='e3d0ae3cfce5c6941f74fed61ca83e53d4cd2deb431b906cbd0687f246efede4' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.22.1/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;


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
# This is taken from https://raw.githubusercontent.com/docker-library/golang/master/1.15/buster/Dockerfile
ENV PATH /usr/local/go/bin:$PATH
ENV GOLANG_VERSION 1.15.3

RUN set -eux; \
	\
	dpkgArch="$(dpkg --print-architecture)"; \
	case "${dpkgArch##*-}" in \
		'amd64') \
			arch='linux-amd64'; \
			url='https://storage.googleapis.com/golang/go1.15.3.linux-amd64.tar.gz'; \
			sha256='010a88df924a81ec21b293b5da8f9b11c176d27c0ee3962dc1738d2352d3c02d'; \
			;; \
		'armhf') \
			arch='linux-armv6l'; \
			url='https://storage.googleapis.com/golang/go1.15.3.linux-armv6l.tar.gz'; \
			sha256='aacb49968d08e222c83dea7307b4523c3ae498a5d2e91cd0e480ef3f198ffef6'; \
			;; \
		'arm64') \
			arch='linux-arm64'; \
			url='https://storage.googleapis.com/golang/go1.15.3.linux-arm64.tar.gz'; \
			sha256='b8b88a87ada918ef5189fa5938ef4c46a4f61952a34317612aaac705f4275f80'; \
			;; \
		'i386') \
			arch='linux-386'; \
			url='https://storage.googleapis.com/golang/go1.15.3.linux-386.tar.gz'; \
			sha256='e2f4f9ccfebd38b112fe84572af44bb2fa230d605fcec84def9498095c1bd6ce'; \
			;; \
		'ppc64el') \
			arch='linux-ppc64le'; \
			url='https://storage.googleapis.com/golang/go1.15.3.linux-ppc64le.tar.gz'; \
			sha256='ea420501f9dc4bb1f0db37bb91a7d4e1bb7607bc1865c3ca51ed802477c169ad'; \
			;; \
		's390x') \
			arch='linux-s390x'; \
			url='https://storage.googleapis.com/golang/go1.15.3.linux-s390x.tar.gz'; \
			sha256='098b256bdee92857270a23a47b396e403be378d4cf8331611038518c921de46d'; \
			;; \
		*) \
# https://github.com/golang/go/issues/38536#issuecomment-616897960
			arch='src'; \
			url='https://storage.googleapis.com/golang/go1.15.3.src.tar.gz'; \
			sha256='896a602570e54c8cdfc2c1348abd4ffd1016758d0bd086ccd9787dbfc9b64888'; \
			echo >&2; \
			echo >&2 "warning: current architecture ($dpkgArch) does not have a corresponding Go binary release; will be building from source"; \
			echo >&2; \
			;; \
	esac; \
	\
	wget -O go.tgz.asc "$url.asc" --progress=dot:giga; \
	wget -O go.tgz "$url" --progress=dot:giga; \
	echo "$sha256 *go.tgz" | sha256sum --strict --check -; \
	\
# https://github.com/golang/go/issues/14739#issuecomment-324767697
	export GNUPGHOME="$(mktemp -d)"; \
# https://www.google.com/linuxrepositories/
	gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 'EB4C 1BFD 4F04 2F6D DDCC EC91 7721 F63B D38B 4796'; \
	gpg --batch --verify go.tgz.asc go.tgz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" go.tgz.asc; \
	\
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	\
	if [ "$arch" = 'src' ]; then \
		savedAptMark="$(apt-mark showmanual)"; \
		apt-get update; \
		apt-get install -y --no-install-recommends golang-go; \
		\
		goEnv="$(go env | sed -rn -e '/^GO(OS|ARCH|ARM|386)=/s//export \0/p')"; \
		eval "$goEnv"; \
		[ -n "$GOOS" ]; \
		[ -n "$GOARCH" ]; \
		( \
			cd /usr/local/go/src; \
			./make.bash; \
		); \
		\
		apt-mark auto '.*' > /dev/null; \
		apt-mark manual $savedAptMark > /dev/null; \
		apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
		rm -rf /var/lib/apt/lists/*; \
		\
# pre-compile the standard library, just like the official binary release tarballs do
		go install std; \
# go install: -race is only supported on linux/amd64, linux/ppc64le, linux/arm64, freebsd/amd64, netbsd/amd64, darwin/amd64 and windows/amd64
#		go install -race std; \
		\
# remove a few intermediate / bootstrapping files the official binary release tarballs do not contain
		rm -rf \
			/usr/local/go/pkg/*/cmd \
			/usr/local/go/pkg/bootstrap \
			/usr/local/go/pkg/obj \
			/usr/local/go/pkg/tool/*/api \
			/usr/local/go/pkg/tool/*/go_bootstrap \
			/usr/local/go/src/cmd/dist/dist \
		; \
	fi; \
	\
	go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH
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
RUN go get github.com/fullstorydev/grpcurl/... \
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
