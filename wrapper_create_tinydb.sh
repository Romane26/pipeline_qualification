#!/bin/bash
## wrapper_update_tinydb.sh
## Version : 1.0
## Description : This script allows user to launch update_tinyDB.py
## Usage : sbatch --export=PIPELINE_QUALIF=<directory/of/qualif/pipeline>,CONFIGFILE=<configfile>,DATABASE_NAME=<chosen_database_name> wrapper_create_tinydb.sh wrapper_create_tinydb.py
## Output : launches create_tinyDB.py
## Requirements : singularity image containing python (3.9 works) and tinyDB

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260805
## Last revision date : 20260805
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=wrapper_create_tinydb
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr


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

if [[ -z DATABASE_NAME ]]
then
    echo "Command :  ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_tinydb.py"
    ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_tinydb.py
else
    echo "Command :  ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_tinydb.py -n ${DATABASE_NAME}"
    ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_tinydb.py -n ${DATABASE_NAME}
fi
