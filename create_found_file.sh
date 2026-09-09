#!/bin/bash
## create_found_file.sh
## Version : 1.0
## Description : This script allows the creation of a file containing one column with dij files and a second column containing True or False depending on if the searched variation in the dij file was found or not
## Usage : sbatch --export=FILES_NAME_FORM=<format of resultfiles, for ex : "research_result_es_*.log">,SAMPLE_TYPE=<"es", "gs" or "nbs",START_DATE=<start date of resultfiles to take into account>,END_DATE=$<end date of resultfiles to take into account> create_found_file.sh
## Output : found file containing one column with dij files and a second column containing True or False depending on if the searched variation in the dij file was found or not
## Requirements : resultfiles produced by research_result.py

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260626
## Last revision date : 20260717
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=create_found_file
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


: > ordered_files_${SAMPLE_TYPE}.txt
: > found_${SAMPLE_TYPE}.txt

{
    for f in ${FILES_NAME_FORM}
    do
        if [[ ${f} =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}) ]]
        then
            d=${BASH_REMATCH[1]}

            if [[ (${d} > "$START_DATE" || ${d} == "$START_DATE") &&
                  (${d} < "$END_DATE"   || ${d} == "$END_DATE") ]]
            then
                printf "%s %s\n" "${d}" "${f}"
            fi
        fi
    done
} | sort | cut -d' ' -f2- > ordered_files_${SAMPLE_TYPE}.txt



if [ ${SAMPLE_TYPE} == "es" ]
then
    for file in $(cat ordered_files_${SAMPLE_TYPE}.txt)
    do
        dijex=$(grep -oE 'dijex[0-9]{4}' ${file} | head -n1)
        if [ "$(awk 'END { print NR }' ${file})" -eq 1 ]
        then
            echo "${dijex} False" >> found_${SAMPLE_TYPE}.txt
        else
            if grep -q "not found" ${file}
            then
                echo "${dijex} False" >> found_${SAMPLE_TYPE}.txt
            else
                echo "${dijex} True" >> found_${SAMPLE_TYPE}.txt
            fi
        fi
    done
fi

if [ ${SAMPLE_TYPE} == "gs" ]
then
    for file in $(cat ordered_files_${SAMPLE_TYPE}.txt)
    do
        dijen=$(grep -oE 'dijen[0-9]{3,4}' ${file} | head -n1)
        if [ "$(awk 'END { print NR }' ${file})" -eq 1 ]
        then
            echo "${dijen} False" >> found_${SAMPLE_TYPE}.txt
        else
            if grep -q "not found" ${file}
            then
                echo "${dijen} False" >> found_${SAMPLE_TYPE}.txt
            else
                echo "${dijen} True" >> found_${SAMPLE_TYPE}.txt
            fi
        fi
    done
fi

if [ ${SAMPLE_TYPE} == "nbs" ]
then
    for file in $(cat ordered_files_${SAMPLE_TYPE}.txt)
    do
        dijnbs=$(grep -oE 'dijnbs[0-9]{3}|dijen[0-9]{4}' ${file} | head -n1)
        if [ "$(awk 'END { print NR }' ${file})" -eq 1 ]
        then
            echo "${dijnbs} False" >> found_${SAMPLE_TYPE}.txt
        else
            if grep -q "not found" ${file}
            then
                echo "${dijnbs} False" >> found_${SAMPLE_TYPE}.txt
            else
                echo "${dijnbs} True" >> found_${SAMPLE_TYPE}.txt
            fi
        fi
    done
fi