#!/bin/bash
version='4.0'
server_list=$(<my_server_list);
logs_dir='/home/hackman'
logfile=$logs_dir/sexec
check_for_user='hackman'
servercount=0
okcount=0
failedcount=0
failedserver=()
file_cmd=''
ssh_options='-t -q'
background_sleep_time=3

if [[ -n $SERVER_LIST ]] && [[ -f $SERVER_LIST ]]; then
	server_list=$(<$SERVER_LIST)
fi

function check_user {
	if ! pwd | grep -q "$check_for_user" ; then
		echo "You are not allowed to use this command!"
		exit 1
	fi
}

function exec_usage_exit {
	echo -e "Usage: $0 command|- script_file\nThe - script_file option can be used only with mexec and sexec.\nExamples:\n\t$0 'cp /etc/exim.conf /etc/exim.old'\n\t$0 - script.sh\n"
	exit 1
}

function exec_usage {
	if [[ -n $1 ]]; then
		if [[ $1 == - ]]; then
			if  [[ -f $2 ]]; then
				echo "Using script file: $2"
				file_cmd=$2
			else
				exec_usage_exit
			fi
		fi
	else
		exec_usage_exit
	fi
}

function copy_usage {
	if [ $# -ne 2 ]; then
		echo -e "Usage: $0 file location\nExample: $0 test.sh /usr/local/sbin\n"
		exit 1
	fi
}

function mexec {
	if [[ -z $file_cmd ]]; then
		if ssh $ssh_options $server "$1" 2>/dev/null & then
			let okcount++
		else
			let failedcount++
			failedservers=(${failedservers[*]} $server)
		fi
	else
		if ssh $ssh_options $server < $file_cmd 2>/dev/null & then
			let okcount++
		else
			let failedcount++
			failedservers=(${failedservers[*]} $server)
		fi
	fi
	let servercount++
}
function sexec {
	echo $server
	if [[ -z $file_cmd ]]; then
		if ssh $ssh_options $server "$1" 2>/dev/null & then
			let okcount++
		else
			let failedcount++
			failedservers=(${failedservers[*]} $server)
		fi
	else
		if ssh $ssh_options $server < $file_cmd 2>/dev/null & then
			let okcount++
		else
			let failedcount++
			failedservers=(${failedservers[*]} $server)
		fi
	fi
	let servercount++
}
function fexec {
	if ssh $ssh_options $server "echo \"\$(hostname) \$($1)\"" 2>/dev/null & then
		let okcount++
	else
		let failedcount++
		failedservers=(${failedservers[*]} $server)
	fi
	let servercount++
}
function mcopy {
	copy_usage $*
	if scp $1 $server:$2 2>/dev/null & then
		let okcount++
	else
		let failedcount++
		failedservers=(${failedservers[*]} $server)
	fi
	let servercount++
}
function scopy {
	copy_usage $*
	echo $server
	if scp $1 $server:$2; then
		let okcount++
	else
		let failedcount++
		failedservers=(${failedservers[*]} $server)
	fi
	let servercount++
}

if [[ $0 =~ [smf]exec ]]; then
	check_user
	exec_usage "$1" "$2" "$3"
	echo "$(date +'%d.%b.%Y %T') $*" >> $logfile
	if echo $1 | grep -q '\s*rm ' ; then
		echo -e -n "Command: $1\nAre you sure you want to execute this command(y/n): "
		read y
		if [ "$y" != 'y' ]; then
			exit 1
		fi
	fi
	if [[ $1 =~ reboot ]]; then
		echo "You can not reboot the servers using $0\!"
		exit 1
	fi
	if [[ $1 =~ halt ]]; then
		echo "You can not reboot the servers using $0\!"
		exit 1
	fi
fi

if [[ $0 =~ copy ]]; then
	if [[ $0 =~ scopy ]]; then
		logfile="$logs_dir/mcopy.log"
	fi
	if [[ $0 =~ mcopy ]]; then
		logfile="$logs_dir/scopy.log"
	fi
	echo "$(date +'%d.%b.%Y %T') File $1 copied to all servers at $2" >> $logfile
fi

for server in $server_list; do
	if [[ $0 =~ mexec ]]; then
		mexec "$1"
	fi
	if [[ $0 =~ sexec ]]; then
		sexec "$1"
	fi
	if [[ $0 =~ fexec ]]; then
		fexec "$1"
	fi
	if [[ $0 =~ mcopy ]]; then
		mcopy $*
	fi
	if [[ $0 =~ scopy ]]; then
		scopy $*
	fi
done
if [[ $0 =~ [fm]exec ]]; then
	sleep $background_sleep_time
fi

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
exit 0
