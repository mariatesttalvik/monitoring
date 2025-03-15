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
