# isc_dhcp service
#
# This class needs to use multi-part files to allow for multiple subnets to be
# defined.
#
# == Parameters
#
# [*interfaces*]
#   List of network interfaces to bind the DHCP service to.
#
# [*ddns_update_style*]
#   Dynamic DNS update style. Default is 'none'.
#
# [*domain_name*]
#   Default domain name for DHCP pools. Default is 'example.org'.
#
# [*domain_name_servers*]
#   Default domain name servers for DHCP pools.
#   Default is [ 'ns1.example.org', 'ns2.example.org' ].
#
# [*default_lease_time*]
#   Default DHCP lease time in seconds for DHCP pools.
#   Defaule value is 600.
#
# [*max_lease_time*]
#   Maxiumum DHCP lease time in seconds for DHCP pools.
#   Defaule value is 7200.
#
# [*authoritative*]
#   Boolean value to determine if this DHCP server is authoritative.
#   Defaule value is false.
#
# == Variables
#
# == Examples
#
#    class { 'isc_dhcp':
#        interfaces => [ 'eth0', 'eth1' ],
#        ddns_update_style = 'none',
#        domain_name => 'example.org',
#        domain_name_servers => [ 'ns1.example.org', 'ns2.example.org' ],
#        default_lease_time => 600,
#        max_lease_time = 7200,
#        authoritative = true,
#    }
#
class isc_dhcp( $interfaces = undef,
  $ddns_update_style = 'none',
  $domain_name = 'example.org',
  $domain_name_servers = [ 'ns1.example.org', 'ns2.example.org' ],
  $default_lease_time = 600,
  $max_lease_time = 7200,
  $authoritative = false,
  $subnet = undef,
  $netmask = undef,
  $range_start = undef,
  $range_end = undef,
  $routers = undef,
  $dynamic_dns_key = undef,
  $dynamic_dns_forward_zone = undef,
  $dynamic_dns_reverse_zone = undef,
  $dynamic_dns_ns_master = undef ) {

  include isc_dhcp::params

  if $::lsbdistid == 'Ubuntu' {
    $user = 'dhcpd'
    $group = 'dhcpd'
  } else {
    $user = 'root'
    $group = 'root'
  }

  package { $isc_dhcp::params::package:
    ensure  => installed,
  }

  file { '/etc/default/isc-dhcp-server':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('isc_dhcp/isc-dhcp-server.erb'),
    require => Package[$isc_dhcp::params::package],
  }

  file { $isc_dhcp::params::conf_dir:
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '2774',
    require => Package[$isc_dhcp::params::package],
  }

  file { "${isc_dhcp::params::conf_dir}/dhcpd.conf":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('isc_dhcp/dhcpd.conf.erb'),
    require => Package[$isc_dhcp::params::package],
  }

  service { $isc_dhcp::params::package:
    ensure    => running,
    enable    => true,
    pattern   => '/usr/sbin/dhcpd',
    require   => Package[$isc_dhcp::params::package],
    subscribe => File['/etc/default/isc-dhcp-server',
      "${isc_dhcp::params::conf_dir}/dhcpd.conf"],
  }

  if $ddns_update_style != 'none' {
    file { "${isc_dhcp::params::conf_dir}/dynamic-dns.key":
      ensure  => file,
      owner   => $user,
      group   => $group,
      mode    => '0640',
      content => template('isc_dhcp/dynamic-dns.key.erb'),
      notify  => Service[$isc_dhcp::params::service],
    }

    file { "${isc_dhcp::params::conf_dir}/dhcpd.conf.ddns":
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template('isc_dhcp/dhcpd.conf.ddns.erb'),
      notify  => Service[$isc_dhcp::params::service],
    }
  }

  file { $isc_dhcp::params::dcl:
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0640',
    require => Package[$isc_dhcp::params::package],
    notify  => Service[$isc_dhcp::params::service],
  }

  file { $isc_dhcp::params::dcl_ffd:
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0700',
    require => [ Package[$isc_dhcp::params::package],
      File[$isc_dhcp::params::conf_dir]
    ],
    recurse => true,
    purge   => true,
    notify  => Exec['dcl_file_assemble'],
  }

  exec { $isc_dhcp::params::dcl_file_assemble:
    refreshonly => true,
    require     => [ File[$isc_dhcp::params::dcl_ffd],
      File[$isc_dhcp::params::dcl]
    ],
    notify      => Service[$isc_dhcp::params::service],
    command     => "/bin/cat ${isc_dhcp::params::dcl_ffd}/*_dhcpd.conf.local_* > ${isc_dhcp::params::dcl}",
  }

  file { $isc_dhcp::params::dcl_preamble:
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0600',
    require => Package[$isc_dhcp::params::package],
    content => template('isc_dhcp/dhcpd.conf.local_preamble.erb'),
    notify  => Exec['dcl_file_assemble'],
  }
}

# vim: set ts=2 sw=2 sts=2 tw=0 et:
