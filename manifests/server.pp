class consul::server (
  $bootstrap          = $::consul::bootstrap,
  $configuration_root = $::consul::configuration_root,
  $encrypt_string     = $::consul::encrypt_string,
  $start_join         = $::consul::start_join,
) {

  firewall { '100 Accept inbound Consul server TCP':
    dport  => '8300',
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '100 Accept inbound Consul server UDP':
    dport  => '8300',
    proto  => 'udp',
    action => 'accept',
  }

  firewall { '100 Accept outbound Consul server TCP':
    chain    => 'OUTPUT',
    proto    => 'tcp',
    dport    => '8300',
    action   => 'accept',
  }

  firewall { '100 Accept outbound Consul server UDP':
    chain    => 'OUTPUT',
    proto    => 'udp',
    dport    => '8300',
    action   => 'accept',
  }

  firewall { '100 Accept inbound Consul serf_wan TCP':
    dport  => '8302',
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '100 Accept inbound Consul serf_wan UDP':
    dport  => '8302',
    proto  => 'udp',
    action => 'accept',
  }

  firewall { '100 Accept outbound Consul serf_wan TCP':
    chain    => 'OUTPUT',
    proto    => 'tcp',
    dport    => '8302',
    action   => 'accept',
  }

  firewall { '100 Accept outbound Consul serf_wan UDP':
    chain    => 'OUTPUT',
    proto    => 'udp',
    dport    => '8302',
    action   => 'accept',
  }

  file { "${configuration_root}/server":
    ensure  => directory,
    require => File[$configuration_root],
  }

  file { "${configuration_root}/server/config.json":
    content => template("${module_name}/server/config.json.erb"),
    require => File["${configuration_root}/server"],
    notify  => Service['consul'],
  }

  unless ($bootstrap) {
    file { "${configuration_root}/server/Pagerduty.json":
      content => template("${module_name}/server/Pagerduty.json.erb"),
      require => File["${configuration_root}/server"],
      notify  => Service['consul'],
    }
  }

  file { "${configuration_root}/checks/reading":
    source  => "puppet:///modules/${module_name}/server/reading",
    require => File["${configuration_root}/checks"],
    mode    => '0755',
  }


}
