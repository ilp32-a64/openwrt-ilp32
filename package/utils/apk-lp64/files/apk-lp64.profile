# LP64 programs installed by apk-lp64: at the end of PATH, so programs of the system come first
for d in /opt/lp64/usr/bin /opt/lp64/usr/sbin /opt/lp64/bin /opt/lp64/sbin; do
	[ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$PATH:$d" ;; esac
done
unset d
export PATH
