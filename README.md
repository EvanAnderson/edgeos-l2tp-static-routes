# edgeos-l2tp-static-routes #

## Description ##

Scripts used on up/down of a PPP connection to ensure a dnsmasq instance is running so classless static routes are distributed to the client.

## Details ##

This runs via an ip-up.d script to start an instance on dnsmasq that ONLY listens on the l2tp interface for the purposes of responding to DHCPINFORM requests from Windows clients.

This should also work correctly for Linux and MacOS clients as the config handles Windows specific (DHCP option 249) and RFC3442 (DHCP option 121) requests.

Once the interface is taken down, the script is executed via an ip-down.d script to kill the specific instance of dnsmasq.

## Requirements ##

This has been tested on a Ubiquiti ER/USG device with a L2TP remote access VPN configured. Windows 7 and Windows 10 clients have been tested.

## Installation Overview ##

1. Copy l2tp-updown.sh to /config/scripts
2. Copy l2tp-updown-install.sh to /config/scripts/post-config.d
3. Set correct ownership/permissions
4. Confgure "remotenetworks" in "l2tp-updown.conf" to match site needs
5. Run install script /config/scripts/post-config.d/l2tp-updown-install.sh

**Notes:** The "/config/scripts/post-config.d/l2tp-updown-install.sh" script will ensure the symlinks in "/etc/ppp/ip-{up,down}.d" are re-created on boot as this is non-persistent.

## Step By Step Instructions ##

### Download Main Script ###

> cd /config/scripts  
> sudo curl -o l2tp-updown.sh https://raw.githubusercontent.com/EvanAnderson/edgeos-l2tp-static-routes/master/l2tp-updown.sh  
> sudo chmod 755 l2tp-updown.sh  
> sudo chown root:vyattacfg l2tp-updown.sh  

### Grab Example config ###

> cd /config/scripts  
> sudo curl -o l2tp-updown.conf https://raw.githubusercontent.com/EvanAnderson/edgeos-l2tp-static-routes/master/l2tp-updown.conf.example  

### Download Install Script ###

> cd /config/scripts/post-config.d  
> sudo curl -o l2tp-updown-install.sh https://raw.githubusercontent.com/EvanAnderson/edgeos-l2tp-static-routes/master/l2tp-updown-install.sh  
> sudo chmod 755 l2tp-updown-install.sh  
> sudo chown root:vyattacfg l2tp-updown-install.sh  

### Edit Config ###

> sudo vi /config/scripts/l2tp-updown.conf

### Run Install Script ###

> sudo /config/scripts/post-config.d/l2tp-updown-install.sh


## Other Notes ##

This code is forked from Andrew Heberle's original code (https://gitlab.com/andrewheberle/edgeos-l2tp-static-routes) and incldues merge requests taken from Phil Ross (https://gitlab.com/philross/edgeos-l2tp-static-routes).

This started out of Andrew Heberle's desire to push static routes to clients connecting to his network over L2TP/IPSEC via a Ubiquiti Unifi Security Gateway (which runs Ubiquiti's EdgeOS based firmware). The only parts that are EdgeOS are the use of "/config/scripts" (to store presistent scripts) and the code in the "get-l2tp-dns-servers" function.

These sections could be easily removed/changed and used on any Linux based VPN gateway using pppd for a L2TP VPN.

The only external dependency for this is dnsmasq and pppd (as the script is assumed to be executed by PPPd on interface up/down).

**Important:** The scripts use "/bin/vbash" as their interpreter/shell which is the VyOS/Vyatta/EdgeOS version of Bash.  Change this to suit your environment.

## License ##

The MIT License (MIT)  
Copyright (c) 2016 Andrew Heberle