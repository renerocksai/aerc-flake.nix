# aerc-flake.nix

This flake installs [aerc](https://aerc-mail.org) and required additional
commands from NixOS-21.11 release packages. In addition, it creates
`~/.aerc-tools/`, and puts symlinks to all installed commands in there.

It adds aerc's filter directory to the path, as well as the newly created aerc
tools directory.

This allows you to write filters that use commands like awk, bash, socksify, etc
in shebang lines in filters, without having to know nix store location of aerc
or any other package.

It also allows you to re-use existing aerc filters, like `.html-wrapped` in your
own filters.

For instance, here is my `~/.config/aerc/filters/html`:

```bash
#!/home/rs/.aerc-tools/bash -e
set -e
exec -a "$0" ".html-wrapped"  "$@"
```

...and my `~/.config/aerc/filters/html-unsafe`:

```bash
#!/home/rs/.aerc-tools/bash
# aerc filter which runs w3m using socksify (from the dante package) to prevent
# any phoning home by rendered emails. If socksify is not installed then w3m is
# used without it.
if [ $(command -v socksify) ]; then
	export SOCKS_SERVER="127.0.0.1:1"
	PRE_CMD=socksify
else
	PRE_CMD=""
fi
exec $PRE_CMD w3m \
	-T text/html \
	-cols $(tput cols) \
	-dump \
	-o display_image=false \
	-o display_link_number=true
```

Note the shebang line and the use of socksify.
