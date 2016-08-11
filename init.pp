ec2_vpc { 'projectvpc':
  ensure       => present,
  region       => 'us-east-1',
  cidr_block   => '10.0.0.0/16',
}

ec2_securitygroup { 'projectsg':
  ensure      => present,
  region      => 'us-east-1',
  vpc         => 'projectvpc',
  description => 'Security group for VPC',
  ingress     => [{
    security_group => 'projectsg',
  },{
    protocol => 'tcp',
    port     => 22,
    cidr     => '0.0.0.0/0'
  }
  {
    protocol => 'https',
    port     => 443,
    cidr     => '0.0.0.0/0'
  }
  {
    protocol => 'http',
    port     => 80,
    cidr     => '0.0.0.0/0'
  }
  ]
}

ec2_vpc_subnet { 'projectsubnet':
  ensure            => present,
  region            => 'us-east-1',
  vpc               => 'projectvpc',
  cidr_block        => '10.0.0.0/24',
  availability_zone => 'us-east-1c',
  route_table       => 'projectroutes',
}

ec2_vpc_internet_gateway { 'projectigw':
  ensure => present,
  region => 'us-east-1',
  vpc    => 'projectvpc',
ec2_vpc_routetable { 'projectroutes':
  ensure => present,
  region => 'us-east-1',
  vpc    => 'projectvpc',
  routes => [
    {
      destination_cidr_block => '10.0.0.0/16',
      gateway                => 'local'
    },{
      destination_cidr_block => '0.0.0.0/0',
      gateway                => 'projectigw'
    },
  ],
}
}

ec2_instance { 'projectinstance1':
  ensure            => present,
  region            => 'us-east-1',
  vpc               => 'projectvpc',
  availability_zone => 'us-east-1a',
  image_id          => 'ami-d732f0b7',
  instance_type     => 't2.micro',
  monitoring        => true,
  security_groups   => 'projectsg',
  user_data         => template('apache-puppetbootstrapscript.sh'),
}
ec2_instance { 'projectinstance2':
  ensure            => present,
  region            => 'us-east-1',
  vpc               => 'projectvpc',
  availability_zone => 'us-east-1b',
  image_id          => 'ami-d732f0b7',
  instance_type     => 't2.micro',
  monitoring        => true,
  security_groups   => 'projectsg',
  user_data         => template('apache-puppetbootstrapscript.sh'),
}
elb_loadbalancer { 'projectloadbalancer':
  ensure               => present,
  region               => 'us-east-1',
  availability_zones   => ['us-east-1a', 'us-east-1b'],
  instances            => ['projectinstance1', 'projectinstance2'],
  security_groups      => ['projectsg'],
  listeners            => [{
    protocol           => 'HTTP',
    load_balancer_port => 80,
    instance_protocol  => 'HTTP',
    instance_port      => 80,
  },{
    protocol           => 'HTTPS',
    load_balancer_port => 443,
    instance_protocol  => 'HTTPS',
    instance_port      => 8080,
  }],
}


ec2_launchconfiguration { 'projectconfig':
  ensure          => present,
  security_groups => ['projectsg'],
  region          => 'us-east-1',
  image_id        => 'ami-d732f0b7',
  instance_type   => 't2.micro',
}

ec2_autoscalinggroup { 'projectasg':
  ensure               => present,
  min_size             => 2,
  max_size             => 2,
  region               => 'us-east-1',
  launch_configuration => 'projectconfig',
  availability_zones   => ['us-east-1a', 'us-east-1b'],
}

ec2_scalingpolicy { 'scaleout':
  ensure             => present,
  auto_scaling_group => 'projectasg',
  scaling_adjustment => +1,
  adjustment_type    => 'ChangeInCapacity',
  region             => 'us-east-1',
}

ec2_scalingpolicy { 'scalein':
  ensure             => present,
  auto_scaling_group => 'projectasg',
  scaling_adjustment => -1,
  adjustment_type    => 'ChangeInCapacity',
  region             => 'us-east-1',
}

cloudwatch_alarm { 'AddCapacity':
  ensure              => present,
  metric              => 'CPUUtilization',
  namespace           => 'AWS/EC2',
  statistic           => 'Average',
  period              => 120,
  threshold           => 70,
  comparison_operator => 'GreaterThanOrEqualToThreshold',
  dimensions          => [{
    'AutoScalingGroupName' => 'projectasg',
  }],
  evaluation_periods  => 2,
  alarm_actions       => 'scaleout',
  region              => 'us-east-1',
}

cloudwatch_alarm { 'RemoveCapacity':
  ensure              => present,
  metric              => 'CPUUtilization',
  namespace           => 'AWS/EC2',
  statistic           => 'Average',
  period              => 120,
  threshold           => 40,
  comparison_operator => 'LessThanOrEqualToThreshold',
  dimensions          => [{
    'AutoScalingGroupName' => 'projectasg',
  }],
  evaluation_periods  => 2,
  region              => 'us-east-1',
  alarm_actions       => 'scalein',
}
 
