#!/bin/bash
## get_nb_var.sh
## Version : 1.0
## Description : This script allows the creation of a file containing, for one sample type, one column with the dij name and a second column with the number of variations found for this dij
## Usage : sbatch --export=INPUTDIR=<path/to/directory/containing/qualif_2_12/directory,SAMPLE_TYPE=<"es", "gs" or "nbs">,OUTPUT_FILE=<"not mandatory name of output file">,LIST_PED_ARG=<list of PED to analyze under this format "PED1:PED2:PED3:etc">,LIST_DIJ_ARG=<list of dij (corresponding to PED) to analyze under this format "dij1:dij2:dij3:etc"> get_nb_var.sh
## Output : nb_var file containing, for one sample type, one column with the dij name and a second column with the number of variations found for this dij
## Requirements : analysed dij files (with analysis pipeline)

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260701
## Last revision date : 20260717
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=get_nb_var
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr


if [ -z ${INPUTDIR} ]
then
    echo "INPUTDIR was not specified"
    exit 1
fi

if [ -z ${SAMPLE_TYPE} ]
then
    echo "SAMPLE_TYPE was not specified"
    exit 1
fi

if [ -z ${LIST_PED_ARG} ]
then
    echo "LIST_PED_ARG was not specified"
    exit 1
fi

if [ -z ${LIST_DIJ_ARG} ]
then
    echo "LIST_DIJ_ARG was not specified"
    exit 1
fi

if [ -z ${OUTPUT_FILE} ]
then 
    OUTPUT_FILE="nb_var_${SAMPLE_TYPE}.txt"
fi

IFS=: read -ra LIST_PED <<< ${LIST_PED_ARG}
IFS=: read -ra LIST_DIJ <<< ${LIST_DIJ_ARG}

nb_PED=${#LIST_PED[@]}
:> ${OUTPUT_FILE}

if [ ${SAMPLE_TYPE} == "es" ]
then
    for ((i=0; i<nb_PED; i++))
    do
        nb_var=$(grep -v "^##" ${INPUTDIR}/qualif_2_12/es/${LIST_PED[$i]}/${LIST_DIJ[$i]}/${LIST_DIJ[$i]}.[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].annot.vcf | wc -l)
        echo "${LIST_DIJ[$i]}    ${nb_var}" >> ${OUTPUT_FILE}
    done
fi


if [ ${SAMPLE_TYPE} == "gs" ]
then
    for ((i=0; i<nb_PED; i++))
    do
        nb_var=$(grep -v "^##" ${INPUTDIR}/qualif_2_12/gs/${LIST_PED[$i]}/${LIST_DIJ[$i]}/${LIST_DIJ[$i]}.full.[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].annot.vcf | wc -l)
        echo "${LIST_DIJ[$i]}    ${nb_var}" >> ${OUTPUT_FILE}
    done
fi


if [ ${SAMPLE_TYPE} == "nbs" ]
then
    for ((i=0; i<nb_PED; i++))
    do
        nb_var=$(grep -v "^##" ${INPUTDIR}/qualif_2_12/nbs/${LIST_PED[$i]}/${LIST_DIJ[$i]}/${LIST_DIJ[$i]}.pgc1.annotate_variants.vcf | wc -l)
        echo "${LIST_DIJ[$i]}    ${nb_var}" >> ${OUTPUT_FILE}
    done
fi