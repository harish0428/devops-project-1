Assumptions
1.I am assumming that I have a running EC2 instance with puppet master installed on it, from which I am implementing this project.
2.I had downloaded AWS, APACHE modules from puppet forge on to the puppet master.

Description : 

I have included the init.pp file, which would be inside /etc/puppet/modules/manifests/ 
This init.pp file would spin up two ec2 instances in a said VPC, Subnet, Security Group and in said region and Availability Zone.
This would also have auto scalling policies configured with auto scalling group and auto scalling launch configuration mentioned in init.pp file.
This would also send in user data to download and install apache on the two instances.
User data script is also configrued to install puppet agent on the nodes. 
To redirect the http requests to https, I had included the apache module rules in site.pp file.
Site.pp file would make sure requests are redirected. Also, ssl => true and changing port from 80 to 443 is configured to get the site up with a self-signed cert, which will be automatically generated. 
The link would then serve a static file which was passed on through the user data.
User data is passed through script named apachebootstrapscript.sh.

To validate server configurations, I am using puppet. Puppet agents would send in facts from facter which is checked every 30 minutes by default to help maintain the said server configurations. 



