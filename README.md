**Heads up! Code contributions welcome. Please issue pull requests against the
`develop` branch.**

imapcli
=======

> Command-line interface (CLI) for IMAP servers

`imapcli` is a command-line tool that offers a convenient way to query an IMAP
server for configuration details and e-mail statistics. It can be used to gather
IMAP folder sizes.


Table of contents
-----------------

*   [Motivation](#motivation)
*   [Warning](#warning)
*   [Installing and executing `imapcli`](#installing-and-executing-imapcli)
*   [Terminology](#terminology)
*   [Commands](#commands)
*   [Alternative resources](#alternative-resources)
*   [State of the project](#state-of-the-project)
*   [Credits](#credits)
*   [License](#license)


Motivation
----------

When my university mail account had almost reached the quota, I needed to find
out what the largest mail folders were (in terms of megabytes, not message count).
To my surprise, there was no easy way to accomplish this; or at least I did not
find one by searching the web. A couple of specialized IMAP-related tools exist
(see below), but when it comes to querying an IMAP server for configuration and
stats, you have to resort to communicating with the server by telnet or OpenSSL.

`imapcli` offers a convenient way to query an IMAP server.


Warning
-------

Some servers are configured to detect malicious login attempts by the frequency
of connections from a given source. **It may happen that you get locked out of
a server if you use `imapcli` to issue too many queries in too short a time!**

If you happen to be the server administrator yourself, have
[fail2ban](https://www.fail2ban.org) running, and find your IP being denied
access to the IMAP port, you can SSH into your server and un-ban your IP like
this:

    sudo fail2ban-client set dovecot unbanip <your-ip>

If your IMAP server is not [Dovecot](https://www.dovecot.org), you need to change
this command and provide the appropriate 'jail' name.

To prevent `fail2ban` from blocking your IP, you may want to add a network and
submask to `jail.local`:

    # /etc/fail2ban/jail.local
    [DEFAULT]
    ignoreip = 127.0.0.1/8 123.123.123.0/24 # or whatever your net/mask are

Do not forget to reload the `jail2ban` configuration afterwards:

    sudo service fail2ban reload

(On Ubuntu Linux, the [indicator-ip](https://github.com/bovender/indicator-ip)
applet may be useful to know your remote IP. Disclaimer: I am the author of this
tool.)

Installing and executing `imapcli`
--------------------------------

`imapcli` is a Ruby project and as such does not need to be compiled. You'll
need Ruby on your system.


### Run in the repository

Just clone this repository and run

    bin/imapcli


### Gem

To follow.

Run:

    imapcli


### .deb installer

To follow.


### Docker image

To follow. This will be an option if you don't have Ruby installed.


Terminology
-----------

`imapcli` attempts to use the typical IMAP terminology. I guess most people
have their mails organized in *folders*; in IMAP speak, a folder is a *maibox*.


Commands
--------

For basic usage instructions and possible options, run `imapcli` and examine
the output. Please note that `imapcli` distinguishes between global and
command-specific options. Global options *precede* and command-specific options
*follow* a `command`, see the output of `imapcli` (without command or options)
for more information.


### Commands

*   `info`: Prints configuration information about the server.
*   `examine`: Examines a mailbox (i.e., folder) and returns statistics about it.


### Command-line options

*   `-s SERVER`: Set the server domain name (e.g., `imap.example.com`). May be
    omitted if the information is given in the `IMAP_SERVER` environment variable
    (see below).
*   `-u USER`: Set the login (user) name (e.g., `john@example.com`). May be
    omitted if the information is given in the `IMAP_USER` environment variable
    (see below).
*   `-p PASSWORD`: Set the password. May be omitted if the `-P` option is used
    or if the information is given in the `IMAP_PASS` environment variable (see below).
*   `-P`: Prompt for the password.


### Using environment variables for the server and authentication details

You can set the following environment variables to avoid having to type the
server information over and over again:

    IMAP_SERVER="imap.example.com"
    IMAP_USER="your_imap_login"
    IMAP_PASS="your_imap_password"

If you put this in a file `.env` in the root directory of the repository, this
information will be used. `.env` is git-ignored, so your credentials won't end up
in the repository, but of course anyone on your system who has access to this file
will be able to read the clear-text credentials.


Alternative resources
---------------------

While researching command-line tools for IMAP servers, I came across the
following:


### IMAP folder size script

*   <https://code.iamcal.com/pl/imap_folders>

    Ad-hoc perl script that computes the sizes of each mailbox. `imapcli` was
    inspired by this!


### IMAP synchronization and backup tools

*   <https://github.com/OfflineIMAP/imapfw>

    Framework to work with mails

*   <https://github.com/polo2ro/imapbox>

    Pull down e-mails from an IMAP server to your local disk



### IMAP via Telnet or OpenSSL


State of the project
--------------------

Please consider this an alpha version. It does what I needed it for most (collect
information about the folder sizes), but that's pretty much it. I'll be happy
to take **pull request**. Please issue those against the **develop** branch as
I like to follow *[a successful Git branching model](http://nvie.com/git-model)*.

### Versioning

This project is [semantically versioned](https://semver.org).

### To do

-   Man page
-   .deb installer
-   More commands?


Credits
-------

This tool is build around the awesome [GLI](https://github.com/davetron5000/gli) gem.
See the `Gemfile` for other work that this tool depends on.


License
-------

&copy; 2017 Daniel Kraus (bovender)

Apache license.
