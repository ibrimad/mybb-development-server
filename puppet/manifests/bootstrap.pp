include augeasproviders
include sysctl

# defaults
Exec        { path => '/usr/sbin:/sbin:/bin:/usr/bin' }
Sshd_config { notify => Service[ 'sshd' ] }
User        { managehome => true }

package { "yum-utils":
    ensure => "installed",
}

exec { "Install epel rpm":
  command => "bash -c 'cd /tmp/; wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm; rpm -ivh epel-release-6-8.noarch.rpm;'",
  unless => "ls /tmp/epel-release-6-8.noarch.rpm",
}

exec { "Install remi rpm":
  command => "bash -c 'cd /tmp/; wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm; rpm -ivh remi-release-6.rpm; yum-config-manager --enable remi;'",
  unless => "ls /tmp/remi-release-6.rpm",
  require => Exec['Install epel rpm'],
}

$packages = [ 'httpd', 'mysql-server', 'mysql', 'php', 'php-mysqlnd', 'php-devel', 'php-pear', 'php-xml', 'php-pecl-memcached', 'php-mbstring', 'php-gd', 'git', 'memcached', 'php-pecl-apc', 'siege', 'strace', 'graphviz', 'vim-enhanced', 'postgresql', 'php-pgsql' ]

package { $packages:
    ensure => installed,
    require => Exec['Install remi rpm'],
}

file { '/etc/profile.d/aliases.sh':
    owner  => 'root', group => 'root', mode => '0644',
    source => 'puppet:///modules/configs/aliases.sh',
    tag    => 'setup',
}

file { '/var/www/html/index.html':
    owner  => 'apache', group => 'apache', mode => '0644',
    source => 'puppet:///modules/configs/default.html',
    tag    => 'setup',
}

file { '/etc/my.cnf':
    owner  => 'root', group => 'root', mode => '0644',
    source => 'puppet:///modules/configs/my.cnf',
    tag    => 'setup',
}

file { '/etc/rc.local':
    owner  => 'root', group => 'root', mode => '0644',
    source => 'puppet:///modules/configs/rc.local',
    tag    => 'setup',
}

service { 'iptables':
    ensure => 'stopped',
    enable => 'true',
}

service { 'sshd':
    ensure => 'running',
    enable => 'true',
}

service { 'httpd':
    ensure  => 'running',
    enable  => true,
    require => Package[ [ 'httpd', 'php' ] ],
}

service { 'mysqld':
    ensure  => 'running',
    enable  => true,
    require => [ Package[ [ 'mysql-server', 'mysql' ] ], File["/etc/my.cnf"] ],
}

# sshd config
#
sshd_config { 'LoginGraceTime':
    value  => '30s',
}

sshd_config { 'AllowTcpForwarding':
    value => 'yes',
}

sshd_config { 'PermitRootLogin':
    value  => 'yes',
}

sshd_config { 'AllowUsers':
    value  => [ 'root', 'vagrant' ],
}

sshd_config { 'MaxAuthTries':
    value  => '3',
}

sshd_config { 'PasswordAuthentication':
    value  => 'yes',
}

# Setup sudo
file { 'sudo_wheel':
    tag     => 'setup',
    path    => '/etc/sudoers.d/99_wheel',
    owner   => 'root', group => 'root', mode => '0440',
    content => "%wheel ALL = (ALL) ALL\n",
}

augeas { 'sudo_include_dir':
    tag     => 'setup',
    context => '/files/etc/sudoers',
    changes => 'set #includedir "/etc/sudoers.d"',
}

# make 'service httpd ...' work properly
file { '/etc/sysconfig/httpd':
    owner   => 'root', group => 'root', mode => '0644',
    content => "PIDFILE=/var/run/httpd/httpd.pid\nDAEMON_COREFILE_LIMIT=unlimited\n",
    require => Package[ "httpd" ],
}

file { '/etc/motd':
    content => "\nWelcome to the MyBB Development Server! \n\nHappy Hacking!\n\n"
}

file { '/setup.sh':
    owner   => 'root', group => 'root', mode => '0755',
    content => "#!/bin/bash\n\nsudo chown -Rv vagrant:vagrant /var/www\ncd /var/www/html\ngit clone --branch=stable git@github.com:mybb/mybb.git stable\ngit clone --branch=feature git@github.com:mybb/mybb.git feature\ncd /var/www/html/stable
cat > .gitignore << EOF
.DS_Store?
.DS_Store
*.sw?
*~
ehthumbs.db
Icon?
Thumbs.db
.gitignore
install/lock
inc/config.php
cache/
uploads/
admin/backups/
EOF
git update-index --assume-unchanged inc/config.default.php inc/settings.php\ncd /var/www/html/feature\n
cat > .gitignore << EOF
.DS_Store?
.DS_Store
*.sw?
*~
ehthumbs.db
Icon?
Thumbs.db
.gitignore
install/lock
inc/config.php
cache/
uploads/
admin/backups/
EOF
git update-index --assume-unchanged inc/config.default.php inc/settings.php\nsudo chown -Rv apache:apache /var/www"
}

exec { "Install xhprof":
  unless => "ls /tmp/xhprof/",
  command => "bash -c 'cd /tmp; git clone https://github.com/facebook/xhprof xhprof; cd xhprof/extension; phpize && ./configure && make && make install'",
  require => Package[ "php" ],
}

exec { "Link Xhprof":
  unless => "ls /etc/php.d/xhprof.ini",
  command => "bash -c 'cd /etc/php.d/; echo extension=xhprof.so > xhprof.ini'",
  require => Package[ "php" ],
}

exec { "Install xhprof gui":
  unless => "ls /tmp/xhprof.io/",
  command => "bash -c 'mkdir /var/www/html/xhprof/; cd /tmp; git clone https://github.com/gajus/xhprof.io xhprof.io; cp -r xhprof.io/* /var/www/html/xhprof/; cd /var/www/html/xhprof/; wget http://pastebin.com/raw.php?i=qj0jdGKH -O config.php; mv config.php xhprof/includes/config.inc.php'",
  require => Package[ "php" ],
}

exec { "date.timezone":
  unless => "ls /etc/php.d/timezone.ini",
  command => "bash -c 'cd /etc/php.d/; echo date.timezone=Europe/London > timezone.ini'",
  require => Package[ "php" ],
}

# Lazy c+p, use file.

exec { "PHP append/prepend":
  unless => "ls /etc/php.d/php_append_prepend.ini",
  command => "bash -c 'cd /etc/php.d/; echo \"auto_prepend_file = /var/www/html/xhprof/inc/prepend.php\" >> php_append_prepend.ini; echo \"auto_append_file = /var/www/html/xhprof/inc/append.php\" >> php_append_prepend.ini'",
  require => Package[ "php" ],
}

exec { "Link APC":
  unless => "ls /etc/php.d/apc.ini",
  command => "bash -c 'cd /etc/php.d/; echo extension=apc.so > apc.ini'",
  require => Package[ "php-pecl-apc" ],
}

exec { "Copy apc.php":
  unless => "ls /var/www/html/apc.php",
  command => "bash -c 'cp /usr/share/doc/php-pecl-apc-*/apc.php /var/www/html/apc.php'",
  require => Package[ "php-pecl-apc" ],
}

exec { "createdbxhprof":
  unless => ["mysql -uroot xhprof || mysql -uroot -pvagrant xhprof"],
  command => "mysql -uroot -e \"create database if not exists xhprof;\" && mysql -uroot xhprof < /var/www/html/xhprof/setup/database.sql",
  require => [ Service["mysqld"], Exec["Install xhprof gui"] ],
}

exec { "Create MySQL database: mybb_stable":
  unless => ["mysql -uroot mybb_stable || mysql -uroot -pvagrant mybb_stable"],
  command => "mysql -uroot -e \"create database mybb_stable;\"",
  require => Service["mysqld"],
}

exec { "Create MySQL database: mybb_feature":
  unless => ["mysql -uroot mybb_feature || mysql -uroot -pvagrant mybb_feature"],
  command => "mysql -uroot -e \"create database if not exists mybb_feature;\"",
  require => Service["mysqld"],
}

exec { "Set MySQL server root password":
  unless => "mysqladmin -uroot -pvagrant status",
  command => "mysqladmin -uroot password vagrant",
  require => [ Service["mysqld"], Exec["createdbxhprof"] ],
}
