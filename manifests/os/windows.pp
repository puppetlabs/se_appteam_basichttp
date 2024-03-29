# @summary Manage the basic HTTP demo for Windows
#
# Manages a basic website
#
# @example
#   include appteam_basichttp::os::windows
class appteam_basichttp::os::windows (
  String $doc_root           = 'C:\\inetpub\\wwwroot\\sample_website',
  Integer $webserver_port    = 80,   # change this default value in Hiera common.yaml
  String $apppool            = 'sample_website',
  String $website_source_dir = 'puppet:///modules/appteam_basichttp/sample_website',
  Boolean $enable_monitoring = false,
) {

  #if $enable_monitoring {
    # future improvements
  #}

  class{'::appteam_webserver::middleware::iis':
    default_website => false,
  }

  # configure iis
  iis_application_pool {'sample_website':
    require => [
      Class['appteam_webserver::middleware::iis'],
    ],
  }

  iis_site { 'sample_website':
    ensure          => 'started',
    physicalpath    => $doc_root,
    applicationpool => $apppool,
    bindings        => [
      {
        'bindinginformation' => "*:${webserver_port}:",
        'protocol'           => 'http',
      },
    ],
    require         => [
      Iis_application_pool['sample_website']
    ],
  }

  windows_firewall::exception { 'IIS':
    ensure       => present,
    direction    => 'in',
    action       => 'allow',
    enabled      => true,
    protocol     => 'TCP',
    local_port   => $webserver_port,
    display_name => "HTTP_${webserver_port}", # generate a unique inbound rule. this new rule per port value is just for demo purposes
    description  => 'Inbound rule for HTTP Server',
  }

  file { $website_source_dir:
    ensure  => directory,
    path    => $doc_root,
    source  => $website_source_dir,
    recurse => true,
  }

  file { "${doc_root}/index.html":
    ensure  => file,
    content => epp('appteam_basichttp/sample_website.html.epp'),
  }

}
