default {}
{
include => apache
}

apache::vhost { 'webserver.puppetlabs.com':  
  port     => '443',  
  docroot  => '/var/www/webserver',  
  ssl      => true,  
  }
