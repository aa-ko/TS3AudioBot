# Credit for the original Dockerfile goes to: https://github.com/getdrunkonmovies-com/TS3AudioBot_docker

# Things to note when using this:
# - youtube-dl path has to be set to '/usr/local/bin/youtube-dl' in ts3audiobot.toml
# - web interface path has to be set to '/opt/TS3AudioBot/bin/WebInterface' in ts3audiobot.toml

FROM mcr.microsoft.com/dotnet/core/sdk:2.2.402-bionic

# Install build pre-requisites.
RUN apt-get update && apt-get install -y \
      openssl \
      libopus-dev \
      opus-tools \
      ffmpeg \
      zip \
      npm \
      python3

# Manually download and install youtube-dl.
# The Bionic package repository contains youtube-dl 2018.03.14-1. Downloading from Youtube does not work with this version.
RUN curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl && chmod a+rx /usr/local/bin/youtube-dl

# Create directories for build and binaries. All data aside from configuration will reside in '/opt/TS3AudioBot'.
RUN mkdir -p /opt/TS3AudioBot/build \
    && mkdir -p /opt/TS3AudioBot/bin \
    && cd /opt/TS3AudioBot/build
COPY . /opt/TS3AudioBot/build/

# Build TS3AudioBot
WORKDIR /opt/TS3AudioBot/build/
RUN dotnet publish --framework netcoreapp2.2 --configuration Release -r linux-x64 --self-contained true -o /opt/TS3AudioBot/bin TS3AudioBot

# Build the web interface via webpack and move it to the bin folder.
WORKDIR /opt/TS3AudioBot/build/WebInterface/
RUN npm install && npm run build
RUN mv /opt/TS3AudioBot/build/WebInterface/dist /opt/TS3AudioBot/bin/WebInterface

# Cleanup build directory.
RUN rm -r /opt/TS3AudioBot/build

# Add new user to run TS3AudioBot
RUN useradd -ms /bin/bash -u 9999 ts3bot

# Create data directory and chown it to the ts3bot user
RUN mkdir -p /data
RUN chown -R ts3bot:nogroup /data

# Set user to ts3bot, we don't want to be root from now on.
USER ts3bot

# Users can mount their config files to this dir with '-v /host/path/to/data:/data'.
WORKDIR /data

CMD ["dotnet", "/opt/TS3AudioBot/bin/TS3AudioBot.dll", "--non-interactive"]