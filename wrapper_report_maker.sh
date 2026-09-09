#!/bin/bash
## wrapper_report_maker.sh
## Version : 1.0
## Description : This script allows user to launch report_maker.sh
## Usage : sbatch --export=REPORT_NAME=<"not_mandatory_report_name">,FILES_TO_ADD=<list of vcfeval resultfiles to add to report under this format "resultfile1:resultfile2:resultfile3:etc">,SAMPLE_TYPE=<"es","gs" or "nbs">,NB_VAR_FILE=<name of relevant nb_var file>,FOUND_FILE=<name of relevant found file>,LIST_SUMMARY_FILES=<list of paths to vcfeval summary.txt files under this format "summary1:summary2:summary3:etc">,LIST_DIJ_ARG=<list of dij analysed with vcfeval to add to report under this format "dij1:dij2:dij3:etc">,PIPELINE_QUALIF=<directory/of/qualif/pipeline> wrapper_report_maker.sh
## Output : launches report_maker.sh
## Requirements : nb_var file created by get_nb_var.sh

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260624
## Last revision date : 20260717
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=wrapper_report_maker
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr

if [ -z ${REPORT_NAME} ]
then
    REPORT_NAME="report_$(date +"%F_%H-%M-%S")"
fi

if [ -z ${SAMPLE_TYPE} ]
then
    echo "SAMPLE_TYPE was not specified : execution stopped."
    exit 1
fi

if [ -z ${NB_VAR_FILE} ]
then
    echo "NB_VAR_FILE was not specified : execution stopped."
    exit 1
fi

if [[ -z ${LIST_SUMMARY_FILES} && -n ${LIST_DIJ_ARG} ]]
then
    echo "LIST_SUMMARY_FILES was not specified : execution stopped."
    exit 1
fi

if [[ -z ${LIST_DIJ_ARG} && -n ${LIST_SUMMARY_FILES} ]]
then
    echo "LIST_DIJ_ARG was not specified : execution stopped."
    exit 1
fi

if [ -z ${PIPELINE_QUALIF} ]
then
    echo "PIPELINE_QUALIF was not provided : execution stopped."
    exit 1
fi


if [[ -f "selected_files_${SAMPLE_TYPE}.txt" ]]
then
    files=($(cat selected_files_${SAMPLE_TYPE}.txt))
else
    files=()
fi

if [ -n ${FILES_TO_ADD} ]
then
    IFS=: read -ra LIST_FILES <<< ${FILES_TO_ADD}
else
    LIST_FILES=()
fi

if [[ -f ${FOUND_FILE} ]]
then
    echo "Command : sbatch --export=REPORT="${REPORT_NAME}.html",SAMPLE_TYPE=${SAMPLE_TYPE},NB_VAR_FILE=${NB_VAR_FILE},FOUND_FILE=${FOUND_FILE},LIST_SUMMARY_FILES=${LIST_SUMMARY_FILES},LIST_DIJ_ARG=${LIST_DIJ_ARG} ${PIPELINE_QUALIF}/common/qualification/report_maker.sh  "${files[@]}" "${LIST_FILES[@]}""
    sbatch --export=REPORT="${REPORT_NAME}.html",SAMPLE_TYPE=${SAMPLE_TYPE},NB_VAR_FILE=${NB_VAR_FILE},FOUND_FILE=${FOUND_FILE},LIST_SUMMARY_FILES=${LIST_SUMMARY_FILES},LIST_DIJ_ARG=${LIST_DIJ_ARG} ${PIPELINE_QUALIF}/common/qualification/report_maker.sh  "${files[@]}" "${LIST_FILES[@]}"
else
    echo "Command : sbatch --export=REPORT="${REPORT_NAME}.html",SAMPLE_TYPE=${SAMPLE_TYPE},NB_VAR_FILE=${NB_VAR_FILE},LIST_SUMMARY_FILES=${LIST_SUMMARY_FILES},LIST_DIJ_ARG=${LIST_DIJ_ARG} ${PIPELINE_QUALIF}/common/qualification/report_maker.sh  "${files[@]}" "${LIST_FILES[@]}""
    sbatch --export=REPORT="${REPORT_NAME}.html",SAMPLE_TYPE=${SAMPLE_TYPE},NB_VAR_FILE=${NB_VAR_FILE},LIST_SUMMARY_FILES=${LIST_SUMMARY_FILES},LIST_DIJ_ARG=${LIST_DIJ_ARG} ${PIPELINE_QUALIF}/common/qualification/report_maker.sh  "${files[@]}" "${LIST_FILES[@]}"
fi