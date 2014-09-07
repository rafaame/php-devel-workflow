#PHP Development Workflow
##Um workflow para desenvolver, testar e instalar aplicações PHP.

Este é o meu workflow para desenvolver, testar e instalar aplicações PHP. Ele consiste em subir 3 servidores diferentes: o servidor de desenvolvimento, o servidor de staging e o servidor de produção.

##O Workflow

O workflow consiste em desenvolver a aplicação na sua máquina e no **servidor de desenvolvimento**. Quando uma nova versão ou uma funcionalidade a qual você queira subir para a produção estiver pronta você deve subi-la ao **servidor de staging** (através de um commit ao repositório de staging - haverá um hook do git o qual tratará isso). Após ela ser testada e estiver rodando no **servidor de staging** você pode enviá-la ao servidor de produção sem (ou com um mínimo) downtime (através de um commit ao repositório de produção - haverá um hook do git o qual tratará isso).

##Os scripts

Os scripts para subir os servidores e também os projetos estão separatos em /scripts/dev (para o **servidor de desenvolvimento**), /scripts/staging/ (for **staging server**) and /scripts/prod/ (for **production server**).

O script setup-server.sh serve para instalar os pacotes necessários em um servidor **limpo**. O script setup-project.sh serve para criar um novo projeto no servidor (i.e. criar um novo virtual host com as configurações necessárias).

OBS: estamos considerando Debian 7 para os servidores

##O servidor de desenvolvimento

Este será onde você irá frequentemente testar e ver se o seu código funciona. É, no meu caso, uma máquina virtual dentro do meu computador, mas pode estar em qualquer lugar

This will be where you will be frequently testing to see if your code works. It is, in my case, a virtual machine inside my own PC, but it could be anywhere as long as you keep the latency very low because ou should maintain your development code synchronized with this server.

If you use NetBeans you may setup its remote synchronization feature to keep all files sync between your machine and the development server. Also, if you use Sublime Text 3 you could use SFTP package to upload the files for the first time and then upload each file as it is saved during the development.

###The Setup

The setup-server.sh script will install Apache2 and PHP (with mod_php) and should be used in a clean Debian 7 install. This script will not install a database purposely, you should install the necessary databases to your PHP application.

OBS: you may omit this step if you want to use other distros or to setup the server yourself. But keep in mind that you should install Apache2 with PHP using mod_php, because the setup-project.sh script will create the virtual host configuration file based on this.

###Creating a Project

The setup-project.sh script will create the virtual host of the project, including the virtual host configuration file (in /etc/apache2/sites-available/) and the directory structure in /var/www/.

OBS: an important thing to note is that in the case of this server being a virtual machine in your PC, it is a really bad idea to use the sharing directory features (either from VMWare or Parallels) if you are developing an application with, say, Zend Framework, that reads/writes to a lot of files in each request (i.e. for caching in the disk).

##The Staging Server

This will be a server to deploy and test functionalities and features before deploying it to **production server**. In my case, it is a virtual machine in a public cloud, so I can show my customers how the project is going. There is no necessity of low latency in this case.

The deployment to this server will be made by commiting to a bare git repository created for each project during its setup.

###The Setup

The setup-server.sh script will install Apache2 and PHP (using fcgid and suEXEC) and should be used in a clean Debian 7 install. Also, a databse won't be installed purposely.

OBS: if you are going to use other distro rather than Debian 7, edit the setup-server.sh script and make the necessary changes, otherwise the setup-project.sh script may not work properly.

###Creating a Project

The setup-project.sh script will create a virtual host of the project, including the virtual host configuration file (in /etc/apache2/sites-available) and the directory structure, including the fcgid wrapper, in /var/www/.

The script will create a bare git repository in /var/www/example.com/repository.git/. This repository has a git hook (post-receive) so that when you push changes to this repository, this hook will be executed and will automatically deploy the files to the correct directory (usually /var/www/example.com/httpdocs/, but it can be changed during the project creation).

###Deploying to Staging

In order to deploy to the staging server you should be able to push changes into the project git repository that was created by the setup-project.sh script. To do this you need to add a remote to the local git repository of your project:

    $ git remote add staging ssh://user@staging.server.host/var/www/example.com/repository.git

And push changes to it:

    $ git push staging master

During the git push command output you should see:

    $ === Deploying application to staging server ===
    $ === Done ===