#PHP Development Workflow
##A workflow for developing, testing and deploying PHP applications.

This is my workflow for developing, testing and deploying PHP applications. It consists into setting up 3 different servers: the development server, the staging server and the production server.

##Changelog
- v0.0.1 - initial release including only the workflow for the development server.

##Versioning

Font Awesome will be maintained under the Semantic Versioning guidelines as much as possible. Releases will be numbered with the following format:

`<major>.<minor>.<patch>`

And constructed with the following guidelines:

* Breaking backward compatibility bumps the major (and resets the minor and patch)
* New additions, without breaking backward compatibility bumps the minor (and resets the patch)
* Bug fixes and misc changes bumps the patch

For more information on SemVer, please visit http://semver.org.

##Author
- Email: eu@rafaa.me
- GitHub: https://github.com/rafaame
- Website: http://rafaa.me

##The Workflow

The workflow consisting into developing the application in your machine and the **development server**. When a new version or a functionality that you want to send to production is ready, you should deploy it to the **staging server** (by commiting to the staging repository - there will be a git hook to handle this). After it is tested and running in the **staging server** you may deploy it to the production server with minimal or no downtime (by commiting to the production repository - there will also be a git hook to handle this).

##The scripts

The scripts to setup the servers and also the projects are separated into /scripts/dev/ (for the **development server**), /scripts/staging/ (for **staging server**) and /scripts/prod/ (for **production server**).

The setup-server.sh script is for installing the needed packages into a clean server. The setup-project.sh script is for setting up a new project into the server (i.e. create a new virtual host with needed config).

OBS: we are considering Debian 7 for the servers

##The Development Server

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