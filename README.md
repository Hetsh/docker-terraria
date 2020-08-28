# Terraria
Simple to set up terraria server.

## Running the server
```bash
docker run --detach --interactive --name terraria --publish 7777:7777/tcp hetsh/terraria
```
`--interactive` enables passing commands to the running server (required for shutdown).

## Stopping the container
```bash
echo exit | docker attach terraria
```
Because the terraria server does not save the world when receiving the `SIGTERM` signal that is sent by `docker stop`, we have to gracefully shut down the server by piping the `exit` command to the container.

## Configuration
Terraria Server is configured via configuration file `/terraria/config.txt`.
Configuable parameters are listed on the terraria [wiki](https://terraria.gamepedia.com/Server#Server_config_file).

## Creating persistent storage
```bash
MP="/path/to/storage"
mkdir -p "$MP"
chown -R 1369:1369 "$MP"
```
`1369` is the numerical id of the user running the server (see Dockerfile).
Start the server with the additional mount flag:
```bash
docker run --mount type=bind,source=/path/to/storage,target=/terraria ...
```

## Automate startup and shutdown via systemd
The systemd unit can be found in my GitHub [repository](https://github.com/Hetsh/docker-terraria).
```bash
systemctl enable terraria@<port> --now
```
Individual server instances are distinguished by port.
By default, the systemd service assumes `/apps/terraria/<port>` for persistent storage and `/etc/localtime` for timezone.
Since this is a personal systemd unit file, you might need to adjust some parameters to suit your setup.

## Fork Me!
This is an open project (visit [GitHub](https://github.com/Hetsh/docker-terraria)). Please feel free to ask questions, file an issue or contribute to it.