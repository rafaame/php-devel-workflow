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

# Deploy the VirtualHost on apache
confirm "This script works for Debian 7 and is going to install a Apache2 and PHP 5 (from Dotdeb.org) in this system. The Apache and PHP integration will be made with mod_php (non-threaded). Are you sure? "
if [ $? != 0 ]
then

    cd ~

    echo "Adding Dotdeb.org to your /etc/apt/sources.list"
    echo "deb http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list
    echo "deb-src http://packages.dotdeb.org wheezy all" >> /etc/apt/sources.list
    echo "deb http://packages.dotdeb.org wheezy-php55 all" >> /etc/apt/sources.list
    echo "deb-src http://packages.dotdeb.org wheezy-php55 all" >> /etc/apt/sources.list
    wget http://www.dotdeb.org/dotdeb.gpg
    cat dotdeb.gpg | apt-key add -

    echo "Updating..."
    apt-get update

    echo "Installing Apache2"
    apt-get install apache2 apache2-mpm-prefork

    echo "Installing PHP 5"
    apt-get install php5 php5-curl php5-gd libapache2-mod-php5

    echo "Cleaning /var/www/"
    rm -rf /var/www/*

    echo "Enabling Apache2 mod_rewrite and mod_php5"
    a2enmod rewrite php5

    echo "Disabling default Apache2 virtual host"
    a2dissite default

    service apache2 restart

    echo "Your server is ready!"

fi
