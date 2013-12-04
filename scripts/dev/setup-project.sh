#!/bin/bash

if [ `id -u` -ne 0 ]
then
    echo "You must run this script as root"
    exit 0
fi

confirm() 
{

    pass=0

    echo -n "$1 "
    read testt

    if [ ""$testt != 'n' ]
    then
        pass=1
    fi

    return $pass

}

#Set the script directory as the workdir
cd $(cd -P -- "$(dirname -- "$0")" && pwd -P)

# Deploy the VirtualHost on apache
confirm "Configure the apache virtual host now? (Y/n) "
if [ $? != 0 ]
then
    echo -n "Provide a hostname for the project (will be used as ServerName and ServerAlias): "
    read hostname

    echo -n "Provide a port to listen in apache (default 80): "
    read port
    if [ -z "$port" ]
    then
        port=80
    fi

    echo -n "Provide virtual hosts directory (/var/www): "
    read vhostdir
    if [ -z "$vhostdir" ]
    then
        vhostdir="/var/www"
    fi

    echo -n "Provide the apache sites-available directory (default /etc/apache2/sites-available): "
    read available
    if [ -z "$available" ]
    then
        available="/etc/apache2/sites-available"
    fi

    awk_args="{
        sub(/PORT/,\"$port\");
        sub(/SERVERNAME/,\"$hostname\");
        sub(/SERVERALIAS/,\"$hostname\");
        sub(/DOCROOT/, \"$vhostdir/$hostname\");
        print
    }"

    cat apache2-conf/virtual-host | awk "$awk_args" > "$available/$hostname"
    grep $hostname /etc/hosts
    if [ $? -eq 0 ]
    then
        echo "Host may be already set. Ignoring..."
    else
        if [ "$port" != "80" ]
        then
            echo "127.0.0.1:$port $hostname" >> /etc/hosts
        else
            echo "127.0.0.1 $hostname" >> /etc/hosts
        fi
    fi

    #Create vhost directory structure
    confirm "Create virtual host directory structure? (Y/n)"
    if [ $? != 0 ]
    then

        mkdir -p $vhostdir/$hostname/
        cp -R vhost-skel/* $vhostdir/$hostname/

    #BAD IDEA
	#confirm "Is your virtual host httpdocs directory going to be a symlink to a shared filesystem? (Y/n)"
	#if [ $? != 0 ]
	#then

	#	echo -n "Provide the full path to the directory that your httpdocs will link to: "
    #	read httpdocssymlink

	#	rm -rf $vhostdir/$hostname/httpdocs
	#	ln -s $httpdocssymlink $vhostdir/$hostname/httpdocs

	#fi

        echo "Your virtual host directory structure is ready! "

    fi

    echo "Setting up permissions..."
    echo -n "Provide the user that will own the project directory (www-data): "
    read user
    chown -R $user:$user $vhostdir/$hostname

    a2ensite "$hostname"
    echo "Reloading apache2..."
    /etc/init.d/apache2 reload

    echo "Your virtual host was created!"

fi
