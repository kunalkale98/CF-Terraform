#!/bin/bash
cd /
cd new_chatapp/fundoo/fundoo
sudo echo > .env
sudo echo "DB_PORT = '3306'" >> .env
sudo echo "DB_HOST = 'terraform-20210602061950686900000001.cxg414qacf1o.us-east-1.rds.amazonaws.com'" >> .env
sudo echo "DB_USER = 'kunal'" >> .env
sudo echo "DB_PASS = 'Kunal2898'" >> .env
sudo echo "DB_NAME = 'chatappDB'" >> .env
sudo systemctl restart chatapp.service