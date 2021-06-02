#!/bin/bash 
cd / 
cd etc/nginx/sites-available 
sudo sed -i 's+Internal_ELB_DNS+http://internal-backend-ELB-1628762401.us-east-1.elb.amazonaws.com+g' chatapp 
cd / 
sudo systemctl restart nginx