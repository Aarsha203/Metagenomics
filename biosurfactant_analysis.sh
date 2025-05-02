#!/bin/bash

# Set the main antiSMASH output directory
ANTISMASH_DIR="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/antismash_results/"

# Number of threads
THREADS=8

# Output file for summary of biosurfactant-related hits
OUTPUT_SUMMARY="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/antismash_results/biosurfactant_hits_summary.tsv"
KEYWORDS=("biosurfactant" "rhamnosyltransferase" "surfactin" "lipopeptide" "glycolipid" "NRPS" "PKS")

# Create or clear the summary file
echo -e "File\tKeyword\tLine" > "$OUTPUT_SUMMARY"

echo "Searching for biosurfactant-related keywords in antiSMASH .gbk files..."

# Function to search for a keyword in a .gbk file
search_keyword_in_file() {
    local gbk_file="$1"
    local keyword="$2"
    
    # Debugging: Output the file and keyword being processed
    echo "Searching in $gbk_file for keyword: $keyword"

    matches=$(grep -i "$keyword" "$gbk_file")
    if [[ ! -z "$matches" ]]; then
        while IFS= read -r line; do
            echo -e "$(basename "$gbk_file")\t$keyword\t$line" >> "$OUTPUT_SUMMARY"
        done <<< "$matches"
    fi
}

# Loop through all .gbk files and search keywords
find "$ANTISMASH_DIR" -type f -name "*.gbk" | while read -r gbk_file; do
    for keyword in "${KEYWORDS[@]}"; do
        search_keyword_in_file "$gbk_file" "$keyword"
    done
done

echo "Search completed. Summary saved to:"
echo "$OUTPUT_SUMMARY"

### Plotting part ###

# Set input and output paths
INPUT_TSV="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/antismash_results/biosurfactant_hits_summary.tsv"
COUNT_FILE="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/antismash_results/keyword_counts.txt"
PLOT_SCRIPT="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/antismash_results/plot_commands.gnuplot"
OUTPUT_PNG="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/antismash_results/biosurfactant_keyword_plot.png"

# Extract keyword counts
awk -F '\t' 'NR>1 {counts[$2]++} END {for (k in counts) print k, counts[k]}' "$INPUT_TSV" | sort > "$COUNT_FILE"

# Debugging: Check if counts were created
echo "Counts from keyword analysis:"
cat "$COUNT_FILE"

# Check if the COUNT_FILE is empty or contains valid data
if [[ ! -s "$COUNT_FILE" ]]; then
    echo "No valid data found for plotting."
    exit 1
fi

# Create gnuplot script
cat <<EOF > "$PLOT_SCRIPT"
set terminal pngcairo size 1000,600 enhanced font 'Verdana,10'
set output '$OUTPUT_PNG'
set title 'Biosurfactant-related Genes from antiSMASH Results'
set xlabel 'Keyword'
set ylabel 'Count'
set style data histograms
set style fill solid 1.0 border -1
set boxwidth 0.5
set xtics rotate by -45
plot '$COUNT_FILE' using 2:xtic(1) title ''
EOF

# Generate the plot
gnuplot "$PLOT_SCRIPT"

echo "Plot saved to: $OUTPUT_PNG"

