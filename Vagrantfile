# -*- mode: ruby -*-
# vi: set ft=ruby :

# Require YAML module
require 'yaml'
VAGRANTFILE_API_VERSION = 2

# mutable by ARGV and settings file
file    = 'servers.yml'
facts = {}
facts[:domain]  = 'example.com'
facts[:box] = 'centos/7'
facts[:network] = '192.168.2.0/24'
facts[:memory] = 1024
facts[:cpus] = 1
facts[:linux] = 'bento/centos-7.6'
facts[:win] = 'jacqinthebox/windowsserver2016'


required_plugins = %w( vagrant-cachier vagrant-dns )
required_plugins.each do |plugin|
  system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
end

vagrantfiledir = File.expand_path File.dirname(__FILE__)
f = File.join(vagrantfiledir, file)

# Read YAML file with box details
begin
  settings = YAML.load_file f
  facts.merge!(settings)
  if facts[:vms].is_a?(Array)
    vms = facts[:vms]
  end
  vms.each do |v|
    v.merge!(facts.tap{ |x| x.delete(:vms)}){ |key, v1, v2| v1 }
  end
rescue
  puts "Create a servers.yml file in current direcory"
  message = <<-EOF
  ---
  :domain: gaurav.com
  :network: 192.168.10.0/24
  :os: linux
  :cpus: 2
  :memory: 2048
  :vms:
    - :name: master
      :ip: 192.168.10.2
    - :name: client1
      :ip: 192.168.10.3
  EOF
  puts message
  exit 1
end


roles = Hash.new { |h, k| h[k] = Array.new }
INVENTORY_PATH = "./environments/vagrant/hosts"


vms.each_with_index do |x, i|
  name     = x[:name]
  ip       = x[:ip]
  role     = x[:role]
  domain   = x[:domain]
  memory   = x[:memory]
  cpus     = x[:cpus]
  playbook = x[:playbook]
  os       = x[:os]
  win      = x[:win]
  linux    = x[:linux]
  fqdn     = [name, domain].join('.')

  if role && os == "win"
    role << "windows"
  end

  if role
    role.each do |r|
      if roles.has_key?(r)
        roles[r].push(fqdn)
      else
        roles[r].push(fqdn)
      end
    end

    File.open("#{INVENTORY_PATH}", 'w+') { |f|
      roles.keys.sort.each do |k|
        f.write("[#{k}]\n")
        roles[k].each { |v| f.write("#{v}\n") }
        f.write("\n")
      end
    }
  end

  Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    if Vagrant.has_plugin?('vagrant-cachier')
      config.cache.scope = :box
      config.cache.auto_detect = true
    else
      puts 'WARN:  Vagrant-cachier plugin not detected. Continuing unoptimized.'
    end

      config.vm.define name.to_sym do |nm|
        if os == "win"
        nm.vm.box_check_update    = false
        nm.vm.guest = :windows
        nm.vm.communicator = :winrm
        nm.vm.box = win
        nm.vm.hostname = name
        nm.dns.tld = domain
        # Port forward WinRM and RDP
        nm.vm.network :private_network, ip: ip
        nm.vm.network :forwarded_port, guest: 22,   host: 2222,  id: "ssh", auto_correct: true
        nm.vm.network :forwarded_port, guest: 3389, host: 33389, id: "rdp", auto_correct: true
        nm.vm.network :forwarded_port, guest: 5985, host: 55985, id: "winrm", auto_correct: true
        #nm.vm.provision "shell", privileged: "true", powershell_elevated_interactive: "true", path: "ConfigureRemotingForAnsible.ps1"
        else
          nm.vm.box = linux
          nm.vm.network :private_network, ip: ip
          nm.vm.hostname = name
          nm.dns.tld = domain
        end
        nm.vm.provider :virtualbox do |vb|
          vb.gui = false
          vb.linked_clone = true
          vb.memory = memory
          vb.cpus = cpus
          vb.customize [
            "modifyvm", :id,
            "--natdnshostresolver1", "on",
          ]
        end
        if role
          role.each do |r|
            config.vm.provision :ansible do |a|
              a.playbook = "playbook/main.yaml"
              a.inventory_path = INVENTORY_PATH
              #a.galaxy_role_file = 'requirements.yaml'
              a.limit = "#{fqdn}"
            end
          end
        end
      end
    end
end
