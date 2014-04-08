FROM dockerfile/ubuntu

MAINTAINER Mars Hall <mars@substantial.com>

RUN apt-get update && apt-get upgrade

#-----------------------------------------------------------------------
# ssh server install
#-----------------------------------------------------------------------
RUN apt-get install -y openssh-server
ADD etc/ssh/sshd_config /etc/ssh/sshd_config
ADD .ssh/authorized_keys /root/.ssh/authorized_keys
RUN mkdir -p /var/run/sshd
RUN chmod -R 700 /root/.ssh && \
    chown -R root /root/.ssh

#-----------------------------------------------------------------------
# Supervisor install
#-----------------------------------------------------------------------
RUN apt-get install -y supervisor
ADD etc/supervisor/conf.d /etc/supervisor/conf.d

#-----------------------------------------------------------------------
# Redis install
# https://index.docker.io/u/dockerfile/redis/
#-----------------------------------------------------------------------
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:chris-lea/redis-server
RUN apt-get update
RUN apt-get install -y redis-server

# Configure Redis (specifically data dir & mem limit)
ADD etc/redis.conf /etc/redis.conf

# Persist data between containers
VOLUME ["/opt/redis-data"]

#-----------------------------------------------------------------------
# Ruby install
# https://index.docker.io/u/paintedfox/ruby/
#-----------------------------------------------------------------------
# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Install ruby.
# Solution from: http://stackoverflow.com/a/16224372
ADD http://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p451.tar.gz /tmp/
RUN apt-get -y install build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev && \
    tar -xzf /tmp/ruby-2.0.0-p451.tar.gz && \
    (cd ruby-2.0.0-p451/ && ./configure --disable-install-doc && make && make install) && \
    rm -rf ruby-2.0.0-p451/ && \
    rm -f /tmp/ruby-2.0.0-p451.tar.gz

#-----------------------------------------------------------------------
# Rails app 
# http://ilikestuffblog.com/2014/01/06/how-to-skip-bundle-install-when-eploying#-a-rails-app-to-docker/
#-----------------------------------------------------------------------
RUN gem install bundler

# Cache bundle by running install before adding the app itself.
# Installs into the system rubygems instead of vendor/bundle.
WORKDIR /tmp 
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install
WORKDIR /

# Now copy the app into the image.
ADD . /opt/rails_app
# Clear origin's bundle config & cache, so there's
# no confusion with the Docker-cached bundle.
RUN rm -rf /opt/rails_app/.bundle
RUN rm -rf /opt/rails_app/vendor/bundle
# Clear cruft from origin dev environment.
RUN rm -rf /opt/rails_app/log/*
RUN rm -rf /opt/rails_app/tmp/*

#-----------------------------------------------------------------------
# initialize environment
#-----------------------------------------------------------------------
# Set the final working dir to the Rails app's location.
WORKDIR /opt/rails_app

#-----------------------------------------------------------------------
# Container config
#-----------------------------------------------------------------------
CMD ["/usr/bin/supervisord"]
EXPOSE 22 80
