The set up a **single Multipass node** and simulate a **multi-node Elasticsearch cluster** on it using Docker. This approach is perfect for a test lab environment. Here's how to do it step-by-step:

---

## **1. Create a Multipass Node**

### **Step 1.1: Launch a Multipass Instance**
Run this command to create a VM with sufficient resources:
```bash
multipass launch -n elastic-node --cpus 4 --mem 4G --disk 20G
```

### **Step 1.2: Access the Node**
```bash
multipass shell elastic-node
```

---

## **2. Prepare the Multipass Node**

### **Step 2.1: Update and Install Docker**
1. Update packages:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. Install Docker:
   ```bash
   sudo apt install -y docker.io
   ```

3. Verify Docker installation:
   ```bash
   docker --version
   ```

4. Allow your user to run Docker commands without `sudo`:
   ```bash
   sudo usermod -aG docker $USER
   ```
   Log out and back in for this to take effect.

5. Install Docker Compose:
   ```bash
   sudo apt install -y docker-compose
   ```

6. Verify Docker Compose installation:
   ```bash
   docker-compose --version
   ```

