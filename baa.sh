#!/bin/bash
#
#~ Options:
#~   -r         Get Random Ascii Art.
#~   -h         Print this help.
#~   -p         Print Ascii Art Categories.
#~   -s STRING  Search Ascii Art.
#~   -v         Be verbose.
#~   -V         Print the Version.
#~
#~ baa - Bash Ascii Art is a CLI tool to search and fetch the ascii art
#~ hosted in http://chris.com
#~
#~ Exit Codes:
#~    0    Success
#~    1    Failed

_VERSION=0.1
FULLNAME=$(basename $0)
NAME=$(basename $0 | cut -d. -f1)

SITE_URL='http://chris.com/ascii/'
MEM_FS=/dev/shm

LINKS=$( command -v links )
CURL=$( command -v curl )
USER_AGENT="baa/${_VERSION}"
CURL_OPTS="--user-agent ${USER_AGENT} -s"

print_help(){
  echo "Usage: ${FULL_NAME} [-hpvV] [-r] [-s SEARCH]"
  grep -E '^#~' $0|sed -e 's/^#~//'
}


validate_tools() {
  local missing=0
  if [[ -z ${LINKS} ]]; then
    echo "Error links was not found and is required." >&2
    missing=$(( ${missing} + 1 ))
  fi
  if [[ -z ${CURL} ]]; then
    echo "Error curl was not found and is required." >&2
    missing=$(( ${missing} + 1 ))
  fi
  if [[ ${missing} -eq 0 ]]; then
    return 0
  else
    exit 1
  fi
}

create_tmp() {
  local tmpf=''
  df -t tmpfs --output=target ${MEM_FS} &>/dev/null
  if [[ $? -eq 0 ]]; then
    tmpf=$(mktemp ${MEM_FS}/ascii.XXXXX)
  else
    tmpf=$(mktemp /tmp/ascii.XXXXX)
  fi
  echo ${tmpf}
}


search_asciiart() {
  search=$*
  local categories=$( ${CURL} ${CURL_OPTS} ${SITE_URL} |
  awk -F, '/d.add.*art=.[^,]./ {printf "%s,%s\n",$3,$4}' | sort -u )
  local match=''
  local num_match=''
  local uri=''
  if [[ -n ${categories} ]]; then
    match=$( grep -i "${search// /.*}" <<<"${categories}" )
    if [[ -n ${match} ]]; then
      num_match=$( wc -l <<<"${match}" )
      echo "Found ${num_match} $( [ ${num_match} -eq 1 ] &&
                                  echo "match" || 
                                  echo "matches" ):"
      echo "${match}" | awk -F, '{printf " %0'${#num_match}'d %s\n", NR, $1}'
    else
      echo "Couldn't find a match for your search."
      return 0
    fi
    #TODO: loop until exit? or until valid entry
    read -p"Select the entry to print: " entry
    if [[ -n ${entry} ]]; then
      if [[ ${entry} =~ ^[0-9]+$ ]]; then
        if [[ ${entry} -gt 0 && ${entry} -le ${num_match} ]]; then
            uri=$( sed -n ${entry}p <<<"${match}" |
                   sed -e 's/ /%20/g' |
                   awk -F, '{print $NF}' |
                   tr -d \')
            ${CURL} ${CURL_OPTS} "${SITE_URL}/${uri}" |
              sed -n '/<pre>/,/<\/pre>/p' > ${tmp}
        else
          echo "TODO"
          echo "not inthe range"
        fi
      else
        echo "TODO"
        echo "not a numeric entry"
      fi
    else  
      echo "TODO"
      echo "A value was expected"
      return 1
    fi
  fi
}

print_categories() {
  local categories=$( ${CURL} ${CURL_OPTS} ${SITE_URL} |
                        awk -F, '/d.add.*art=.,./ {print $3}' |
                        tr -d \' )
  local num_cat=$( wc -l <<<"${categories}")
  echo "Categories found: ${num_cat}"
  if [[ -n "${categories}" ]]; then
    echo "${categories}" | awk '{printf " %0'${#num_cat}'d %s\n", NR, $0}'
  fi
}

print_asciiart() {
  local tmpf=$1
  links -dump file:///${tmpf}
  rm -f ${tmpf}
}

if [[ "$#" -eq 0 ]]; then
    echo "ERROR Missing arguments!"
    print_help
    exit 1
fi

while getopts hprs:vV flag; do
  validate_tools
  case ${flag} in
    p)
      print_categories
      ;;
    r)
      echo "TODO"
      ;;
    s)
      search="${OPTARG}"
      tmp=$( create_tmp )
      search_asciiart "${search}"
      print_asciiart "${tmp}"
      ;;
    v)
      verbose=1
      ;;
    V)
      echo ${NAME} ${_VERSION}
      exit 0
      ;;
    h|*)
      print_help
      exit 1
      ;;
  esac
done

exit 0
