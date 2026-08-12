#!/bin/bash

# just type (. ui.sh) to dot source the file and use aliases instead

function llog() {
	echo $1 >> "logs.md"
	echo $(date) >> "logs.md"
}

alias li='llog;git add --all;git commit -m "modi comm";git push'
alias dn='sudo echo "HandleLidSwitch=ignore" >> /etc/systemd/login.conf'
alias lc='clear;ls -A'
alias lsc='clear;lsblk;ls -A'
alias gl='git log --graph --pretty=oneline --abbrev-commit'
alias tt='clear;ls -A;tree -L 2 .'

function jl() {
	while (true); do
		clear
		ls -A
		tree "0time"
		sleep 2
	done
}

change_prefix() {
    local old_pref="$1"
    local new_pref="$2"

    # Validate inputs
    if [[ -z "$old_pref" || -z "$new_pref" ]]; then
        echo "Usage: change_prefix <old_prefix> <new_prefix>"
        return 1
    fi

    # Loop through matching files safely
    for file in "$old_pref"*; do
        # Ensure it is a valid file, not a directory or empty glob
        if [[ -f "$file" ]]; then
            # Strip old prefix and prepend new prefix
            local new_name="${new_pref}${file#"$old_pref"}"
            mv -n -- "$file" "$new_name"
        fi
    done
}

wh() {
	clear
	ls -A
	echo "---"
	find /home/niko/f/envs/invs -name "*$1*" | grep -v ".venv"
	sleep 2
}

vm() {
	chmod -x -R ./
	git add --all
	git commit -m "quik modi vm commit"
	git push
}

sb() {
	echo "ctrld ends"
	local input=$(cat)

	if [[ -n "$input" ]]; then
		git add .
		git commit -m "$input"
		git push
	else
		echo "empty..."
	fi
}

ah() {
	python3 ./script.py "$@"
}

ticker() {
	# examples provided by google ai, these do not represent whole investments, just an example
	/snap/bin/ticker -w AAPL,MSFT,NVDA,GOOGL,AMZN,META,TSLA,BRK.B,JPM,LLY,V,UNH,WMT,XOM,HD,PG,MA,COST,JNJ,AVGO,NFLX,AMD,DIS,PEP,KO,ADBE,CRM,BAC,TM,ORCL,CSCO,NKE
}

