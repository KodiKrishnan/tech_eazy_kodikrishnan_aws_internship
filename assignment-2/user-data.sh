#!/bin/bash
set -e

# 1. Update the package index
sudo apt update

# 2. Install dependencies
sudo apt install -y curl unzip git maven software-properties-common

# 3. Download the AWS CLI installer
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# 4. Extract the installer
unzip awscliv2.zip

# 5. Run the installer
sudo ./aws/install

# 6. (Optional) Clean up
rm -rf awscliv2.zip aws

# Install Java 21
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo apt update -y
sudo apt install -y openjdk-21-jdk

# Set JAVA_HOME
echo "export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64" >> /etc/profile
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile
source /etc/profile

# Clone and build the app
cd /home/ubuntu
git clone https://github.com/techeazy-consulting/techeazy-devops.git
cd techeazy-devops
mvn clean package

# Run the app in background
JAR_FILE=$(find target -name "*.jar" | head -n 1)
nohup java -jar "$JAR_FILE" > /var/log/app.log 2>&1 &

# Wait and check if the app is running
sleep 10
APP_STATUS=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost)
if [ "$APP_STATUS" = "200" ]; then
    echo "Application started successfully and is accessible on port 80."
    (sleep 600; sudo shutdown -h now) &
else
    echo "Application failed to start or is not accessible on port 80."
fi

BUCKET_NAME="ec2-logs-kodi-20250610"

cat <<EOF > /usr/local/bin/upload-logs.sh
#!/bin/bash
aws s3 cp /var/log/cloud-init.log s3://$BUCKET_NAME/logs/system/
aws s3 cp /var/log/app.log s3://$BUCKET_NAME/logs/app/
EOF

chmod +x /usr/local/bin/upload-logs.sh

# Systemd service to trigger on shutdown
cat <<EOF > /etc/systemd/system/upload-logs.service
[Unit]
Description=Upload logs to S3 on shutdown
DefaultDependencies=no
Before=shutdown.target
After=network-online.target cloud-init.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/upload-logs.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable upload-logs.service
