# PenDock

Inspired by [grazfather](https://github.com/Grazfather/pwndock), I decided to create a fully fledged dockerized pentesting/CTF containter. This is my attempt to create a faster, easier-to-setup version of Kali.

## Installation
1. Install Docker: `brew cask install docker && brew install docker` on OSX. You can figure it out on Windows and Linux.
2. Clone [this OTHER repo](https://github.com/drtychai/mypendock).
3. Add customizations to the _Dockerfile_, and the other scripts if your desire, for example, to use a different name.
4. Build: `./build`

## Running it
Management: `start`, `stop`, `connect`
