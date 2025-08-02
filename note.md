fstab :

```
/dev/loop1  /var/lib/kvmd/msd  vfat  rw,users,X-kvmd.otgmsd-root=/var/lib/kvmd/msd  0  0
```

janus in /etc...
all files in /etc/kvmd/

/usr/share/kvmd/platform
/usr/share/kvmd/extras/

/usr/share/kvmd/platform

```
PIKVM_MODEL=v2
PIKVM_VIDEO=hdmi
PIKVM_BOARD=rpi4
```



different boot options

kvmd-gencert


/etc/kvmd/janus/janus.plugin.ustreamer.jcfg
/etc/kvmd/tc358743-edid.hex

setfacl -m u:kvmd-media:rwx kvmd/
setfacl -m u:kvmd-pst:rwx kvmd/



todo:
- kvmd-watchdog
- kvmd-otgnet
