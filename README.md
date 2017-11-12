imapcli
=======

> Command-line interface (CLI) for IMAP servers

`imapcli` is a command-line tool that offers a convenient way to query an IMAP
server for configuration details and e-mail statistics. It can be used to gather
IMAP folder sizes.


Motivation
----------

When my university mail account had almost reached the quota, I needed to find
out what the largest mail folders were (in terms of megabytes, not message count).
To my surprise, there was no easy way to accomplish this; or at least I did not
find one by searching the web. A couple of specialized IMAP-related tools exist
(see below), but when it comes to querying an IMAP server for configuration and
stats, you have to resort to communicating with the server by telnet or OpenSSL.

`imapcli` offers a convenient way to query an IMAP server.


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


Commands
--------

For basic usage instructions and possible options, run `imapcli` and examine
the output.


### Commands

*   `info`: Prints configuration information about the server.


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

License
-------

&copy; 2017 Daniel Kraus (bovender)

Apache license.
