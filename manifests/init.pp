class consul (
  $bootstrap          = false,
  $configuration_root = '/etc/consul.d',
  $download_file      = 'consul_0.6.0_linux_amd64.zip',
  $download_source    = 'https://releases.hashicorp.com/consul/0.6.0',
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
    mode    => '0755',
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
      mode    => '0755',
      require => File["${configuration_root}/checks"],
    }
  }

  if ( $::osfamily == 'RedHat' ) {
    if ( $::operatingsystemmajrelease >= 7 ) {
      $service_file = '/usr/lib/systemd/system/consul.service'
      $service_file_source = 'systemd.erb'
      $service_file_mode = '0755'
      $webserver_file = '/usr/lib/systemd/system/webserver.service'
    }
    else {
      $service_file = '/etc/init.d/consul'
      $service_file_source = 'init.erb'
      $service_file_mode = '0755'
      $webserver_file = '/etc/init.d/webserver'
    }
  }
  if ( $::osfamily == 'Debian' ) {
    $service_file = '/etc/init/consul.conf'
    $service_file_source = 'upstart.erb'
    $service_file_mode = '0644'
    $webserver_file = '/etc/init.d/webserver.conf'
 
   file { '/etc/init.d/consul':
      ensure  => link,
      target  => '/lib/init/upstart-job',
      require => File[$service_file],
    }

   file { '/etc/init.d/webserver':
      ensure  => link,
      target  => '/lib/init/upstart-job',
      require => File[$webserver_file],
    }

    file { '/var/log/consul.log':
      before => Service['consul'],
    }
  }

  file { $service_file:
    mode    => $service_file_mode,
    content => template("${module_name}/service/${service_file_source}"),
    notify  => Service['consul'],
  }

  file { $webserver_file:
    mode    => $service_file_mode,
    content => template("${module_name}/service/webserver/${service_file_source}"),
    notify  => Service['consul'],
  }

  service { 'webserver':
    ensure  => running,
    enable  => true,
    require => File[$webserver_file],
  }

  service { 'consul':
    ensure  => running,
    enable  => true,
    require => File['/usr/bin/consul'],
  }

  

}
