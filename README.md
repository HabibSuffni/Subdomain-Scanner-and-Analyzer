# Subdomain-Scanner-and-Analyzer

This script performs the following steps:
- Checks the reachability of a given host or IP address.
- Uses subfinder to find subdomains for each hostname.
- Runs nuclei and nmap scans on reachable subdomains.
- Saves reachable subdomains to a file.
- Saves all subdomains found with subfinder in a file.

HOW TO USE:
$ git clone https://github.com/HabibSuffni/Subdomain-Scanner-and-Analyzer.git
$ cd Subdomain-Scanner-and-Analyzer
$ chmod +x Domain_Discovery_V2.1.sh 
$ ./Domain_Discovery_V2.1.sh HOST_FILE

