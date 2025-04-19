# Lab 1: Simple Linux Logging Lab
## Introduction to Linux Logging

This lab will guide you through the basics of Linux logging using just a single Linux machine (Ubuntu recommended). Each section builds on the previous one, with clear steps and examples.

## Lab Setup

### VM Requirements
- **Operating System**: Ubuntu Server 22.04 LTS (recommended)
- **Memory**: 1GB RAM minimum
- **Disk Space**: 10GB
- **CPU**: 1 virtual CPU
- **Network**: Basic NAT networking or Bridge

You can use any virtualization software:
- VirtualBox (free, works on Windows/Mac/Linux), WSL2 or Multipass

### Requirements
- One Linux machine (physical or virtual) with Ubuntu
- Basic command-line knowledge
- A text editor (like nano or vim)

### Software Installation
```bash
# Update your system's package lists to get information about newest versions
sudo apt update

# Upgrade all installed packages to their latest versions
sudo apt upgrade -y
# The -y flag automatically answers "yes" to prompts

# Install necessary packages for this lab
sudo apt install -y rsyslog logrotate python3-pip python3-venv
# rsyslog: System logging daemon
# logrotate: Log file management utility
# python3-pip: Python package manager
# python3-venv: Python virtual environment creator

# Check that rsyslog service is active and running
systemctl status rsyslog
# This shows the current status, run time, and recent logs

# Verify logrotate is installed and check its version
logrotate --version
# Shows the version number of the installed logrotate
```

## Part 1: Understanding Linux Logs (15 minutes)

### Exploring Log Files
```bash
# View the main system log file with pagination (allows scrolling)
sudo less /var/log/syslog
# Keys to navigate: Space (next page), b (back page), q (quit)
# The sudo command gives you elevated permissions needed to access log files

# View authentication logs (login attempts, sudo usage, etc.)
sudo less /var/log/auth.log
# These logs track all authentication events on your system

# View kernel logs (hardware events, driver messages, etc.)
sudo dmesg | less
# dmesg displays kernel ring buffer messages
# The | (pipe) symbol sends the output to the 'less' command for pagination
```

### Understanding Log Format
Most Linux log entries follow this pattern:
```
timestamp hostname process[PID]: message
```

For example:
```
Mar 7 10:15:30 ubuntu-server sshd[12345]: Accepted password for user from 192.168.1.10
```

### Using Log Commands
```bash
# View the last 10 lines of a log file
tail /var/log/syslog
# 'tail' displays the end of a file - useful for seeing recent entries

# View logs in real-time (continuously updates as new logs arrive)
tail -f /var/log/syslog
# The -f flag means "follow" - it keeps the display updated
# Press Ctrl+C to exit

# Search for specific terms in log files
grep "error" /var/log/syslog
# 'grep' searches for patterns in text
# This command finds all lines containing the word "error"

# See logs from today only
grep "$(date '+%b %d')" /var/log/syslog
# $(date '+%b %d') executes the date command to get current month and day
# Result would look like "Mar 7" which is then used in the search
```

## Part 2: Creating Your Own Logs (15 minutes)

### Using logger Command
The `logger` command lets you create your own log entries:

```bash
# Create a simple log message that goes to syslog
logger "This is a test log message"
# The 'logger' command sends messages to the system logging facility
# By default, messages go to /var/log/syslog

# Check where your message appeared by searching for it
grep "test log message" /var/log/syslog
# This searches for your exact message in the syslog file

# Log with priority (facility.severity)
logger -p auth.notice "User action performed"
# The -p flag specifies the priority level
# 'auth.notice' means it's an authentication message with 'notice' severity
# This message will go to both syslog and auth.log

# Verify it went to the auth log
grep "User action performed" /var/log/auth.log
# This confirms your message was recorded in the authentication log
```

### Common Priority Levels
- **Facilities**: auth, cron, daemon, kern, user, local0-local7
  *(Facilities determine which subsystem the message belongs to)*
- **Severities**: emerg, alert, crit, err, warning, notice, info, debug
  *(Severities indicate how important the message is, from emergency to debug)*

### Writing a Simple Log Script
```bash
# Create a log generator script
cat << 'EOF' > ~/log-generator.sh
#!/bin/bash
echo "Starting log generator..."
count=1
while [ $count -le 10 ]; do
    logger "Test log #$count: Generated at $(date)"
    echo "Generated log #$count"
    count=$((count+1))
    sleep 2
done
echo "Log generation complete."
EOF
# The 'cat << EOF > file' syntax creates a file with multiple lines
# This creates a bash script that will generate 10 log entries
# The script waits 2 seconds between each log entry

# Make the script executable
chmod +x ~/log-generator.sh
# The chmod command changes file permissions
# +x adds executable permission so you can run the script

# Run the script
~/log-generator.sh
# This executes your script, which will generate 10 log entries
# You'll see "Generated log #X" printed to the console

# Check the logs it created in syslog
grep "Test log #" /var/log/syslog
# This searches for all the "Test log #" entries your script created
```

## Part 3: Basic rsyslog Configuration (20 minutes)

### Understanding rsyslog Configuration
The main rsyslog configuration file is `/etc/rsyslog.conf`, with additional configs in `/etc/rsyslog.d/`.

```bash
# Create a backup before making changes (always a good practice)
sudo cp /etc/rsyslog.conf /etc/rsyslog.conf.bak
# This creates a backup copy of the original configuration file
# If something goes wrong, you can restore from this backup

# View current configuration
less /etc/rsyslog.conf
# This shows the main rsyslog configuration file
# Look for sections like 'modules', 'global directives', and 'rules'
```

### Creating Custom Log Files
Let's create a configuration to send certain logs to a custom file:

```bash
# Create a new config file in the rsyslog.d directory
sudo nano /etc/rsyslog.d/custom.conf
# 'nano' is a simple text editor (use Ctrl+O to save, Ctrl+X to exit)
# Files in rsyslog.d/ are automatically included in the main configuration

# Add these lines to the file:
# Send all logger messages with local6 facility to a custom file
local6.* /var/log/custom.log
# This rule will capture all messages with the 'local6' facility
# The '*' means all severity levels
# Messages matching this will be written to /var/log/custom.log

# Save and exit (Ctrl+O, Enter, Ctrl+X in nano)

# Restart rsyslog to apply changes
sudo systemctl restart rsyslog
# systemctl manages system services
# This restarts the rsyslog service to load your new configuration

# Create the log file with correct permissions
sudo touch /var/log/custom.log
# 'touch' creates an empty file if it doesn't exist

sudo chmod 640 /var/log/custom.log
# Sets permissions to: owner can read/write, group can read, others no access
# 6 (rw-) for owner, 4 (r--) for group, 0 (---) for others
```

### Test Custom Log Configuration
```bash
# Send a log to our custom facility
logger -p local6.info "This should go to the custom log file"
# The -p local6.info specifies the facility.severity
# This message should be routed to our custom log file

# Check if it worked
sudo tail /var/log/custom.log
# This displays the last few lines of the custom log file
# You should see your message there
```

## Part 4: Log Rotation (15 minutes)

### Understanding Log Rotation
Over time, log files grow and need to be managed. Linux uses logrotate to handle this.

```bash
# View the main logrotate configuration
less /etc/logrotate.conf
# This displays the global settings for log rotation
# It defines how often logs rotate and other default behaviors

# View specific service configurations
ls -l /etc/logrotate.d/
# Lists all the logrotate configuration files for specific services
# Each file contains rotation settings for different log files
```

### Create a Custom Log Rotation Configuration
```bash
# Create a config for our custom log
sudo nano /etc/logrotate.d/custom
# This creates a new logrotate configuration file for our custom log

# Add these lines to the file:
/var/log/custom.log {
    daily                # Rotate the log file daily
    rotate 7             # Keep 7 old copies (1 week worth)
    compress             # Compress old log files
    delaycompress        # Don't compress the most recent old file
    missingok            # Don't error if the log file is missing
    notifempty           # Don't rotate empty files
    create 640 syslog adm  # Create new files with these permissions/ownership
}
# Each setting affects how the log files are managed:
# 'daily' means rotate every day
# 'rotate 7' keeps one week of logs before deleting
# 'compress' saves space by gzipping old logs
# 'create 640 syslog adm' ensures proper permissions on new files

# Save and exit
```

### Testing Log Rotation
```bash
# Force a log rotation (dry run)
sudo logrotate -d /etc/logrotate.d/custom
# The -d flag means "debug" - it shows what would happen without making changes
# This is useful to verify your configuration is correct

# Actually force a rotation
sudo logrotate -f /etc/logrotate.d/custom
# The -f flag forces a rotation regardless of rotation criteria
# This immediately applies your rotation rules to test them

# Check if it worked
ls -l /var/log/custom*
# Lists all files matching the custom log pattern
# You should see your original log and possibly a rotated version
# Rotated logs will have extensions like .1, .2.gz, etc.
```

## Part 5: Practical Exercises (15 minutes)

### Exercise 1: Filtering Logs
```bash
# Find all SSH login attempts
grep "sshd" /var/log/auth.log | grep "Accepted"
# First 'grep' finds all lines containing "sshd" in auth.log
# The pipe (|) sends those results to a second 'grep' for "Accepted"
# This shows only successful SSH logins

# Count error messages in syslog
grep -c "error" /var/log/syslog
# The -c flag counts matching lines instead of displaying them
# This gives you a total number of errors without showing each one

# Find all actions by a specific process
grep "systemd" /var/log/syslog | head -n 20
# Finds all lines containing "systemd" in syslog
# The pipe to 'head -n 20' shows only the first 20 matches
# This prevents overwhelming your terminal with too many results
```

### Exercise 2: Creating a System Report
Create a simple script to report system events:

```bash
cat << 'EOF' > ~/system-report.sh
#!/bin/bash
echo "=== System Log Summary ==="
echo "Date: $(date)"
echo ""

echo "1. Recent Authentication Events:"
sudo grep "$(date '+%b %d')" /var/log/auth.log | tail -n 10
echo ""

echo "2. System Errors Today:"
sudo grep "error" /var/log/syslog | grep "$(date '+%b %d')" | wc -l
echo ""

echo "3. Kernel Messages:"
sudo dmesg | tail -n 5
echo ""

echo "=== End of Report ==="
EOF
# This creates a bash script that:
# - Shows the 10 most recent authentication events from today
# - Counts system errors that occurred today
# - Displays the 5 most recent kernel messages

chmod +x ~/system-report.sh
# Makes the script executable

./system-report.sh
# Runs the script to generate a basic system report
```

## Part 6: Understanding Log File Permissions (15 minutes)

### Default Log Permissions
Log files in Linux typically have specific permissions to balance security and functionality:

```bash
# Check permissions on standard log files
ls -l /var/log/syslog
# Lists file details including permissions, owner, group, size and date
# The -l flag means "long format" showing detailed information

ls -l /var/log/auth.log
# Similarly shows details for the authentication log file

# You should see something like:
# -rw-r----- 1 syslog adm 12345 Mar 7 10:15 /var/log/syslog
# This shows: permissions, links, owner, group, size, date, and filename
```

### Understanding Log Permissions
The typical permission structure is:
- **Owner**: syslog (system user that writes logs)
- **Group**: adm (administrator group that can read logs)
- **Permissions**: 640 (rw-r-----)
  - Owner can read and write (rw-)
  - Group can read only (r--)
  - Others have no access (---)

### Managing Log File Permissions
```bash
# Set correct permissions on our custom log
sudo chown syslog:adm /var/log/custom.log
# Changes the owner to "syslog" and the group to "adm"
# This matches the standard log file ownership

sudo chmod 640 /var/log/custom.log
# Sets file permissions to 640 (rw-r-----)
# This allows the syslog service to write to it and admins to read it

# For logs that might contain sensitive information
sudo chmod 600 /var/log/custom.log  # Owner only access
# 600 means only the owner (syslog) can read/write the file
# This is more restrictive for very sensitive logs

# For logs that need to be readable by a specific application
sudo usermod -a -G adm myappuser  # Add user to adm group
# Adds the user "myappuser" to the "adm" group
# -a means "append" and -G specifies the group
# This gives the application running as "myappuser" read access to log files
```

### Security Best Practices
- Never make log files world-readable (chmod o+r)
- Use groups to manage access instead of modifying user permissions
- Regularly audit log permissions with: `find /var/log -type f -ls`
  *(This command finds all files in /var/log and lists their details)*

## Part 7: Web Application Logging with Flask (30 minutes)

### Setup Flask Project
Let's create a simple Flask application that demonstrates logging:

```bash
# Create a project directory
mkdir -p ~/flask-logging-demo
# Creates a directory for our Flask project
# The -p flag creates parent directories if they don't exist

cd ~/flask-logging-demo
# Change to the project directory

# Set up a Python virtual environment
python3 -m venv venv
# Creates a virtual environment named "venv"
# Virtual environments isolate Python dependencies for different projects

source venv/bin/activate
# Activates the virtual environment
# Your prompt should change to show (venv) at the beginning

# Install Flask and logging libraries
pip install flask python-json-logger
# Installs the required Python packages:
# - flask: Web framework for building the application
# - python-json-logger: Library for JSON-formatted logging
```

### Create a Flask Application with Logging
Create an app file:

```bash
cat << 'EOF' > ~/flask-logging-demo/app.py
from flask import Flask, request, jsonify
import logging
import os
from pythonjsonlogger import jsonlogger
import time

# Ensure log directory exists
os.makedirs('logs', exist_ok=True)

# Set up basic logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    filename='logs/app.log'
)

# Setup JSON logger for structured logging
logHandler = logging.FileHandler('logs/app_json.log')
formatter = jsonlogger.JsonFormatter('%(timestamp)s %(level)s %(name)s %(message)s')
logHandler.setFormatter(formatter)

# Get the logger
logger = logging.getLogger('flask-demo')
logger.addHandler(logHandler)
logger.setLevel(logging.INFO)

# Create Flask app
app = Flask(__name__)

@app.route('/')
def home():
    logger.info('Home page accessed', extra={
        'remote_addr': request.remote_addr,
        'user_agent': request.user_agent.string
    })
    return "Hello! Check the logs to see this request."

@app.route('/error')
def error():
    try:
        # Simulate an error
        result = 1 / 0
    except Exception as e:
        logger.error('An error occurred', extra={
            'error': str(e),
            'remote_addr': request.remote_addr
        })
        return "Error triggered! Check the logs."

@app.route('/warning')
def warning():
    logger.warning('This is a warning log', extra={
        'warning_time': time.time(),
        'remote_addr': request.remote_addr
    })
    return "Warning logged!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF
# This creates a Flask application with:
# - Basic file logging configuration to logs/app.log
# - JSON-formatted structured logging to logs/app_json.log
# - Three endpoints that generate different types of log entries
```

### Run the Flask Application

```bash
# Make sure you're in the project directory with the virtual environment activated
cd ~/flask-logging-demo
source venv/bin/activate
# Ensures you're in the right directory with the virtual env active

# Run the app
python app.py
# Starts the Flask application
# The server will run on port 5000 and listen on all interfaces (0.0.0.0)
```

### Test the Flask Application
In a new terminal, use curl to test the endpoints:

```bash
# Access the home page
curl http://localhost:5000/
# Makes an HTTP request to the root endpoint
# This will trigger the info-level log

# Trigger a warning
curl http://localhost:5000/warning
# Accesses the /warning endpoint
# This will create a warning-level log entry

# Trigger an error
curl http://localhost:5000/error
# Accesses the /error endpoint
# This will create an error-level log by attempting division by zero
```

### Examine the Generated Logs
```bash
# View the standard log
cat ~/flask-logging-demo/logs/app.log
# Displays the content of the standard log file
# Shows logs in the format: timestamp - name - level - message

# View the JSON-formatted log
cat ~/flask-logging-demo/logs/app_json.log
# Shows the structured JSON logs
# Each log entry is a complete JSON object with fields for all log details
```

### Configure rsyslog to Monitor Flask Logs
Let's set up rsyslog to monitor our Flask application logs:

```bash
# Create a new rsyslog config
sudo nano /etc/rsyslog.d/flask-app.conf
# Creates a new rsyslog configuration file specifically for our Flask app

# Add this content:
input(type="imfile"
      File="/home/youruser/flask-logging-demo/logs/app.log"
      Tag="flask-app:"
      Severity="info"
      Facility="local5")

local5.* /var/log/flask-app.log
# This configuration:
# - Uses the "imfile" input module to monitor a file
# - Sets the file path to our Flask app's log file
# - Adds a "flask-app:" tag to all entries from this file
# - Sets default severity to "info" and facility to "local5"
# - Routes all local5 facility messages to /var/log/flask-app.log

# Save and exit

# Create the log file with proper permissions
sudo touch /var/log/flask-app.log
# Creates the log file if it doesn't exist

sudo chown syslog:adm /var/log/flask-app.log
# Sets the proper ownership (syslog user, adm group)

sudo chmod 640 /var/log/flask-app.log
# Sets permissions to allow syslog to write, admins to read

# Restart rsyslog
sudo systemctl restart rsyslog
# Applies the new configuration by restarting the service
```

Now your Flask application logs will also be available in the system log files! occurred', extra={
            'error': str(e),
            'remote_addr': request.remote_addr
        })
        return "Error triggered! Check the logs."

@app.route('/warning')
def warning():
    logger.warning('This is a warning log', extra={
        'warning_time': time.time(),
        'remote_addr': request.remote_addr
    })
    return "Warning logged!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF
```

### Run the Flask Application

```bash
# Make sure you're in the project directory with the virtual environment activated
cd ~/flask-logging-demo
source venv/bin/activate

# Run the app
python app.py
```

### Test the Flask Application
In a new terminal, use curl to test the endpoints:

```bash
# Access the home page
curl http://localhost:5000/

# Trigger a warning
curl http://localhost:5000/warning

# Trigger an error
curl http://localhost:5000/error
```

### Examine the Generated Logs
```bash
# View the standard log
cat ~/flask-logging-demo/logs/app.log

# View the JSON-formatted log
cat ~/flask-logging-demo/logs/app_json.log
```

### Configure rsyslog to Monitor Flask Logs
Let's set up rsyslog to monitor our Flask application logs:

```bash
# Create a new rsyslog config
sudo nano /etc/rsyslog.d/flask-app.conf

# Add this content:
input(type="imfile"
      File="/home/youruser/flask-logging-demo/logs/app.log"
      Tag="flask-app:"
      Severity="info"
      Facility="local5")

local5.* /var/log/flask-app.log

# Save and exit

# Create the log file with proper permissions
sudo touch /var/log/flask-app.log
sudo chown syslog:adm /var/log/flask-app.log
sudo chmod 640 /var/log/flask-app.log

# Restart rsyslog
sudo systemctl restart rsyslog
```

Now your Flask application logs will also be available in the system log files!

### Troubleshooting Tips
1. If logs aren't appearing where expected:
   ```bash
   sudo systemctl restart rsyslog
   ```

2. If permission issues occur:
   ```bash
   sudo chmod 640 /var/log/custom.log
   sudo chown syslog:adm /var/log/custom.log
   ```

3. To check rsyslog status:
   ```bash
   sudo journalctl -u rsyslog
   ```

4. Flask app isn't writing logs:
   ```bash
   # Check directory permissions
   ls -la ~/flask-logging-demo/logs/
   # Make sure it's writable by your user
   ```
