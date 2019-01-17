#!/bin/bash
eval $(cat ../.env | sed 's/^/export /')
export AWS_CONFIG_FILE="/home/web/.aws/config"
SITE="${DB_USER//_/.}"
ENVIRONMENT="$WP_ENV"
TIMESTAMP=`env TZ=Europe/Madrid date +%Y-%m-%d-%H%M`
ARCHIVE_PATH=/tmp/$SITE-$ENVIRONMENT-$TIMESTAMP
ARCHIVE_FILENAME=$SITE-$ENVIRONMENT-$TIMESTAMP.tar.gz
mkdir -p $ARCHIVE_PATH &&
cd /srv/www/$SITE/current && wp db export $ARCHIVE_PATH/db.sql &&
rsync -kavzP --exclude web/wp/ --exclude web/wp-config.php /srv/www/$SITE/current/web $ARCHIVE_PATH &&
rsync -kavzP /srv/www/$SITE/shared/uploads $ARCHIVE_PATH/web/app &&
tar -C $ARCHIVE_PATH -czf /tmp/$ARCHIVE_FILENAME . &&
/usr/local/bin/aws s3 cp /tmp/$ARCHIVE_FILENAME s3://wp-451/$SITE/$ARCHIVE_FILENAME &&
rm -rf $ARCHIVE_PATH &&
rm /tmp/$ARCHIVE_FILENAME
