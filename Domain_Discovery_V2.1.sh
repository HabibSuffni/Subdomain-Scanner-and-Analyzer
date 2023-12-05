#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Banner explaining the tool
echo -e "${GREEN}----------------------------------------------${NC}"
echo -e "${GREEN}        Subdomain Scanner and Analyzer         ${NC}"
echo -e "${GREEN}----------------------------------------------${NC}"
echo -e "This script performs the following steps:"
echo -e "  - Checks the reachability of a given host or IP address."
echo -e "  - Uses subfinder to find subdomains for each hostname."
echo -e "  - Runs nuclei and nmap scans on reachable subdomains."
echo -e "  - Saves reachable subdomains to a file."
echo -e "  - Saves all subdomains found with subfinder in a file."
echo -e "${GREEN}----------------------------------------------${NC}"

# Function to check if a host is reachable
function is_reachable {
    local host="$1"
    if ping -c 1 -W 1 "$host" &> /dev/null; then
        return 0  # Reachable
    else
        return 1  # Not reachable
    fi
}

# Function to run nuclei scan
function run_nuclei_scan {
    local subdomain="$1"
    local output_dir="$2"

    echo -e "${GREEN}Running nuclei scan on $subdomain${NC}"
    nuclei -uc -retries 2 -u "$subdomain" -o "$output_dir/nuclei_$subdomain.txt"
}

# Function to run nmap scan
function run_nmap_scan {
    local subdomain="$1"
    local output_dir="$2"

    echo -e "${GREEN}Running nmap scan on $subdomain${NC}"
    nmap --random-agent --script discovery, vuln -Pn -sV -p- "$subdomain" -oA "$output_dir/nmap_$subdomain"
}

# Function to perform subdomain scanning
function scan_subdomain {
    local subdomain="$1"
    local output_dir="$2"
    local reachable_subdomains_file="$3"

    echo "Checking reachability for $subdomain"

    # Check if the subdomain is reachable
    if is_reachable "$subdomain"; then
        echo -e "${GREEN}Scanning $subdomain${NC}"

        # Save reachable subdomain to the file
        echo -e "${GREEN}All subdomains found saved to $reachable_subdomains_file${NC}"
        echo "$subdomain" >> "$reachable_subdomains_file"

        # Run nuclei scan
        run_nuclei_scan "$subdomain" "$output_dir"

        # Run nmap scan
        run_nmap_scan "$subdomain" "$output_dir"

        echo "-----------------------------"
    else
        echo -e "${RED}$subdomain is not reachable. Skipping scan.${NC}"
    fi
}

# Function to perform subdomain scanning for a given hostname
function scan_host {
    local hostname="$1"
    local output_dir="$2"
    local reachable_subdomains_file="$3"

    echo "Checking reachability for $hostname"

    # Check if the host is reachable
    if is_reachable "$hostname"; then
        echo -e "${GREEN}$hostname is reachable. Scanning subdomains.${NC}"

        # Use subfinder to find subdomains
        subdomains=$(subfinder -d "$hostname" -silent)
        echo "$subdomains" >> "$output_dir/$hostname Subdomains"

        # Loop through each subdomain
        while IFS= read -r subdomain; do
            scan_subdomain "$subdomain" "$output_dir" "$reachable_subdomains_file"
        done <<< "$subdomains"
    else
        echo -e "${RED}$hostname is not reachable. Skipping subdomain scan.${NC}"
    fi
}

# Function to create the output directory
function create_output_directory {
    local output_dir="$1"
    mkdir -p "$output_dir"
}

# Function to perform the main scanning process
function perform_scan {
    local input_file="$1"
    local output_dir="$2"
    local reachable_subdomains_file="$output_dir/reachable_subdomains.txt"

    create_output_directory "$output_dir"

    # Loop through each hostname in the input file
    while IFS= read -r hostname; do
        scan_host "$hostname" "$output_dir" "$reachable_subdomains_file"
    done < "$input_file"

    echo -e "${GREEN}Scan completed. Results stored in: $output_dir${NC}"
    echo -e "${GREEN}Reachable subdomains saved to: $reachable_subdomains_file${NC}"
}

# Check if subfinder is installed
if ! command -v subfinder &> /dev/null; then
    echo -e "${RED}subfinder is not installed. Please install it first (https://github.com/projectdiscovery/subfinder)${NC}"
    exit 1
fi

# Check if nuclei is installed
if ! command -v nuclei &> /dev/null; then
    echo -e "${RED}nuclei is not installed. Please install it first (https://github.com/projectdiscovery/nuclei)${NC}"
    exit 1
fi

# Check if nmap is installed
if ! command -v nmap &> /dev/null; then
    echo -e "${RED}nmap is not installed. Please install it first (https://nmap.org/)${NC}"
    exit 1
fi

# Ask the user for the output directory name
read -p "Enter the name for the output directory: " output_name

# Run the main scanning process
perform_scan "$1" "$output_name"
