#!/bin/bash

# Activate environment if needed
# conda activate antismash_env

# Define directories
BIN_DIR="/media/user/3076B93776B8FF22/metagenomics_WGS/results/GenomeBinning/224/MaxBin2/bins/"
ANNOTATION_DIR="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/"
ANTISMASH_DIR="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/antismash_results"

# Create output directories if they don't exist
mkdir -p "$ANNOTATION_DIR"
mkdir -p "$ANTISMASH_DIR"

# Step 1: Run Prokka on all .fa/.fasta/.fa.gz/.fasta.gz files
echo "Running Prokka on bin files in $BIN_DIR..."
shopt -s nullglob
for fa_file in "$BIN_DIR"/*.fa "$BIN_DIR"/*.fasta "$BIN_DIR"/*.fa.gz "$BIN_DIR"/*.fasta.gz; do
    if [[ -f "$fa_file" ]]; then
        # Get filename without path and extensions (.fa/.gz/etc.)
        base_name=$(basename "$fa_file")
        base_name_no_ext="${base_name%%.fa*}"
        base_name_no_ext="${base_name_no_ext%%.fasta*}"
        prokka_outdir="$ANNOTATION_DIR/$base_name_no_ext"

        echo "Running Prokka on: $base_name"

        if [[ "$fa_file" == *.gz ]]; then
            temp_fa=$(mktemp --suffix=.fa)
            gunzip -c "$fa_file" > "$temp_fa"
            prokka --outdir "$prokka_outdir" --prefix "$base_name_no_ext" "$temp_fa"
            rm "$temp_fa"
        else
            prokka --outdir "$prokka_outdir" --prefix "$base_name_no_ext" "$fa_file"
        fi
    fi
done
shopt -u nullglob

# Step 2: Run antiSMASH on Prokka .gbk files
echo "Running antiSMASH on all .gbk files in $ANNOTATION_DIR..."
find "$ANNOTATION_DIR" -type f -name "*.gbk" | while read -r gbk_file; do
    base_name=$(basename "$gbk_file" .gbk)
    outdir="$ANTISMASH_DIR/$base_name"

    echo "Running antiSMASH on: $base_name"

    antismash --output-dir "$outdir" \
              --genefinding-tool none \
              --cpus 2 \
              --cb-general \
              --cb-subclusters \
              --cb-knownclusters \
              --asf \
              "$gbk_file"
done

echo "Pipeline completed."

