# multy-command

`multy-command` is a Bash utility that simplifies the management of large amount of servers.

It provides you with an easy way to copy files between groups of servers or execute commands.

It allows you to do this sequentially or in parallel, with multiple output modes for the parallel execution.

The nice thing is that you also get a feedback of what faild and on which servers.


# Installation

Place the main script somewhere in your `$PATH`, for example:

`/usr/local/bin/multy-command.sh`

Create symlinks to expose different behaviors:

```bash
ln -s /usr/local/bin/multy-command.sh /usr/local/bin/sexec
ln -s /usr/local/bin/multy-command.sh /usr/local/bin/mexec
ln -s /usr/local/bin/multy-command.sh /usr/local/bin/fexec
ln -s /usr/local/bin/multy-command.sh /usr/local/bin/scopy
ln -s /usr/local/bin/multy-command.sh /usr/local/bin/mcopy
ln -s /usr/local/bin/multy-command.sh /usr/local/bin/rcopy
```
The script determines behavior based on how it is invoked ($0).

# Commands

* sexec - Sequential execution of the supplied command on all servers from $server_list
* mexec - Parallel execution of the supplied command on all servers from $server_list performed in background
* fexec - Parallel execution of the supplied command on all servers from $server_list performed in background, but print the output with the hostname of every machine, so we can get better ordered output
* scopy - Sequential copy of a file to all servers from $server_list, this is usefull for files bigger then 2-3MB
* rcopy - Recursive copy of directory to all servers, sequentially
* mcopy - Parallel copy of a file to all server from $server_list, this is usefull for transfering configuration files and archives under 2MB

# Usage

The mexec and sexec commands can also be used to execute local scripts on the remote servers:
`  Usage: $0 command|- script_file`

The - script_file option can be used only with mexec and sexec.

Examples:
`$0 - script.sh`

So all *exec commands can be used with a command as:
`$0 'cp /etc/exim.conf /etc/exim.old'`

But only sexec and mexec can be used with scripts like:
`$0 - script.sh`

The copy commands can be used as:
`Usage: $0 local_file remote_destination`
Example:
`$0 test.sh /usr/local/sbin`


If you specify a file in the SERVER_LIST environment variable, the contents of that file will be used as the server list.
`export SERVER_LIST=/path/to/server/list.txt`


