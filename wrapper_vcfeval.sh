#!/bin/bash
## wrapper_vcfeval.sh
## Version : 1.0
## Description : This script allows user to anallyse a file with vcfeval 
## Usage : sbatch --export=TRUTH_FILE=< truth benchmark.vcf.gz file>,TEST_FILE=<path/to/file/to/test(vcf.gz)>,TEMPLATE=<sdf template file>,OUTPUTDIR=<path and name of new directory to store vcfeval results>,BED_REGIONS=<eventual bed regions>,EVALUATION_REGIONS=<enventual evalutions regions>,RESULT="not mandatory name of resultfile",CONFIGFILE=<path/to/configfile>,PIPELINE_QUALIF=<directory/of/qualif/pipeline> wrapper_vcfeval.sh
## Output : vcfeval results in a specified directory and a resultfile containing a brief summary of it
## Requirements : configfile with singularityexec, singularity image with rtg-tools

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260616
## Last revision date : 20260717
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=wrapper_vcfeval
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr


# Options
#while getopts “b:c:t:o:r:s:e:g:” OPTION
#do
#     case $OPTION in
#         b)
#             TRUTH_FILE=$OPTARG
#             ;;
#         c)
#             TEST_FILE=$OPTARG
#             ;;
#         t)
#             TEMPLATE=$OPTARG
#             ;;
#         o)
#             OUTPUTDIR=$OPTARG
#             ;;
#         r)
#             BED_REGIONS=$OPTARG
#             ;;
#         s)
#             SAMPLE=$OPTARG
#             ;;
#         e)  
#             EVALUATION_REGIONS=$OPTARG
#             ;;
#         g)
#             CONFIGFILE=$OPTARG
#             ;;
#     esac
#done

# Logging
logbasename=$(date +"%F_%H-%M-%S")
LOGFILE=wrapper_vcfeval.$logbasename.log
exec 1>> ${LOGFILE} 2>&1
echo "$(date +"%F_%H-%M-%S"): START"

if [ -z ${RESULT} ]
then
    RESULT=result_wrapper_vcfeval.$logbasename.log
fi

if [ -z ${TRUTH_FILE} ]
then
    echo "TRUTH FILE was not defined : execution stopped" 
    exit 1
fi

if [ -z ${TEST_FILE} ]
then
    echo "TEST FILE was not defined : execution stopped" 
    exit 1
fi

if [ -z ${TEMPLATE} ]
then
    echo "TEMPLATE FILE was not defined : execution stopped" 
    exit 1
fi

if [ -z ${OUTPUTDIR} ]
then
    echo "OUTPUTDIR was not defined : execution stopped" 
    exit 1
fi

if [ -z ${CONFIGFILE} ]
then
    CONFIGFILE=${PIPELINE_QUALIF}/common/analysis_config_mesobfc.tsv
fi

echo "configfile : ${CONFIGFILE}"


SINGULARITYEXEC=$(grep singularityexec ${CONFIGFILE} | cut -f 2)
SINGULARITYBIND=$(grep singularitybind ${CONFIGFILE} | cut -f 2)
SINGULARITYRTG=$(grep singularityrtg ${CONFIGFILE} | cut -f 2)

echo "singularityexec : ${SINGULARITYEXEC}"
echo ${TEST_FILE}
#echo "sample : ${SAMPLE}"
#echo "bed regions : ${BED_REGIONS}"
#echo "evaluation regions : ${EVALUATION_REGIONS}"

TEST_FILE=$(printf '%s\n' ${TEST_FILE})

echo "Using gzip to compress vcf file"
echo "Command : bgzip -c ${TEST_FILE} > ${TEST_FILE}.gz"
declare -p TEST_FILE
printf '<%s>\n' "$TEST_FILE"
bgzip -c ${TEST_FILE} > ${TEST_FILE}.gz

echo "Creating index"
echo "Command : tabix -p vcf ${TEST_FILE}.gz"
tabix -p vcf ${TEST_FILE}.gz


echo "Results of comparison between ${TEST_FILE}.gz and reference ${TRUTH_FILE} and ${TEMPLATE}" >> ${RESULT}

echo "Starting vcfeval"
if [ -z ${BED_REGIONS} ]
then
    if [ -z ${SAMPLE} ]
    then
        if [ -z ${EVALUATION_REGIONS} ]
        then
            #echo "Case 1"
            echo "Command :  ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} | tee -a ${RESULT}
        else
            #echo "Case 2"
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --evaluation-regions ${EVALUATION_REGIONS}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --evaluation-regions ${EVALUATION_REGIONS} | tee -a ${RESULT}
        fi
    else
        if [ -z ${EVALUATION_REGIONS} ]
        then
            #echo "Case 3"
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --sample ${SAMPLE}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --sample ${SAMPLE} | tee -a ${RESULT}
        else
            #echo "Case 4"
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --sample ${SAMPLE} --evaluation-regions ${EVALUATION_REGIONS}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --sample ${SAMPLE} --evaluation-regions ${EVALUATION_REGIONS} | tee -a ${RESULT}
        fi
    fi
else
    if [ -z ${SAMPLE} ]
    then
        if [ -z ${EVALUATION_REGIONS} ]
        then
            #echo "Case 5"    
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --bed-regions ${BED_REGIONS}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --bed-regions ${BED_REGIONS} | tee -a ${RESULT}
        else
            #echo "Case 6"
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --bed-regions ${BED_REGIONS} --evaluation-regions ${EVALUATION_REGIONS}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --bed-regions ${BED_REGIONS} --evaluation-regions ${EVALUATION_REGIONS} | tee -a ${RESULT}
        fi
    else
        if [ -z ${EVALUATION_REGIONS} ]
        then
            #echo "Case 7"
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --bed-regions ${BED_REGIONS} --sample ${SAMPLE}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --bed-regions ${BED_REGIONS} --sample ${SAMPLE} | tee -a ${RESULT}
        else
            #echo "Case 8"
            echo "Command : ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --bed-regions ${BED_REGIONS} --sample ${SAMPLE} --evaluation-regions ${EVALUATION_REGIONS}"
            ${SINGULARITYEXEC} exec -e --bind ${SINGULARITYBIND} ${SINGULARITYRTG} rtg vcfeval -b ${TRUTH_FILE} -c ${TEST_FILE}.gz -t ${TEMPLATE} -o ${OUTPUTDIR} --bed-regions ${BED_REGIONS} --sample ${SAMPLE} --evaluation-regions ${EVALUATION_REGIONS} | tee -a ${RESULT}
        fi
    fi
fi

echo "$(date +"%F_%H-%M-%S"): END"