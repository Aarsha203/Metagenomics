#!/bin/bash
set -e

ANNOTATION_DIR="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/eggnog_annotations/"
OUTPUT="$ANNOTATION_DIR/final.emapper.annotations"

# Remove existing final file if it exists
rm -f "$OUTPUT"

# Add header from the first matching file
first_file=$(find "$ANNOTATION_DIR" -type f -name "*.emapper.annotations" ! -name "$(basename "$OUTPUT")" | head -n 1)
if [[ -f "$first_file" ]]; then
    head -n 1 "$first_file" > "$OUTPUT"
else
    echo "No .emapper.annotations files found in $ANNOTATION_DIR"
    exit 1
fi

# Append data (excluding header and excluding the output file)
find "$ANNOTATION_DIR" -type f -name "*.emapper.annotations" ! -name "$(basename "$OUTPUT")" | while read -r file; do
    tail -n +2 "$file" >> "$OUTPUT"
    echo "✅ Added $(basename "$file")"
done

echo "🎉 Done combining emapper annotation files into final.emapper.annotations"

#!/bin/bash
set -e

# -------- CONFIG --------
ANNOTATION_FILE="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/eggnog_annotations/final.emapper.annotations"
OUTPUT_DIR="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/eggnog_annotations/"
OUTPUT_TSV="${OUTPUT_DIR}/KEGG-WGMG314_annotations.tsv"  # Added explicit filename
# ------------------------

echo "[*] Parsing $ANNOTATION_FILE to extract UniProt and KEGG info..."

python3 - <<EOF
import csv

input_file = "$ANNOTATION_FILE"
output_file = "$OUTPUT_TSV"

with open(input_file) as infile, open(output_file, 'w', newline='') as out:
    writer = csv.writer(out, delimiter='\t')
    writer.writerow([
        "UniProt_ID", "KEGG_Pathways", "EC_Number", "BRENDA_EC",
        "Recommended_Name", "Organism", "KEGG_ID"
    ])
    for line in infile:
        if line.startswith('#'):
            continue
        fields = line.strip().split('\t')
        if len(fields) < 11:
            continue
        uniprot_id = fields[5] or "-"
        kegg_pathways = fields[10] or "-"
        ec_number = fields[9] or "-"
        brenda_ec = ec_number
        recommended_name = fields[6] or "-"
        organism = fields[4] or "-"
        kegg_id = fields[10] or "-"

        writer.writerow([
            uniprot_id, kegg_pathways, ec_number, brenda_ec,
            recommended_name, organism, kegg_id
        ])
print(f"[✓] Output saved to {output_file}")
EOF
