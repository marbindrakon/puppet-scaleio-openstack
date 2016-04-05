class scaleio_openstack::nova(
  $ensure              = present,
  $gateway_user        = admin,
  $gateway_password    = undef,
  $gateway_ip          = undef,
  $gateway_port        = 4443,
  $protection_domains  = undef,
  $storage_pools       = undef,
  $provisioning_type   = 'ThickProvisioned',
  $nova_compute_conf_file_name = 'nova.conf',
)
{
  notify {'Configuring Compute node for ScaleIO integration': }

  if ! $::nova_path {
    warning('Nova is not installed on this node')
  }
  else {

    #TODO: FUEL7.0 MOS: 2015.1.1-mos19665.diff is the copy of original patch.
    #      Split logic for juno and kilo and remove duplicated patch file 2015.1.1-mos19665.diff.
    $version_str = split($::nova_version, '-')
    $core_version = $version_str[0]
    $custom_version_str = split($version_str[1], 'mos')
    $custom_version = $custom_version_str[1]
    if $custom_version != '' {
      $version = "${core_version}-mos${custom_version}"
    }
    else {
      $version = $core_version
    }
    notify { "Detected nova version: ${version}": }
    if $core_version in ['12.0.1', '12.0.2'] {
      notify { "Detected nova version ${version} - treat as Liberty": }

      scaleio_openstack::nova_common { 'nova common for Liberty':
        ensure => $ensure,
        gateway_user => $gateway_user,
        gateway_password => $gateway_password,
        gateway_ip => $gateway_ip,
        gateway_port => $gateway_port,
        protection_domains => $protection_domains,
        storage_pools => $storage_pools,
        provisioning_type => $provisioning_type,
        openstack_version => 'liberty',
        siolib_file => 'siolib-1.4.5.tar.gz',
        nova_patch => "${version}.diff",
      } ~>
      service { 'nova-compute':
        ensure => running,
      }
    }
    elsif $core_version in ['2015.1.1', '2015.1.2', '2015.1.3']  {
      notify { "Detected nova version ${version} - treat as Kilo": }

      scaleio_openstack::nova_common { 'nova common for Kilo':
        ensure => $ensure,
        gateway_user => $gateway_user,
        gateway_password => $gateway_password,
        gateway_ip => $gateway_ip,
        gateway_port => $gateway_port,
        protection_domains => $protection_domains,
        storage_pools => $storage_pools,
        provisioning_type => $provisioning_type,
        openstack_version => 'kilo',
        siolib_file => 'siolib-1.3.5.tar.gz',
        nova_patch => "${version}.diff",
      } ->

      file { ["${::nova_path}/virt/libvirt/drivers", "${::nova_path}/virt/libvirt/drivers/emc"]:
        ensure  => directory,
        mode    => '0755',
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for nova file 001':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt/drivers",
        file_name => '__init__.py',
        src_dir   => 'kilo/nova'
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for nova file 002':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt/drivers/emc",
        file_name => '__init__.py',
        src_dir   => 'kilo/nova'
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for nova file 003':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt/drivers/emc",
        file_name => 'driver.py',
        src_dir   => 'kilo/nova'
      } ->
      scaleio_openstack::file_from_source {'scaleio driver for nova file 004':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt/drivers/emc",
        file_name => 'scaleiolibvirtdriver.py',
        src_dir   => 'kilo/nova'
      } ->
      ini_setting { 'scaleio_nova_compute_config compute_driver':
        ensure  => $ensure,
        path    => "/etc/nova/${nova_compute_conf_file_name}",
        section => 'DEFAULT',
        setting => 'compute_driver',
        value   => 'nova.virt.libvirt.drivers.emc.driver.EMCLibvirtDriver',
      } ~>

      service { 'nova-compute':
        ensure => running,
      }

    }
    elsif $core_version in ['2014.2.2', '2014.2.4'] {
      notify { "Detected nova version ${version} - treat as Juno": }

      scaleio_openstack::nova_common { 'nova common for Juno':
        ensure => $ensure,
        gateway_user => $gateway_user,
        gateway_password => $gateway_password,
        gateway_ip => $gateway_ip,
        gateway_port => $gateway_port,
        protection_domains => $protection_domains,
        storage_pools => $storage_pools,
        provisioning_type => $provisioning_type,
        openstack_version => 'juno',
        siolib_file => 'siolib-1.2.5.tar.gz',
        nova_patch => "${version}.diff",
      } ->

      scaleio_openstack::file_from_source { 'scaleio driver for nova':
        ensure    => $ensure,
        dir       => "${::nova_path}/virt/libvirt",
        file_name => 'scaleiolibvirtdriver.py',
        src_dir   => 'juno/nova'
      } ->
      ini_subsetting { 'scaleio_nova_config':
        ensure               => $ensure,
        path                 => '/etc/nova/nova.conf',
        section              => 'libvirt',
        setting              => 'volume_drivers',
        subsetting           => 'scaleio=nova.virt.libvirt.scaleiolibvirtdriver.LibvirtScaleIOVolumeDriver',
        subsetting_separator => ',',
      } ~>

      service { 'nova-compute':
        ensure => running,
      }

    }
    else {
      fail("Version ${::nova_version} isn't supported.")
    }
  }

  # TODO: Disintigrate to separate files for each version
}

