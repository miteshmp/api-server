# === 0 ===

FROM hubbleconnected/api-server-base:c3-large-phusion4.x-1.0.0

MAINTAINER nikhil.vs "nikhil.vs@monitoreverywhere.com"

# ==== 1 ====
# Add config to profile
ADD server-config/integration/export-env.sh /tmp/export-env.sh
ADD server-config/integration/env.conf /tmp/env.conf
RUN chmod 755 /tmp/export-env.sh && /tmp/export-env.sh


# === 2 ===
# Add the rails app 
ADD . $WEBAPP_HOME
WORKDIR $WEBAPP_HOME
RUN  bundle install --path vendor/cache  && \
     bundle pack && \
     mkdir $WEBAPP_HOME/log -p && \
     mkdir $WEBAPP_HOME/tmp/cache -p && \
     touch $WEBAPP_HOME/log/production.log && \
     touch $WEBAPP_HOME/log/newrelic_agent.log && \
     touch $WEBAPP_HOME/log/passenger.log && \
     touch $WEBAPP_HOME/log/development.log && \
     cd /var/log/nginx && ln -s  $WEBAPP_HOME/log api-server && \
     chmod 777 $WEBAPP_HOME/log -R  && \
     chmod 777 $WEBAPP_HOME/tmp -R && \
     chown app:app /tmp  -R && \
     chown app:app /home/app  -R && \
     cd $WEBAPP_HOME && bundle exec whenever -i

