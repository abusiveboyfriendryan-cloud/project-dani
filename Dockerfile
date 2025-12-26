FROM ubuntu:22.04

ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/34.0.0

RUN apt update && apt install -y \
 openjdk-17-jdk \
 wget unzip curl git \
 && rm -rf /var/lib/apt/lists/*

# Android SDK
RUN mkdir -p $ANDROID_HOME/cmdline-tools && \
 wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O tools.zip && \
 unzip tools.zip -d $ANDROID_HOME/cmdline-tools && \
 mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest && \
 rm tools.zip

RUN yes | sdkmanager --licenses && \
 sdkmanager \
  "platform-tools" \
  "platforms;android-34" \
  "build-tools;34.0.0"

WORKDIR /app
COPY . .

RUN chmod +x build.sh

CMD ["./build.sh"]
