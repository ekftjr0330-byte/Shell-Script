#!/bin/bash

REGION_CODE="ap-northeast-2"
SECRET_NAME="apdev-rds-secrets"

SECRET=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --query "SecretString" --output text --region "$REGION_CODE")

MYSQL_USER=$(echo "$SECRET" | jq -r '.MYSQL_USER')
MYSQL_PASSWORD=$(echo "$SECRET" | jq -r '.MYSQL_PASSWORD')
MYSQL_HOST=$(echo "$SECRET" | jq -r '.MYSQL_HOST')
MYSQL_PORT=$(echo "$SECRET" | jq -r '.MYSQL_PORT')
MYSQL_DBNAME=$(echo "$SECRET" | jq -r '.MYSQL_DBNAME')

while :
do
    mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -P "$MYSQL_PORT" -p"$MYSQL_PASSWORD" -D "$MYSQL_DBNAME" -N -B -e "SELECT CONCAT('KILL ', ID, ';') FROM information_schema.PROCESSLIST WHERE COMMAND='Sleep' AND TIME>=300 AND USER NOT LIKE '%rds%' AND USER NOT LIKE '%event_scheduler%';" > /tmp/kill.txt

    if [ -s /tmp/kill.txt ]; then
        mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -P "$MYSQL_PORT" -p"$MYSQL_PASSWORD" -D "$MYSQL_DBNAME" < /tmp/kill.txt
    fi

    sleep 60
done