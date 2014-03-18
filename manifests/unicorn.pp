# Define: nginx::server::vhost
#
#   nginx vhost. For serving web traffic as you would with apache.
#
# Parameters:
#
# Requires:
#   include nginx::server
#
define nginx::unicorn(
  $unicorn_socket,
  $priority           = '10',
  $template           = 'nginx/vhost-unicorn.conf.erb',
  $servername         = '',
  $path               = '',
  $auth               = '',
  $unicorn_magic      = '',
  $magic              = '',
  $port               = '80',
  $ssl                = false,
  $ssl_port           = '443',
  $ssl_cert           = $nginx::server::default_ssl_cert,
  $ssl_key            = $nginx::server::default_ssl_key,
  $ssl_ca             = $nginx::server::default_ssl_ca,
  $ssl_crl_path       = $nginx::server::default_ssl_crl_path,
  $ssl_ciphers        = $nginx::server::default_ssl_ciphers,
  $ssl_protocols      = $nginx::server::default_ssl_protocols,
  $ssl_verify_client  = $nginx::server::default_ssl_verify_client,
  $sslonly            = false,
  $serveraliases      = undef,
  $isdefaultvhost     = false,
  $aliases            = {},
  $gunicorn           = false
) {

  include nginx
  include nginx::server
  include nginx::params

  if $servername == '' {
    $srvname = $name
  } else {
    $srvname = $servername
  }

  if $path == '' {
    $rootpath = "/var/www/${srvname}"
  } else {
    $rootpath = $path
  }

  # Try and work out what we're talking to on the other end of unicorn
  # If it's a bare path, put unix: before it, otherwise pass it
  # through. This means just files are assumed to be socket. If it's
  # something else (unix/http) all good, otherwise fail.
  case $unicorn_socket {
    /^(unix|https?):/: { $unicorn_upstream = regsubst( $unicorn_socket, '^(https?://)(.+?)/?$', '\2' , 'I' ) }
    /^\//:             { $unicorn_upstream = "unix:${unicorn_socket}" }
    default:           { fail( "Value of ${unicorn_socket} is unsupported.")}
  }

  # Need to make some variable names so the templates can use them!
  # Such as an app_server name that is unique, so when we have ssl and
  # non-ssl unicorn hosts they still work.
  if $ssl == true {
    $appname = regsubst( $srvname , '^(\w+?)\..*?$' , '\1_ssl' )

    # puppetlabs-stdlib functions
    validate_absolute_path($ssl_cert)
    validate_absolute_path($ssl_key)

  } else {
    $appname = regsubst( $srvname , '^(\w+?)\..*?$' , '\1' )
  }

  file { "${nginx::params::vdir}/${priority}-${name}":
    content => template($template),
    owner   => 'root',
    group   => '0',
    mode    => '0755',
    require => Package['nginx'],
    notify  => Service['nginx'],
  }
}
