#!/bin/bash
## organize_test_dataset.sh
## Version : 1.0
## Description : This script allows user to organize the qualification dataset (es, gs and nbs) by family
## Usage : sbatch --export=INPUTDIR=directory/of/full/qualif/dataset,PIPELINE_QUALIF=directory/to/qualif/pipeline,CONFIGFILE=configfile organize_test_dataset.sh
## Output : qualfifcation dataset organized by families
## Requirements : directory of qualification dataset, pyhton (3.9 works) singularity image, access to common/fastq/organize_data_folder.py script

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260611
## Last revision date : 20260717
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=organize_test_dataset
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr

# Log file path option
if [ -z ${LOGFILE} ]
then
LOGFILE=organize_test_dataset.$(date +"%F_%H-%M-%S").log
fi

# logging
exec 1>> ${LOGFILE} 2>&1
echo "$(date +"%F_%H-%M-%S"): START"

# input file path option
if [ -z ${INPUTDIR} ]
then
    echo "Input directory does not specify"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi

# Check if input directory exists
if [ ! -d ${INPUTDIR} ]
then
    echo "Input directory does not exist"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi

if [ -z ${PIPELINE_QUALIF} ]
then
    echo "PIPELINE_QUALIF was not provided : execution stopped."
    exit 1
fi

if [ -z ${CONFIGFILE} ]
then
    echo "CONFIGFILE was not provided : execution stopped."
    exit 1
fi

PYTHONBIN=$(grep pythonbin ${CONFIGFILE} | cut -f 2)
TARGETLIST=$(grep targetlist ${CONFIGFILE} | cut -f 2)

# organize es
echo "Creating es sample list"
for f in ${INPUTDIR}/es/dij*; do
    echo "${f##*/}" | cut -d '.' -f1
done | sort -u > ${INPUTDIR}/es/samples_to_organize.list

if [ ! -e ${INPUTDIR}/es/samples_to_organize.list ] || [ ! -s ${INPUTDIR}/es/samples_to_organize.list ]
then
    echo "samples_to_organize.list file doesn't exist"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi

echo "Organizing es directory"
echo "Command : ${PYTHONBIN} ${PIPELINE_QUALIF}/common/fastq/organize_data_folder.py -d ${INPUTDIR}/es -b translad.chu-dijon.fr -p ${PIPELINE_QUALIF}/ -e organize_data_folder.log -s ${INPUTDIR}/es/samples_to_organize.list -t ${TARGETLIST} -c False -u ${INPUTDIR}/es"
${PYTHONBIN} ${PIPELINE_QUALIF}/common/fastq/organize_data_folder.py -d ${INPUTDIR}/es -b translad.chu-dijon.fr -p ${PIPELINE_QUALIF}/ -e organize_data_folder.log -s ${INPUTDIR}/es/samples_to_organize.list -t ${TARGETLIST} -c False -u ${INPUTDIR}/es

echo "Organizing es samples by family"
for i in ${INPUTDIR}/es/*.family.list
do
    family=${i##*/}        
    family=${family%%.*}   

    mkdir ${INPUTDIR}/es/${family}
    mkdir ${INPUTDIR}/es/${family}/logs/

    mv $i ${INPUTDIR}/es/${family}

    for line in $(cat ${INPUTDIR}/es/${family}/${family}.family.list)
    do
        mv ${INPUTDIR}/es/${line} ${INPUTDIR}/es/${family}/
    done
done


# organize gs
echo "Creating gs sample list"
for f in ${INPUTDIR}/gs/dij*; do
    echo "${f##*/}" | cut -d '.' -f1
done | sort -u > ${INPUTDIR}/gs/samples_to_organize.list

if [ ! -e ${INPUTDIR}/gs/samples_to_organize.list ] || [ ! -s ${INPUTDIR}/gs/samples_to_organize.list ]
then
    echo "samples_to_organize.list file doesn't exist"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi

echo "Organizing gs directory"
echo "Command : ${PYTHONBIN} ${PIPELINE_QUALIF}/common/fastq/organize_data_folder.py -d ${INPUTDIR}/gs -b translad.chu-dijon.fr -p ${PIPELINE_QUALIF}/ -e organize_data_folder.log -s ${INPUTDIR}/gs/samples_to_organize.list -t ${TARGETLIST} -c False -u ${INPUTDIR}/gs"
${PYTHONBIN} ${PIPELINE_QUALIF}/common/fastq/organize_data_folder.py -d ${INPUTDIR}/gs -b translad.chu-dijon.fr -p ${PIPELINE_QUALIF}/ -e organize_data_folder.log -s ${INPUTDIR}/gs/samples_to_organize.list -t ${TARGETLIST} -c False -u ${INPUTDIR}/gs

echo "Organizing gs samples by family"
for i in ${INPUTDIR}/gs/*.family.list
do
    family=${i##*/}        
    family=${family%%.*}   

    mkdir ${INPUTDIR}/gs/${family}
    mkdir ${INPUTDIR}/gs/${family}/logs/

    mv $i ${INPUTDIR}/gs/${family}

    for line in $(cat ${INPUTDIR}/gs/${family}/${family}.family.list)
    do
        mv ${INPUTDIR}/gs/${line} ${INPUTDIR}/gs/${family}/
    done
done


# organize nbs
echo "Creating nbs sample list"
for f in ${INPUTDIR}/nbs/dij*; do
    echo "${f##*/}" | cut -d '.' -f1
done | sort -u > ${INPUTDIR}/nbs/samples_to_organize.list

if [ ! -e ${INPUTDIR}/nbs/samples_to_organize.list ] || [ ! -s ${INPUTDIR}/nbs/samples_to_organize.list ]
then
    echo "samples_to_organize.list file doesn't exist"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi

echo "Organizing nbs directory"
echo "Command : ${PYTHONBIN} ${PIPELINE_QUALIF}/common/fastq/organize_data_folder.py -d ${INPUTDIR}/nbs -b translad.chu-dijon.fr -p ${PIPELINE_QUALIF}/ -e organize_data_folder.log -s ${INPUTDIR}/nbs/samples_to_organize.list -t ${TARGETLIST} -c False -u ${INPUTDIR}/nbs"
${PYTHONBIN} ${PIPELINE_QUALIF}/common/fastq/organize_data_folder.py -d ${INPUTDIR}/nbs -b translad.chu-dijon.fr -p ${PIPELINE_QUALIF}/ -e organize_data_folder.log -s ${INPUTDIR}/nbs/samples_to_organize.list -t ${TARGETLIST} -c False -u ${INPUTDIR}/nbs

echo "Organizing nbs samples by family"
for i in ${INPUTDIR}/nbs/*.family.list
do
    family=${i##*/}        
    family=${family%%.*}   

    mkdir ${INPUTDIR}/nbs/${family}
    mkdir ${INPUTDIR}/nbs/${family}/logs/

    mv $i ${INPUTDIR}/nbs/${family}

    for line in $(cat ${INPUTDIR}/nbs/${family}/${family}.family.list)
    do
        mv ${INPUTDIR}/nbs/${line} ${INPUTDIR}/nbs/${family}/
    done
done


echo "$(date +"%F_%H-%M-%S"): END"