#!/bin/bash

echo "🔄 Merging genus-level abundances from Kraken reports..."

INPUT_DIR="/media/user/1TB_Drive/metagenomics_WGS/results/taxonomy_mine/karken2"
OUTPUT_DIR="/media/user/1TB_Drive/metagenomics_WGS/results/analysis/beta_diversity"
mkdir -p "$OUTPUT_DIR"

# Create an empty temporary directory
TMP_DIR=$(mktemp -d)

# Extract genus-level data from each sample
for FILE in "$INPUT_DIR"/*_kraken_report.txt; do
    SAMPLE_NAME=$(basename "$FILE" .tabular)

    # Extract genus-level (G) lines, get abundance (%) and name
    awk '$4 ~ /^G$/ { gsub(/^[ \t]+/, "", $6); print $6 "\t" $1 }' "$FILE" > "$TMP_DIR/${SAMPLE_NAME}_genus.tsv"
done

echo "📑 Merging into abundance matrix..."

# Combine all genus files
python3 - <<EOF
import pandas as pd
import glob
import os

tmp_dir = "$TMP_DIR"
files = glob.glob(f"{tmp_dir}/*_genus.tsv")

dfs = []
for file in files:
    sample = os.path.basename(file).replace("_genus.tsv", "")
    df = pd.read_csv(file, sep="\t", header=None, names=["Taxa", sample])
    dfs.append(df)

# Merge all on Taxa
from functools import reduce
merged = reduce(lambda left, right: pd.merge(left, right, on="Taxa", how="outer"), dfs).fillna(0)

# Save matrix
out_path = os.path.join("$OUTPUT_DIR", "genus_abundance_matrix.tsv")
merged.to_csv(out_path, sep="\t", index=False)
EOF

echo "📊 Computing beta diversity and generating PCoA plot..."

# Now compute beta diversity and plot
python3 - <<EOF
import pandas as pd
from sklearn.metrics import pairwise_distances
from sklearn.decomposition import PCA
import matplotlib.pyplot as plt
import seaborn as sns

df = pd.read_csv("$OUTPUT_DIR/genus_abundance_matrix.tsv", sep="\t")
df.set_index("Taxa", inplace=True)
df = df.T  # Samples as rows

# Bray-Curtis dissimilarity
dist = pairwise_distances(df, metric="braycurtis")

# PCoA via PCA
pca = PCA(n_components=2)
coords = pca.fit_transform(dist)

pcoa_df = pd.DataFrame(coords, columns=["PC1", "PC2"], index=df.index)
pcoa_df.reset_index(inplace=True)
pcoa_df.rename(columns={"index": "Sample"}, inplace=True)

# Plot
sns.set(style="whitegrid")
plt.figure(figsize=(8,6))
sns.scatterplot(data=pcoa_df, x="PC1", y="PC2", hue="Sample", palette="Set2", s=100)
plt.title("PCoA Plot (Bray-Curtis)")
plt.xlabel("PC1")
plt.ylabel("PC2")
plt.tight_layout()
plt.savefig("$OUTPUT_DIR/beta_diversity_pcoa.png", dpi=300)
EOF

echo "✅ Beta diversity matrix and plot saved to: $OUTPUT_DIR"

