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



## kvmd-otg argparse fix

**Problem:** kvmd-otg was failing with error:
```
kvmd-otg: error: argument --main-config: invalid valid_abs_file value: '/usr/lib/kvmd/main.yaml'
```

**Root cause:** Python's argparse validates the `default` value using the `type` function even when a different value is provided via command line. The hardcoded defaults like `/usr/lib/kvmd/main.yaml` don't exist in NixOS, causing validation to fail.

**Solution:**
1. Patched `kvmd/apps/__init__.py` to remove `type=valid_abs_file`, `type=valid_abs_path`, and `type=valid_abs_dir` from argparse argument declarations
2. Created `/etc/kvmd/override.yaml` file via systemd.tmpfiles
3. Updated systemd services to explicitly provide all config paths:
   - `--main-config` (from Nix store)
   - `--override-dir /etc/kvmd/override.d`
   - `--override-config /etc/kvmd/override.yaml`

This allows kvmd-otg to start without attempting to validate non-existent default paths.

todo:
- kvmd-watchdog
- kvmd-otgnet
