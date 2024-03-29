# @summary A module for managing CheckMK
#
# Configures a CheckMK server or agent
#
# @example
#   # CheckMK Server
#   class { '::checkmk':
#     mode        => 'server',
#     sha256_hash => '8804c0291e897f6185b147613a5fc86d61c0bcf73eaac5b11d90afe58af10c9f', # get from https://checkmk.com/download
#   }
#
#   # CheckMK Agent
#   class { '::checkmk':
#     mode                        => 'agent',
#     agent_download_host         => 'checkmk.example.com',
#     agent_download_bearer_token => '1234567890',
#   }
#
# @param [String] version The version of CheckMK server to install
# @param [Optional[String]] download_url The URL to download the CheckMK server from
#   The default URL is derived from the version defined and the host codename
# @param [String] sha256_hash The SHA256 hash of the CheckMK server package
# @param [String] mode Install mode for either 'server' or 'agent'
# @param [String] site_name The site name for the CheckMK server
# @param [Optional[String]] cmkadmin_user_password The password for the "cmkadmin" user, required when using mode => 'server'
# @param [String] agent_download_protocol Either 'http' or 'https' for the server URL
# @param [String] agent_download_host The hostname to download the agent package from
# @param [String] automation_user_password The password for the "automation" user
# @param [String] agent_folder The folder in CheckMK Hosts to create the host in
# @param [String] hostname The hostname for the CheckMK agent
class checkmk (
  String $version,
  Optional[String] $download_url,
  String $sha256_hash,
  String $mode,
  String $site_name,
  Optional[String] $cmkadmin_user_password,
  Enum[latest, present, absent] $agent_package_ensure,
  String $agent_download_protocol,
  String $agent_download_host,
  String $automation_user_password,
  String $agent_folder,
  String $hostname,
) {
  unless $site_name =~ /^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$/ {
    fail('site_name must be a valid CheckMK site name')
  }

  case $mode {
    'server': {
      class { 'checkmk::install::server': }
      -> class { 'checkmk::install::agent': }
    }
    'agent': {
      class { 'checkmk::install::agent': }
    }
    default: {
      fail('checkmk::mode must be either "server" or "agent"')
    }
  }
}
