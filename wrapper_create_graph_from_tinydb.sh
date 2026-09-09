#!/bin/bash
## wrapper_create_graph_from_tinydb.sh
## Version : 1.0
## Description : This script allows user to launch create_graph_from_tinydb.py
## Usage : sbatch --export=DATABASE=<path/to/tinyDB/database>,SAMPLE_TYPE=<"es","gs","nbs","all">,GRAPH_TYPE=<"var_ref","nb_var","f-measure">,LOGFILE=<not_mandatory_logfile_name>,DIJEXN=<dijex.n.nbs, mandatory for nb_var and f-measure graphs>,TABLE_TYPE=<"variations" or "vcfeval", mandatory argument for nb_var graph type>,PIPELINE_QUALIF=<directory/of/qualif/pipeline>,CONFIGFILE=<configfile> wrapper_create_graph_from_tinydb.sh
## Requirements :singularity image containing python (3.9 works), tinyDB and plotly

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260630
## Last revision date : 20260720
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=wrapper_create_graph_from_tinydb
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr

if [ -z ${DATABASE} ]
then
    echo "DATABASE was not specified : execution stopped."
    exit 1
fi

if [ -z ${SAMPLE_TYPE} ]
then
    echo "SAMPLE_TYPE was not specified : execution stopped."
    exit 1
fi


if [ -z ${GRAPH_TYPE} ]
then
    echo "GRAPH_TYPE was not specified : execution stopped."
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


if [[ ${GRAPH_TYPE} == "nb_var" ]]
then
    if [ -z ${DIJEXN} ]
    then
        echo "DIJEXN was not specified : execution stopped."
        exit 1
    fi

    if [ ${DIJEXN} == "all" ]
    then
        if [ -z ${LOGFILE} ]
        then
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -j ${DIJEXN}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -j ${DIJEXN}
        else
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -l ${LOGFILE} -j ${DIJEXN}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -l ${LOGFILE} -j ${DIJEXN}
        fi
    else
        if [ -z ${TABLE_TYPE} ]
        then
            echo "TABLE_TYPE was not specified : execution stopped."
            exit 1
        fi

        if [ -z ${LOGFILE} ]
        then
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -j ${DIJEXN} -a ${TABLE_TYPE}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -j ${DIJEXN} -a ${TABLE_TYPE}
        else
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -l ${LOGFILE} -j ${DIJEXN} -a ${TABLE_TYPE}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -l ${LOGFILE} -j ${DIJEXN} -a ${TABLE_TYPE}
        fi
    fi

elif [[ ${GRAPH_TYPE} == "f-measure" ]]
then
    if [ ${SAMPLE_TYPE} == "all" ]
    then
        if [ -z ${LOGFILE} ]
        then
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE}
        else
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -l ${LOGFILE}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -l ${LOGFILE}
        fi
    else
        if [ -z ${DIJEXN} ]
        then
            echo "DIJEXN was not specified : execution stopped."
            exit 1
        fi

        if [ -z ${LOGFILE} ]
        then
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -j ${DIJEXN}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -j ${DIJEXN}
        else
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -l ${LOGFILE} -j ${DIJEXN}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -l ${LOGFILE} -j ${DIJEXN}
        fi
    fi
elif [[ ${GRAPH_TYPE} == "var_ref" ]]
then 
    if [ -z ${LOGFILE} ]
    then
        echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE}"
        ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE}
    else
        echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -l ${LOGFILE}"
        ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${PIPELINE_QUALIF}/common/qualification/python3.9_qualif.sif python3 ${PIPELINE_QUALIF}/common/qualification/create_graph_from_tinydb.py -d ${DATABASE} -s ${SAMPLE_TYPE} -t ${GRAPH_TYPE} -l ${LOGFILE}
    fi
fi