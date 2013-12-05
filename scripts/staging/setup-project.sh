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
echo -n "Provide a hostname for the project (will be used as ServerName and ServerAlias): "
read hostname

echo -n "Provide the user that will own the virtual host: "
read vhostuser
if ! id -u $vhostuser > /dev/null 2>&1; then
    echo "User $vhostuser doesn't exists. Creating..."
    adduser $vhostuser
fi

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
    sub(/USER/, \"$vhostuser $vhostuser\");
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

    chown -R $vhostuser:$vhostuser $vhostdir/$hostname/

    echo "Your virtual host directory structure is ready!"

    confirm "Setup git repository for deployment? (Y/n)"
    if [ $? != 0 ]
    then

        git init --bare $vhostdir/$hostname/repository.git

        echo -n "Provide the directory (relative to /var/www/example.com/) that the files will be copied from the repository (httpdocs): "
        read deploydir
        if [ -z "$deploydir" ]
        then
            deploydir="httpdocs"
        fi

        #echo -n "Provide the command that will be used to import the database on the post-receive git hook. It will be used as "\$command < .database_dump". Default: (mysql -u [user] -p[password] [database]): "
        #read importdbcommand
        #if [ -z "$importdbcommand" ]
        #then
        #    importdbcommand="mysql -u root -p dbtest"
        #fi

        awk_args="{
            sub(/_APPLICATION_DIR/,\"$deploydir\");
            sub(/_CHOWN/,\"$vhostuser:$vhostuser\");
            sub(/_IMPORT_DATABASE_COMMAND/,\"$importdbcommand\");
            print
        }"

        cat git-hooks/post-receive | awk "$awk_args" > $vhostdir/$hostname/repository.git/hooks/post-receive

        chmod 755 $vhostdir/$hostname/repository.git/hooks/post-receive

    fi

fi

echo "Setting up permissions..."
chown -R $vhostuser:$vhostuser $vhostdir/$hostname
chmod 755 $vhostdir/$hostname/fcgi-bin/php5-fcgi

a2ensite "$hostname"
echo "Reloading apache2..."
/etc/init.d/apache2 reload

echo "Your virtual host was created!"