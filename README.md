# PenDock

Inspired by [grazfather](https://github.com/Grazfather/pwndock), I decided to create a fully fledged dockerized pentesting/CTF containter. This is my attempt to create a faster, more portable, and easier-to-setup version of Kali built purely on Ubuntu.

Note: You should not clone this repo. Either clone [mypendock](https://github.com/drtychai/mypendock) or use `drtychai/pendock:latest` in your Dockerfile to grab the latest build.

## Installation
1. Install Docker:  
  macOS: `brew cask install docker && brew install docker`  
  Ubuntu: `sudo apt update && sudo apt install docker-ce`  
  Windows: https://docs.docker.com/docker-for-windows/install/  
2. Clone [this OTHER repo](https://github.com/drtychai/mypendock).
3. Add customizations to the _Dockerfile_, and the other scripts if your desire, for example, to use a different name.
4. Build: `./build`

## Running it
Management:
- `start` - Start the built image
- `stop`  - Stop the running image
- `connect [COMMAND]` - Connect to the running container. A new `tmux` session is created by default.
