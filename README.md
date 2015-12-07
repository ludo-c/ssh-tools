# utils
- tunnel.sh: create a socks proxy or remote|local port forwarding
- tunnel.service: systemd autostart configuration

## Dependencies
- tunnel.sh depends of autossh

## Advices
I recommand to create a 'tunnel' user on your server with '/bin/false' shell.
Thus, if someone wants to reuse the ssh control socket (or use the publickey login) he will not be able to connect to your server.

You will still be able to connect to add authorized public keys:
```shell
sudo su -s /bin/{zsh,bash} tunnel
```

You can also generate a special private key (client side) with no passphrase in order to connect at startup without login.

## Tips
You can use soft links to create multiple socks or tunnels. There will be a config file for each link.

```shell
cd $HOME/bin
ln -s tunnel.sh socks.sh
socks.sh # will create ~/.config/socks.sh.conf
```
