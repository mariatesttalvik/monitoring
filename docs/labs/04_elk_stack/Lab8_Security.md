# Lab 8: Elasticsearch Security

### 1. Security Health Check
First, let's check the overall security status:
```bash
GET /_security/health
```
This shows if security features are properly enabled.

### 2. User Management
Create a test user with limited permissions:
```json
POST /_security/user/test_analyst
{
  "password": "secure_password123",
  "roles": ["kibana_read_only"],
  "full_name": "Test Analyst"
}
```

### 3. Role Inspection
Review existing roles and their permissions:
```bash
GET /_security/role
```

Create a custom role for logs access:
```json
POST /_security/role/logs_viewer
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["logs-*"],
      "privileges": ["read"],
      "field_security": {
        "grant": ["timestamp", "message", "level"]
      }
    }
  ]
}
```

### 4. Certificate Check
Verify SSL certificates status:
```bash
GET /_ssl/certificates
```

### 5. Audit Log Test
Make some test requests and check the audit log:
```yaml
# In elasticsearch.yml
xpack.security.audit.enabled: true
xpack.security.audit.logfile.events.include: ["authentication_success", "authentication_failure", "access_denied"]
```

### Verification Tasks
1. Try logging in with the new test user
2. Attempt to access an unauthorized index
3. Check audit logs for these actions
4. Verify TLS connection is working

### Cleanup
Remove test user when done:
```bash
DELETE /_security/user/test_analyst
```
