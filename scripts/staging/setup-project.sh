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
echo -n "What kind of project would you like to create? (basic | angularjs): "
read ptype

vhost_config="apache2-conf-$ptype"
vhost_skel="vhost-skel-$ptype"
vhost_githooks="git-hooks-$ptype"

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
    sub(/SERVERALIAS/,\"www.$hostname\");
    sub(/DOCROOT/, \"$vhostdir/$hostname\");
    sub(/USER/, \"$vhostuser $vhostuser\");
    print
}"

cat "$vhost_config/virtual-host" | awk "$awk_args" > "$available/$hostname"
grep $hostname /etc/hosts
if [ $? -eq 0 ]
then
    echo "Host may be already set. Ignoring..."
else
    if [ "$port" != "80" ]
    then
        #FIXME: check if angularjs and add all hosts
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
    cp -R "$vhost_skel"/* $vhostdir/$hostname/

    awk_args="{
        sub(/_SESSION_DIR/,\"$vhostdir/$hostname/tmp\");
        print
    }"

    cat "$vhost_skel"/fcgi-bin/php.ini | awk "$awk_args" > $vhostdir/$hostname/fcgi-bin/php.ini

    chown -R $vhostuser:$vhostuser $vhostdir/$hostname/

    echo "Your virtual host directory structure is ready!"

    confirm "Setup git repository for deployment? (Y/n)"
    if [ $? != 0 ]
    then

        case "$ptype" in

            basic) 
            
                git init --bare $vhostdir/$hostname/repository.git

                echo -n "Please enter the API database update command that will be executed after an API deploy (Zend:'php httpdocs/index.php orm:schema-tool:update --force'; Laravel: 'php artisan doctrine:schema:update'): "
                read api_database_update_command

                if [ -z "$api_database_update_command" ]
                then
                    api_database_update_command="echo -n \\\"No database update command provided. Skipping.\\\""
                fi

                echo -n "Provide the directory (relative to /var/www/example.com/) that the files will be copied from the repository (httpdocs): "
                read deploydir

                if [ -z "$deploydir" ]
                then
                    deploydir="httpdocs"
                fi

                awk_args="{
                    sub(/_APPLICATION_DIR/,\"$deploydir\");
                    sub(/_CHOWN/,\"$vhostuser:$vhostuser\");
                    sub(/_DATABASE_UPDATE_COMMAND/, \"$api_database_update_command\");
                    print
                }"

                cat "$vhost_githooks"/post-receive | awk "$awk_args" > $vhostdir/$hostname/repository.git/hooks/post-receive

                chmod +x $vhostdir/$hostname/repository.git/hooks/post-receive

                ;;

            angularjs)

                git init --bare $vhostdir/$hostname/app/repository.git
                git init --bare $vhostdir/$hostname/admin/repository.git
                git init --bare $vhostdir/$hostname/api/repository.git
                git init --bare $vhostdir/$hostname/common/repository.git

                echo -n "Please enter the API database update command that will be executed after an API deploy (Zend:'php httpdocs/index.php orm:schema-tool:update --force'; Laravel: 'php artisan doctrine:schema:update'): "
                read api_database_update_command

                if [ -z "$api_database_update_command" ]
                then
                    api_database_update_command="echo -n \\\"No database update command provided. Skipping.\\\""
                fi

                deploydir="."

                awk_args="{
                    sub(/_APPLICATION_DIR/,\"$deploydir\");
                    sub(/_CHOWN/,\"$vhostuser:$vhostuser\");
                    sub(/_DATABASE_UPDATE_COMMAND/, \"$api_database_update_command\");
                    print
                }"

                cat "$vhost_githooks"/post-receive-angularjs | awk "$awk_args" > $vhostdir/$hostname/app/repository.git/hooks/post-receive
                cat "$vhost_githooks"/post-receive-angularjs | awk "$awk_args" > $vhostdir/$hostname/admin/repository.git/hooks/post-receive
                cat "$vhost_githooks"/post-receive-api | awk "$awk_args" > $vhostdir/$hostname/api/repository.git/hooks/post-receive
                cat "$vhost_githooks"/post-receive-common | awk "$awk_args" > $vhostdir/$hostname/common/repository.git/hooks/post-receive

                chmod +x $vhostdir/$hostname/app/repository.git/hooks/post-receive
                chmod +x $vhostdir/$hostname/admin/repository.git/hooks/post-receive
                chmod +x $vhostdir/$hostname/api/repository.git/hooks/post-receive
                chmod +x $vhostdir/$hostname/common/repository.git/hooks/post-receive

                ;;

            *)

                echo -n "Wrong project type choosen."

                ;;

        esac

    fi

fi

echo "Setting up permissions..."
chown -R $vhostuser:$vhostuser $vhostdir/$hostname
chmod +x $vhostdir/$hostname/fcgi-bin/php5-fcgi

a2ensite "$hostname"
echo "Reloading apache2..."
/etc/init.d/apache2 reload

echo "Your project was created!"