# VirtualBox Setup Guide for Monitoring Lab

## Resource Requirements

For optimal performance when running this monitoring lab in VirtualBox, configure your VM with:

- **CPU**: 4 cores (or 2 cores)
- **RAM**: 12-16GB ( alternative 8GB)
- **Storage**: 50GB (dynamically allocated)
- **OS**: Ubuntu 22.04 LTS Server or Desktop
- **Network**: Bridged Adapter (for easy access to web interfaces)

## Step-by-Step VirtualBox Setup

1. **Install VirtualBox ( if you dont have it)**
   - Download and install from [virtualbox.org](https://www.virtualbox.org/)
   - Install the Extension Pack for better USB support and other features

2. **Create a New Virtual Machine**
   - Open VirtualBox and click "New"
   - Name: `Monitoring Lab`
   - Type: Linux
   - Version: Ubuntu (64-bit)
   - Follow the wizard, allocating resources as specified above
   - Choose "Create a virtual hard disk now"
   - Select "VDI (VirtualBox Disk Image)"
   - Choose "Dynamically allocated" for storage
   - Set size to 50GB

3. **Configure VM Settings**
   - Select your new VM and click "Settings"
   - **System → Processor**: Set to 4 CPUs
   - **System → Motherboard**: Enable EFI (if your host supports it)
   - **Display → Screen**: Set Video Memory to 128MB
   - **Network → Adapter 1**: Change to "Bridged Adapter"
   - **USB**: Enable USB 3.0 controller

4. **Install Ubuntu**
   - Start the VM
   - Select your Ubuntu ISO file when prompted
   - Follow the Ubuntu installation process
   - Choose "Install OpenSSH server" during setup for remote access

5. **Post-Installation Setup**
   - Install VirtualBox Guest Additions:
     ```bash
     sudo apt update
     sudo apt install -y build-essential linux-headers-$(uname -r)
     ```
   - Insert Guest Additions CD from VirtualBox menu
   - Mount and install:
     ```bash
     sudo mount /dev/cdrom /mnt
     cd /mnt
     sudo ./VBoxLinuxAdditions.run
     ```
   - Reboot the VM

6. **Take a Snapshot**
   - Once basic setup is complete, take a snapshot
   - This allows you to return to a clean state if needed

## Troubleshooting Tips

- **VM won't start with error about virtualization**: Enable virtualization in your BIOS/UEFI
- **Performance issues**: Reduce allocated resources or close other applications on host
- **Network problems**: Try NAT with port forwarding if bridged adapter doesn't work
- **Shared folders not working**: Reinstall Guest Additions and add user to vboxsf group

## Starting the Lab

After VM setup:
1. Log in to your Ubuntu VM
2. Continue with Section 1.3 of the lab manual (Create Directory Structure)