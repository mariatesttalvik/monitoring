### Guide to Certificates, Keystore, Truststore, and CA

### 1. Introduction
Digital certificates are a key element in ensuring security when using Elastic Stack. They are used for:
- Data encryption (SSL/TLS).
- Authentication of servers and nodes in the cluster.
- Establishing trust between network participants.

This guide covers:
- CA certificates and how they differ from regular certificates.
- Using keystore and truststore.
- Certificate generation, renewal, and replacement.
- Best practices.

---

### 2. What Are Certificates?

#### 2.1 Certificate Components
- **Private Key**: Used to encrypt data.
- **Public Key**: Used to decrypt data.
- **Digital Signature**: Confirms the authenticity of the certificate.
- **Validity Period**: Limits the duration for which the certificate is valid.

#### 2.2 Digital Signature
A digital signature is used to verify the authenticity of a certificate. It is created based on certificate data and the private key of the certificate issuer (e.g., CA).

**Example of a digital signature in a certificate:**
```
Signature Algorithm: sha256WithRSAEncryption
    45:bd:1e:ab:c4:12:3f:55:8f:9a:2d:3c:76:91:0f:43:1e:0a:
    b4:91:e7:88:5f:e2:1b:33:87:5d:bc:91:8c:7f:b2:0e:3d:84:
    44:8b:cc:91:ff:55:6d:ee:67:91:10:3a:12:4b:3a:29:83
```
- **Signature Algorithm**: Specifies the algorithm used for creating the signature (e.g., `sha256WithRSAEncryption`).
- **Signature**: The encrypted hash of the certificate data, created using the issuer’s private key.

The signature is verified using the issuer’s public key, ensuring the certificate’s authenticity and integrity.

---

### 3. Keystore and Truststore

#### 3.1 Keystore
- Stores private keys and certificates.
- Used to enable a server to authenticate itself.

#### 3.2 Truststore
- Stores trusted CA certificates.
- Used to verify certificates of other servers or nodes.

#### Formats:
- **PKCS#12 (`.p12`)**: A universal format supporting both keystore and truststore.
- **Java Keystore (`.jks`)**: Used in Java applications.

---

### 4. Generating Certificates

#### 4.1 Creating a CA
```bash
# Generate the CA private key
openssl genrsa -out rootCA.key 2048

# Create a self-signed certificate
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt \
  -subj "/CN=RootCA"
```

#### 4.2 Generating a Server Certificate
```bash
# Generate the server’s private key
openssl genrsa -out server.key 2048

# Create a CSR (Certificate Signing Request)
openssl req -new -key server.key -out server.csr -subj "/CN=example.com"

# Sign the server certificate with the CA
openssl x509 -req -in server.csr -CA rootCA.crt -CAkey rootCA.key \
  -CAcreateserial -out server.crt -days 365 -sha256
```

#### 4.3 Generating Certificates with elasticsearch-certutil
```bash
# Generate a CA
elasticsearch-certutil ca --pem --out ca.zip

# Generate node certificates
elasticsearch-certutil cert --ca ca/ca.crt --ca-key ca/ca.key --pem --out node-certificates.zip
```

---

### 5. Replacing Certificates

#### 5.1 Can You Keep Both Certificates in the Store?
Yes, you can keep both certificates (old and new) in the same keystore or truststore. This allows for a smooth transition, as clients using the old certificate can continue to function until it expires, while new connections can use the new certificate.

#### 5.2 Steps to Add a New Certificate to an Existing Store:

##### For `.p12` (PKCS#12):
```bash
# Add a new certificate to an existing keystore
openssl pkcs12 -export -in new-cert.crt -inkey new-key.key -certfile ca.crt \
  -out updated-keystore.p12 -password pass:yourpassword
```
This process creates a new `.p12` file containing both certificates. Update the configuration path if necessary.

##### For `.jks` (Java Keystore):
```bash
# Add a new certificate to the truststore
keytool -import -trustcacerts -file new-cert.crt -alias new-cert \
  -keystore truststore.jks -storepass yourpassword

# Check the contents of the store
keytool -list -keystore truststore.jks -storepass yourpassword
```

#### 5.3 Removing Old Certificates (Optional):
After the old certificate expires, you can remove it from the store.
```bash
# Remove a certificate from .jks
keytool -delete -alias old-cert -keystore truststore.jks -storepass yourpassword

# Removing from .p12 requires recreating the store
```

#### 5.4 Restarting Services:
After updating the stores, restart Elastic Stack nodes to apply the changes:
```bash
systemctl restart elasticsearch
```

---

### 6. Internal Use of Certificates

#### 6.1 What Is "Internal Use"?
- Certificates are used within a closed network or organization.
- They do not need to be trusted by external clients.

#### 6.2 Examples:
- **Encrypting data between Elastic Stack nodes** (Transport Layer).
- **Client-server interaction within a network** (e.g., Kibana → Elasticsearch).
- **DevOps Automation** (e.g., Jenkins, Ansible).

#### 6.3 Why Are Self-Signed Certificates Suitable for Internal Use?
- They are free and easy to create.
- Can be used in isolated or secure networks where participants are pre-configured to trust a single CA.

#### 6.4 Configuration for Internal Use:
1. Create a CA:
   ```bash
   elasticsearch-certutil ca --pem --out ca.zip
   ```
2. Generate certificates for nodes:
   ```bash
   elasticsearch-certutil cert --ca ca/ca.crt --ca-key ca/ca.key --pem --out node-certificates.zip
   ```
3. Configure paths to certificates:
   ```yaml
   xpack.security.transport.ssl:
     enabled: true
     verification_mode: certificate
     certificate: /path/to/node.crt
     certificate_authorities: [ "/path/to/ca.crt" ]
     key: /path/to/node.key
   ```

---

### 7. Best Practices

1. **Use Trusted CAs for Public Services**:
   - For example, Let’s Encrypt for services accessible over the internet.

2. **Regularly Update Certificates**:
   - Set reminders for expiration dates.

3. **Restrict Access to Keys and Certificates**:
   - Set proper file permissions (e.g., `chmod 600`).

4. **Test Changes in a Test Environment**:
   - Ensure new certificates work before deploying them.

5. **Protect the CA**:
   - Store the CA private key securely, for example:
     - Locally on a server in a protected directory with `chmod 600`.
     - In dedicated secret management systems like HashiCorp Vault or AWS Secrets Manager.

6. **Automate Certificate Management**:
   - Use scripts or configuration management tools (Ansible, Terraform). Example:

```yaml
- name: Generate a new certificate using OpenSSL
  hosts: all
  tasks:
    - name: Generate a private key
      command: "openssl genrsa -out /etc/certs/server.key 2048"

    - name: Create a CSR
      command: "openssl req -new -key /etc/certs/server.key -out /etc/certs/server.csr -subj '/CN={{ inventory_hostname }}'"

    - name: Sign the certificate
      command: "openssl x509 -req -in /etc/certs/server.csr -CA /etc/certs/ca.crt -CAkey /etc/certs/ca.key -CAcreateserial -out /etc/certs/server.crt -days 365 -sha256"
```

---

### 8. Verifying Certificates

#### View a Certificate:
```bash
openssl x509 -in server.crt -text -noout
```

#### Verify Trust Chain:
```bash
openssl verify -CAfile rootCA.crt server.crt
```

#### Verify CA Chain:
```bash
# Verify the certificate chain
openssl verify -CAfile chain.pem server.crt
```
- **`chain.pem`**: A file containing the complete certificate chain (Root CA and intermediate CAs).
- **`server.crt`**: The certificate you want to verify.

#### Check Contents of a Protected Keystore or Truststore:
- For `.p12`:
  ```bash
  openssl pkcs12 -info -in keystore.p12 -password pass:yourpassword
  ```

- For `.jks`:
  ```bash
  keytool -list -keystore truststore.jks -storepass yourpassword
  ```

---
