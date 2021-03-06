FROM library/debian:stable-20210621-slim
RUN DEBIAN_FRONTEND="noninteractive" && \
    apt update && \
    apt install --no-install-recommends --assume-yes \
        unzip=6.0-23+deb10u2 && \
    rm -r /var/lib/apt/lists /var/cache/apt

# App user
ARG APP_USER="terraria"
ARG APP_UID=1369
ARG DATA_DIR="/terraria"
RUN useradd --uid "$APP_UID" --user-group --create-home --home "$DATA_DIR" --shell /sbin/nologin "$APP_USER"

# Download app
ARG APP_DIR="/opt/terraria"
ARG APP_ARCHIVE="terraria.zip"
ARG APP_URL="https://terraria.org/system/dedicated_servers/archives/000/000/046/original/terraria-server-1423.zip"
ADD "$APP_URL" "$APP_ARCHIVE"
RUN TMP_DIR="/opt" && \
    unzip -d "$TMP_DIR" "$APP_ARCHIVE" && \
    apt purge -y unzip && \
    mv "$TMP_DIR/"*"/Linux" "$APP_DIR" && \
    rm -r -f "$APP_ARCHIVE" "$APP_DIR/changelog.txt" "$APP_DIR/lib" "$APP_DIR/Terraria.png" "$APP_DIR/TerrariaServer" && \
    chmod +x "$APP_DIR/TerrariaServer.bin.x86_64" && \
    chown -R "$APP_USER":"$APP_USER" "$APP_DIR"

# Config
ARG CONFIG="$DATA_DIR/config.txt"
RUN WORLD_NAME="world" && \
    echo "world=$DATA_DIR/$WORLD_NAME.wld\nautocreate=1\nworldname=$WORLD_NAME\nworldpath=$DATA_DIR" > "$CONFIG" && \
    chown -R "$APP_USER":"$APP_USER" "$DATA_DIR"

#      GAME
EXPOSE 7777/tcp

# Launch parameters
USER "$APP_USER"
WORKDIR "$DATA_DIR"
ENV APP_DIR="$APP_DIR" \
    CONFIG="$CONFIG"
ENTRYPOINT exec "$APP_DIR/TerrariaServer.bin.x86_64" -config "$CONFIG"