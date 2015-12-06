#!/bin/sh

/etc/init.d/newrelic-sysmond start
cd $WEBAPP_HOME && bundle exec rake db:migrate && bundle exec rake db:seed && chown app:app /home/app  -R
