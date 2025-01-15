# Vagrant Cheat Sheet

## Common commands

- `vagrant init [name]`: Initialize a new project with the given name.
- `vagrant up`: Start the virtual machine.
- `vagrant ssh`: Connect to the virtual machine via SSH.
- `vagrant halt`: Stop the virtual machine.
- `vagrant reload`: Reload the virtual machine.
- `vagrant destroy`: Remove the virtual machine.
- `vagrant package`: Package the virtual machine to a box.
- `vagrant box list`: List all installed boxes.
- `vagrant box add [name]`: Add a new box with the given name.
- `vagrant box remove [name]`: Remove a box with the given name.
- `vagrant box update [name]`: Update a box with the given name.

## Detailed examples

### Initialize a project

To initialize a new Vagrant project, navigate to your desired directory and run the following command:

```sh
vagrant init ubuntu/bionic64
```

This will create a `Vagrantfile` with the specified box.

### Start and SSH into the VM

Once your project is initialized, you can start the virtual machine and SSH into it:

```sh
vagrant up
vagrant ssh
```

### Provision with a Shell Script

You can automate the provisioning of your VM by adding a shell script to your `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y apache2
  SHELL
end
```

### Synced Folders

Share a folder between your host and guest machine by adding the following to your `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.synced_folder "./data", "/vagrant_data"
end
```

### Network Configuration

Set up port forwarding or a private network in your `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"

  # Forwarding port 8080 on host to port 80 on guest
  config.vm.network "forwarded_port", guest: 80, host: 8080

  # Setting up a private network
  config.vm.network "private_network", ip: "192.168.33.10"
end
```

### Creating Multiple Machines

Vagrant allows you to define multiple virtual machines within one `Vagrantfile`. Here's an example:

```ruby
Vagrant.configure("2") do |config|
  config.vm.define "web" do |web|
    web.vm.box = "ubuntu/bionic64"
    web.vm.network "forwarded_port", guest: 80, host: 8080
  end

  config.vm.define "db" do |db|
    db.vm.box = "ubuntu/bionic64"
    db.vm.network "private_network", ip: "192.168.33.11"
  end
end
```

### Using Ansible for Provisioning

You can provision your VM using Ansible by adding the following to your `Vagrantfile`:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
  end
end
```

### Using Docker as a Provider

Vagrant can also work with Docker. Here's an example configuration:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provider "docker" do |docker|
    docker.image = "nginx:latest"
    docker.ports = ["8080:80"]
  end
end
```
