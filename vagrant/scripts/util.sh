#! /bin/bash

#Change the return behaviour of piplined scripts
#TODO:This might be needed for better logging
set -o pipefail

is1BInt ()
{
	case $1 in
		''|*[!0-9]*) # catches negative numbers (not truly accurate but works)
		return 1
		;;
		*)
		if [ "$1" -gt "255" ]; then
		return 1
	else
		if [ "$1" -lt "0" ]; then
			return 1
		else return 0
		fi
	fi
esac
}

isPosInt ()
{
	case $1 in
		''|*[!0-9]*)
		return 1
		;;
		*)
		if [ "$1" -lt "0" ]; then
			return 1
		else return 0
		fi
	esac
}

isValidIP ()
{
	IFS="." read a b c d <<< $1
	is1BInt $a
	a1BInt=$?
	if [ "$a1BInt" -eq "0" ]; then
		is1BInt $b
		b1BInt=$?
		if [ "$b1BInt" -eq "0" ]; then
			is1BInt $c
			c1BInt=$?
			if [ "$c1BInt" -eq "0" ]; then
				is1BInt $d
				d1BInt=$?
				if [ "$d1BInt" -eq "0" ]; then return 0
			else return 1
			fi
		else return 1
		fi
	else return 1
	fi
else return 1
fi
}

incrIP ()
{
	local result=$1
	if [ "$1" == "localhost" ]
	then
		local result="localhost"
	else
		isValidIP $1
		IPisValid=$?
		if [ "$IPisValid" -eq 0 ]; then

			IFS="." read a b c d <<< $1
			if [ "$d" -gt "253" ]; then
				if [ "$c" -gt "253" ]; then
					if [ "$b" -gt "253" ]; then
						if [ "$a" -gt "253" ]; then
						echo "IP out of range"
						return 1
					else
						a=$(( a+1 ))
						local result="$a.0.0.1"
					fi
				else
					b=$(( b+1 ))
					local result="$a.$b.0.1"
				fi
			else
				c=$(( c+1 ))
				local result="$a.$b.$c.1"
			fi
		else
			d=$(( d+1 ))
			local result="$a.$b.$c.$d"
		fi

	else
		echo "ip address is invalid"
		return 1
	fi

fi
echo "$result"
return 0
}

offsetIP ()
{
	local result=$1
	if [ "$1" == "localhost" ]; then
		echo "localhost"
		return 0
	else
		isValidIP $1
		IPisValid=$?
		if [ "$IPisValid" -eq 0 ]; then

			local offset=$2
			isPosInt $offset
			offsetPosInt=$?
			if [ "$offsetPosInt" -eq "0" ]; then
				IFS="." read a b c d <<< $1
				is1BInt $a
				a1BInt=$?
				if [ "$?" -eq "0" ]; then
					is1BInt $b
					b1BInt=$?
					if [ "$?" -eq "0" ]; then
						is1BInt $c
						c1BInt=$?
						if [ "$?" -eq "0" ]; then
							is1BInt $d
							d1BInt=$?
							if [ "$?" -eq "0" ]; then
								n=0
								newip=$1
								while [ $n -lt $offset ]; do
									n=$(( n+1 ))
									returnVal=$(incrIP $newip)
									newip="$returnVal"
								done
								result=$newip
							else
								echo "error: ip address is invalid"
								return 1
							fi
						else
							echo "error: ip address is invalid"
							return 1
						fi
					else
						echo "error: ip address is invalid"
						return 1
					fi
				else
					echo "error: ip address is invalid"
					return 1
				fi
			else
				echo "error: offset is not positive integer"
				return 1
			fi

		else
			echo "ip address is invalid"
			return 1
		fi


		echo "$result"
		return 0
	fi
}

ispow2(){
	if [ "$1" -ne 0 ]
	then
	(( bitwise=($1 & (($1-1))) ))
	if [ "$bitwise" -eq 0 ]
	then
	echo 0
else
	echo 1
fi
else
	echo 1
fi
}

display() {
	echo -e "\n----->" $*
}

abort() {
	echo $* ; exit 1
}

indent() {
	sed -u "s/^/       /"
}
