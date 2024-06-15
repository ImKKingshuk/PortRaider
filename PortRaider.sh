#!/bin/bash


print_banner() {
    local banner=(
        "******************************************"
        "*                PortRaider              *"
        "*          Network Research Tool         *"
        "*                  v1.3.1                *"
        "*      ----------------------------      *"
        "*                        by @ImKKingshuk *"
        "* Github- https://github.com/ImKKingshuk *"
        "******************************************"
    )
    local width=$(tput cols)
    for line in "${banner[@]}"; do
        printf "%*s\n" $(((${#line} + width) / 2)) "$line"
    done
    echo
}


port_scan() {
    local host="$1"
    local port="$2"

    (echo >/dev/tcp/"$host"/"$port") 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Port $port is open"
    else
        echo "Port $port is closed"
    fi
}


parallel_port_scan() {
    local host="$1"
    local port_range="$2"
    for port in $(seq $port_range); do
        port_scan "$host" "$port" &
      
        if [ $(jobs | wc -l) -ge 50 ]; then
            wait -n
        fi
    done
    wait
}


save_results() {
    local host="$1"
    local port_range="$2"
    local output_file="$3"
    local format="$4"
    if [[ "$format" == "json" ]]; then
        parallel_port_scan "$host" "$port_range" | jq -c . > "$output_file"
    else
        parallel_port_scan "$host" "$port_range" > "$output_file"
    fi
    echo "Results saved to $output_file"
}


discover_common_ports() {
    local host="$1"
    local common_ports="21 22 80 443 3306"  
    echo "Scanning common ports ($common_ports) on $host..."
    parallel_port_scan "$host" "$common_ports"
}


scan_ip_range() {
    local base_ip="$1"
    local start_range="$2"
    local end_range="$3"
    local port_range="$4"
    for ip in $(seq $start_range $end_range); do
        local host="$base_ip.$ip"
        parallel_port_scan "$host" "$port_range"
    done
}


main() {
    print_banner

    read -p "Enter the host or IP to scan: " host
    read -p "Enter the range of ports to scan (e.g., 80-1000): " port_range
    read -p "Do you want to save the results to a file? (y/n): " save_results_option

    if [[ "$save_results_option" == "y" || "$save_results_option" == "Y" ]]; then
        read -p "Specify the output format (json/txt): " output_format
        read -p "Enter the output filename: " output_file
        save_results "$host" "$port_range" "$output_file" "$output_format"
    else
        parallel_port_scan "$host" "$port_range"
    fi

    read -p "Do you want to scan common ports? (y/n): " scan_common_ports
    if [[ "$scan_common_ports" == "y" || "$scan_common_ports" == "Y" ]]; then
        discover_common_ports "$host"
    fi

    read -p "Do you want to scan a range of IP addresses? (y/n): " scan_ip_range_option
    if [[ "$scan_ip_range_option" == "y" || "$scan_ip_range_option" == "Y" ]]; then
        read -p "Enter the base IP address (e.g., 192.168.0): " base_ip
        read -p "Enter the starting IP range: " start_range
        read -p "Enter the ending IP range: " end_range
        scan_ip_range "$base_ip" "$start_range" "$end_range" "$port_range"
    fi

    echo "Port scanning complete."
}


if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0"
    echo "This tool scans a range of ports on a specified host or IP address to check for open or closed ports."
    exit 0
fi

main
