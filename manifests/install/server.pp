# @summary Installs CheckMK Server
class checkmk::install::server {
  if $checkmk::cmkadmin_user_password == undef {
    fail("cmkadmin_user_password must be defined when `mode => 'server'` is used")
  }
  $cmkadmin_user_password = Sensitive($checkmk::cmkadmin_user_password)
  $automation_user_password = Sensitive($checkmk::automation_user_password)

  case $facts['os']['family'] {
    'Debian': {
      if $checkmk::download_url {
        $download_url = $checkmk::download_url
      } else {
        $download_url = "https://download.checkmk.com/checkmk/${checkmk::version}/check-mk-raw-${checkmk::version}_0.${facts['os']['codename']}_amd64.deb"
      }

      file { '/tmp/check-mk-raw.deb':
        ensure         => file,
        source         => $checkmk::download_url,
        checksum       => 'sha256',
        checksum_value => $checkmk::sha256_hash,
      }

      package { "check-mk-raw-${checkmk::version}":
        ensure   => installed,
        provider => 'apt',
        source   => '/tmp/check-mk-raw.deb',
        require  => File['/tmp/check-mk-raw.deb'],
      }

      # TODO: make sure a user configurable password is set
      exec { "create omd site ${checkmk::site_name}":
        command => "/usr/bin/omd create ${checkmk::site_name}",
        creates => "/opt/omd/sites/${checkmk::site_name}",
        require => Package["check-mk-raw-${checkmk::version}"],
      }

      exec { 'checkmk_cmkadmin_password':
        command     => "/usr/bin/htpasswd -b /opt/omd/sites/${checkmk::site_name}/etc/htpasswd cmkadmin ${cmkadmin_user_password}",
        refreshonly => true,
        subscribe   => Exec["create omd site ${checkmk::site_name}"],
      }

      exec { 'checkmk_automation_password':
        command     => "/usr/bin/htpasswd -b /opt/omd/sites/${checkmk::site_name}/etc/htpasswd automation ${automation_user_password}",
        refreshonly => true,
        subscribe   => Exec["create omd site ${checkmk::site_name}"],
      }

      exec { "start odm site ${checkmk::site_name}":
        command => "/usr/bin/omd start ${checkmk::site_name}",
        require => Exec["create omd site ${checkmk::site_name}"],
        unless  => "/usr/bin/omd status ${checkmk::site_name}",
      }
    }
    default: {
      fail('Unsupported OS family')
    }
  }
}
