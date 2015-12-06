#!/bin/bash



ENV_PATH=/etc/container_environment
ENV_CONFIG_FILE=/tmp/env.conf
ENV_FILE=/etc/profile.d/app-env.sh

if [[ ! -d ${ENV_PATH} ]]; then
    echo "${release} dir not there so will not be able to configure optional configurations"
mkdir /etc/container_environment
fi

touch $ENV_FILE
chmod 755 $ENV_FILE
echo "#!/bin/bash" > $ENV_FILE

while read line
do
    env=$line
    echo "export "$env >> $ENV_FILE
    envArray=(${env//=/ })
    echo ${envArray[1]} > ${ENV_PATH}/${envArray[0]}
done < $ENV_CONFIG_FILE



