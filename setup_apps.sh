#!/bin/bash
sudo su
yum update -y
yum install -y httpd git
cd /var/www/html
#git clone https://github.com/sheikh76/ansible_slide.git
git clone https://github.com/sheikh76/terraform_slide.git
cp -r terraform_slide/* /var/www/html/
rm -rf terraform_slide
systemctl enable httpd 
systemctl start httpd
