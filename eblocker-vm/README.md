# Build eBlocker VM

Prerequisites for building an eBlocker VM:

* Ansible is installed on your local machine
* You have a Debian Buster VM running (e.g. on VirtualBox) with SSH
  enabled and Python installed.

## Prepare

If you have a template VM:

1. Clone a VM from the template _eBlocker VM Base_.
1. Name it _eBlockerVM_ and select _full clone_.
1. Go to the settings and change the number of CPU cores to __2__.
1. Remove the description.

Otherwise, create a Debian Buster VM manually. Add a user named `eblockerbuild`.

Now you should have a VM with SSH enabled. Continue:

1. Boot the VM.
1. Edit the file `hosts` and enter the VM's IP address.
1. Try to login as `eblockerbuild` via SSH so the host key is accepted.

## Go back to eth0

On `amd64` the default network interface is named `enp0s3`. The eBlocker
cannot work with that, it needs `eth0`. Run the following playbook to
change the interface name:

    ansible-playbook -k -K -i hosts prepare-ethernet.yml

## Install eBlocker software

This step installs all eBlocker software packages. You can decide
whether the eBlocker should get updates from the production or the
test repositories.

### Production environment

    ansible-playbook -k -K -i hosts install-eblocker.yml

### Test environment

    ansible-playbook -k -K -i hosts install-eblocker.yml -e eblocker_env=test

## Cleanup

Note: after that, SSH is disabled, so no more playbooks can be run.

### Production environment

    ansible-playbook -k -K -i hosts cleanup.yml

### Test environment

    ansible-playbook -k -K -i hosts cleanup.yml -e eblocker_env=test

## Final manual cleanup

These last steps must be done at the console by `root`:

### Remove eblockerbuild user

    deluser --remove-home eblockerbuild

### Lock the root account

    passwd -l root

### Clean history

Unfortunately, `history -c` does __not__ work! This is a brutal method but works:

    rm .bash_history && kill -9 $$

### Factory reset

Lastly, do a factory reset via eBlocker's web interface.
