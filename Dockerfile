# ===============================
# Base OS
# ===============================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ===============================
# Environment Variables
# ===============================
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
ENV PATH=$PATH:$ANDROID_HOME/platform-tools
ENV PATH=$PATH:$ANDROID_HOME/build-tools/34.0.0
ENV PATH=$PATH:$JAVA_HOME/bin

# ===============================
# System Dependencies
# ===============================
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    wget \
    unzip \
    curl \
    git \
    ca-certificates \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# ===============================
# Android SDK Command Line Tools
# ===============================
RUN mkdir -p $ANDROID_HOME/cmdline-tools

RUN wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip \
    -O /tmp/cmdline-tools.zip && \
    unzip /tmp/cmdline-tools.zip -d $ANDROID_HOME/cmdline-tools && \
    mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# ===============================
# Accept Licenses & Install SDK Packages
# ===============================
RUN yes | sdkmanager --licenses

RUN sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0"

# ===============================
# Cloudflared (Optional, Safe)
# ===============================
RUN wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    -O /usr/local/bin/cloudflared && \
    chmod +x /usr/local/bin/cloudflared

# ===============================
# App Workspace
# ===============================
WORKDIR /app

# Copy project files
COPY . .

# Ensure build script is executable
RUN chmod +x build.sh

# ===============================
# Default Command
# ===============================
CMD ["./build.sh"]
