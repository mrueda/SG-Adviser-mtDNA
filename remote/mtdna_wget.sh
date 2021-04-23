#!/bin/bash
#
#   SG-Adviser mtDNA web server download script
#
#   https://genomics.scripps.edu/mtdna
#
#   Author: Manuel Rueda Ph.D.
#   Scripps Stranslational Science Institute
#   La Jolla, CA  92093-0747
#   mrueda@scripps.edu
#
#   Version: 1.0.0
#
#   Copyright (C) 2016 Manuel Rueda (mrueda@scripps.edu)
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, see <https://www.gnu.org/licenses/>.
#
#   If this program helps you in your research, please cite.

set -eu

if [[ $# -eq 0 ]] ; then
    echo "Usage: $0 URL"
    exit 0
fi

url1=$1/mit_prioritized_variants.txt
echo $url1
#url2=$1/info.txt
#url3=$1/mt_classification_best_results.csv
#url4=$1/VCF_file.vcf
if [[ $(wget $url1 -O-) ]] 2>/dev/null
  then 
   echo "Info: Calculation has finished"
   echo "Info: Downloading data..."
   wget $url1 2>/dev/null
  else
   echo "Info: The calculation is not ready yet"
fi
