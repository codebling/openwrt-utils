## opkg-cleanup

When `opkg` tries to install a package but fails (this can occur if, for example, your router runs out of space during installation, which can happen because `opkg` only naively checks space requirements), it doesn't clean up after itself.

This script looks up all files that would have been installed by a specific package, and if they exist, it deletes them.

Based on [this gist](https://gist.github.com/vbajpai/4463250).

### Installation

```
wget https://github.com/codebling/openwrt-utils/raw/master/opkg-cleanup.sh
```

### Usage

`sh opkg-cleanup.sh` to view usage

```
sh opkg-cleanup.sh <packages>
```
where <packages> is a list of (space-separated) packages (which were partially installed) to clean up.
