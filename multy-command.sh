#!/bin/bash
version='2.0'
server_list=$(<my_server_list);
logs_dir='/home/hackman'
logfile=$logs_dir/sexec
check_for_user='hackman'
servercount=0
okcount=0
failedcount=0
failedserver=()

function check_user {
	if ! pwd | grep -q "$check_for_user" ; then
		echo "You are not allowed to use this command!"
		exit 1
	fi
}

function exec_usage {
	if [ $# -ne 1 ]; then
		if [ $# == 2 ] && [ "$1" == '-' ] && [ -f "$2" ]; then
			echo "Using script file: $2"
			file_cmd=1
		else
			echo -e "Usage: $0 command|- script_file\nThe - script_file option can be used only with mexec and sexec.\nExamples:\n\t$0 'cp /etc/exim.conf /etc/exim.old'\n\t$0 - script.sh\n"
			exit 1
		fi
	fi
}

function copy_usage {
	if [ $# -ne 2 ]; then
		echo -e "Usage: $0 file location\nExample: $0 test.sh /usr/local/sbin\n"
		exit 1
	fi
}

function mexec {
	check_user $*
	exec_usage $*
	file_cmd=0
	if [ "$file_cmd" == 0 ]; then
		if ssh -t -q $server "$1" 2>/dev/null & then
			let okcount++
		else
			let failedcount++
			failedservers=(${failedservers[*]} $server)
		fi
	else
		if ssh -t -q $server < $2 2>/dev/null & then
			let okcount++
		else
			let failedcount++
			failedservers=(${failedservers[*]} $server)
		fi
	fi
	let servercount++
}
function sexec {
	check_user $*
	exec_usage $*
	echo $server
	file_cmd=0
	if [ "$file_cmd" == 0 ]; then
		if ssh -t -q $server "$1" 2>/dev/null & then
			let okcount++
		else
			let failedcount++
			failedservers=(${failedservers[*]} $server)
		fi
	else
		if ssh -t -q $server < $2 2>/dev/null & then
			let okcount++
		else
			let failedcount++
			failedservers=(${failedservers[*]} $server)
		fi
	fi
	let servercount++
}
function fexec {
	check_user $*
	exec_usage $*
	if ssh -t -q $server "echo \"\$(hostname) \$($1)\"" 2>/dev/null & then
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

if [[ $0 =~ s|m|fexec ]]; then
	echo "$(date +'%d.%b.%Y %T') $1" >> $logfile
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

if [[ $0 =~ scopy ]]; then
	logfile="$logs_dir/mcopy"
fi
if [[ $0 =~ mcopy ]]; then
	logfile="$logs_dir/scopy"
fi
echo "$(date +'%d.%b.%Y %T') File $1 copied to all servers at $2" >> $logfile

for server in $server_list; do
	if [[ $0 =~ mexec ]]; then
		mexec $*
	fi
	if [[ $0 =~ sexec ]]; then
		sexec $*
	fi
	if [[ $0 =~ fcopy ]]; then
		fcopy $*
	fi
	if [[ $0 =~ mcopy ]]; then
		mcopy $*
	fi
	if [[ $0 =~ sexec ]]; then
		sexec $*
	fi
done
if [[ $0 =~ fexec ]]; then
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
