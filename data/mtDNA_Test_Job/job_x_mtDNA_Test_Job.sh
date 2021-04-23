#!/bin/sh
cd /var/www/mtdna/data/mtDNA_Test_Job
/var/www/mtdna/mit_single.sh -n 4 > sgadviser_mtdna.log 2> sgadviser_mtdna.err 
/pro/scrippscall/WEB_SERVER/mtb2json.pl -i mit_prioritized_variants.txt -f json4html > mit.json
/var/www/mtdna/sendmail.pl mit_prioritized_variants.txt mtDNA_Test_Job mrueda@scripps.edu
rm *.ba? *.fastq
