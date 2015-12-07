#!/bin/bash
APP_NAME=api-server
CODELOCATION="/home/ubuntu/$APP_NAME/"
SCRIPTLOCATION="/home/ubuntu/$APP_NAME/script/"
#TCP_PORT=2000

chmod 775 $CODELOCATION -R
chown ubuntu. $CODELOCATION -R
mkdir -p $CODELOCATION/log $CODELOCATION/tmp
chmod 777 $CODELOCATION/log/ -R
chmod 777 $CODELOCATION/tmp/ -R
su ubuntu -c "cd $CODELOCATION/;bundle install"

######################Setting Application Enviroment Variables##############################
ENV_CONFIG_FILE=$SCRIPTLOCATION/env.conf
ENV_FILE=/etc/profile.d/$APP_NAME.sh
truncate -s 0 $ENV_FILE
touch $ENV_FILE
chmod 755 $ENV_FILE
echo "#!/bin/bash" > $ENV_FILE

while read line
do
   env=$line
   echo "export "$env >> $ENV_FILE
   envArray=(${env//=/ })
done < $ENV_CONFIG_FILE
###########################################END##############################################

/etc/init.d/nginx restart &
#passenger-config restart-app /home/ubuntu/$APP_NAME/
#fuser $TCP_PORT/tcp -k
#sleep 1
#cd $CODELOCATION/;nohup ruby tcp_server_control.rb  run & 2>&1
exit 0
