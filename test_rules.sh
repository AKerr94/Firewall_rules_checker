#!/bin/bash
# Main script to run to test firewall rules
# Reads in source, destination and ports to test from config
# Interpret config and loop over, testing each connection and compiling results
# Optional args -i <config file> (default is 'config')
#
# This script uses telnet with timeouts as not all servers have netcat installed
# A better alternative solution would've used: nc -w <timeout> -z <destination> <port>
#
# These tests rely on having passwordless SSH access to the source hosts 

YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Default config vars
CONFIG_FILE="config"
CONFIG_FILE_OUT="${CONFIG_FILE}_out"
RESULTS_OUT="test_results"

function usage {
    echo -e "${YELLOW}Usage: [-i <config file>]${NC}"
}

while [[ $# > 0 ]]
do
flag="$1"
case $flag in
    -i|--config)
    CONFIG_FILE="$2"
    echo -e "Read in ${YELLOW}${CONFIG_FILE}${NC} as config file location"
    shift
    ;;
    *)
    echo -e "${RED}Unknown flag `echo $flag | tr -d '-'`${NC}"
    usage && exit 1
esac
shift
done

# Call python script to interpret and rewrite config in a more useable format
./rewrite_config.py -i ${CONFIG_FILE} -o ${CONFIG_FILE_OUT}

# Read in interpreted config file, ssh into source and test access to port on destination address
echo -e "${YELLOW}Testing firewall rules now..${NC}"
> test_results
while read -r line
do
    RULE_ARR=()
    while IFS=',' read -ra ADDR; do
        count=1
        for j in "${ADDR[@]}"; do
            RULE_ARR[${count}]=${j}
            count=$((count+1))
        done
    done <<< "${line}"

    SOURCE=${RULE_ARR[1]}
    DEST=${RULE_ARR[2]}
    PORT=${RULE_ARR[3]}
    RULE="${SOURCE} -> ${DEST}:${PORT}"

    # Build commands to execute on remote host and save result to temp file
    COMMAND="echo QUIT > quit; timeout 3s telnet ${DEST} ${PORT} < quit; echo EXIT_STATUS; rm -f quit"
    COMMAND=$(echo ${COMMAND} | sed s/EXIT_STATUS/\$\?/g)
    SSHKEY=$(ssh-keyscan ${SOURCE} 2> /dev/null)
    echo ${SSHKEY} >> ~/.ssh/known_hosts
    ssh -n ${SOURCE} ${COMMAND} > tmp_result

    # 124 = timeout command cut connection, else success
    EXIT_STATUS=$(tail -n 1 tmp_result)
    if [ "${EXIT_STATUS}" = "124" ]; then
        echo -e "${RED}${RULE} FAILED${NC}" >> ${RESULTS_OUT}
    else
        echo -e "${GREEN}${RULE} PASSED${NC}" >> ${RESULTS_OUT}
    fi
done < ${CONFIG_FILE_OUT}

# Cleanup and output results
rm -f tmp_result ${CONFIG_FILE_OUT}

echo -e "\n${GREEN}The script successfully executed${NC}\n"
echo -e "Results (saved to '${RESULTS_OUT}'):\n"
cat ${RESULTS_OUT}