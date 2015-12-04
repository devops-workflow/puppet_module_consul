class consul::install ( 
 $download_source = $::consul::download_source,
 $download_file   = $::consul::download_file,
) {

  exec { 'download-consul-zipfile':
    command => "/usr/bin/wget ${download_source}/${download_file} -O /root/${download_file}",
    unless  => "/bin/ls /usr/bin/consul",
  } ->
  exec { 'unzip-consul-zipfile':
    command => "/usr/bin/unzip /root/${download_file} -d /root",
    unless  => "/bin/ls /usr/bin/consul",
  } ->
  exec { 'copy-consul-bin':
    command => "/bin/mv /root/consul /usr/bin/consul",
    unless  => "/bin/ls /usr/bin/consul",
  } ->
  exec { 'delete-consul-zipfile':
    command => "/bin/rm /root/${download_file}",
    onlyif  => "/bin/ls /root/${download_file}",
  } ->
  file { '/usr/bin/consul':
    mode => 0755,
  }

}
