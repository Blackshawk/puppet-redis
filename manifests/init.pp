# == Class: redis-server
#
# Install and configure redis-server.
#
# === Examples
#
# include redis-server
#
# === Authors
#
# Thomas Van Doren
#
# === Copyright
#
# Copyright 2012 Thomas Van Doren, unless otherwise noted.
#
class redis-server (
  $redis_src_dir = '/opt/redis-src',
  $redis_bin_dir = '/opt/redis-server',
  $redis_max_memory = '4gb',
  $redis_max_clients = 0,           # 0 = unlimited
  $redis_timeout = 300,         # 0 = disabled
  $redis_loglevel = 'notice',
  $redis_databases = 16,
  $redis_slowlog_log_slower_than = 10000, # microseconds
  $redis_slowlog_max_len = 1024
  ) {
  $redis_pkg = "${redis_src_dir}/redis-2.4.13.tar.gz"

  File {
    owner => root,
    group => root,
  }
  file { $redis_src_dir:
    ensure => directory,
  }
  file { '/etc/redis':
    ensure => directory,
  }
  file { 'redis-lib':
    ensure => directory,
    path   => '/var/lib/redis',
  }
  file { 'redis-lib-port':
    ensure => directory,
    path   => '/var/lib/redis/6379',
  }
  file { 'redis-pkg':
    ensure => present,
    path   => "${redis_pkg}",
    mode   => 0644,
    source => 'puppet:///modules/redis-server/redis-2.4.13.tar.gz',
  }
  file { 'redis-init':
    ensure => present,
    path   => '/etc/init.d/redis_6379',
    mode   => 0755,
    source => 'puppet:///modules/redis-server/redis.init',
  }
  file { '6379.conf':
    ensure => present,
    path   => '/etc/redis/6379.conf',
    mode   => 0644,
    content => template('redis-server/6379.conf.erb'),
  }
  file { 'redis.conf':
    ensure => present,
    path   => '/etc/redis/redis.conf',
    mode   => 0644,
    source => 'puppet:///modules/redis-server/redis.conf',
  }
  file { 'redis-cli-link':
    ensure => link,
    path   => '/usr/local/bin/redis-cli',
    target => "${redis_bin_dir}/bin/redis-cli",
  }
  package { 'build-essential':
    ensure => present,
  }
  exec { 'unpack-redis':
    command => "tar --strip-components 1 -xzf ${redis_pkg}",
    cwd     => "${redis_src_dir}",
    path    => '/bin:/usr/bin',
    unless  => "test -f ${redis_src_dir}/Makefile",
    require => File['redis-pkg'],
  }
  exec { 'install-redis':
    command => "make && make install PREFIX=${redis_bin_dir}",
    cwd     => "${redis_src_dir}",
    path    => '/bin:/usr/bin',
    unless  => "test $(${redis_bin_dir}/bin/redis-server --version | cut -d ' ' -f 1) = 'Redis'",
    require => [ Exec['unpack-redis'],
                 Package['build-essential'],
                 ],
  }
  service { 'redis-server':
    name      => 'redis_6379',
    ensure    => running,
    enable    => true,
    require   => [ File['6379.conf'],
                   File['redis.conf'],
                   File['redis-init'],
                   File['redis-lib-port'],
                   Exec['install-redis'],
                   ],
    subscribe => File['6379.conf'],
  }
}
