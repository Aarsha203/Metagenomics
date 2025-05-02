#!/bin/bash

# Path to eggNOG-mapper executable
EMAPPER="/home/user/miniconda3/envs/eggnog_env/bin/emapper.py"

# Top-level directory containing subfolders 1 to 37
BASE_DIR="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/predicted_proteins"

# Output directory for eggNOG-mapper results
OUTPUT_DIR="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/eggnog_annotations"
mkdir -p "$OUTPUT_DIR"

# eggNOG database directory
EGGNOG_DB="/home/user/.eggnogmapper/"

# Number of threads to use
THREADS=8

# Find all .faa and .fasta files in subdirectories 1 to 37
find "$BASE_DIR" -type f \( -name "*.faa" -o -name "*.fasta" \) | while read -r faa_file; do
    base_name=$(basename "$faa_file")
    base_name="${base_name%.*}"  # Strip extension

    echo "Processing $base_name..."

    "$EMAPPER" -i "$faa_file" \
        --output "$base_name" \
        --cpu "$THREADS" \
        --data_dir "$EGGNOG_DB" \
        --output_dir "$OUTPUT_DIR" \
        --itype proteins \
        --go_evidence non-electronic \
        --usemem
done

echo "All eggNOG-mapper annotations completed."

