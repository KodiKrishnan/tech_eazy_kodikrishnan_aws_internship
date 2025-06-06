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
