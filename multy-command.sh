#!/bin/bash
version='1.1.0'
server_list=$(<my_server_list);
logs_dir='/home/hackman'
check_for_user='hackman'
servercount=0
okcount=0
failedcount=0
failedserver=()
if [[ "$0" =~ 'sexec' ]] || [[ "$0" =~ 'mexec' ]] || "$0" =~ 'fexec' ]]; then
	echo "$(date +'%d.%b.%Y %T') $1" >> $logs_dir/sexec
	if ( echo $1 | grep '\s*rm ' > /dev/null ); then
		echo -e -n "Command: $1\nAre you sure you want to execute this command(y/n): "
		read y
		if [ "$y" != 'y' ]; then 
			exit 1
		fi
	fi
	if [[ "$1" =~ 'reboot' ]]; then
        echo "You can not reboot the servers using $0\!"
        exit 1
    fi
	if [[ "$1" =~ 'halt' ]]; then
        echo "You can not reboot the servers using $0\!"
        exit 1
    fi
fi

if [[ "$0" =~ 'scopy' ]]; then
	logfile="$logs_dir/mcopy"
fi
if [[ "$0" =~ 'mcopy' ]]; then
	logfile="$logs_dir/scopy"
fi
echo "$(date +'%d.%b.%Y %T') File $1 copied to all servers at $2" >> $logfile

for server in $server_list; do
	if [[ "$0" =~ 'mcopy' ]]; then
		if [ $# -ne 2 ]; then
			echo -e "Usage: $0 file location\nExample: $0 test.sh /usr/local/sbin\n"
			exit 1
		fi
		if ( scp $1 $server:$2 2>/dev/null & ); then
                        let okcount++
		else
						let failedcount++
						failedservers=(${failedservers[*]} $server)
		fi
		let servercount++
	fi
	if [[ "$0" =~ 'mexec' ]]; then
		if ( ! pwd | grep "$check_for_user" > /dev/null ); then
			echo "You are not allowed to use this command!"
			exit 1
		fi
		file_cmd=0
        if [ $# -ne 1 ]; then
			if [ $# == 2 ] && [ "$1" == '-' ] && [ -f "$2" ]; then
				echo "Using script file: $2"
				file_cmd=1
			else
	            echo -e "Usage: $0 command\nExample: $0 'cp /etc/exim.conf /etc/exim.old'\n"
    	        exit 1
			fi
        fi
		if [ "$file_cmd" == 0 ]; then
	        if ( ssh -t -q $server "$1" 2>/dev/null & ); then
	            let okcount++
	        else
	            let failedcount++
				failedservers=(${failedservers[*]} $server)
    	    fi
		else
            if ( ssh -t -q $server < $2 2>/dev/null & ); then
	            let okcount++
			else
	            let failedcount++
				failedservers=(${failedservers[*]} $server)
			fi
		fi
        let servercount++
	fi
    if [[ "$0" =~ 'fexec' ]]; then
        if ( ! pwd | grep "$check_for_user" > /dev/null ); then
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
			failedservers=(${failedservers[*]} $server)
		fi
    	let servercount++
	fi
	if [[ "$0" =~ 'scopy' ]]; then
		if [ $# -ne 2 ]; then
			echo -e "Usage: $0 file location\nExample: $0 test.sh /usr/local/sbin\n"
			exit 1
		fi
		echo $server
		if ( scp $1 $server:$2 ); then
			let okcount++
		else
			let failedcount++
			failedservers=(${failedservers[*]} $server)
		fi
		let servercount++
	fi
	if [[ "$0" 'sexec' ]]; then
		if [ $# -ne 1 ]; then
			echo -e "Usage: $0 command\nExample: $0 'cp /etc/exim.conf /etc/exim.old'\n"
			exit 1
		fi
		echo $server
		if ( ssh -q -t $server "$1" ); then
			let okcount++
		else
			let failedcount++
			failedservers=(${failedservers[*]} $server)
		fi
		let servercount++
	fi	
done
if [[ "$0" =~ 'fexec' ]]; then
	sleep 5
else
	echo "Server count: $servercount"
	echo "OK servers: $okcount"
	echo "Failed servers: $failedcount"
	if [ "$failedcount" -gt 0 ]; then
		echo -n "List failed servers (y/n): "
		read a
		if [ "$a" == 'y' ]; then
			for i in ${failedservers[*]}; do 
				echo -e "\t$i"
			done
		fi
	fi
fi
exit 0
