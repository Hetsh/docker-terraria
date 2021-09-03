FROM amd64/debian:stable-20210902-slim

# App user
ARG APP_USER="terraria"
ARG APP_UID=1369
ARG DATA_DIR="/terraria"
RUN useradd --uid "$APP_UID" --user-group --create-home --home "$DATA_DIR" --shell /sbin/nologin "$APP_USER"

# Install Terraria Server
ARG APP_VERSION=1423
ARG APP_ARCHIVE="terraria-server-1423.zip"
ARG APP_URL="https://terraria.org/api/download/pc-dedicated-server/$APP_ARCHIVE"
RUN DEBIAN_FRONTEND="noninteractive" && \
    apt update && \
    apt install --no-install-recommends --assume-yes \
        ca-certificates \
        wget \
        unzip && \
    wget --quiet "$APP_URL" && \
    APP_DIR="/opt/terraria" && \
    unzip -q -d "$APP_DIR" "$APP_ARCHIVE" && \
    apt purge --assume-yes --auto-remove \
        ca-certificates \
        wget \
        unzip && \
    mv "$APP_DIR/$APP_VERSION/Linux/"* "$APP_DIR" && \
    rm -r \
        /var/lib/apt/lists \
        /var/cache/apt \
        "$APP_ARCHIVE" \
        "$APP_DIR/$APP_VERSION" \
        "$APP_DIR/changelog.txt" \
        "$APP_DIR/lib" \
        "$APP_DIR/Terraria.png" \
        "$APP_DIR/TerrariaServer" && \
    chown -R "$APP_USER":"$APP_USER" "$APP_DIR" && \
    chmod +x "$APP_DIR/TerrariaServer.bin.x86_64" && \
    ln -s "$APP_DIR/TerrariaServer.bin.x86_64" "/usr/bin/TerrariaServer"

# Config
ARG CONFIG="$DATA_DIR/config.txt"
RUN WORLD_NAME="world" && \
    echo "world=$DATA_DIR/$WORLD_NAME.wld\nautocreate=1\nworldname=$WORLD_NAME\nworldpath=$DATA_DIR" > "$CONFIG" && \
    chown -R "$APP_USER":"$APP_USER" "$DATA_DIR"
VOLUME ["$DATA_DIR"]

#      GAME
EXPOSE 7777/tcp

# Launch parameters
USER "$APP_USER"
WORKDIR "$DATA_DIR"
ENV APP_DIR="$APP_DIR" \
    CONFIG="$CONFIG"
ENTRYPOINT exec "TerrariaServer" -config "$CONFIG"