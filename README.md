# multiroom-ansible
Ansible scripts used to install and configure needed tools to setup a multiroom server on moode audio (based on raspberrypi OS). 


# ports in use

| Port               | Description                                                             |
|--------------------|-------------------------------------------------------------------------|
| 80                 | Moode Audio webinterface                                                |
| 6600               | Moode Audio default MPD port                                            |
| 6601               | MPD left port                                                           |
| 6602               | MPD rigt port                                                           |
| 6681               | HTTP port for myMPD left (redirects to SSL port)                        |
| 6691               | SSL port for myMPD left                                                 |
| 6682               | HTTP port for myMPD right (redirects to SSL port)                       |
| 6692               | SSL port for myMPD right                                                |
| 1704               | Snapcast server stream (player) port                                    |
| 1705               | Snapcast server TCP (control) port (TCP JSON RPC)                       |
| 1780               | Snapcast server HTTP RPC port (HTTP POST and websockets)                |

# service names and ports

| Name                    | Port                                      |
|-------------------------|-------------------------------------------|
|mpd-@left.service        | 6601                                      |
|mpd-@right.service       | 6602                                      |
|snapserver.service       | 1704, 1705, 1780                          |
|snapclient@left.service  |                                           |
|snapclient@right.service |                                           |
|mympd-@left.service      | 6681, 6691                                |
|mympd-@right.service     | 6682, 6692                                |

# useful commands

```
alsamixer
AUDIODEV=mono play -n synth sine 1000
moodeutl -f
moodeutl -t
ansible-playbook -i hosts multiroom.yml
cat /var/log/moode.log
sudo vim /lib/systemd/system/snapclient@.service
tail -f /var/log/moodeutl.log
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='sessionid'"
sqlite3 /var/local/www/db/moode-sqlite3.db "select param, value from cfg_system"
sudo fuser 80/tcp
journalctl -u mympd-@left
```

