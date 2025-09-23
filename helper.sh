#!/bin/zsh --no-rcs

bin='populate_clipboard'
sentinel='version.sentinel'

_dbg() {
	(( DEBUG == 1 )) || return 0
	cat >&2 <<-EOF
	🪵DEBUG: $1
	EOF
}

if [[ -e $sentinel ]]; then
	read VERSION < $sentinel
	_dbg "sentinel @ v${VERSION}"
fi

if [[ ! -x $bin ]] || [[ $alfred_workflow_version != "$VERSION" ]]; then
	_dbg "compiling $bin binary"
	osascript <<-EOS
	display notification "The $alfred_workflow_name workflow uses a helper program to interface with the clipboard history. This only occurs once, when a new workflow version is installed." with title "Compiling Swift binary"
	EOS
	swiftc -O -o $bin{,.swift}
	echo $alfred_workflow_version > $sentinel
	_dbg "set sentinel @ v${alfred_workflow_version}"
fi

./$bin "$1"
