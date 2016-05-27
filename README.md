# Firewall rules checker
Script to automate checking connections to given ports on source and destination hosts read in from a config file

# Usage
Set up the config file with stanzas for each source address. Following lines for each stanza should be comma separated with no whitespace, listing a destination address and then one or more ports to check. 

To run: ./test_rules.sh 

Pass a config file location with -i if you wish to use one other than the default config.

# Functionality
The config file is rewritten using a python script into a more easily useable format; this expands the stanzas into separate lines giving a source address, destination address and port to check. 

Netcat would be a good tool to use because its native functionality allows for a non-default timeout to be set. However, because netcat is not always available for use, this solution uses telnet issued through the timeout command. 

For this script to work you must have passwordless SSH access to the given source addresses. SSH-keyscan is used to pull the keys before connecting so the hosts do not have to already be in your known_hosts. 

# Output
The script runs through every check and then outputs the results at the end. This output is also saved to a file (default name 'test_results')
