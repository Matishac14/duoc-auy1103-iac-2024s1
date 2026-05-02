#!/bin/bash
amazon-linux-extras install docker -y
service docker start
usermod -aG docker ec2-user
docker run -d -p 80:80 ${image}