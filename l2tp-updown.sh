#!/bin/vbash
#
# Start/stop dnsmasq instance for responding to VPN client DHCPINFORM requests
#
# Copyright (c) 2016 Andrew Heberle
#
# Permission is hereby granted, free of charge, to any person obtaining a 
# copy of this software and associated documentation files (the "Software"), 
# to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, 
# and/or sell copies of the Software, and to permit persons to whom the 
# Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

## This script is called with the following arguments:
#    Arg  Name                          Example
#    $1   Interface name                l2tp0
#    $2   The tty                       ttyS1
#    $3   The link speed                38400
#    $4   Local IP number               12.34.56.78
#    $5   Peer  IP number               12.34.56.99
#    $6   Optional ``ipparam'' value    foo

## Load config file
#
config="/config/scripts/l2tp-updown.conf"
if [ -f ${config} ]; then
	. ${config}
else
	echo "Error: Config (${config}) not found."
	exit 1
fi

#
## There should be no need to change anything beyond this line
#

# Some functions we use later on to start/stop dnsmasq
start-dnsmasq() {
	/usr/sbin/dnsmasq ${dnsmasqopts} \
	--pid-file="${pidfile}" \
	--interface=${interface} \
	${dhcprange} ${dhcpoptions} ${dhcprfcroutes} ${dhcpwinroutes}
}

stop-dnsmasq() {
	if [ -f "${pidfile}" ]; then
		kill $(cat "${pidfile}")
	else
		echo "PID file (${pidfile}) for dnsmasq not found"
	fi
}

atexit() {
		# If we are in a session then tear it down at exit of script
		cli-shell-api inSession
		if [ $? -eq 0 ]; then
			cli-shell-api teardownSession
		fi
}
trap atexit EXIT

get-l2tp-dns-servers() {
	# Outputs dnsmasq config option for DNS servers based on current config

	# Initiate a CLI API session
	session_env=$(cli-shell-api getSessionEnv $PPID)
	if [ $? -ne 0 ]; then
		# Problem with getSessionEnv call
		return 1
	fi
	eval $session_env

	# Setup session
	cli-shell-api setupSession
	if [ $? -ne 0 ]; then
		# Problem with setupSession call
		return 1
	fi
	
	# Check we are in a CLI session
	cli-shell-api inSession
	if [ $? -ne 0 ]; then
			# No valid session
	        return 1
	fi

	# Grab list of nodes under vpn "l2tp remote-access dns-servers" 
	node_list=$(cli-shell-api listNodes vpn l2tp remote-access dns-servers)
	eval "NODES=($node_list)"
	n=0
	# Loop through nodes and print values comma seperated
	for i in "${NODES[@]}"; do
		# Get current node
		server=$(cli-shell-api returnValue vpn l2tp remote-access dns-servers $i)
		# Check call was successful
		if [ $? -eq 0 ]; then
			# First item includes relevan dnsmasq config option
			if [ ${n} -eq 0 ]; then
				echo -n "--dhcp-option=6"
			fi
			# Print value
			echo -n ",${server}"
		fi
		n=$((n + 1))
	done

	# Tear down API session
	cli-shell-api teardownSession

	# Return a good status
	return 0
}

# Set delay while waiting for DHCPINFORM
delay=15

# Check how we were called
name=$(basename $0)
case "${name}" in
	l2tp-up)
		action="up"
		;;
	l2tp-down)
		action="down"
		;;
	*)
    	echo "Must be called as either: l2tp-up or l2tp-down"
		exit 1
		;;
esac

# Check we got required arguments (5 or 6 arguments)
if [ $# -ne 5 ] && [ $# -ne 6 ]; then
	echo "Usage: $0 interface tty speed localip peerip <ipparam>"
	exit 1
fi

# Grab supplied arguments we are interested in
interface=$1
localip=$4
peerip=$5

# Make sure we only do stuff for l2tp* interfaces
case "${interface}" in
        l2tp*)
                echo "L2TP interface matched: ${interface}"
                ;;
        *)
                echo "Not L2TP interface: ${interface}"
                exit 0
                ;;
esac

# Set options for DNSMASQ
dnsmasqopts="--user=dnsmasq --port=0 --bind-interfaces —-conf-file=/dev/null"
# DHCP range is just VPN peer
dhcprange="--dhcp-range=${peerip},${peerip},255.255.255.255"
# Set name server
nsoption=$(get-l2tp-dns-servers)
if [ $? -eq 0 ]; then
	dhcpoptions="${nsoption}"
else
	dhcpoptions=""
fi
# PID file
pidfile="/var/run/dnsmasq/dnsmasq-${interface}.pid"

# Start with blank list of routes
dhcprfcroutes=""
dhcpwinroutes=""

# Go through list of remotenetworks and append correct DHCP options
for n in ${remotenetworks}; do
        dhcprfcroutes="${dhcprfcroutes} --dhcp-option=121,${n},${localip}"
        dhcpwinroutes="${dhcpwinroutes} --dhcp-option=249,${n},${localip}"
done

# Run "up" or "down" process as requested
case "${action}" in
        up)
				# Start dnsmasq
                echo "Performing up tasks for ${interface}..."
                start-dnsmasq
                sleep ${delay}
                stop-dnsmasq
                ;;
        down)
				# Kill dnsmasq if it's still running (it really shouldn't be)
                echo "Performing down tasks for ${interface}..."
                stop-dnsmasq
                ;;
esac

# Exit with good status regardless of exit status of other commands
exit 0
