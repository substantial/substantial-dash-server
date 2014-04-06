# Substantial Dash server [![Build Status](https://travis-ci.org/substantial/substantial-dash-server.png)](https://travis-ci.org/substantial/substantial-dash-server)

**An early work-in-progress** to visualize realtime events, statuses, and key performance indicators.

Designed to broadcast data to [Substantial Dash client](https://github.com/substantial/substantial-dash-client).

## Tech

* [Ruby on Rails 4](http://rubyonrails.org)
* [Bayeux/Faye events](http://faye.jcoglan.com): publish & subscribe to data streams
* [Redis](http://redis.io): work queue, scheduling, and key/value persistence
* [Sidekiq](http://mperham.github.com/sidekiq/): asynchronous job processing
* [OmniAuth](https://github.com/intridea/omniauth): user authentication

## Development

### Requirements

* [Ruby 2.0.0](https://www.ruby-lang.org/en/installation/) installed
* `gem install bundler`
* `brew install direnv` & [add the hook for your shell](http://direnv.net/)
* `brew install redis` & follow resulting directions to start the server or add launcher

### Install

    git clone git@github.com:substantial/substantial-dash-server.git
    cd substantial-dash-server/
    bundle install --path vendor/bundle

Set-up the **.envrc** file containing auth keys:

    export BAYEUX_URL="http://0.0.0.0:8001/bayeux"
    export BAYEUX_PUBLISH_KEY=XXXXX
    export INTAKE_GITHUB_API_ORG_FEED_URL=https://api.github.com/...
    export INTAKE_GITHUB_API_TOKEN=XXXXX
    export INTAKE_GITHUB_ORG_SLUG=XXXXX
    export INTAKE_GITHUB_TEAM_SLUG=XXXXX
    export INTAKE_GOOGLE_ICALENDAR_URL=https://www.google.com/calendar/ical/...
    export INTAKE_PIPEDRIVE_FILTER_NAMES='...'
    export INTAKE_PIPEDRIVE_PIPELINE_NAME='...'
    export INTAKE_PIPEDRIVE_API_URL=https://api.pipedrive.com/v1
    export INTAKE_PIPEDRIVE_API_TOKEN=...

Then, execute `direnv allow`

### Testing

Run the test suite:

    bundle exec rspec

### Boot-up
    
Start the application:
    
    PORT=8001 bundle exec foreman start

...and visit [http://0.0.0.0:8001](http://0.0.0.0:8001) in your browser.

### Deployment

While our MVP hosting is via Heroku, we're now experimenting with deployment as a [Docker container](https://www.docker.io/).

These notes are for a development [installation of Docker on OS X](http://docs.docker.io/en/latest/installation/mac/) using **boot2docker**.

    # Expose the Docker hosts ssh & HTTP service ports to the host OS X system.
    # (Must match the host ports in the `docker run` command below.)
    boot2docker stop
    VBoxManage modifyvm "boot2docker-vm" --natpf1 "tcp-port2222,tcp,,2222,,2222"
    VBoxManage modifyvm "boot2docker-vm" --natpf1 "tcp-port8080,tcp,,8080,,8080"
    boot2docker start

    # Import a public key for ssh access to the container.
    cat ~/.ssh/id_rsa.pub > .ssh/authorized_keys

    # The main build.
    time docker build -t="substantial-dash" .

    # Fire it up. Note all environment variables must be passed
    # as `-e` options.
    docker run -d -p 0.0.0.0:8080:80 -p 0.0.0.0:2222:22 -e BAYEUX_PUBLISH_KEY=meow -e BAYEUX_URL="http://0.0.0.0:8080/bayeux" -t substantial-dash

    # ssh into the container
    ssh -p 2222 root@0.0.0.0

The [Dockerfile](http://docs.docker.io/en/latest/reference/builder/) defines the build.

See all [Docker commands](http://docs.docker.io/en/latest/reference/commandline/cli/)

#### Caveats

Because Redis is running inside the conatiner without any external connectivity, **persistence will be lost** when the container is restarted or rebuilt. This shall be solved by running a Redis server external to the app container.

The passing of environment variable for all the DataIntake API configurations is clunky.
