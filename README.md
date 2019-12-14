# Secure SSH Tunneling to AWS EC2 Instance

## Prerequisite

### Client: Raspberry Pi, Bearbone or etc

- Linux OS
- [OpenSSH](https://www.openssh.com/)
- `autossh` (optional)
- Generated RHA Key (`id_rsa`, `id_rsa.pub` in `~/.ssh`): If you don't have these, simply run `ssh-keygen` without passphrase

### Server: AWS EC2 or any Linux server

#### Create user account named `tunnel`

For security reasons, this account should not be a sudo account.

- Amazon Linux 2 or Amazon Linux AMI EC2 Instance

```bash
[ec2-user ~]$ sudo adduser tunnel
```

- AWS Ubuntu EC2 Instance

```bash
[ubuntu ~]$ sudo adduser newuser --disabled-password
```

#### Login `tunnel` account

```bash
sudo su - tunnel
```

#### Add SSH Public key of clients

- make `authorized_keys`

```bash
mkdir .ssh
chmod 700 .ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

- add public key of client to `authorized_keys`

```bash
nano ~/.ssh/authorized_keys
```

## Installation

This script should be provided with `[REMOTE-IPADDRESS]` and `[REMOTE_PORT]`.

### Full installation script: case of `autossh`

```bash
curl --insecure -o- \
https://raw.githubusercontent.com/eunchurn/aws-secure-tunnel/scripts/secure-tunnel-autossh@aws.service \
| bash -s [REMOTE_IPADDRESS] [REMOTE_PORT]
```

### Full installation script: case of `ssh`

```bash
curl --insecure -o- \
https://raw.githubusercontent.com/eunchurn/aws-secure-tunnel/scripts/secure-tunnel-ssh@aws.service \
| bash -s [REMOTE_IPADDRESS] [REMOTE_PORT]
```

## Contents of these script files

### `secure-tunnel@aws` file in `/dev/default/`

- `TARGET` is your EC2 IP address.
- `USERNAME` is `tunnel` user account.
- `REMOTE_PORT` is the port number of EC2 that you need to connect to the client from the EC2 instance.

```yml
TARGET=$1
LOCAL_ADDR=0.0.0.0
LOCAL_PORT=22
REMOTE_PORT=$2
USERNAME=tunnel
SSH_TARGET_PORT=22
```

### `secure-tunnel@aws.service` file in `/dev/systemd/system/`

#### In case of `autossh`

```yml
[Unit]
Description=Setup a secure tunnel to %I
After=network.target

[Service]
Environment="LOCAL_ADDR=localhost"
EnvironmentFile=/etc/default/secure-tunnel-autossh@%i
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -M 0 -o "ExitOnForwardFailure=yes" -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -NR ${REMOTE_PORT}:${LOCAL_ADDR}:${LOCAL_PORT} -p ${SSH_TARGET_PORT} ${USERNAME}@${TARGET}

# Restart every >2 seconds to avoid StartLimitInterval failure
RestartSec=5
Restart=always

[Install]
WantedBy=multi-user.target
```

#### In case of `ssh`

```yml
[Unit]
Description=Setup a secure tunnel to %I
After=network.target

[Service]
Environment="LOCAL_ADDR=localhost"
EnvironmentFile=/etc/default/secure-tunnel@%i
ExecStart=/usr/bin/ssh -NT -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes -L ${LOCAL_ADDR}:${LOCAL_PORT}:localhost:${REMOTE_PORT} ${TARGET}

# Restart every >2 seconds to avoid StartLimitInterval failure
RestartSec=5
Restart=always

[Install]
WantedBy=multi-user.target
```

## Example

### AWS Server

- DNS: `ec2-13-124-180-92.ap-northeast-2.compute.amazonaws.com`
- IP Address: `13.124.180.92`
- Port: `10022`
- Client Username: `client-user`

### Installation `autossh` tunnel system

- In your client

```bash
curl --insecure -o- \
https://raw.githubusercontent.com/eunchurn/aws-secure-tunnel/scripts/secure-tunnel-autossh@aws.service \
| bash -s 13.124.180.92 10022
```

- Make sure your tunnel daemon alive

```bash
systemctl status secure-tunnel@aws
```

- Or check log: `-r` is reverse, `-f` is follow

```bash
journalctl -u secure-tunnel@aws -r
```

### Check tunnel and Log in client from your EC2 instance

- Make sure PORT is open.

```bash
sudo lsof -i:10022 | grep IPv4
```

- Connect to SSH and log in through the tunnel.

```bash
ssh client-user@localhost -p 10022
```

- Enjoy
