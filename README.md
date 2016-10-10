# Gemirro | [![Build Status](https://travis-ci.org/PierreRambaud/gemirro.svg?branch=master)](https://travis-ci.org/PierreRambaud/gemirro) [![Gem Version](https://badge.fury.io/rb/gemirro.svg)](http://badge.fury.io/rb/gemirro)

Gemirro is a Ruby application that makes it easy way to create your own RubyGems mirror without having to push or write all gem you wanted in a configuration file.
It does mirroring without any authentication and you can add your private gems in the `gems` directory.
More, to mirroring a source, you only need to start the server, and gems will automaticly be downloaded when needed.

## Requirements

* Ruby 2.0.0 or newer
* Enough space to store Gems
* A recent version of Rubygems (`gem update --system`)

## Installation

Assuming RubyGems isn't down you can install the Gem as following:

```bash
$ gem install gemirro
```

## Usage

The process of setting up a mirror is fairly easy and can be done in few seconds.

The first step is to set up a new, empty mirror directory.
This is done by running the `gemirro init` command.

```bash
$ gemirro init /srv/http/mirror.com/
```

Once created you can edit the main configuration file called `config.rb`.
This configuration file specifies what source to mirror, destination directory, server host and port, etc.

Once configured and if you add gem in the `define_source`, you can pull them by running the following command:

```bash
$ gemirro update
```

Once all the Gems have been downloaded you'll need to generate an index of all the installed files. This can be done as following:

```bash
$ gemirro index
$ gemirro index --update # Or only update new files
```

Last, launch the server, and all requests will check if gems are detected, and download them if necessary and generate index immediately.

```bash
$ gemirro server --start
$ gemirro server --status
$ gemirro server --restart
$ gemirro server --stop

```

If you want to use a custom configuration file not located in the current directory, use the `-c` or `--config` option.

### Available commands

```
Usage: gemirro [COMMAND] [OPTIONS]

Options:

    -v, --version      Shows the current version
    -h, --help         Display this help message.

Available commands:

  index    Retrieve specs list from source.
  init     Sets up a new mirror
  list     List available gems.
  server   Manage web server
  update   Updates the list of Gems

See `<command> --help` for more information on a specific command.
```

## Apache configuration

You must activate the apache `proxy` module.

```bash
$ sudo a2enmod proxy
$ sudo a2enmod proxy_http
```

Create your VirtualHost and replace following `http://localhost:2000` with your custom server configuration located in your `config.rb` file and restart Apache.

```
<VirtualHost *:80>
  ServerName mirror.gemirro
  ProxyPreserveHost On
  ProxyRequests off
  ProxyPass / http://localhost:2000/
  ProxyPassReverse / http://localhost:2000/
</VirtualHost>
```

## Nginx configuration

Replace `localhost:2000` with your custom server configuration located in your `config.rb` file and restart Nginx.

```
upstream gemirro {
  server localhost:2000;
}

server {
  server_name rbgems;

  location / {
    proxy_pass http://gemirro;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
```

## Known issues

### could not find a temporary directory

If you use ruby >= 2.0, some urls in the server throwing errors telling `could not find a temporary directory`.
You only need to do a `chmod o+t /tmp`

