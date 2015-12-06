# === 0 ===
FROM phusion/passenger-ruby19:0.9.14
MAINTAINER nikhil.vs "nikhil.vs@monitoreverywhere.com"

# === 1 ===
# Set correct environment variables.
ENV HOME /root
ENV USER root
ENV WEBAPP_HOME /home/app/api-server
ENV DOWNLOAD_TOKEN 8e48674ef641f89d2f7ad0468d3b1a3d74c446be123e1942fd05692dbc1a161f

# === 2 ===
# Update software repo for latest apps
RUN apt-get update -y && \
    apt-get install curl unzip libwww-perl libcrypt-ssleay-perl -y && \
    apt-get install libswitch-perl -y 

# === 3 ===
# Install new relic app
RUN sh -c 'echo deb http://apt.newrelic.com/debian/ newrelic non-free >> /etc/apt/sources.list.d/newrelic.list' && \
    curl -o key https://download.newrelic.com/548C16BF.gpg && \
    apt-key add key && \
    apt-get update -y && \
    apt-get install newrelic-sysmond -y 
    
# === 4 ===
# Install phusion passenger server
RUN echo "******************************passenger production setup***************************"
ADD ./server-config/production/passenger-enterprise-license-cloud /etc/passenger-enterprise-license
RUN echo deb https://download:$DOWNLOAD_TOKEN@www.phusionpassenger.com/enterprise_apt trusty main > /etc/apt/sources.list.d/passenger.list
#RUN apt-get update && apt-get install -y passenger-enterprise 
RUN apt-get update && apt-get remove -y nginx-extras && apt-get install -y passenger-enterprise nginx-extras
RUN echo "***********************************************************************************"



# === 5 ===
# Start Nginx / Passenger & Remove the default site
RUN rm -f /etc/service/nginx/down && rm /etc/nginx/sites-enabled/default


# === 6 =====
# Configure nginx and passenger accordingly for our app
ADD server-config/production/nginx.conf /etc/nginx/nginx.conf
ADD server-config/production/api-server.conf /etc/nginx/sites-enabled/api-server.conf

# === 7 ===
# Prepare folders for app and certificates
RUN mkdir $WEBAPP_HOME && mkdir /crt && mkdir -p /opt/aws-scripts-mon 
ADD ./server-config/production/aws-scripts-mon/ /opt/aws-scripts-mon/
ADD ./server-config/production/newrelic/nrsysmond.cfg /etc/newrelic/
ADD ./server-config/production/crt/ /crt/
ADD ./server-config/production/newrelic/start-newrelic.sh /etc/rc.local
ADD ./server-config/production/memory-cloudwatch-crontab.cron /tmp/cronentry
RUN crontab /tmp/cronentry


# === 8 ===
# Add the rails app 
ADD . $WEBAPP_HOME
WORKDIR $WEBAPP_HOME
RUN  bundle install --path vendor/cache  && \
     bundle pack
     
RUN  mkdir $WEBAPP_HOME/log -p && \
     mkdir $WEBAPP_HOME/tmp/cache -p && \
     touch $WEBAPP_HOME/log/production.log && \
     touch $WEBAPP_HOME/log/newrelic_agent.log && \
     touch $WEBAPP_HOME/log/passenger.log && \
     touch $WEBAPP_HOME/log/development.log && \
     cd /var/log/nginx && ln -s  $WEBAPP_HOME/log api-server && \
     chmod 777 $WEBAPP_HOME/log -R  && \
     chmod 777 $WEBAPP_HOME/tmp -R && \
     chown app:app /tmp  -R && \
     chown app:app /home/app  -R



# === 9 ===
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# === 10 ===
# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# === 11 ===
# Expose api server service ports
EXPOSE 80 443

ADD ./server-config/production/docker.pub /tmp/docker.pub
RUN cat /tmp/docker.pub >> /root/.ssh/authorized_keys && rm -f /tmp/docker.pub


