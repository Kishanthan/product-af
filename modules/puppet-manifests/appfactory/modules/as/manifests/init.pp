class as (
  $s2_enabled=true,
  $version,
  $offset=0,
  $members=undef,
  $as_subdomain='am',
  $localmember_port=4100,
  $config_db=governance,
  $maintenance_mode=true,
  $depsync=false,
  $sub_cluster_domain=mgt,
  $owner=root,
  $group=root,
  $clustering='true',
  $target="/mnt"
  ) inherits params {


  $deployment_code	= "as"
  $service_code 		= "as"
  $carbon_home		  = "${target}/wso2${service_code}-${version}"

  $service_templates 	= [
          "conf/axis2/axis2.xml",
          "conf/carbon.xml",
          "conf/email/email-admin-config.xml",
          "conf/datasources.properties",
          "conf/tomcat/catalina-server.xml",
          "conf/issuetracker/issuetracker.xml",
          "conf/datasources/as-datasources.xml",
          "deployment/server/jaggeryapps/cloudmgt/site/conf/cloud_mgt.json",
      ]

  $common_templates = [
          "conf/tenant-mgt.xml",
          "conf/appfactory/appfactory.xml",
          "conf/user-mgt.xml",
          "conf/registry.xml",
          "conf/log4j.properties",
          "conf/etc/cache.xml",
          "conf/datasources/master-datasources.xml",
          "conf/multitenancy/stratos.xml",
      ]

  tag ('as')

  clean { $deployment_code:
    mode   => $maintenance_mode,
    target => $carbon_home,
  }

  initialize { $deployment_code:
    repo      => $package_repo,
    version   => $version,
    mode      => $maintenance_mode,
    service   => $service_code,
    local_dir => $local_package_dir,
    owner     => $owner,
    target    => $target,
    require   => Clean[$deployment_code],
  }

  deploy { $deployment_code:
    security => true,
    owner    => $owner,
    group    => $group,
    target   => $carbon_home,
    require  => Initialize[$deployment_code],
  }

  push_templates {
    $service_templates:
      target     => $carbon_home,
      directory  => $deployment_code,
      require    => Deploy[$deployment_code];

    $common_templates:
      target     => $carbon_home,
      directory  => "wso2base",
      require    => Deploy[$deployment_code];
  }

  file { "${carbon_home}/bin/wso2server.sh":
    ensure    => present,
    owner     => $owner,
    group     => $group,
    mode      => '0755',
    content   => template("${deployment_code}/wso2server.sh.erb"),
    require   => Deploy[$deployment_code]; 
  }

  start {
    $deployment_code:
    owner   => $owner,
    target  => $carbon_home,
    require => [  Initialize[$deployment_code],
        Deploy[$deployment_code],
        Push_templates[$service_templates],],
  }
}
