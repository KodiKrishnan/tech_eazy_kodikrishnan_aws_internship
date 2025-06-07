#!/bin/bash
sudo apt update -y
sudo apt install -y curl unzip git maven -y

# Install Java 21 (from PPA)
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo apt update -y
sudo apt install -y openjdk-21-jdk

# Set JAVA_HOME
echo "export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64" >> /etc/profile
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile
source /etc/profile

# Clone the repo
cd /home/ubuntu
git clone https://github.com/techeazy-consulting/techeazy-devops.git
cd techeazy-devops

# Build the project
mvn clean package

# Find and run the built JAR
JAR_FILE=$(find target -name "*.jar" | head -n 1)
nohup java -jar "$JAR_FILE" > /var/log/app.log 2>&1 &


sleep 10
# Check if the app is running and accessible on port 80
APP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
if [ "$APP_STATUS" = "200" ]; then
    echo "Application started successfully and is accessible on port 80."
    # Schedule shutdown in 15 minutes (900 seconds) in the background
    (sleep 900; sudo shutdown -h now) &
else
    echo "Application failed to start or is not accessible on port 80."
fi