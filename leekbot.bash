#!/bin/bash

NICK=${NICK:-leekbot-$RANDOM}
CHANNEL=${CHANNEL:-#memleek}
SERVER=${SERVER:-chat.freenode.net}
PORT=${PORT:-6667}

exec 3<> /dev/tcp/$SERVER/$PORT

exec <&3
exec 1>&3

cleanup() {
	echo "QUIT"
	exec 3<&-
	exec 3>&-
}

trap cleanup SIGHUP SIGINT SIGTERM

echo "NICK $NICK"
echo "USER $NICK $NICK $NICK $NICK"

while read -r l; do
	echo "<$l" >&2

	if [[ $l == PING\ * ]]; then
		echo ">PONG ${l#PING }" >&2
		echo "PONG ${l#PING }"
	elif [[ $l == *\ 001\ * ]]; then
		echo ">JOIN $CHANNEL" >&2
		echo "JOIN $CHANNEL"
	elif [[ $l =~ "PRIVMSG ${CHANNEL} :${NICK}: quit" ]]; then
		cleanup
		exit 0
	elif [[ $l =~ "PRIVMSG ${CHANNEL} :${NICK}: reload" ]]; then
		cleanup
		exec "$(realpath "$0")" "$@" >&2
	elif [[ $l =~ "PRIVMSG ${CHANNEL} :${NICK}: source" ]]; then
		if type curl > /dev/null 2>/dev/null; then
			url=$(curl -F 'sprunge=<-' http://sprunge.us < "$0")
			echo "PRIVMSG ${CHANNEL} :${url}?bash"
		else
			echo "PRIVMSG ${CHANNEL} :sorry, can't find curl."
		fi
	elif [[ $l =~ "PRIVMSG ${CHANNEL} :${NICK}: uptime" ]]; then
		if ! type uptime > /dev/null 2>/dev/null; then
			echo "PRIVMSG ${CHANNEL} :sorry, can't find uptime."
		elif ! type hostname > /dev/null 2>/dev/null; then
			echo "PRIVMSG ${CHANNEL} :sorry, can't find hostname."
		else
			echo "PRIVMSG ${CHANNEL} :$(hostname -f 2>&1) - $(uptime)"
		fi
	elif [[ $l =~ "PRIVMSG ${CHANNEL} :${NICK}: wall" ]]; then
		if type wall > /dev/null 2>/dev/null; then
			srcnick=${l%%!*}
			srcnick=${srcnick#:}
			message=${l##*PRIVMSG ${CHANNEL} :${NICK}: wall}
			wall "$srcnick: $message" >&2
		else
			echo "PRIVMSG ${CHANNEL} :sorry, can't find wall."
		fi
	elif [[ $l =~ "PRIVMSG ${CHANNEL} :${NICK}:" ]]; then
		echo "PRIVMSG ${CHANNEL} :okay."
	fi
done

cleanup
exit 0
