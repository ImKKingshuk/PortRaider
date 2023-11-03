#!/bin/bash


welcome_screen() {
    cat << "EOF"
******************************************
*               PortRaider               *
*          Network Research Tool         *
*      ----------------------------      *
*                        by @ImKKingshuk *
* Github- https://github.com/ImKKingshuk *
******************************************
EOF
}


port_scan() {
    host="$1"
    port="$2"


    (echo >/dev/tcp/"$host"/"$port") 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Port $port is open"
    else
        echo "Port $port is closed"
    fi
}


parallel_port_scan() {
    host="$1"
    port_range="$2"
    for port in $(seq $port_range); do
        port_scan "$host" "$port" &
        # Limit the number of concurrent scans to 50 (adjust as needed)
        if [ $(jobs | wc -l) -ge 50 ]; then
            wait -n
        fi
    done
    wait
}


save_results() {
    host="$1"
    port_range="$2"
    output_file="$3"
    if [[ "$4" == "json" ]]; then
        parallel_port_scan "$host" "$port_range" | jq -c . > "$output_file"
    else
        parallel_port_scan "$host" "$port_range" > "$output_file"
    fi
    echo "Results saved to $output_file"
}


discover_common_ports() {
    host="$1"
    common_ports="21 22 80 443 3306"  # Add more ports as needed
    echo "Scanning common ports ($common_ports) on $host..."
    parallel_port_scan "$host" "$common_ports"
}


scan_ip_range() {
    base_ip="$1"
    start_range="$2"
    end_range="$3"
    for ip in $(seq $start_range $end_range); do
        host="$base_ip.$ip"
        parallel_port_scan "$host" "$port_range"
    done
}


main() {
    welcome_screen  

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
        scan_ip_range "$base_ip" "$start_range" "$end_range"
    fi

    echo "Port scanning complete."
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: $0"
    echo "This tool scans a range of ports on a specified host or IP address to check for open or closed ports."
    exit 0
fi

main
