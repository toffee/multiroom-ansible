# multiroom-ansible
Ansible scripts used to install and configure needed tools to setup a multiroom server on moode audio (based on raspberrypi OS). 

This repository contains files for universum - raspberry pi zero 2w with hifiberry miniamp used as snapclient for old Quelle Universum 309503 speakers.

# step by step configuration
Create SD card with moode audio: Use Raspberry Pi Imager to write the image downloaded from https://moodeaudio.org/ to SD card.
TODO: To verify/test if this infrastructure work on plain Rapsberry Pi OS Lite - https://www.raspberrypi.com/software/operating-systems/

Configure the raspberrypi to use the Hifiberry AMP 2:

```
pi@moode:~ $ cat /boot/config.txt
disable_splash=1
disable_overscan=1
hdmi_drive=2
hdmi_blanking=1
hdmi_force_edid_audio=1
hdmi_force_hotplug=1
hdmi_group=0
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
dtoverlay=hifiberry-dacplus
#dtoverlay=disable-wifi
#dtoverlay=disable-bt
force_eeprom_read=0
```

Modify /boot/moodecfg.ini (rename on SDCard file /boot/moodecfg.ini.default) at least the following:
>hostname = "moode01"
>timezone = "Europe/Bucharest"
>i2sdevice = "HiFiBerry Amp2"
>mixer_type = "hardware"
>first_use_help = "No"
>source_name[0] = "nfs-ds-music"
>source_type[0] = "nfs"
>source_address[0] = "192.168.120.4"
>source_remotedir[0] = "volume1/music"
>source_username[0] = ""
>source_password[0] = ""
>source_charset[0] = "utf8"
>source_rsize[0] = "61440"
>source_wsize[0] = "65536"
>source_options[0] = "ro,nolock"


Connect with ssh to control node and clone this repository. Control node in my case is jupiter, but can be the moode itself - default user name: pi, password: moodeaudio.
>git clone https://github.com/toffee/multiroom-ansible.git

Update repositories on control node (bellow the command for raspberry pi) 
>sudo apt-get update --allow-releaseinfo-change

Install ansible on control node 
>sudo apt install ansible 

Configure public key authentication from jupiter to moode/universum:
>ssh-copy-id -i ~/git/toffee/smartserver/config/jupiter/vault/ssh_auth/auth-moode01.toffee.ro.pub pi@moode01.toffee.ro
>ssh-copy-id -i ~/git/toffee/smartserver/config/jupiter/vault/ssh_auth/universum.toffee.ro.pub daniel@universum.toffee.ro

Run ansible script on specific node/host (the -l switch) or on all configured nodes (without -l)
>cd multiroom-ansible/
>ansible-playbook -i hosts.yml -l universum multiroom.yml
>ansible-playbook -i hosts.yml -l snapserver multiroom.yml

The following are not needed if made the auto-configure at boot in /boot/moodecfg.ini, but make sense to verify.
Edit configuration in moode - http://192.168.120.71/ (or http://moode01.toffee.ro)
 * Audio>Named device and reboot (sudo systemmctl reboot)
 * System>Timezone
 * System>Host name
 * Audio>MPD Settings>Volume type - Hardware.

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

cat /var/lib/alsa/asound.state
```

#Known problems

The ansible script change the name of the host using command
>hostnamectl set-hostname {{host_name}}
but this does not update the /etc/hosts file (the 127.0.0.1 still points to the old hostname). This lead to the error
>sudo: unable to resolve host moode-one: Name or service not known
to be written into /tmp/cfg_audiodev.sql (the files that is check for integrity in function integrityCheck from /var/www/inc/playerlib.php
The worker.php does not start and write to the log /var/log/moode.log

```
20211212 224638 worker: -- Start
20211212 224638 worker: Successfully daemonized
20211212 224639 worker: Integrity check (failed:3)
20211212 224639 worker: Exited
```


Sometimes the sound stops working... seems that it's due to moode audio put the "Digital" mixer on mute.
Check the asound.state file from /var/lib/alsa/asound.state and see the consfiguration:
```
	control.1 {
		iface MIXER
		name 'Digital Playback Volume'
		value.0 0
		value.1 0
		comment {
			access 'read write'
			type INTEGER
			count 2
			range '0 - 207'
			dbmin -9999999
			dbmax 0
			dbvalue.0 -9999999
			dbvalue.1 -9999999
		}
	}
```

To hear sound should be something like:
```
	control.1 {
		iface MIXER
		name 'Digital Playback Volume'
		value.0 163
		value.1 163
		comment {
			access 'read write'
			type INTEGER
			count 2
			range '0 - 207'
			dbmin -9999999
			dbmax 0
			dbvalue.0 -2200
			dbvalue.1 -2200
		}
	}
```
Altering the mixer from alsamixer seems to solve the problem.



https://github.com/skalavala/Multi-Room-Audio-Centralized-Audio-for-Home

Nice redings:

https://www.reddit.com/r/homeassistant/comments/fmbskz/please_recommend_me_a_multi_room_audio_setup/
https://github.com/markferry/multizone-audio
https://github.com/ahayworth/snapcast-autoconfig
https://github.com/Burningstone91/smart-home-setup

Integrating openHAB with snapcast via PulseAudio:
 * https://community.openhab.org/t/audio-playback-with-openhab-and-snapcast/137584/6
 * https://github.com/shivasiddharth/PulseAudio-System-Wide/