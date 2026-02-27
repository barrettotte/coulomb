#!/bin/bash

# Initialize mobile-box distrobox

set -ex

source "$(dirname "$0")/common.sh"
init_start "mobile-box"

echo "Installing packages..."
install_apt_base

# Java (Android requires JDK 17)
sudo apt-get install -y \
    openjdk-17-jdk

# Android tools
sudo apt-get install -y \
    adb \
    fastboot \
    scrcpy

# Android SDK cmdline-tools
echo "Installing Android SDK command-line tools..."
ANDROID_HOME="$HOME/Android/Sdk"
mkdir -p "$ANDROID_HOME/cmdline-tools"
ANDROID_SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
curl -L "$ANDROID_SDK_URL" -o /tmp/cmdline-tools.zip
unzip -o /tmp/cmdline-tools.zip -d /tmp/cmdline-tools
mv /tmp/cmdline-tools/cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
rm -rf /tmp/cmdline-tools /tmp/cmdline-tools.zip

# accept licenses and install SDK components
yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses || true
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
    "platform-tools" \
    "build-tools;34.0.0" \
    "platforms;android-34" \
    "emulator"

# Kotlin compiler
echo "Installing Kotlin..."
KOTLIN_VERSION=$(curl -s https://api.github.com/repos/JetBrains/kotlin/releases/latest | grep -oP '"tag_name":\s*"v?\K[^"]+')
curl -L "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip" -o /tmp/kotlin.zip
mkdir -p "$HOME/.local"
unzip -o /tmp/kotlin.zip -d "$HOME/.local"
rm -f /tmp/kotlin.zip

# Gradle
echo "Installing Gradle..."
GRADLE_VERSION=$(curl -s https://services.gradle.org/versions/current | grep -oP '"version"\s*:\s*"\K[^"]+')
curl -L "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip
unzip -o /tmp/gradle.zip -d "$HOME/.local"
ln -snf "$HOME/.local/gradle-${GRADLE_VERSION}" "$HOME/.local/gradle"
rm -f /tmp/gradle.zip

# Flutter SDK
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable "$HOME/.local/flutter" --depth 1

setup_zsh
setup_symlinks
init_end

echo ""
echo "NOTE: Add the following to your shell profile:"
echo "  export ANDROID_HOME=\$HOME/Android/Sdk"
echo "  export PATH=\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$PATH"
echo "  export PATH=\$HOME/.local/kotlinc/bin:\$PATH"
echo "  export PATH=\$HOME/.local/gradle/bin:\$PATH"
echo "  export PATH=\$HOME/.local/flutter/bin:\$PATH"
