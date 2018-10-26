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
	&& apt -y install man sudo inetutils-ping gnupg locate\
	&& apt clean

RUN apt update \
    && apt -y install python-dev python-pip \
    && apt -y install python3-dev python3-pip \
    && apt clean

RUN python3 -m pip install --upgrade pip
RUN python -m pip install --upgrade pip

RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
	&& curl -sSL https://get.rvm.io | bash -s stable --rails

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

#####################################################
# Install information gathering tools
#####################################################
RUN apt update \
	&& apt -y install arp-scan masscan nikto nmap snmp \
	&& apt clean

# Install and alias dnsrecon
RUN cd $HOME/tools \
	&& git clone https://github.com/darkoperator/dnsrecon \
	&& pip install -r ./dnsrecon/requirements.txt \
	&& chmod +x ./dnsrecon/dnsrecon.py \
	&& echo 'alias dnsrecon="~/tools/dnsrecon/dnsrecon.py"' >> $HOME/.bashrc

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

# Install and alias aquatone
#RUN gem install aquatone

WORKDIR /root/
