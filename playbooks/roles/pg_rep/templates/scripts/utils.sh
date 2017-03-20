#!/bin/bash

set -o pipefail

indent() {
	sed -u "s/^/       /"
}

display() {
	echo -e "\n----->" $*
}

abort() {
	echo $* ; exit 77
}


function logEntry {
	local timestamp=$(TZ=utc date --iso-8601=seconds)
	local type=$1
	local message=$2
	local hostname=$HOSTNAME
	. /etc/lsb-release
	local desc=$DISTRIB_DESCRIPTION
	local uptime=$(cut -d ' ' -f 1 </proc/uptime)
	local loadavg=$(cat /proc/loadavg)

	local format=""
	local LOGSTRING=""
	if [[ $NODE_ENV == "development" ]]; then
		if [[ $type != "INFO" ]]; then
			format='{
	"timestamp": "%s",
	"type": "%s",
	"message": "%s",
	"h": "%s",
	"r": "%s",
	"u": "%s",
	"l": "%s"
}'
			LOGSTRING=$( printf "$format" "$timestamp" "$type" "$message" "$hostname" "$desc" "$uptime" "$loadavg")
		else
			format='{
	"timestamp": "%s",
	"type": "%s",
	"message": "%s"
}'
			LOGSTRING=$( printf "$format" "$timestamp" "$type" "$message" )
		fi
	else
		if [[ $type != "INFO" ]]; then
			format='{"timestamp":"%s","type":"%s","message":"%s","h":"%s","r":"%s","u":"%s","l":"%s"}'
			LOGSTRING=$( printf "$format" "$timestamp" "$type" "$message" "$hostname" "$desc" "$uptime" "$loadavg")
		else
			format='{"timestamp":"%s","type":"%s","message":"%s"}'
			LOGSTRING=$( printf "$format" "$timestamp" "$type" "$message" )
		fi
	fi

	echo "$LOGSTRING"

}
