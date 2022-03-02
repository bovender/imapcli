# imapcli

> Command-line interface (CLI) for IMAP servers
> (<https://github.com/bovender/imapcli>)

`imapcli` is a command-line tool that offers a convenient way to query an IMAP
server for configuration details and e-mail statistics. It can be used to gather
IMAP mailbox sizes.

## Table of contents

* [Motivation](#motivation)
* [Warning](#warning)
* [Installing and executing `imapcli`](#installing-and-executing-imapcli)
* [Terminology](#terminology)
* [Usage](#usage)
* [Alternative resources](#alternative-resources)
* [State of the project](#state-of-the-project)
* [Credits](#credits)
* [License](#license)

## Motivation

When my university mail account had almost reached the quota, I needed to find
out what the largest mail folders were (in terms of megabytes, not message
count). To my surprise, there was no easy way to accomplish this; or at least I
did not find one by searching the web. A couple of specialized IMAP-related
tools exist (see [below](#alternative-resources)), but when it comes to querying
an IMAP server for configuration and stats, you have to resort to communicating
with the server by telnet or OpenSSL.

`imapcli` offers a convenient way to query an IMAP server.

## Warning

Some servers are configured to detect potentially malicious login attempts by
the frequency of repeat connections from a given source. **It may happen that
you get locked out of a server if you use `imapcli` to issue too many queries in
too short a time!**

If you happen to be the server administrator yourself, have
[fail2ban](https://www.fail2ban.org) running, and find your IP being denied
access to the IMAP port, you can SSH into your server and un-ban your IP like
this:

    sudo fail2ban-client set dovecot unbanip <your-ip>

If your IMAP server is not [Dovecot](https://www.dovecot.org), you need to adjust
this command to provide the appropriate 'jail' name.

To prevent `fail2ban` from blocking your IP, you may want to add your network and
submask to `jail.local`:

    # /etc/fail2ban/jail.local
    [DEFAULT]
    ignoreip = 127.0.0.1/8 123.123.123.0/24 # or whatever your net/mask are

Do not forget to reload the `jail2ban` configuration afterwards:

    sudo service fail2ban reload

Of course this only works if your IP addresses do not change too much.

## Installing and executing `imapcli`

`imapcli` is a Ruby project and as such does not need to be compiled. To run it
on your machine, you can either pull the repository, install a Gem, or use a
Docker image.

Detailed usage instructions follow [below](#usage).

I don't currently provide a .deb package because Debian packaging done right
is kind of complicated (for me).

### Run in the repository

Requirements: git, a recent Ruby, and [bundler](http://bundler.io).

Install:

    git clone https://github.com/bovender/imapcli

Run:

    cd imapcli
    bundle exec bin/imapcli

### Install the gem

Requirements: a recent Ruby and RubyGems.

Install:

    gem install imapcli

Run:

    imapcli

### Docker image

With [Docker](https://www.docker.com), you do not have to install Ruby and the
additional dependencies. Everything is contained in the, well, container. The
Docker image is about 120 MB in size though (I did not manage to make it
smaller).

Run:

    docker run -it bovender/imapcli <arguments>

Example:

    docker run -it bovender/imapcli -s myserver.example.com -u user -P info

The Docker repository is at <https://hub.docker.com/r/bovender/imapcli>.

## Terminology

`imapcli` attempts to use the typical IMAP terminology. I guess most people
have their mails organized in **folders**; in IMAP speak, a folder is a **maibox**.

## Usage

For basic usage instructions and possible options, run `imapcli` and examine
the output. Please note that `imapcli` distinguishes between global and
command-specific options. Global options *precede* and command-specific options
*follow* a `command`, see the output of `imapcli` (without command or options)
for more information.

Note: The following examples use the command `imapcli`. Depending on how you
[installed](#installing-and-executing-imapcli) `imapcli`, you may need to use a
different command.

### Setting your server and account information

Server and account information are given as *global options*:

    imapcli -s example.com -u username -p password

Of course it is **not recommended** to type a password on the command line. If
you *must* give the password on the command line, and have the Bash shell,
precede the line with a space to prevent it from being saved in the shell history.

To have `imapcli` prompt you for a password, use the `-P` option:

    imapcli -s example.com -u username -P

If you have one just IMAP server that you want to query, consider setting
environment variables:

    IMAP_SERVER="imap.example.com"
    IMAP_USER="your_imap_login"
    IMAP_PASS="your_imap_password" # OPTIONAL, NOT RECOMMENDED, VERY INSECURE!

These variables can also be set in a `.env` file that resides in the root
directory of the repository. Never add this `.env` file to the repository!

### Obtain general information about the IMAP server

    $ bundle exec bin/imapcli -s yourserver.example.com -u myusername -P info
    Enter password: ••••••••
    server: yourserver.example.com
    user: myusername
    greeting: Dovecot ready.
    capability: IMAP4REV1 LITERAL+ SASL-IR LOGIN-REFERRALS ID ENABLE IDLE SORT SORT=DISPLAY THREAD=REFERENCES THREAD=REFS THREAD=ORDEREDSUBJECT MULTIAPPEND URL-PARTIAL CATENATE UNSELECT CHILDREN NAMESPACE UIDPLUS LIST-EXTENDED I18NLEVEL=1 CONDSTORE QRESYNC ESEARCH ESORT SEARCHRES WITHIN CONTEXT=SEARCH LIST-STATUS BINARY MOVE SPECIAL-USE
    hierarchy separator: /
    quota: IMAP QUOTA extension not supported by this server

### List all mailboxes (folders) without size information

    $ bundle exec bin/imapcli -s yourserver.example.com -u myusername -P list
    Enter password: ••••••••
    server: yourserver.example.com
    user: myusername
    - Work
      - Boss
      - Project
    - Family
    - Sports
    ...

### Obtain size information about mailboxes

To obtain mailbox sizes, the server has to be queried for the message sizes for
each mailbox of interest. Depending on the number of mailboxes and the number
of messages in them, this may take a little while.

`imapcli` prints the following statistics about the message sizes in a mailbox:

* `Count`: Number of individual messages
* `Total size`: Total size of all messages in the mailbox (in kiB)
* `Min`: Size of the smallest message in the mailbox (in kiB)
* `Q1`: First quartile of message sizes in the mailbox (in kiB)
* `Median`: Median of all message sizes in the mailbox (in kiB)
* `Q3`: First quartile of message sizes in the mailbox (in kiB)
* `Max`: Size of the largest message in the mailbox (in kiB)

#### All mailboxes

To obtain stats for all mailboxes, use the `stats` command without the optional
mailbox argument:

    $ bundle exec bin/imapcli -s yourserver.example.com -u myusername -P stats
    Enter password: ••••••••
    server: yourserver.example.com
    user: myusername
    info: collecting stats for 109 folders
    ┌────────────────────────────────┬─────┬─────────────┬──────┬───────┬─────────┬──────────┬──────────┐
    │Mailbox                         │Count│   Total size│   Min│     Q1│   Median│        Q3│       Max│
    ├────────────────────────────────┼─────┼─────────────┼──────┼───────┼─────────┼──────────┼──────────┤
    ...
    │Total                           │13168│2,498,517 kiB│ 0 kiB│  4 kiB│    7 kiB│    25 kiB│33,681 kiB│
    └────────────────────────────────┴─────┴─────────────┴──────┴───────┴─────────┴──────────┴──────────┘

#### Specific mailboxes without child mailboxes

    $ bundle exec bin/imapcli -s yourserver.example.com -u myusername -P stats Archive Com
    Enter password: ••••••••
    server: yourserver.example.com
    user: myusername
    ┌───────┬─────┬──────────┬─────┬─────┬──────┬──────┬───────┐
    │Mailbox│Count│Total size│  Min│   Q1│Median│    Q3│    Max│
    ├───────┼─────┼──────────┼─────┼─────┼──────┼──────┼───────┤
    │Archive│    0│     0 kiB│   NA│   NA│    NA│    NA│     NA│
    │Com    │   60│ 3,276 kiB│2 kiB│5 kiB│13 kiB│65 kiB│478 kiB│
    │Total  │   60│ 3,276 kiB│2 kiB│5 kiB│13 kiB│65 kiB│478 kiB│
    └───────┴─────┴──────────┴─────┴─────┴──────┴──────┴───────┘

#### Specific mailboxes and child mailboxes

Use the `-r`/`--recurse` flag:

    $ bundle exec bin/imapcli -s yourserver.example.com -u myusername -P stats -r Archive Com
    Enter password: ••••••••
    server: yourserver.example.com
    user: myusername
    info: collecting stats for 58 folders
    ┌──────────────────────────┬─────┬──────────┬──────┬───────┬───────┬───────┬─────────┐
    │Mailbox                   │Count│Total size│   Min│     Q1│ Median│     Q3│      Max│
    ├──────────────────────────┼─────┼──────────┼──────┼───────┼───────┼───────┼─────────┤
    ...

#### Sorting the output

By default, mailboxes are sorted alphabetically. To sort by a specific statistic,
use an `-o`/`--sort` option:

* `-o count`
* `-o total_size`
* `-o min_size`
* `-o q1`
* `-o median_size`
* `-o q3`
* `-o max_size`

Example:

    bundle exec -it bin/imapcli -s yourserver.example.com -u myusername -P stats -r -o max_size Archive

#### Obtaining comma-separated values (CSV)

Use the `--csv` flag.

## Alternative resources

While researching command-line tools for IMAP servers, I came across the
following:

### IMAP folder size script

* <https://code.iamcal.com/pl/imap_folders>

  Ad-hoc perl script that computes the sizes of each mailbox. `imapcli` was
  inspired by this!

### IMAP synchronization and backup tools

* <https://github.com/OfflineIMAP/imapfw>

  Framework to work with mails

* <https://github.com/polo2ro/imapbox>

  Pull down e-mails from an IMAP server to your local disk

## State of the project

I have not been able to work on this project for quite some time. It still
serves me well when I occasionally need it. Pull requests are of course welcome.

I've decided to have one `main` branch, and to get rid of the `master` and
`

This project is [semantically versioned](https://semver.org).

### To do

* More human-friendly number formatting (e.g., MiB/GiB as appropriate)
* Output to file
* Deal with server-specific mailbox separator characters (e.g. '.' vs. '/')
* Man page
* More commands?

## Credits

This tool is build around the awesome [GLI](https://github.com/davetron5000/gli)
gem by [David Copeland](https://github.com/davetron5000) and makes extensive use
of [Piotr Murach's](https://github.com/piotrmurach) excellent `TTY` tools. See
the `Gemfile` for other work that this tool depends on.

## License

&copy; 2017, 2022 Daniel Kraus (bovender)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
