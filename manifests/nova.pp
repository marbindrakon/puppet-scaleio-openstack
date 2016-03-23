class scaleio_openstack::nova(
  $ensure = present,
)
{
  notify {'Configuring Compute node for ScaleIO integration': }

  if ! $::nova_path {
    warning('Nova is not installed on this node')
  }
  else {
    file_from_source { 'scaleiolibvirtdriver.py':
      ensure => $ensure,
      path   => "${::nova_path}/virt/libvirt",
    } ->
    scaleio_filter_file { 'nova':
      ensure => $ensure,
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
}
