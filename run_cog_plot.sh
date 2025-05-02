#!/bin/bash
#run in base 
# if you want to combine all the .emapper file do this code 
# Then combine only the real input files
#head -n 1 1.emapper.annotations > final.emapper.annotations
#tail -n +2 -q 1.emapper.annotations 2.emapper.annotations 3.emapper.annotations 4.emapper.annotations >> final.emapper.annotations
set -e

# --------- Config ---------
ANNOTATION_FILE="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/eggnog_annotations/final.emapper.annotations"
OUTPUT_IMAGE="/media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/cog_results/cog_functional_piechart.png"
TMP_COG_LIST="media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/cog_results/cog_categories.tmp"
CSV_OUTPUT="media/user/3076B93776B8FF22/metagenomics_WGS/results/analysis/224/cog_results/cog_functional_counts.csv"
# --------------------------
mkdir -p "$(dirname "$CSV_OUTPUT")"

# COG function descriptions
declare -A COG_FUNCTIONS=(
    [A]="RNA processing and modification"
    [B]="Chromatin structure and dynamics"
    [C]="Energy production and conversion"
    [D]="Cell cycle, cell division, chromosome partitioning"
    [E]="Amino acid transport and metabolism"
    [F]="Nucleotide transport and metabolism"
    [G]="Carbohydrate transport and metabolism"
    [H]="Coenzyme transport and metabolism"
    [I]="Lipid transport and metabolism"
    [J]="Translation, ribosomal structure and biogenesis"
    [K]="Transcription"
    [L]="Replication, recombination and repair"
    [M]="Cell wall/membrane/envelope biogenesis"
    [N]="Cell motility"
    [O]="Post-translational mod, protein turnover, chaperones"
    [P]="Inorganic ion transport and metabolism"
    [Q]="Secondary metabolites biosynthesis"
    [R]="General function prediction only"
    [S]="Function unknown"
    [T]="Signal transduction mechanisms"
    [U]="Intracellular trafficking, secretion, vesicular transport"
    [V]="Defense mechanisms"
    [W]="Extracellular structures"
    [X]="Mobilome: prophages, transposons"
    [Y]="Nuclear structure"
    [Z]="Cytoskeleton"
)

# Check annotation file exists
if [[ ! -f "$ANNOTATION_FILE" ]]; then
    echo "❌ Error: Annotation file not found!"
    exit 1
fi

echo "[*] Extracting COG functional categories..."
awk -F'\t' '!/^#/ && $21 != "-" && $21 != "" { print $21 }' "$ANNOTATION_FILE" | \
    sed 's/[^A-Z]//g' | fold -w1 | sort | uniq -c > "$TMP_COG_LIST"

echo "[*] Generating CSV with function descriptions and percentages..."

# Inline Python to handle CSV + pie plot
python3 - <<EOF
import matplotlib.pyplot as plt
import csv

# COG descriptions from Bash dict
cog_descriptions = {
    "A": "RNA processing and modification",
    "B": "Chromatin structure and dynamics",
    "C": "Energy production and conversion",
    "D": "Cell cycle, cell division, chromosome partitioning",
    "E": "Amino acid transport and metabolism",
    "F": "Nucleotide transport and metabolism",
    "G": "Carbohydrate transport and metabolism",
    "H": "Coenzyme transport and metabolism",
    "I": "Lipid transport and metabolism",
    "J": "Translation, ribosomal structure and biogenesis",
    "K": "Transcription",
    "L": "Replication, recombination and repair",
    "M": "Cell wall/membrane/envelope biogenesis",
    "N": "Cell motility",
    "O": "Post-translational mod, protein turnover, chaperones",
    "P": "Inorganic ion transport and metabolism",
    "Q": "Secondary metabolites biosynthesis",
    "R": "General function prediction only",
    "S": "Function unknown",
    "T": "Signal transduction mechanisms",
    "U": "Intracellular trafficking, secretion, vesicular transport",
    "V": "Defense mechanisms",
    "W": "Extracellular structures",
    "X": "Mobilome: prophages, transposons",
    "Y": "Nuclear structure",
    "Z": "Cytoskeleton"
}

counts = {}
total = 0

with open("$TMP_COG_LIST") as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) != 2:
            continue
        count, code = parts
        count = int(count)
        counts[code] = count
        total += count

# Write CSV
with open("$CSV_OUTPUT", "w", newline='') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["COG Code", "Function Description", "Count", "Percentage (%)"])
    for code in sorted(counts.keys()):
        desc = cog_descriptions.get(code, "Unknown")
        count = counts[code]
        pct = round((count / total) * 100, 2)
        writer.writerow([code, desc, count, pct])
        
from prettytable import PrettyTable

table = PrettyTable()
table.field_names = ["COG Code", "Function Description", "Count", "Percentage (%)"]

for code in sorted(counts.keys()):
    desc = cog_descriptions.get(code, "Unknown")
    count = counts[code]
    pct = round((count / total) * 100, 2)
    table.add_row([code, desc, count, pct])

print(table)

# Calculate labels like "A (11.1%)"
labels = [f"{code} ({(counts[code] / total) * 100:.1f}%)" for code in counts]
sizes = [counts[code] for code in counts]

plt.figure(figsize=(10, 10))
# autopct removed, percentage is now part of the label
plt.pie(
    sizes,
    labels=labels,
    startangle=140,
    textprops={'fontsize': 10}
)
plt.title("COG Functional Category Distribution")
plt.tight_layout()
plt.savefig("$OUTPUT_IMAGE", dpi=300)

print("[✓] Pie chart saved as $OUTPUT_IMAGE")
print("[✓] CSV saved as $CSV_OUTPUT")
EOF

print(table)

# Cleanup
rm "$TMP_COG_LIST"

