#!/bin/bash
## copy_test_dataset.sh
## Version : 1.0
## Description : This script allows user to copy the qualification dataset (es, gs and nbs)
## Usage : sbatch --export=OUTPUTDIR=path_where_the_qualif_dataset_is_and/where_a_new_qualif_2_12_dataset_will_be_copied copy_test_dataset.sh
## Output : qualif_2_12 directory containing a copy of the qualification dataset (es, gs and nbs)
## Requirements : the directory of the current qualification dataset

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260610
## Last revision date : 20260717
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=copy_test_dataset
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr

# while getopts “o:l:” OPTION
# do
#      case $OPTION in
#          o)
#              OUTPUTDIR=$OPTARG
#              ;;
#          l)
#              LOGFILE=$OPTARG
#              ;;
#      esac
# done


# Log file path option
if [ -z ${LOGFILE} ]
then
LOGFILE=copy_test_dataset.$(date +"%F_%H-%M-%S").log
fi

# logging
exec 1>> ${LOGFILE} 2>&1
echo "$(date +"%F_%H-%M-%S"): START"

# Output file path option
if [ -z ${OUTPUTDIR} ]
then
    echo "Output directory does not specify"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi

# Check if output directory exists
if [ ! -d ${OUTPUTDIR} ]
then
    echo "Output directory does not exist"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi

# Rename old directory
if [ -d ${OUTPUTDIR}/qualif_2_12 ]
then
    echo "A qualif_2_12 directory already exists: renaming old directory"
    old=`ls -l --time-style=+"%Y%m%d" ${OUTPUTDIR}/qualif_2_12 | cut -d " " -f6`
    echo "Command : mv ${OUTPUTDIR}/qualif_2_12 ${OUTPUTDIR}/qualif_2_12_${old}"
    mv ${OUTPUTDIR}/qualif_2_12 ${OUTPUTDIR}/qualif_2_12_$old
fi

echo "Creating directory $OUTPUTDIR/qualif_2_12"
mkdir ${OUTPUTDIR}/qualif_2_12

# Copy es
echo "Copying es folder"
echo "Command : cp -r ${OUTPUTDIR}/es ${OUTPUTDIR}/qualif_2_12/"
cp -r ${OUTPUTDIR}/es ${OUTPUTDIR}/qualif_2_12/
echo "es copy done"

echo "Checking es copy"
for file in ${OUTPUTDIR}/es/*
do
    base=$(basename ${file})

    if [ ! -e ${OUTPUTDIR}/qualif_2_12/es/${base} ] || [ ! -s ${OUTPUTDIR}/qualif_2_12/es/${base} ]
    then
        echo "Manquant ou vide dans qualif_2_12/es : ${base}"
    fi
done
echo "es check done"

echo "Removing dijex_list.txt file from es directory"
rm ${OUTPUTDIR}/qualif_2_12/es/dijex_list.txt

# Copy gs
echo "Copying gs folder"
echo "Command : cp -r ${OUTPUTDIR}/gs ${OUTPUTDIR}/qualif_2_12/"
cp -r ${OUTPUTDIR}/gs ${OUTPUTDIR}/qualif_2_12/
echo "gs copy done"

echo "Checking gs copy"
for file in ${OUTPUTDIR}/gs/*
do
    base=$(basename ${file})

    if [ ! -e ${OUTPUTDIR}/qualif_2_12/gs/${base} ] || [ ! -s ${OUTPUTDIR}/qualif_2_12/gs/${base} ]
    then
        echo "Manquant ou vide dans qualif_2_12/gs : $base"
    fi
done
echo "gs check done"

echo "Removing dijen_list.txt file from gs directory"
rm ${OUTPUTDIR}/qualif_2_12/gs/dijen_list.txt


# Copy nbs
echo "Copying nbs folder"
echo "Command : cp -r ${OUTPUTDIR}/nbs ${OUTPUTDIR}/qualif_2_12/"
cp -r ${OUTPUTDIR}/nbs ${OUTPUTDIR}/qualif_2_12/
echo "nbs copy done"

echo "Checking nbs copy"
for file in ${OUTPUTDIR}/nbs/*
do
    base=$(basename ${file})

    if [ ! -e ${OUTPUTDIR}/qualif_2_12/nbs/${base} ] || [ ! -s ${OUTPUTDIR}/qualif_2_12/nbs/${base} ]
    then
        echo "Manquant ou vide dans qualif_2_12/nbs : $base"
    fi
done
echo "nbs check done"

echo "Removing dijnbs_list.txt file from nbs directory"
rm ${OUTPUTDIR}/qualif_2_12/nbs/dijnbs_list.txt

echo "$(date +"%F_%H-%M-%S"): END"