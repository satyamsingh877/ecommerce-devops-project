#!/bin/bash
echo "Installing SonarQube..."
sudo apt-get update
sudo apt-get install -y unzip
sudo docker pull sonarqube:lts
sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:lts
echo "SonarQube installed and running on port 9000"
