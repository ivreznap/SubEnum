#!/bin/bash
#
# script for subdomain enumeration using 4 of the best tools with some APIs:
#   * findomain: https://github.com/Edu4rdSHL/findomain
#   * SubFinder: https://github.com/projectdiscovery/subfinder
#   * Amass: https://github.com/OWASP/Amass
#   * AssetFinder: https://github.com/tomnomnom/assetfinder
#   * Github Subdomains: https://github.com/gwen001/github-subdomains
#
# a perl version is being developed by @terminalforlife 
#   * https://github.com/terminalforlife/PerlProjects/tree/master/source/dominator
#

bold="\e[1m"
Underlined="\e[4m"
red="\e[31m"
green="\e[32m"
blue="\e[34m"
end="\e[0m"
VERSION="2020-05-15"

PRG=${0##*/}


Usage(){
	while read -r line; do
		printf "%b\n" "$line"
	done <<-EOF
	\r$blue
	\r#Options:
	\r    -d, --domain       - Domain To Enumerate
	\r    -l, --list         - List of domains
	\r    -u, --use          - Tools To Be Used ex(Findomain,Subfinder,...,etc)
	\r    -e, --exclude      - Tools To Be Excluded ex(Findomain,Amass,...,etc)
	\r    -o, --output       - The output file to save the Final Results (Default: <TargetDomain>-DATE-TIME.txt)
	\r    -s, --silent       - The Only output will be the found subdomains - (Results saved: subenum-<DOMAIN>.txt).
	\r    -k, --keep         - To Keep the TMPs files (the results from each tool).
	\r    -r, --resolve      - To Probe For Working HTTP and HTTPS Subdomains, (Output: resolved-<DOMAIN>.txt).
	\r    -t, --thread       - Threads for Httprobe - works with -r/--resolve option (Default: 40)
	\r    -h, --help         - Displays this help message and exit.
	\r    -v, --version      - Displays the version and exit.

	\r#Available Tools:
	\r	  wayback,crt,bufferover,Findomain,Subfinder,Amass,Assetfinder,Github Subdomains

	\r#Examples:
	\r	  - To use a specific Tools:
	\r		 $PRG -d hackerone.com -u Findomain,wayback,Subfinder
	\r	  - To exclude a specific Tools:
	\r		 $PRG -d hackerone.com -e Amass,Assetfinder
	\r	  - To use all the Tools:
	\r		 $PRG -d hackerone.com 
	\r	  - To run SubEnum.sh against a list of domains:
	\r		 $PRG -l domains.txt
	\r $end
EOF
	exit 1
}


wayback() { 
	[ "$silent" == True ] && curl -sk "http://web.archive.org/cdx/search/cdx?url=*.$domain&output=txt&fl=original&collapse=urlkey&page=" | awk -F/ '{gsub(/:.*/, "", $3); print $3}' | sort -u | anew subenum-$domain.txt  || {
		printf "$bold[+] WayBackMachine$end"
		printf "                        \r"
		curl -sk "http://web.archive.org/cdx/search/cdx?url=*.$domain&output=txt&fl=original&collapse=urlkey&page=" | awk -F/ '{gsub(/:.*/, "", $3); print $3}' | sort -u > tmp-wayback-$domain
		echo -e "$bold[*] WayBackMachine$end: $(wc -l < tmp-wayback-$domain)"
	}
}

crt() {
	[ "$silent" == True ] && curl -sk "https://crt.sh/?q=%.$domain&output=json" | tr ',' '\n' | awk -F'"' '/name_value/ {gsub(/\*\./, "", $4); gsub(/\\n/,"\n",$4);print $4}' | anew subenum-$domain.txt || {
		printf "$bold[+] crt.sh$end"
		printf "                        \r"
		curl -sk "https://crt.sh/?q=%.$domain&output=json" | tr ',' '\n' | awk -F'"' '/name_value/ {gsub(/\*\./, "", $4); gsub(/\\n/,"\n",$4);print $4}' | sort -u > tmp-crt-$domain
		echo -e "$bold[*] crt.sh$end: $(wc -l < tmp-crt-$domain)" 
	}
}

bufferover() {
	[ "$silent" == True ] && curl -s "https://dns.bufferover.run/dns?q=.$domain" | grep $domain | awk -F, '{gsub("\"", "", $2); print $2}' | anew subenum-$domain.txt || {
		printf "$bold[+] BufferOver$end"
		printf "                        \r"
		curl -s "https://dns.bufferover.run/dns?q=.$domain" | grep $domain | awk -F, '{gsub("\"", "", $2); print $2}' | sort -u > tmp-bufferover-$domain
		echo -e "$bold[*] BufferOver$end: $(wc -l < tmp-bufferover-$domain)"
	}
}

Findomain() {
	[ "$silent" == True ] && findomain -t $domain -q 2>/dev/null | anew subenum-$domain.txt || {
		printf "$bold[+] Findomain$end"
		printf "                        \r"
		findomain -t $domain -u tmp-findomain-$domain &>/dev/null
		echo -e "$bold[*] Findomain$end: $(wc -l tmp-findomain-$domain 2>/dev/null | awk '{print $1}')"
	}
}

Subfinder() {
	[ "$silent" == True ] && subfinder -silent -d $domain 2>/dev/null | anew subenum-$domain.txt || {
		printf "$bold[+] SubFinder$end"
		printf "                        \r"
		subfinder -silent -d $domain 1> tmp-subfinder-$domain 2>/dev/null
		echo -e "$bold[*] SubFinder$end: $(wc -l < tmp-subfinder-$domain)"
	}
}



Amass() {
	# amass is with "-passive" option to make it faster, but it may cuz less results
	[ "$silent" == True ] && amass enum -passive -norecursive -noalts -d $domain 2>/dev/null | anew subenum-$domain.txt || {
		printf "$bold[+] Amass$end"
		printf "                        \r"
		amass enum -passive -norecursive -noalts -d $domain 1> tmp-amass-$domain 2>/dev/null
		echo -e "$bold[*] Amass$end: $(wc -l < tmp-amass-$domain)"
	}
}

Assetfinder() {
	[ "$silent" == True ] && assetfinder --subs-only $domain | anew subenum-$domain.txt || {
		printf "$bold[+] AssetFinder$end"
		printf "                        \r"
		assetfinder --subs-only $domain > tmp-assetfinder-$domain
		echo -e "$bold[*] AssetFinder$end: $(wc -l < tmp-assetfinder-$domain)"
	}
}

github-subdomains() {
	[ "$silent" == True ] && github-subdomains -d $domain -t n2gittoken.txt | anew subenum-$domain.txt || {
		printf "$bold[+] github-subdomains$end"
		printf "                        \r"
		github-subdomains -d $domain -t n2gittoken.txt > tmp-github-subdomains-$domain
		echo -e "$bold[*] github-subdomains$end: $(wc -l < tmp-github-subdomain-$domain)"
	}
}

USE() {
	for i in $lu; do
		$i
	done
	OUT
}


EXCLUDE() {
	for i in ${list[@]}; do
		if [[ " ${le[@]} " =~ " ${i} " ]]; then
			continue
		else
			$i
		fi
	done
	OUT
}

OUT(){
	[ "$silent" == False ] && { 
		[ -n "$1" ] && out="$1" || out="$domain-$(date +'%Y-%m-%d').txt"
		sort -u tmp-* > $out
		echo -e $green"[+] The Final Results:$end $(wc -l $out)"
		[ $resolve == True ] && ALIVE "$out" "$domain"

		[ $delete == True ] && rm tmp-*	
	}
}


ALIVE(){
	[ "$silent" == False ] && printf "$bold[+] Resolving $end"
	printf "                        \r"
	cat $1 | httprobe -c $thread > "resolved-$2.txt"
	[ "$silent" == False ] && echo -e $green"[+] Resolved:$end $(wc -l < resolved-$2.txt)"

}


LIST() {
	lines=$(wc -l < $hosts)
	count=1
	while read domain; do
		[ "$silent" == False ] && echo -e "$Underlined$bold$green\n[+] Domain ($count/$lines):$end $domain"
		[ $prv == "a" ] && {
			wayback
			crt
			bufferover
			Findomain 
			Subfinder 
			Amass 
			Assetfinder
			Github-Subdomains
			OUT
		}
		[ $prv == "e" ] && EXCLUDE 
		[ $prv == "u" ] && USE 
		let count+=1
	done < $hosts
}

Main() {
	[ $domain == False ] && [ $hosts == False ] && { echo -e $red"[-] Argument -d/--domain OR -l/--list is Required!"$end; Usage; }
	[ $use != False ] && [ $exclude != False ] && { echo -e $Underlined$red"[!] You can use only one Option: -e/--exclude OR -u/--use"$end; Usage; }
	[ $domain != False ] && { 
		[ $use == False ] && [ $exclude == False ] && { 
			wayback
			crt
			bufferover
			Findomain 
			Subfinder 
			Amass 
			Assetfinder
			Github-Subdomains
			[ "$out" == False ] && OUT || OUT $out
		} || { 
			[ $use != False ] && USE 
			[ $exclude != False ] && EXCLUDE
		}
	}
	[ "$hosts" != False ] && { 
		[ $use != False ] && prv=u
		[ $exclude != False ] && prv=e
		[ $use == False ] && [ $exclude == False ] && prv=a
		LIST
	 } 
}


domain=False
hosts=False
use=False
exclude=False
silent=False
delete=True
out=False
resolve=False
thread=40

list=(
	wayback
	crt
	bufferover
	Findomain 
	Subfinder 
	Amass 
	Assetfinder
	Github-Subdomains
	)

while [ -n "$1" ]; do
	case $1 in
		-d|--domain)
			domain=$2
			shift ;;
		-l|--list)
			hosts=$2
			shift ;;
		-u|--use)
			use=$2
			lu=${use//,/ }
			for i in $lu; do
				if [[ ! " ${list[@]} " =~ " ${i} " ]]; then
					echo -e $red$Underlined"[-] Unknown Function: $i"$end
					Usage
				fi
			done
			shift ;;
		-e|--exclude)
			exclude=$2
			le=${exclude//,/ }
			for i in $le; do
				if [[ ! " ${list[@]} " =~ " ${i} " ]]; then
					echo -e $red$Underlined"[-] Unknown Function: $i"$end
					Usage
				fi
			done
			shift ;;
		-o|--output)
			out=$2
			shift ;;
		-s|--silent)
			silent=True ;;
		-k|--keep)
			delete=False ;;
		-r|--resolve)
			resolve=True ;;
		-t|--thread)
			thread=$2
			shift ;;
		-h|--help)
			Usage;;
		-v|--version)
			echo "Version: $VERSION"
			exit 0 ;;
		*)
			echo "[-] Unknown Option: $1"
			Usage ;;
	esac
	shift
done

[ "$silent" == False ] && echo -e $blue$bold"
 ____        _     _____                       
/ ___| _   _| |__ | ____|_ __  _   _ _ __ ___  
\___ \| | | | '_ \|  _| | '_ \| | | | '_ \` _ \\ 
 ___) | |_| | |_) | |___| | | | |_| | | | | | |
|____/ \__,_|_.__/|_____|_| |_|\__,_|_| |_| |_|
           SubDomains Enumeration Tool
              By: bing0o @hack1lab
"$end

Main
