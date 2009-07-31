#!/bin/bash
server_list=$(<my_server_list);
logs_dir='/home/hackman'
check_for_user='hackman'
servercount=0;
okcount=0;
failedcount=0;
if ( echo $0|grep "sexec" > /dev/null ) || ( echo $0|grep "mexec" > /dev/null ) || ( echo $0|grep "fexec" > /dev/null ); then
	echo "$(date +'%d.%b.%Y %T') $1" >> $logs_dir/sexec
	if ( echo $1 | grep '\s*rm ' > /dev/null ); then
		echo -e -n "Command: $1\nAre you sure you want to execute this command(y/n): "
		read y
		if [ "$y" != 'y' ]; then 
			exit 1
		fi
	fi
    if ( echo $1|grep reboot > /dev/null); then
        echo "You can not reboot the servers using $0\!"
        exit 1
    fi
    if ( echo $1|grep halt > /dev/null); then
        echo "You can not reboot the servers using $0\!"
        exit 1
    fi
fi
if ( echo $0|grep "mcopy" > /dev/null ); then
        echo "$(date +'%d.%b.%Y %T') File $1 copied to all servers at $2" >> $logs_dir/mcopy
fi
if ( echo $0|grep "scopy" > /dev/null ); then
        echo "$(date +'%d.%b.%Y %T') File $1 copied to all servers at $2" >> $logs_dir/scopy
fi
for server in $server_list; do
	if ( echo $0|grep "mcopy$" > /dev/null ); then
		if [ $# -ne 2 ]; then
			echo -e "Usage: $0 file location\nExample: $0 test.sh /usr/local/sbin\n"
			exit 1
		fi
		if ( scp $1 $server:$2 2>/dev/null & ); then
                        let okcount++
		else
                        let failedcount++			
		fi
		let servercount++
	fi
	if ( echo $0|grep "mexec$" > /dev/null ); then
		if ( ! echo `pwd` | grep "$check_for_user" > /dev/null ); then
			echo "You are not allowed to use this command!"
			exit 1
		fi
        if [ $# -ne 1 ]; then
            echo -e "Usage: $0 command\nExample: $0 'cp /etc/exim.conf /etc/exim.old'\n"
            exit 1
        fi
        if ( ssh -t -q $server "$1" 2>/dev/null & ); then
            let okcount++
        else
            let failedcount++
        fi
        let servercount++
	fi
    if ( echo $0|grep "fexec$" > /dev/null ); then
        if ( ! echo `pwd` | grep "$check_for_user" > /dev/null ); then
            echo "You are not allowed to use this command!"
            exit 1
        fi
		if [ $# -ne 1 ]; then
			echo -e "Usage: $0 command\nExample: $0 'cp /etc/exim.conf /etc/exim.old'\n"
			exit 1
		fi
		if ( ssh -t -q $server "echo \"\$(hostname) \$($1)\"" 2>/dev/null & ); then
			let okcount++
		else
			let failedcount++
		fi
    	let servercount++
	fi
	if ( echo $0|grep "scopy$" > /dev/null ); then
		if [ $# -ne 2 ]; then
			echo -e "Usage: $0 file location\nExample: $0 test.sh /usr/local/sbin\n"
			exit 1
		fi
		echo $server
		if ( scp $1 $server:$2 ); then
			let okcount++
		else
			let failedcount++
		fi
		let servercount++
	fi
	if ( echo $0|grep "sexec" > /dev/null ); then
		if [ $# -ne 1 ]; then
			echo -e "Usage: $0 command\nExample: $0 'cp /etc/exim.conf /etc/exim.old'\n"
			exit 1
		fi
		echo $server
		if ( ssh -q -t $server "$1" ); then
			let okcount++
		else
			let failedcount++
		fi
		let servercount++
	fi	
done
if ( echo $0|grep "fexec" > /dev/null ); then
	sleep 5
else
	echo "Server count: $servercount"
	echo "OK servers: $okcount"
	echo "Failed servers: $failedcount"
fi
exit 0
