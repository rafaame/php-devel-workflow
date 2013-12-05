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
confirm "This script works for Debian 7 and is going to install Apache2 and PHP 5 (from Dotdeb.org) in this system. The Apache and PHP integration will be made fcgid and suEXEC. Are you sure? "
if [ $? != 0 ]
then

    echo "Adding Dotdeb.org to your /etc/apt/sources.list"
    echo "deb http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list
    echo "deb-src http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list
    echo "deb http://packages.dotdeb.org wheezy-php55 all" >> /etc/apt/sources.list
    echo "deb-src http://packages.dotdeb.org wheezy-php55 all" >> /etc/apt/sources.list
    wget http://www.dotdeb.org/dotdeb.gpg
    cat dotdeb.gpg | sudo apt-key add -

    echo "Updating..."
    apt-get update

    echo "Installing Apache2"
    apt-get install apache2 apache2-mpm-worker

    echo "Installing PHP 5.5 with fcgid and suEXEC"
    apt-get install php5-cli php5-cgi php5-curl php5-gd libapache2-mod-fcgid apache2-suexec-custom

    echo "Cleaning /var/www/"
    rm -rf /var/www/*

    echo "Enabling Apache2 mod_rewrite, mod_actions, mod_fcgid and mod_suexec"
    a2enmod rewrite actions fcgid suexec

    echo "Creating fcgid configuration file"
    pwd
    cp server-setup/apache2-fcgid /etc/apache2/conf.d/fcgid

    echo "Disabling default Apache2 virtual host"
    a2dissite default

    service apache2 restart

    echo "Your server is ready!"

fi
