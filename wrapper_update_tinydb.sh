#!/bin/bash
## wrapper_update_tinydb.sh
## Version : 1.0
## Description : This script allows user to launch update_tinyDB.py
## Usage : sbatch --export=DATABASE=<path/to/tinyDB/database/to/update,SAMPLE_TYPE=<"es", "gs" or "nbs">,VAR=<"True" or "anything_else">,VCFEVAL=<"True" or "anything_else">,DATA_VAR_FILE=<data_variations file made by get_data_variations.sh (mandatory if VAR=True)>,DATA_VCFEVAL_FILE=<data_vcfeval file made by get_data_vcfeval.sh (mandatory if VCFEVAL=True)>,PIPELINE_QUALIF=<directory/of/qualif/pipeline>,CONFIGFILE=configfile wrapper_update_tinydb.sh
## Output : launches update_tinyDB.py
## Requirements : if VAR=True data_variations file made by get_data_variations.sh, if VCFEVAL=True data_vcfeval file made by get_data_vcfeval.sh, singularity image containing python (3.9 works) and tinyDB

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260625
## Last revision date : 20260720
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=wrapper_update_tinydb
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr

if [ -z ${DATABASE} ]
then
    echo "DATABASE was not defined : execution stopped" 
    exit 1
fi

if [ -z ${SAMPLE_TYPE} ]
then
    echo "SAMPLE TYPE was not defined : execution stopped" 
    exit 1
fi

if [ -z ${CONFIGFILE} ]
then
    CONFIGFILE=${PIPELINE_QUALIF}/common/analysis_config_mesobfc.tsv
fi

if [ -z ${PIPELINE_QUALIF} ]
then
    echo "PIPELINE_QUALIF was not provided : execution stopped."
    exit 1
fi

SINGULARITYEXEC=$(grep singularityexec ${CONFIGFILE} | cut -f 2)
SINGULARITYBIND=$(grep singularitybind ${CONFIGFILE} | cut -f 2)

if [ -n ${VAR} ]
then

if [ ${VAR} == "True" ]
then
    if [ -z ${DATA_VAR_FILE} ]
    then
        echo "DATA_VAR_FILE was not defined : execution stopped" 
        exit 1
    fi

    echo "Command :  ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/update_tinyDB.py -v -f ${DATA_VAR_FILE} -t ${SAMPLE_TYPE} -b ${DATABASE}"
    ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/update_tinyDB.py -v -f ${DATA_VAR_FILE} -t ${SAMPLE_TYPE} -b ${DATABASE}
fi

fi

if [ -n ${VCFEVAL} ]
then

if [ "${VCFEVAL}" == "True" ]
then
    if [ -z ${DATA_VCFEVAL_FILE} ]
    then
        echo "DATA_VCFEVAL_FILE was not defined : execution stopped" 
        exit 1
    fi

    echo "Command :  ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/update_tinyDB.py -e -d ${DATA_VCFEVAL_FILE} -t ${SAMPLE_TYPE} -b ${DATABASE}"
    ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/update_tinyDB.py -e -d ${DATA_VCFEVAL_FILE} -t ${SAMPLE_TYPE} -b ${DATABASE}
fi

fi

