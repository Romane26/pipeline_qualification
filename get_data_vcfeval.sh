#!/bin/bash
## get_data_vcfeval.sh
## Version : 1.0
## Description : This script allows user the creation of a file containing all useful data about a vcfeval analysis
## Usage : sbatch --export=SAMPLE_TYPE=<"es", "gs" or "nbs">,DIJEXN=<dijex.n.nbs>,DATE=<date of the analysis>,VCF_TRUTH=<benchmark.vcf.gz truth file>,SDF_REFERENCE=<sdf reference files>,OPTIONS=<options used for the analysis (bed_regions, evaluation_regions,etc)>,SUMMARY_FILE=<summary.txt file of the analysis>,HTML_REPORT=<name of html report mentionning the analysis if existing>,NB_VAR_FOUND_FILE=<path/to/nb_var_found_file> get_data_vcfeval.sh
## Output : data_vcfeval text file containing one piece of information per line about a vcfeval analysis
## Requirements : nb_var_found file created by get_nb_var.sh

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260624
## Last revision date : 20260720
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=get_data_vcfeval
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr

if [ -z ${SAMPLE_TYPE} ]
then
    echo "SAMPLE TYPE was not specified : execution stopped" 
    exit 1
fi

if [ -z ${DIJEXN} ]
then
    echo "Dijex or dijen was not specified : execution stopped" 
    exit 1
fi

if [ -z ${DATE} ]
then
    echo "Date was not specified : execution stopped" 
    exit 1
fi

if [ -z ${VCF_TRUTH} ]
then
    echo "vcf truth file was not specified : execution stopped" 
    exit 1
fi

if [ -z ${SDF_REFERENCE} ]
then
    echo "sdf reference file was not specified : execution stopped" 
    exit 1
fi

if [ -z ${OPTIONS} ]
then
    OPTIONS=None
fi

if [ -z ${SUMMARY_FILE} ]
then
    echo "Summary.txt file was not specified : execution stopped"
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

NB_VAR_FOUND=$(awk -v dij_searched=${DIJEXN} '$1==dij_searched {print $2}' ${NB_VAR_FOUND_FILE})

echo ${DIJEXN} > data_vcfeval_${SAMPLE_TYPE}.txt
echo ${DATE} >> data_vcfeval_${SAMPLE_TYPE}.txt
echo ${VCF_TRUTH} >> data_vcfeval_${SAMPLE_TYPE}.txt
echo ${SDF_REFERENCE} >> data_vcfeval_${SAMPLE_TYPE}.txt
echo "${OPTIONS}" >> data_vcfeval_${SAMPLE_TYPE}.txt
awk 'NR==4 {print $1}' ${SUMMARY_FILE} >> data_vcfeval_${SAMPLE_TYPE}.txt
awk 'NR==4 {print $2}' ${SUMMARY_FILE} >> data_vcfeval_${SAMPLE_TYPE}.txt
awk 'NR==4 {print $3}' ${SUMMARY_FILE} >> data_vcfeval_${SAMPLE_TYPE}.txt
awk 'NR==4 {print $4}' ${SUMMARY_FILE} >> data_vcfeval_${SAMPLE_TYPE}.txt
awk 'NR==4 {print $5}' ${SUMMARY_FILE} >> data_vcfeval_${SAMPLE_TYPE}.txt
awk 'NR==4 {print $6}' ${SUMMARY_FILE} >> data_vcfeval_${SAMPLE_TYPE}.txt
awk 'NR==4 {print $7}' ${SUMMARY_FILE} >> data_vcfeval_${SAMPLE_TYPE}.txt
awk 'NR==4 {print $8}' ${SUMMARY_FILE} >> data_vcfeval_${SAMPLE_TYPE}.txt
echo ${NB_VAR_FOUND} >> data_vcfeval_${SAMPLE_TYPE}.txt
echo ${HTML_REPORT} >> data_vcfeval_${SAMPLE_TYPE}.txt