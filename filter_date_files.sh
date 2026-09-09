#!/bin/bash
## filter_date_files.sh
## Version : 1.0
## Description : This script allows the creation of a file containing a list of files with a specific name containing a date between two chosen dates
## Usage : sbatch --export=FILES_NAME_FORM=< format of resultfiles, for ex :"research_result_es_*.log">,START_DATE=<start date of resultfiles to take into account>,END_DATE=<end date of resultfiles to take into account>,SAMPLE_TYPE=<"es", "gs" or "nbs"> filter_date_files.sh
## Output : selected files file containing a list of files with a specific name containing a date between two chosen dates
## Requirements : resultfiles produced by research_result.py

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260623
## Last revision date : 20260717
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=filter_date_files
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr

if [[ -z ${FILES_NAME_FORM} ]]
then
    echo "FILES_NAME_FORM was not defined : execution stopped" 
    exit 1
fi

if [ -z ${SAMPLE_TYPE} ]
then
    echo "SAMPLE_TYPE was not defined : execution stopped" 
    exit 1
fi

if [ -z ${START_DATE} ]
then
    echo "START_DATE was not defined : execution stopped" 
    exit 1
fi

if [ -z ${END_DATE} ]
then
    echo "END_DATE was not defined : execution stopped" 
    exit 1
fi

echo "Creating or emptying selected_files.txt"
: > selected_files_${SAMPLE_TYPE}.txt

echo "Selecting files between ${START_DATE} and ${END_DATE}"
for f in ${FILES_NAME_FORM} 
do
    if [[ ${f} =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}) ]]
    then
        d=${BASH_REMATCH[1]}

        if [[ (${d} > "$START_DATE" || ${d} == "$START_DATE") &&
              (${d} < "$END_DATE"   || ${d} == "$END_DATE") ]]
        then
            printf "%s " "$f" >> selected_files_${SAMPLE_TYPE}.txt
        fi
    fi
done