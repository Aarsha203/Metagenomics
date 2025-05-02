set terminal pngcairo size 1000,600 enhanced font 'Verdana,10'
set output '/mnt/06E657BEE657ACA5/metagenomics/results_288/analysis/antismash_results/biosurfactant_keyword_plot.png'
set title 'Biosurfactant- from antiSMASH Results'
set xlabel 'Keyword'
set ylabel 'Count'
set style data histograms
set style fill solid 1.0 border -1
set boxwidth 0.5
set xtics rotate by -45
plot '/mnt/06E657BEE657ACA5/metagenomics/results_288/analysis/antismash_results/keyword_counts.txt' using 2:xtic(1) title ''
