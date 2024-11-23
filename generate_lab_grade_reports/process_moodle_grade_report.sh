#!/bin/bash

# Check if input file is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_csv_file>"
    exit 1
fi

# Input CSV file
input_file="$1"

# Define allowed groups
declare -a groups=("311CA" "312CA" "313CA" "314CA" "315CA"
                   "311CB" "312CB" "313CB" "314CB" "315CB"
                   "311CC" "312CC" "313CC" "314CC" "315CC"
                   "311CD" "312CD" "313CD" "314CD" "315CD")

# Create a temporary directory for output
output_dir="./output"
mkdir -p "$output_dir"

# Clear old files if they exist
rm -f "$output_dir"/*

# Define the header line
header="Student,Email,Grupa,Asistent,Total laborator,Laborator 01,Laborator 02,Laborator 03,Laborator 04,Laborator 05,Laborator 06,Laborator 07,Laborator 08,Laborator 09,Laborator 10,Laborator 11,Laborator 12"

# Add the header to all output files
for group in "${groups[@]}" "Altii"; do
    echo "$header" > "${output_dir}/USO 2024-2025 - Catalog - ${group}.csv"

    # Add a line with all empty columns (same number of columns as the header)
    echo ",,,,,,,,,,,,,,," >> "${output_dir}/USO 2024-2025 - Catalog - ${group}.csv"

    # Add the "Miss Perfection" line
    echo "Miss Perfection,,,,,10,10,10,10,10,10,10,10,10,10,10,10" >> "${output_dir}/USO 2024-2025 - Catalog - ${group}.csv"
done

# Read the CSV file line by line
while IFS=',' read -r firstname lastname _ _ _ email _ _ _ _ _ group _; do
    # Skip header line or invalid rows
    if [[ "$firstname" == "First name" || -z "$group" ]]; then
        continue
    fi

    # Skip groups containing "AC"
    if [[ "$group" == *"AC"* ]]; then
        continue
    fi

    # Combine First Name and Last Name
    fullname="${lastname} ${firstname}"

    # Determine the group file
    if [[ " ${groups[@]} " =~ " ${group} " ]]; then
        group_file="USO 2024-2025 - Catalog - ${group}.csv"
    else
        group_file="USO 2024-2025 - Catalog - Altii.csv"
    fi

    # Append the extracted information to the appropriate file
    echo "${fullname},${email},${group},,,,,,,,,,,,,," >> "${output_dir}/${group_file}"
done < "$input_file"
