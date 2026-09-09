#!/bin/bash
## wrapper_research_result.sh
## Version : 1.0
## Description : This script allows user to launch research_result.py
## Usage : sbatch --export=INPUTFILE=path/to/file/to/search/in,CONFIGFILE=path/to/configfile,RESULT="result_researched_in_file",LOGFILE="not_mandatory_logfile_chosen_name",RESULTFILE="not_mandatory_resultfile_chosen_name",SAMPLE_TYPE=<"es","gs" or "nbs">,PIPELINE_QUALIF=<directory/of/qualif/pipeline> wrapper_research_result.sh
## Output : launches research_result.py
## Requirements : configfile with pythonbin

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260622
## Last revision date : 20260717
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=wrapper_research_result
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr

echo "$(date +"%F_%H-%M-%S"): START"


if [ -z ${CONFIGFILE} ]
then
    CONFIGFILE=${PIPELINE_QUALIF}/common/analysis_config_mesobfc.tsv
fi


PYTHONBIN=`grep pythonbin ${CONFIGFILE} | cut -f2`


# input file path option
if [ -z ${INPUTFILE} ]
then
    echo "Input file does not specify"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi


if [ -z "${RESULT}" ]
then
    echo "No result specified"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi

if [ -z ${SAMPLE_TYPE} ]
then
    echo "No sample type specified"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi

if [ -z ${PIPELINE_QUALIF} ]
then
    echo "PIPELINE_QUALIF was not provided : execution stopped."
    exit 1
fi

if [ -z ${LOGFILE} ]
then
    if [ -z ${RESULTFILE} ]
    then
        echo "Command : ${PYTHONBIN} ${PIPELINE_QUALIF}/common/qualification/research_result.py -f ${INPUTFILE} -r "${RESULT}" -s ${SAMPLE_TYPE}"
        ${PYTHONBIN} ${PIPELINE_QUALIF}/common/qualification/research_result.py -f ${INPUTFILE} -r "${RESULT}" -s ${SAMPLE_TYPE}
    else
        echo "Command : ${PYTHONBIN} ${PIPELINE_QUALIF}/common/qualification/research_result.py -f ${INPUTFILE} -r "${RESULT}" -n ${RESULTFILE} -s ${SAMPLE_TYPE}"
        ${PYTHONBIN} ${PIPELINE_QUALIF}/common/qualification/research_result.py -f ${INPUTFILE} -r "${RESULT}" -n ${RESULTFILE} -s ${SAMPLE_TYPE}
    fi
else
    if [ -z ${RESULTFILE} ]
    then
        echo "Command : ${PYTHONBIN} ${PIPELINE_QUALIF}/common/qualification/research_result.py -f ${INPUTFILE} -r "${RESULT}" -l ${LOGFILE} -s ${SAMPLE_TYPE}"
        ${PYTHONBIN} ${PIPELINE_QUALIF}/common/qualification/research_result.py -f ${INPUTFILE} -r "${RESULT}" -l ${LOGFILE} -s ${SAMPLE_TYPE}
    else
        echo "Command : ${PYTHONBIN} ${PIPELINE_QUALIF}/common/qualification/research_result.py -f ${INPUTFILE} -r "${RESULT}" -l ${OGFILE} -n ${RESULTFILE} -s ${SAMPLE_TYPE}"
        ${PYTHONBIN} ${PIPELINE_QUALIF}/common/qualification/research_result.py -f ${INPUTFILE} -r "${RESULT}" -l ${LOGFILE} -n ${RESULTFILE} -s ${SAMPLE_TYPE}
    fi
fi

echo "$(date +"%F_%H-%M-%S"): END"