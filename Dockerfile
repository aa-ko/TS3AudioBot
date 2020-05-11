# TODO:
# - Do we want the WebInterface to reside in /opt/TS3AudioBot/bin/WebInterface? This requires the config to contain the correct path.
#   Alternatively, we could move the webpack output directly to /data but I have no idea if this is a security concern.
# - Switch to building in release mode

FROM mcr.microsoft.com/dotnet/core/sdk:2.2.402-bionic

# install all pre-requisites and youtube-dl
RUN apt-get update && apt-get install -y \
      openssl \
      libopus-dev \
      opus-tools \
      ffmpeg \
      zip \
      npm \
      python3 \
      youtube-dl

# download and install the TS3AudioBot in the specified version and flavour
RUN mkdir -p /opt/TS3AudioBot/build \
    && mkdir -p /opt/TS3AudioBot/bin \
    && cd /opt/TS3AudioBot/build

COPY . /opt/TS3AudioBot/build/

# build TS3AudioBot
WORKDIR /opt/TS3AudioBot/build/
RUN dotnet publish --framework netcoreapp2.2 --configuration Release -r linux-x64 --self-contained true -o /opt/TS3AudioBot/bin TS3AudioBot

# build and move web interface
WORKDIR /opt/TS3AudioBot/build/WebInterface/
RUN npm install && npm run build
RUN mv /opt/TS3AudioBot/build/WebInterface/dist /opt/TS3AudioBot/bin/WebInterface

# cleanup build directory
RUN rm -r /opt/TS3AudioBot/build

# add user to run under
RUN useradd -ms /bin/bash -u 9999 ts3bot

# make data directory and chown it to the ts3bot user
RUN mkdir -p /data
RUN chown -R ts3bot:nogroup /data

# set user to ts3bot, we dont want to be root from now on
USER ts3bot

# set the work dir to data, so users can properly mount their config files to this dir with -v /host/path/to/data:/data
WORKDIR /data

CMD ["dotnet", "/opt/TS3AudioBot/bin/TS3AudioBot.dll", "--non-interactive"]