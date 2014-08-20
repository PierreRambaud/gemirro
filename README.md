# Gemirro | [![Build Status](https://travis-ci.org/PierreRambaud/gemirro.svg)](https://travis-ci.org/PierreRambaud/gemirro)

Gemirro is a Ruby application that makes it easy way to create your own RubyGems mirror without having to push or write all gem you wanted in a configuration file.
It does mirroring only, it has no authentication and you can't upload Gems to it.
More you only need to launch the server and gems will automaticly be downloaded when requests come.

## Requirements

* Ruby 1.9.2 or newer
* Enough space to store Gems

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
```


Last, launch the `TCPServer`, and all requests will check if gems are detected, and download them if necessary and generate index immediately.

```bash
$ gemirro server
```

If you want to use a custom configuration file not located in the current directory, use the `-c` or `--config` option.


##Apache configuration
TODO

##Nginx configuration
TODO
