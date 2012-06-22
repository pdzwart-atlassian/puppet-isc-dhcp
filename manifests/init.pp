# isc-dhcp service
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
#    class { 'isc-dhcp':
#        interfaces => [ 'eth0', 'eth1' ],
#        ddns_update_style = 'none',
#        domain_name => 'example.org',
#        domain_name_servers => [ 'ns1.example.org', 'ns2.example.org' ],
#        default_lease_time => 600,
#        max_lease_time = 7200,
#        authoritative = true,
#    }
#
class isc-dhcp( $interfaces = undef,
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
    $package = 'isc-dhcp-server'
    $service = 'isc-dhcp-server'

    package { $package:
        ensure  => installed,
    }

    file { '/etc/default/isc-dhcp-server':
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => '0644',
        content => template('isc-dhcp/isc-dhcp-server.erb'),
        require => Package[$package],
    }

    file { '/etc/dhcp/dhcpd.conf':
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => '0644',
        content => template('isc-dhcp/dhcpd.conf.erb'),
        require => Package[$package],
    }

    service { $package:
        ensure      => running,
        enable      => true,
        pattern     => '/usr/sbin/dhcpd',
        require     => Package[$package],
        subscribe   => [ File['/etc/default/isc-dhcp-server'], File['/etc/dhcp/dhcpd.conf'] ],
    }

    if $ddns_update_style != 'none' {
        file { '/etc/dhcp/dynamic-dns.key':
            ensure  => file,
            owner   => root,
            group   => root,
            mode    => '0640',
            content => template('isc-dhcp/dynamic-dns.key.erb'),
            notify  => Service[$service],
        }

        file { '/etc/dhcp/dhcpd.conf.ddns':
            ensure  => file,
            owner   => root,
            group   => root,
            mode    => '0644',
            content => template('isc-dhcp/dhcpd.conf.ddns.erb'),
            notify  => Service[$service],
        }
    }
}
