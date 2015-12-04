class consul (
  $bootstrap          = false,
  $configuration_root = '/etc/consul.d',
  $download_file      = '0.5.2_linux_amd64.zip',
  $download_source    = 'https://dl.bintray.com/mitchellh/consul',
  $encrypt_string     = 'CHANGE_ME',
  $server             = false,
  $start_join         = [""],
) {

  include ::consul::install

  if ( $server ) { include ::consul::server }

  include ::firewall

  firewall { '100 Accept inbound Consul serf_lan TCP':
    proto  => 'tcp',
    dport  => '8301',
    action => 'accept',
  }

  firewall { '100 Accept inbound Consul serf_lan UDP':
    proto  => 'udp',
    dport  => '8301',
    action => 'accept',
  }

  firewall { '100 Accept outbound Consul serf_lan TCP':
    chain    => 'OUTPUT',
    proto    => 'tcp',
    dport    => '8301',
    action   => 'accept',
  }

  firewall { '100 Accept outbound Consul serf_lan UDP':
    chain    => 'OUTPUT',
    proto    => 'udp',
    dport    => '8301',
    action   => 'accept',
  }

  group { 'consul':
    ensure => present,
  } ->
  user { 'consul':
    ensure => present,
    groups => ['consul'],
  }

  file { $configuration_root:
    ensure => directory,
  } ->
  file { "${configuration_root}/client":
    ensure  => directory,
  }
  file { "${configuration_root}/checks":
    ensure  => directory,
  }

  file { "${configuration_root}/client/client.json":
    content => template("${module_name}/client/client.json.erb"),
    require => File["${configuration_root}/client"],
  }

  file { "${configuration_root}/client/http_check.json":
    content => template("${module_name}/client/http_check.json.erb"),
    require => File["${configuration_root}/client"],
  }

  file { '/var/consul':
    ensure  => directory,
    owner   => 'consul',
    group   => 'consul',
    require => File[$configuration_root],
  }

  unless ( $server ) {
    file { "${configuration_root}/checks/webserver":
      source  => "puppet:///modules/${module_name}/client/webserver",
      require => File["${configuration_root}/checks"],
    }
  }

  if ( $::osfamily == 'RedHat' ) {
    if ( $::operatingsystemmajrelease >= 7 ) {
      $service_file = '/usr/lib/systemd/system/consul.service'
      $service_file_source = 'systemd.erb'
      $service_file_mode = '0755'
    }
    else {
      $service_file = '/etc/init.d/consul'
      $service_file_source = 'init.erb'
      $service_file_mode = '0755'
    }
  }
  if ( $::osfamily == 'Debian' ) {
    $service_file = '/etc/init/consul.conf'
    $service_file_source = 'upstart.erb'
    $service_file_mode = '0644'
 
   file { '/etc/init.d/consul':
      ensure  => link,
      target  => '/lib/init/upstart-job',
      require => File[$service_file],
    }

    file { '/var/log/consul.log':
      before => Service['consul'],
    }
  }

  file { $service_file:
    mode    => $service_file_mode,
    content => template("${module_name}/service/${service_file_source}"),
    require => File['/usr/bin/consul'],
    notify  => Service['consul'],
  }

  service { 'consul':
    ensure => running,
    enable => true,
  }

}