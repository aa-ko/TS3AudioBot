FROM mcr.microsoft.com/dotnet/core/sdk:3.1.201-bionic

# install all pre-requisites, these will be needed always
RUN apt-get update && apt-get install -y \
      openssl \
      libopus-dev \
      opus-tools \
      ffmpeg \
      zip

# download and install the TS3AudioBot in the specified version and flavour
RUN mkdir -p /opt/TS3AudioBot/build \
    && cd /opt/TS3AudioBot/build

COPY TS3AudioBot.sln /opt/TS3AudioBot/build/
COPY TS3AudioBot.ruleset /opt/TS3AudioBot/build/
COPY Directory.Build.targets /opt/TS3AudioBot/build/

COPY TS3AudioBot/ /opt/TS3AudioBot/build/TS3AudioBot/
COPY TSLib/ /opt/TS3AudioBot/build/TSLib/

ARG TS3_AUDIOBOT_BUILD_CONFIG="Debug"

WORKDIR /opt/TS3AudioBot/build/
RUN dotnet build --framework netcoreapp3.1 --configuration "$TS3_AUDIOBOT_BUILD_CONFIG" TS3AudioBot

RUN mv /opt/TS3AudioBot/build/TS3AudioBot/bin/"$TS3_AUDIOBOT_BUILD_CONFIG"/netcoreapp3.1/* /opt/TS3AudioBot/

# define this here so we can reuse the above layers
ARG TS3_AUDIOBOT_INCLUDE_YOUTUBE_DL="true"

# install and setup youtube-dl if configured
RUN bash -c 'if [ "xy$TS3_AUDIOBOT_INCLUDE_YOUTUBE_DL" == "xytrue" ] ; then \
        apt-get update && apt-get install -y python3 \
        && update-alternatives --install /usr/bin/python python /usr/bin/python3 99 \
        && curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl && chmod a+rx /usr/local/bin/youtube-dl ; \
    else \
        echo "skipping setup for youtube-dl"; \
    fi'

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