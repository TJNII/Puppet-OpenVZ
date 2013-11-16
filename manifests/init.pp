# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# OpenVZ: Configure OpenVZ kernel and install utilities
# Currently CentOS only
# A reboot is required after install.
# Guide: http://wiki.centos.org/HowTos/Virtualization/OpenVZ
class openvz (
  $venet0_network = "172.31.254.0",
  $venet0_netmask = "255.255.255.0",
  $manage_firewall = true,
#  $firewall_allowed_interfaces = "eth0",
  $firewall_nat_traffic = false,
  ) {
  # Repo config
  file { '/etc/yum.repos.d/openvz.repo':
    ensure  => file,
    source  => "puppet:///modules/openvz/etc/yum.repos.d/openvz.repo",
  }
  
  file { '/etc/pki/rpm-gpg/RPM-GPG-Key-OpenVZ':
    ensure  => file,
    source  => "puppet:///modules/openvz/etc/pki/rpm-gpg/RPM-GPG-Key-OpenVZ",
  }

  # Package installs
  package { [ 'vzkernel',
              'vzctl',
              'vzquota',
              ]:
    ensure  => installed,
    require => [ File['/etc/yum.repos.d/openvz.repo'],
                 File['/etc/pki/rpm-gpg/RPM-GPG-Key-OpenVZ'],
                 ],
  }

  # Sysctl changes
  file { '/etc/sysctl.conf':
    ensure  => file,
    source  => "puppet:///modules/openvz/etc/sysctl.conf",
  }

  # Disable SELinux
  file { '/etc/selinux/config':
    ensure  => file,
    source  => "puppet:///modules/openvz/etc/selinux/config",
  }

  service { 'vz':
    ensure    => running,
    enable    => true,
    require   => [ Package['vzkernel'],
                   Package['vzctl'],
                   Package['vzquota'],
                   ],
  }

  if $manage_firewall == true {
    firewall { "100 Allow openvz traffic":
      chain    => 'FORWARD',
      action   => accept,
      proto    => 'all',
      iniface  => "venet0",
#      outiface => $firewall_allowed_interfaces
    }

    if $firewall_nat_traffic == true {
      firewall { '100 snat for openvz':
        chain    => 'POSTROUTING',
        jump     => 'MASQUERADE',
        proto    => 'all',
        source   => "${venet0_network}/${venet0_netmask}",
        table    => 'nat',
      }
    }
  }    
}
