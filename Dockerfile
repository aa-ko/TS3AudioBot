FROM mcr.microsoft.com/dotnet/core/sdk:2.2.402-bionic

# install all pre-requisites, these will be needed always
RUN apt-get update && apt-get install -y \
      openssl \
      libopus-dev \
      opus-tools \
      ffmpeg \
      zip

# install youtube-dl
RUN apt-get update && apt-get install -y python3 youtube-dl

# download and install the TS3AudioBot in the specified version and flavour
RUN mkdir -p /opt/TS3AudioBot/build \
    && cd /opt/TS3AudioBot/build

COPY TS3AudioBot.sln /opt/TS3AudioBot/build/
COPY TS3AudioBot.ruleset /opt/TS3AudioBot/build/
COPY Directory.Build.targets /opt/TS3AudioBot/build/

COPY TS3AudioBot/ /opt/TS3AudioBot/build/TS3AudioBot/
COPY TSLib/ /opt/TS3AudioBot/build/TSLib/

ARG TS3_AUDIOBOT_BUILD_CONFIG="Debug"

# build TS3AudioBot and cleanup
WORKDIR /opt/TS3AudioBot/build/
RUN dotnet publish --framework netcoreapp2.2 --configuration "$TS3_AUDIOBOT_BUILD_CONFIG" -r linux-x64 --self-contained true -o /opt/TS3AudioBot/ TS3AudioBot
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

CMD ["dotnet", "/opt/TS3AudioBot/TS3AudioBot.dll", "--non-interactive"]