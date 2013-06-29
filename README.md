MyBB Development Server
=======================

What
------------

MyBB Development Server (MDS) is a development server designed for [MyBB](https://www.mybb.com/). Simply, it's a Vagrantfile combined with Puppet allowing you to spin up a server ready for use with MyBB.

Who
------------

Nathan is a developer for the MyBB Group and decided to find ways to make developing MyBB easier and more efficient.

Requirements
------------

 * Linux workstation.
 * Or Windows. Kidding. I don't use Windows. [Get Linux](http://lifehacker.com/5778882/getting-started-with-linux-the-complete-guide) and achieve enlightenment.
 * [ViirtualBox](https://www.virtualbox.org/).
 * [Vagrant](http://vagrantup.com/).

Technical
------------

OS: Centos 6.4 64bit

Webserver: Apache 2

Database Server: MySQL 5.5.32/PostgreSQL 8.4.13

PHP Version: 5.4.16

Box provided by developer.nrel.gov.

Latest packages are from remi/epel.

Profiling: XHProf + XHProf.io. Located at /xhprof/, automatically loaded. siege + strace available.

Cache: APC (Stats at /apc.php), memcached. Both PHP extensions are installed.

Firewall: iptables disabled. No need for it.

IP Address: 33.33.33.33

See /puppet/manifests/bootstrap.pp for more.


Usage
------------

    nathan@local$ git clone https://github.com/nmalcolm/mybb-development-server.git
    nathan@local$ cd mybb-development-server
    nathan@local$ ./setup.sh # Halt the server if running, throw it back up, copy local .gitconfig to the server. 
    nathan@local$ # make cup-of-tea
    nathan@local$ curl -I 'http://33.33.33.33/' # Make sure the server is actually running.
    nathan@local$ vagrant ssh

Follow https://help.github.com/articles/generating-ssh-keys; xclip won't work here though.

    vagrant@mybb-dev-server$ /setup.sh # Fetch stable and feature.
    
That's it! stable is located at `/var/www/html/stable/` and feature is located at `/var/www/html/feature/`

Notice
------------

This is likely unstable, and incomplete. More software will be added and changes will be made.
