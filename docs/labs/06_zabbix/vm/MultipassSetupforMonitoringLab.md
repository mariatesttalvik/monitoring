## Initial VM Setup (Using Multipass)

```bash
# Install Multipass (if not already installed)
# For Ubuntu:
sudo snap install multipass

# For macOS (using Homebrew):
# brew install --cask multipass

# For Windows: Download from https://multipass.run/

# Create a VM with sufficient resources
multipass launch --name monitoring-lab --cpus 4 --mem 12G --disk 50G 22.04 
or
multipass launch --name monitoring-lab --cpus 2 --mem 8G --disk 50G 22.04
# Enter the VM shell
multipass shell monitoring-lab
```

```bash
# Generate a new SSH key pair
ssh-keygen -t ed25519 -C "zabbix-lab-key"

# Follow the prompts to save the key to a specific location or use the default
# You can set a passphrase or leave it empty for ease of use in the lab

# Copy your public key to the VM through Multipass
multipass exec monitoring-lab -- bash -c "mkdir -p ~/.ssh && echo '$(cat ~/.ssh/id_ed25519.pub)' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
