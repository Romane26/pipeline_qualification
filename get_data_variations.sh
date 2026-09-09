#!/bin/bash
## get_data_variations.sh
## Version : 1.0
## Description : This script allows user the creation of a file containing all useful data about a reference variation
## Usage : sbatch --export=DIJEXN=<dijex.n.nbs>,DATE=<date when variation was searched>,SEARCH_FILE=<path/to/file/where/variation/was/searched>,SEARCHED_VARIATION=<variation>,SAMPLE_TYPE=<"es", "gs" or "nbs">,FOUND_FILE=<path/to/found/file>,HTML_REPORT=<name of html report mentionning variation>,NB_VAR_FOUND_FILE=<path/to/nb_var_found_file> get_data_variations.sh
## Output : data_variation text file containing one piece of information per line about a searched reference variation
## Requirements : found_file created by create_found_file.sh, nb_var_found file crated by get_nb_var.sh

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260625
## Last revision date : 20260720
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=get_data_variations
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr

if [ -z ${DIJEXN} ]
then
    echo "Dijex or dijen was not specified : execution stopped" 
    exit 1
fi


if [ -z ${SAMPLE_TYPE} ]
then
    echo "SAMPLE TYPE was not specified : execution stopped" 
    exit 1
fi

if [ -z ${DATE} ]
then
    echo "Date was not specified : execution stopped" 
    exit 1
fi

if [ -z ${SEARCH_FILE} ]
then
    echo "Search file was not specified : execution stopped" 
    exit 1
fi

if [ -z ${SEARCHED_VARIATION} ]
then
    echo "Searched variation was not specified : execution stopped" 
    exit 1
fi

if [ -z ${FOUND_FILE} ]
then
    echo "FOUND_FILE was not specified : execution stopped" 
    exit 1
fi

if [ -z ${NB_VAR_FOUND_FILE} ]
then
    echo "NB_VAR_FOUND_FILE was not specified : execution stopped" 
    exit 1
fi

if [ -z ${HTML_REPORT} ]
then
    HTML_REPORT=None
fi

FOUND=$(awk -v dijex_searched=${DIJEXN} '$1==dijex_searched {print $2}' ${FOUND_FILE})
NB_VAR_FOUND=$(awk -v dijex_searched=${DIJEXN} '$1==dijex_searched {print $2}' ${NB_VAR_FOUND_FILE})


echo ${DIJEXN} > data_variations_${SAMPLE_TYPE}.txt
echo ${DATE} >> data_variations_${SAMPLE_TYPE}.txt
echo ${SEARCH_FILE} >> data_variations_${SAMPLE_TYPE}.txt
echo "${SEARCHED_VARIATION}" >> data_variations_${SAMPLE_TYPE}.txt
echo ${FOUND} >> data_variations_${SAMPLE_TYPE}.txt
echo ${NB_VAR_FOUND} >> data_variations_${SAMPLE_TYPE}.txt
echo ${HTML_REPORT} >> data_variations_${SAMPLE_TYPE}.txt

