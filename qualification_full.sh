#!/bin/bash
## qualification_full.sh
## Version : 1.0
## Description : This script allows user to start the qualification process on a pipeline
## Usage : sbatch --export=INPUTDIR=<path/to/qualification/dataset>,DATABASE=<path/to/tinyDB/database/to/use>,CONFIG_QUALIF=<tsv configfile containing all the variations to analyse>,UPDATE=<"True" or "False">,CONFIGFILE=<configfile>,PIPELINE_QUALIF=<path/to/qualif/pipeline> qualification_full.sh
## Output : updated database, html reports, graphs, individual resultfiles
## Requirements : singularity image with python (3.9 works), tinyDB and plotly, tsv config_qualif file, configfile

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260618
## Last revision date : 20260720
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=qualification_full
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr

# Logging
logbasename=$(date +"%F_%H-%M-%S")
LOGFILE=qualifcation_full.$logbasename.log
exec 1>> ${LOGFILE} 2>&1
echo "$(date +"%F_%H-%M-%S"): START"


# INPUTDIR file path option
if [ -z ${INPUTDIR} ]
then
    echo "Inputdir directory does not specify"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi

# Check if input directory exists
if [ ! -d ${INPUTDIR} ]
then
    echo "Inputdir directory does not exist"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi

if [ -z ${CONFIGFILE} ]
then
    CONFIGFILE=${PIPELINE_QUALIF}/common/analysis_config_mesobfc.tsv
fi

if [ -z ${CONFIG_QUALIF} ]
then
    echo "CONFIG_QUALIF was not provided : execution stopped."
    exit 1
fi

if [ -z ${PIPELINE_QUALIF} ]
then
    echo "PIPELINE_QUALIF was not provided : execution stopped."
    exit 1
fi

if [ ${UPDATE} != "True" ] && [ ${UPDATE} != "False" ]
then 
    echo "Wether to update database was not specified"
    echo "$(date +"%F_%H-%M-%S"): END"
    exit 1
fi

if [ -z ${DATABASE} ] && [ ${UPDATE} == "True" ]
then
    date_database=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --export=CONFIGFILE=${CONFIGFILE},PIPELINE_QUALIF=${PIPELINE_QUALIF},DATABASE_NAME="db_qualif_${date_database}" ${PIPELINE_QUALIF}/common/qualification/wrapper_create_tinydb.sh"
    sbatch --export=CONFIGFILE=${CONFIGFILE},PIPELINE_QUALIF=${PIPELINE_QUALIF},DATABASE_NAME="db_qualif_${date_database}" ${PIPELINE_QUALIF}/common/qualification/wrapper_create_tinydb.sh
    DATABASE=db_qualif_${date_database}.json
fi


function sqn {
    local name="$1"
    local code

    code=$(squeue -h -O jobid:30,name:200 \
        | awk -v name="$name" '$2 == name {id=$1} END {print id}')

    if [[ -n "$code" ]]; then
        echo "$code"
        return
    fi

    code=$(sacct -n -P -X \
        --format JobIDRaw,JobName%200,State \
        | awk -F'|' -v name="$name" '
            $1 ~ /^[0-9]+$/ && $2 == name && $1 > max {
                max=$1
            }
            END {
                if (max != "") print max;
                else print 1
            }')

    echo "$code"
}

GRCh38sdf=$(grep GRCh38sdf ${CONFIGFILE} | cut -f 2)
BEDREFSEQ=$(grep bedrefseq ${CONFIGFILE} | cut -f 2)
GRCh38benchmark=$(grep GRCh38benchmark ${CONFIGFILE} | cut -f 2)
GRCh38bed=$(grep GRCh38bed ${CONFIGFILE} | cut -f 2)




echo "Initialisation of data lists"
PED_es=()
dijex=()
variations_es=()
files_es=()

PED_gs=()
dijen=()
variations_gs=()
files_gs=()

PED_nbs=()
dijnbs=()
variations_nbs=()
files_nbs=()

while IFS=$'\t' read -r sample PED dij var file
do
    if [ ${sample} == "es" ]
    then
        PED_es+=($PED)
        dijex+=($dij)
        variations_es+=($var)
        files_es+=($file)
    elif [ ${sample} == "gs" ]
    then
        PED_gs+=($PED)
        dijen+=($dij)
        variations_gs+=($var)
        files_gs+=($file)
    elif [ ${sample} == "nbs" ]
    then
        PED_nbs+=($PED)
        dijnbs+=($dij)
        variations_nbs+=($var)
        files_nbs+=($file)  
    fi
done < ${CONFIG_QUALIF}

len_es=${#PED_es[@]}
len_gs=${#PED_gs[@]}
len_nbs=${#PED_nbs[@]}

indice_var_es=()
indice_vcf_es=()
indice_var_gs=()
indice_vcf_gs=()
indice_var_nbs=()
indice_vcf_nbs=()


echo "Copying test datasets (es, gs, nbs)"
echo "Command : sbatch -J copy_test_dataset --export=OUTPUTDIR=${INPUTDIR} ${PIPELINE_QUALIF}/common/qualification/copy_test_dataset.sh"
sbatch -J copy_test_dataset --export=OUTPUTDIR=${INPUTDIR} ${PIPELINE_QUALIF}/common/qualification/copy_test_dataset.sh
echo "Copying test datasets done"


echo "Organizing test datasets (es, gs, nbs)"
echo "Command : sbatch -J organize_test_dataset --dependency=afterok:$(sqn copy_test_dataset) --export=INPUTDIR=${INPUTDIR},PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/organize_test_dataset.sh"
sbatch -J organize_test_dataset --dependency=afterok:$(sqn copy_test_dataset) --export=INPUTDIR=${INPUTDIR},PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/organize_test_dataset.sh
echo "Organizing test datasets done"


echo "Starting analysis pipeline for chosen es"
for nom in ${PED_es[@]}
do
    echo "Starting pipeline for ${nom}"
    echo "Command : sbatch --dependency=afterok:$(sqn organize_test_dataset) --ntasks=1 --partition=nompi -J es_pipeline --output %x.%J.out --error %x.%J.log --export=ANALYSISDIR=${INPUTDIR}/qualif_2_12/es/${nom}/,LOGFILE=${INPUTDIR}/qualif_2_12/es/${nom}/logs/es_full_$(date +"%F_%H-%M-%S").log,CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/wes_pipeline/es_full.sh"
    sbatch --dependency=afterok:$(sqn organize_test_dataset) --ntasks=1 --partition=nompi -J es_pipeline --output %x.%J.out --error %x.%J.log --export=ANALYSISDIR=${INPUTDIR}/qualif_2_12/es/${nom}/,LOGFILE=${INPUTDIR}/qualif_2_12/es/${nom}/logs/es_full_$(date +"%F_%H-%M-%S").log,CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/wes_pipeline/es_full.sh
done
echo "All the chosen es pipelines were started"


echo "Starting analysis pipeline for chosen gs"
for nom in ${PED_gs[@]}
do
    echo "Starting pipeline for ${nom}"
    echo "Command : sbatch --dependency=afterok:$(sqn organize_test_dataset) --ntasks=1 --partition=nompi -J gs_pipeline --output %x.%J.out --error %x.%J.log --export=ANALYSISDIR=${INPUTDIR}/qualif_2_12/gs/${nom}/,LOGFILE=${INPUTDIR}/qualif_2_12/gs/${nom}/logs/gs_full_$(date +"%F_%H-%M-%S").log,CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/wgs_pipeline/gs_full.sh"
    sbatch --dependency=afterok:$(sqn organize_test_dataset) --ntasks=1 --partition=nompi -J gs_pipeline --output %x.%J.out --error %x.%J.log --export=ANALYSISDIR=${INPUTDIR}/qualif_2_12/gs/${nom}/,LOGFILE=${INPUTDIR}/qualif_2_12/gs/${nom}/logs/gs_full_$(date +"%F_%H-%M-%S").log,CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/wgs_pipeline/gs_full.sh
done
echo "All the chosen gs pipelines were started"


echo "Starting analysis pipeline for chosen nbs"
for nom in ${PED_nbs[@]}
do
    echo "Starting pipeline for ${nom}"
    echo "Command : sbatch --dependency=afterok:$(sqn organize_test_dataset) --ntasks=1 --partition=nompi -J nbs_pipeline --output %x.%J.out --error %x.%J.log --export=ANALYSISDIR=${INPUTDIR}/qualif_2_12/nbs/${nom}/,LOGFILE=${INPUTDIR}/qualif_2_12/nbs/${nom}/logs/nbs_$(date +"%F_%H-%M-%S").log,CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/wgs_pipeline/gs_solo_nbs.sh"
    sbatch --dependency=afterok:$(sqn organize_test_dataset) --ntasks=1 --partition=nompi -J nbs_pipeline --output %x.%J.out --error %x.%J.log --export=ANALYSISDIR=${INPUTDIR}/qualif_2_12/nbs/${nom}/,LOGFILE=${INPUTDIR}/qualif_2_12/nbs/${nom}/logs/nbs_$(date +"%F_%H-%M-%S").log,CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/wgs_pipeline/gs_solo_nbs.sh
done
echo "All the chosen nbs pipelines were started"


echo "Pausing for 10 minutes to wait for all jobs to be launched"
sleep 600

dependency_all_analysis_es=""
for nom in ${PED_es[@]}
do
    dependency_all_analysis_es=$(printf "${dependency_all_analysis_es}:$(sqn upload_labkey_${nom})")
done

dependency_all_analysis_gs=""
for nom in ${PED_gs[@]}
do
    dependency_all_analysis_gs=$(printf "${dependency_all_analysis_gs}:$(sqn upload_labkey_${nom})")
done

dependency_all_analysis_nbs=""
for nom in ${PED_nbs[@]}
do
    dependency_all_analysis_nbs=$(printf "${dependency_all_analysis_nbs}:$(sqn upload_labkey_nbs_${nom})")
done


# region Search_all_var_es

dependency_all_research_es=""
dependency_all_vcfeval_es=""

echo "Searching for reference variations in es files"
start_search_var_es=$(date +"%F_%H-%M-%S")
files_vcfeval_es=()
summary_vcfeval_es=()
list_dij_vcf_es=()
for ((i=0; i<len_es; i++))
do
    if [ ${variations_es[$i]} != "vcfeval" ]
    then
        echo "${PED_es[$i]}"
        echo "Command : sbatch --dependency=afterok:$(sqn upload_labkey_${PED_es[$i]}) -J es_var_search_${PED_es[$i]} --export=INPUTFILE=${INPUTDIR}/qualif_2_12/es/${PED_es[$i]}/${dijex[$i]}/$(echo ${files_es[$i]}),RESULT=${variations_es[$i]},LOGFILE="research_log_es_$(date +"%F_%H-%M-%S")",RESULTFILE="research_result_es_$(date +"%F_%H-%M-%S")",SAMPLE_TYPE="es",PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_research_result.sh"
        sbatch --dependency=afterok:$(sqn upload_labkey_${PED_es[$i]}) -J es_var_search_${PED_es[$i]} --export=INPUTFILE=${INPUTDIR}/qualif_2_12/es/${PED_es[$i]}/${dijex[$i]}/$(echo ${files_es[$i]}),RESULT=${variations_es[$i]},LOGFILE="research_log_es_$(date +"%F_%H-%M-%S")",RESULTFILE="research_result_es_$(date +"%F_%H-%M-%S")",SAMPLE_TYPE="es",PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_research_result.sh

        indice_var_es+=($i)
        dependency_all_research_es=$(printf "${dependency_all_research_es}:$(sqn es_var_search_${PED_es[$i]})")

        sleep 1
    else
        echo "Starting vcfeval for ${PED_es[$i]}, ${dijex[$i]}"
        vcfeval_time_es=$(date +"%F_%H-%M-%S")
        echo "Command : sbatch --dependency=afterok:$(sqn upload_labkey_${PED_es[$i]}) -J vcfeval_dijex_${PED_es[$i]} --export=TRUTH_FILE=${GRCh38benchmark},TEST_FILE=${INPUTDIR}/qualif_2_12/es/${PED_es[$i]}/${dijex[$i]}/$(echo ${files_es[$i]}),TEMPLATE=${GRCh38sdf},OUTPUTDIR=${INPUTDIR}/qualif_2_12/es/vcfeval_es_${dijex[$i]}_${vcfeval_time_es},BED_REGIONS=${BEDREFSEQ},EVALUATION_REGIONS=${GRCh38bed},RESULT="result_wrapper_vcfeval_es_${dijex[$i]}_${vcfeval_time_es}.log",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_vcfeval.sh"
        sbatch --dependency=afterok:$(sqn upload_labkey_${PED_es[$i]}) -J vcfeval_dijex_${PED_es[$i]} --export=TRUTH_FILE=${GRCh38benchmark},TEST_FILE=${INPUTDIR}/qualif_2_12/es/${PED_es[$i]}/${dijex[$i]}/$(echo ${files_es[$i]}),TEMPLATE=${GRCh38sdf},OUTPUTDIR=${INPUTDIR}/qualif_2_12/es/vcfeval_es_${dijex[$i]}_${vcfeval_time_es},BED_REGIONS=${BEDREFSEQ},EVALUATION_REGIONS=${GRCh38bed},RESULT="result_wrapper_vcfeval_es_${dijex[$i]}_${vcfeval_time_es}.log",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_vcfeval.sh

        files_vcfeval_es+=("result_wrapper_vcfeval_es_${dijex[$i]}_${vcfeval_time_es}.log")
        summary_vcfeval_es+=(${INPUTDIR}/qualif_2_12/es/vcfeval_es_${dijex[$i]}_${vcfeval_time_es}/summary.txt)
        list_dij_vcf_es+=(${dijex[$i]})
        indice_vcf_es+=($i)
        dependency_all_vcfeval_es=$(printf "${dependency_all_vcfeval_es}:$(sqn vcfeval_dijex_${PED_es[$i]})")
    fi
done

end_search_var_es=$(date +"%F_%H-%M-%S")

#endregion

# region Search_all_var_gs

dependency_all_research_gs=""
dependency_all_vcfeval_gs=""

echo "Searching for reference variations in gs files"
start_search_var_gs=$(date +"%F_%H-%M-%S")
files_vcfeval_gs=()
summary_vcfeval_gs=()
list_dij_vcf_gs=()
for ((i=0; i<len_gs; i++))
do
    if [ ${variations_gs[$i]} != "vcfeval" ]
    then
        echo "${PED_gs[$i]}"
        echo "Command : sbatch --dependency=afterok:$(sqn upload_labkey_${PED_gs[$i]}) -J gs_var_search_${PED_gs[$i]} --export=INPUTFILE=$INPUTDIR/qualif_2_12/gs/${PED_gs[$i]}/${dijen[$i]}/$(echo ${files_gs[$i]}),RESULT=${variations_gs[$i]},LOGFILE="research_log_gs_$(date +"%F_%H-%M-%S")",RESULTFILE="research_result_gs_$(date +"%F_%H-%M-%S")",SAMPLE_TYPE="gs",PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_research_result.sh"
        sbatch --dependency=afterok:$(sqn upload_labkey_${PED_gs[$i]}) -J gs_var_search_${PED_gs[$i]} --export=INPUTFILE=$INPUTDIR/qualif_2_12/gs/${PED_gs[$i]}/${dijen[$i]}/$(echo ${files_gs[$i]}),RESULT=${variations_gs[$i]},LOGFILE="research_log_gs_$(date +"%F_%H-%M-%S")",RESULTFILE="research_result_gs_$(date +"%F_%H-%M-%S")",SAMPLE_TYPE="gs",PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_research_result.sh

        indice_var_gs+=($i)
        dependency_all_research_gs=$(printf "${dependency_all_research_gs}:$(sqn gs_var_search_${PED_gs[$i]})")

        sleep 1
    else
        echo "Starting vcfeval for ${PED_gs[$i]}, ${dijen[$i]}"
        vcfeval_time_gs=$(date +"%F_%H-%M-%S")
        echo "Command : sbatch --dependency=afterok:$(sqn upload_labkey_${PED_gs[$i]}) -J vcfeval_dijen_${PED_gs[$i]} --export=TRUTH_FILE=${GRCh38benchmark},TEST_FILE=${INPUTDIR}/qualif_2_12/gs/${PED_gs[$i]}/${dijen[$i]}/$(echo ${files_gs[$i]}),TEMPLATE=${GRCh38sdf},OUTPUTDIR=$INPUTDIR/qualif_2_12/gs/vcfeval_gs_${dijen[$i]}_${vcfeval_time_gs},EVALUATION_REGIONS=${GRCh38bed},RESULT="result_wrapper_vcfeval_gs_${dijen[$i]}_${vcfeval_time_gs}.log",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_vcfeval.sh"
        sbatch --dependency=afterok:$(sqn upload_labkey_${PED_gs[$i]}) -J vcfeval_dijen_${PED_gs[$i]} --export=TRUTH_FILE=${GRCh38benchmark},TEST_FILE=${INPUTDIR}/qualif_2_12/gs/${PED_gs[$i]}/${dijen[$i]}/$(echo ${files_gs[$i]}),TEMPLATE=${GRCh38sdf},OUTPUTDIR=$INPUTDIR/qualif_2_12/gs/vcfeval_gs_${dijen[$i]}_${vcfeval_time_gs},EVALUATION_REGIONS=${GRCh38bed},RESULT="result_wrapper_vcfeval_gs_${dijen[$i]}_${vcfeval_time_gs}.log",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_vcfeval.sh

        files_vcfeval_gs+=(result_wrapper_vcfeval_gs_${dijen[$i]}_${vcfeval_time_gs}.log)
        summary_vcfeval_gs+=(${INPUTDIR}/qualif_2_12/gs/vcfeval_gs_${dijen[$i]}_${vcfeval_time_gs}/summary.txt)
        list_dij_vcf_gs+=(${dijen[$i]})
        indice_vcf_gs+=($i)
        dependency_all_vcfeval_gs=$(printf "${dependency_all_vcfeval_gs}:$(sqn vcfeval_dijen_${PED_gs[$i]})")

    fi
done

end_search_var_gs=$(date +"%F_%H-%M-%S")

# endregion

# region Search_all_var_nbs

dependency_all_research_nbs=""
dependency_all_vcfeval_nbs=""

echo "Searching for reference variations in nbs files and starting vcfeval for reference files"
start_search_var_nbs=$(date +"%F_%H-%M-%S")
files_vcfeval_nbs=()
summary_vcfeval_nbs=()
list_dij_vcf_nbs=()
for ((i=0; i<len_nbs; i++))
do
    if [ ${variations_nbs[$i]} != "vcfeval" ]
    then
        echo "Looking for variation ${variations_nbs[$i]} in ${PED_nbs[$i]}, ${dijnbs[$i]}"
        echo "Command : sbatch --dependency=afterok:$(sqn upload_labkey_nbs_${PED_nbs[$i]}) -J nbs_var_search_${PED_nbs[$i]} --export=INPUTFILE=${INPUTDIR}/qualif_2_12/nbs/${PED_nbs[$i]}/${dijnbs[$i]}/$(echo ${files_nbs[$i]}),RESULT=${variations_nbs[$i]},LOGFILE="research_log_nbs_$(date +"%F_%H-%M-%S")",RESULTFILE="research_result_nbs_$(date +"%F_%H-%M-%S")",SAMPLE_TYPE="nbs",PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_research_result.sh"
        sbatch --dependency=afterok:$(sqn upload_labkey_nbs_${PED_nbs[$i]}) -J nbs_var_search_${PED_nbs[$i]} --export=INPUTFILE=${INPUTDIR}/qualif_2_12/nbs/${PED_nbs[$i]}/${dijnbs[$i]}/$(echo ${files_nbs[$i]}),RESULT=${variations_nbs[$i]},LOGFILE="research_log_nbs_$(date +"%F_%H-%M-%S")",RESULTFILE="research_result_nbs_$(date +"%F_%H-%M-%S")",SAMPLE_TYPE="nbs",PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_research_result.sh

        indice_var_nbs+=($i)
        dependency_all_research_nbs=$(printf "${dependency_all_research_nbs}:$(sqn nbs_var_search_${PED_nbs[$i]})")

        sleep 1
    else
        echo "Starting vcfeval for ${PED_nbs[$i]}, ${dijnbs[$i]}"
        vcfeval_time_nbs=$(date +"%F_%H-%M-%S")
        echo "Command : sbatch --dependency=afterok:$(sqn upload_labkey_nbs_${PED_nbs[$i]}) -J vcfeval_dijnbs_${PED_nbs[$i]} --export=TRUTH_FILE=${GRCh38benchmark},TEST_FILE=${INPUTDIR}/qualif_2_12/nbs/${PED_nbs[$i]}/${dijnbs[$i]}/$(echo ${files_nbs[$i]}),TEMPLATE=${GRCh38sdf},OUTPUTDIR=${INPUTDIR}/qualif_2_12/nbs/vcfeval_nbs_${dijnbs[$i]}_${vcfeval_time_nbs},EVALUATION_REGIONS=${GRCh38bed},RESULT="result_wrapper_vcfeval_nbs_${dijnbs[$i]}_${vcfeval_time_nbs}.log",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_vcfeval.sh"
        sbatch --dependency=afterok:$(sqn upload_labkey_nbs_${PED_nbs[$i]}) -J vcfeval_dijnbs_${PED_nbs[$i]} --export=TRUTH_FILE=${GRCh38benchmark},TEST_FILE=${INPUTDIR}/qualif_2_12/nbs/${PED_nbs[$i]}/${dijnbs[$i]}/$(echo ${files_nbs[$i]}),TEMPLATE=${GRCh38sdf},OUTPUTDIR=${INPUTDIR}/qualif_2_12/nbs/vcfeval_nbs_${dijnbs[$i]}_${vcfeval_time_nbs},EVALUATION_REGIONS=${GRCh38bed},RESULT="result_wrapper_vcfeval_nbs_${dijnbs[$i]}_${vcfeval_time_nbs}.log",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_vcfeval.sh

        files_vcfeval_nbs+=(result_wrapper_vcfeval_nbs_${dijnbs[$i]}_${vcfeval_time_nbs}.log)
        summary_vcfeval_nbs+=(${INPUTDIR}/qualif_2_12/nbs/vcfeval_nbs_${dijnbs[$i]}_${vcfeval_time_nbs}/summary.txt)
        list_dij_vcf_nbs+=(${dijnbs[$i]})
        indice_vcf_nbs+=($i)
        dependency_all_vcfeval_nbs=$(printf "${dependency_all_vcfeval_nbs}:$(sqn vcfeval_dijnbs_${PED_nbs[$i]})")

    fi
done

end_search_var_nbs=$(date +"%F_%H-%M-%S")

# endregion


# region count_variations

echo "Counting the number of variations found"

if (( ${#PED_es[@]} > 0 ))
then
    echo "Counting for es files"
    LIST_PED_ARG_es=$(IFS=:; echo "${PED_es[*]}")
    LIST_DIJ_ARG_es=$(IFS=:; echo "${dijex[*]}")
    start_counting_es_var=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --dependency=afterok:${dependency_all_analysis_es#:} -J get_nb_var_es --export=INPUTDIR=${INPUTDIR},SAMPLE_TYPE="es",OUTPUT_FILE="nb_var_es_${start_counting_es_var}.txt",LIST_PED_ARG=${LIST_PED_ARG_es},LIST_DIJ_ARG=${LIST_DIJ_ARG_es} ${PIPELINE_QUALIF}/common/qualification/get_nb_var.sh"
    sbatch --dependency=afterok:${dependency_all_analysis_es#:} -J get_nb_var_es --export=INPUTDIR=${INPUTDIR},SAMPLE_TYPE="es",OUTPUT_FILE="nb_var_es_${start_counting_es_var}.txt",LIST_PED_ARG=${LIST_PED_ARG_es},LIST_DIJ_ARG=${LIST_DIJ_ARG_es} ${PIPELINE_QUALIF}/common/qualification/get_nb_var.sh
fi

if (( ${#PED_gs[@]} > 0 ))
then
    echo "Counting for gs files"
    LIST_PED_ARG_gs=$(IFS=:; echo "${PED_gs[*]}")
    LIST_DIJ_ARG_gs=$(IFS=:; echo "${dijen[*]}")
    start_counting_gs_var=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --dependency=afterok:${dependency_all_analysis_gs#:} -J get_nb_var_gs --export=INPUTDIR=${INPUTDIR},SAMPLE_TYPE="gs",OUTPUT_FILE="nb_var_gs_${start_counting_gs_var}.txt",LIST_PED_ARG=${LIST_PED_ARG_gs},LIST_DIJ_ARG=${LIST_DIJ_ARG_gs} ${PIPELINE_QUALIF}/common/qualification/get_nb_var.sh"
    sbatch --dependency=afterok:${dependency_all_analysis_gs#:} -J get_nb_var_gs --export=INPUTDIR=${INPUTDIR},SAMPLE_TYPE="gs",OUTPUT_FILE="nb_var_gs_${start_counting_gs_var}.txt",LIST_PED_ARG=${LIST_PED_ARG_gs},LIST_DIJ_ARG=${LIST_DIJ_ARG_gs} ${PIPELINE_QUALIF}/common/qualification/get_nb_var.sh
fi

if (( ${#PED_nbs[@]} > 0 ))
then
    echo "Counting for nbs files"
    LIST_PED_ARG_nbs=$(IFS=:; echo "${PED_nbs[*]}")
    LIST_DIJ_ARG_nbs=$(IFS=:; echo "${dijnbs[*]}")
    start_counting_nbs_var=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --dependency=afterok:${dependency_all_analysis_nbs#:} -J get_nb_var_nbs --export=INPUTDIR=${INPUTDIR},SAMPLE_TYPE="nbs",OUTPUT_FILE="nb_var_nbs_${start_counting_nbs_var}.txt",LIST_PED_ARG=${LIST_PED_ARG_nbs},LIST_DIJ_ARG=${LIST_DIJ_ARG_nbs} ${PIPELINE_QUALIF}/common/qualification/get_nb_var.sh"
    sbatch --dependency=afterok:${dependency_all_analysis_nbs#:} -J get_nb_var_nbs --export=INPUTDIR=${INPUTDIR},SAMPLE_TYPE="nbs",OUTPUT_FILE="nb_var_nbs_${start_counting_nbs_var}.txt",LIST_PED_ARG=${LIST_PED_ARG_nbs},LIST_DIJ_ARG=${LIST_DIJ_ARG_nbs} ${PIPELINE_QUALIF}/common/qualification/get_nb_var.sh
fi

# endregion

# region reports

if (( ${#indice_var_es[@]} > 0 ))
then
    echo "Selecting es research result files"
    echo "Command : sbatch --dependency=afterok:${dependency_all_research_es#:} -J filter_date_files_es --export=FILES_NAME_FORM="research_result_es_*.log",START_DATE=${start_search_var_es},END_DATE=${end_search_var_es},SAMPLE_TYPE="es" ${PIPELINE_QUALIF}/common/qualification/filter_date_files.sh"
    sbatch --dependency=afterok:${dependency_all_research_es#:} -J filter_date_files_es --export=FILES_NAME_FORM="research_result_es_*.log",START_DATE=${start_search_var_es},END_DATE=${end_search_var_es},SAMPLE_TYPE="es" ${PIPELINE_QUALIF}/common/qualification/filter_date_files.sh

    echo "Creating found es file"
    echo "Command : sbatch --dependency=afterok:${dependency_all_research_es#:} -J found_file_es --export=FILES_NAME_FORM="research_result_es_*.log",SAMPLE_TYPE="es",START_DATE=${start_search_var_es},END_DATE=${end_search_var_es} ${PIPELINE_QUALIF}/common/qualification/create_found_file.sh"
    sbatch --dependency=afterok:${dependency_all_research_es#:} -J found_file_es --export=FILES_NAME_FORM="research_result_es_*.log",SAMPLE_TYPE="es",START_DATE=${start_search_var_es},END_DATE=${end_search_var_es} ${PIPELINE_QUALIF}/common/qualification/create_found_file.sh
fi

LIST_DIJ_VCF_ES=$(IFS=:; echo "${list_dij_vcf_es[*]}")
LIST_SUMMARY_VCF_ES=$(IFS=:; echo "${summary_vcfeval_es[*]}")


if (( ${#indice_vcf_es[@]} > 0 && ${#indice_var_es[@]} > 0 ))
then
    echo "Making report for es files"
    LIST_VCFEVAL_ARG_ES=$(IFS=:; echo "${files_vcfeval_es[*]}")
    date_es_report=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --dependency=afterok:$(sqn filter_date_files_es):${dependency_all_vcfeval_es#:}:$(sqn get_nb_var_es):$(sqn found_file_es) --export=REPORT_NAME="report_es_${date_es_report}",FILES_TO_ADD=${LIST_VCFEVAL_ARG_ES},SAMPLE_TYPE="es",NB_VAR_FILE="nb_var_es_${start_counting_es_var}.txt",FOUND_FILE="found_es.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_ES},LIST_DIJ_ARG=${LIST_DIJ_VCF_ES},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh"
    sbatch --dependency=afterok:$(sqn filter_date_files_es):${dependency_all_vcfeval_es#:}:$(sqn get_nb_var_es):$(sqn found_file_es) --export=REPORT_NAME="report_es_${date_es_report}",FILES_TO_ADD=${LIST_VCFEVAL_ARG_ES},SAMPLE_TYPE="es",NB_VAR_FILE="nb_var_es_${start_counting_es_var}.txt",FOUND_FILE="found_es.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_ES},LIST_DIJ_ARG=${LIST_DIJ_VCF_ES},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh
elif (( ${#indice_var_es[@]} > 0 ))
then
    echo "Making report for es files"
    date_es_report=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --dependency=afterok:$(sqn filter_date_files_es):$(sqn get_nb_var_es):$(sqn found_file_es) --export=REPORT_NAME="report_es_${date_es_report}",SAMPLE_TYPE="es",NB_VAR_FILE="nb_var_es_${start_counting_es_var}.txt",FOUND_FILE="found_es.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_ES},LIST_DIJ_ARG=${LIST_DIJ_VCF_ES},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh"
    sbatch --dependency=afterok:$(sqn filter_date_files_es):$(sqn get_nb_var_es):$(sqn found_file_es) --export=REPORT_NAME="report_es_${date_es_report}",SAMPLE_TYPE="es",NB_VAR_FILE="nb_var_es_${start_counting_es_var}.txt",FOUND_FILE="found_es.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_ES},LIST_DIJ_ARG=${LIST_DIJ_VCF_ES},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh
elif (( ${#indice_vcf_es[@]} > 0 ))
then
    echo "Making report for es files"
    LIST_VCFEVAL_ARG_ES=$(IFS=:; echo "${files_vcfeval_es[*]}")
    date_es_report=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --dependency=afterok:${dependency_all_vcfeval_es#:}:$(sqn get_nb_var_es) --export=REPORT_NAME="report_es_${date_es_report}",FILES_TO_ADD=${LIST_VCFEVAL_ARG_ES},SAMPLE_TYPE="es",NB_VAR_FILE="nb_var_es_${start_counting_es_var}.txt",FOUND_FILE="found_es.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_ES},LIST_DIJ_ARG=${LIST_DIJ_VCF_ES},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh"
    sbatch --dependency=afterok:${dependency_all_vcfeval_es#:}:$(sqn get_nb_var_es) --export=REPORT_NAME="report_es_${date_es_report}",FILES_TO_ADD=${LIST_VCFEVAL_ARG_ES},SAMPLE_TYPE="es",NB_VAR_FILE="nb_var_es_${start_counting_es_var}.txt",FOUND_FILE="found_es.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_ES},LIST_DIJ_ARG=${LIST_DIJ_VCF_ES},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh
fi



if (( ${#indice_var_gs[@]} > 0 ))
then
    echo "Selecting gs research result files"
    echo "Command : sbatch --dependency=afterok:${dependency_all_research_gs#:} -J filter_date_files_gs --export=FILES_NAME_FORM="research_result_gs_*.log",START_DATE=${start_search_var_gs},END_DATE=${end_search_var_gs},SAMPLE_TYPE="gs" ${PIPELINE_QUALIF}/common/qualification/filter_date_files.sh"
    sbatch --dependency=afterok:${dependency_all_research_gs#:} -J filter_date_files_gs --export=FILES_NAME_FORM="research_result_gs_*.log",START_DATE=${start_search_var_gs},END_DATE=${end_search_var_gs},SAMPLE_TYPE="gs" ${PIPELINE_QUALIF}/common/qualification/filter_date_files.sh

    echo "Creating found gs file"
    echo "Command : sbatch --dependency=afterok:${dependency_all_research_gs#:} -J found_file_gs --export=FILES_NAME_FORM="research_result_gs_*.log",SAMPLE_TYPE="gs",START_DATE=${start_search_var_gs},END_DATE=${end_search_var_gs} ${PIPELINE_QUALIF}/common/qualification/create_found_file.sh"
    sbatch --dependency=afterok:${dependency_all_research_gs#:} -J found_file_gs --export=FILES_NAME_FORM="research_result_gs_*.log",SAMPLE_TYPE="gs",START_DATE=${start_search_var_gs},END_DATE=${end_search_var_gs} ${PIPELINE_QUALIF}/common/qualification/create_found_file.sh
fi


LIST_DIJ_VCF_GS=$(IFS=:; echo "${list_dij_vcf_gs[*]}")
LIST_SUMMARY_VCF_GS=$(IFS=:; echo "${summary_vcfeval_gs[*]}")

if (( ${#indice_vcf_gs[@]} > 0 && ${#indice_var_gs[@]} > 0 ))
then
    echo "Making report for gs files"
    LIST_VCFEVAL_ARG_GS=$(IFS=:; echo "${files_vcfeval_gs[*]}")
    date_gs_report=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --dependency=afterok:$(sqn filter_date_files_gs):${dependency_all_vcfeval_gs#:}:$(sqn get_nb_var_gs):$(sqn found_file_gs) --export=REPORT_NAME="report_gs_${date_gs_report}",SAMPLE_TYPE="gs",FILES_TO_ADD=${LIST_VCFEVAL_ARG_GS},NB_VAR_FILE="nb_var_gs_${start_counting_gs_var}.txt",FOUND_FILE="found_gs.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_GS},LIST_DIJ_ARG=${LIST_DIJ_VCF_GS},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh"
    sbatch --dependency=afterok:$(sqn filter_date_files_gs):${dependency_all_vcfeval_gs#:}:$(sqn get_nb_var_gs):$(sqn found_file_gs) --export=REPORT_NAME="report_gs_${date_gs_report}",SAMPLE_TYPE="gs",FILES_TO_ADD=${LIST_VCFEVAL_ARG_GS},NB_VAR_FILE="nb_var_gs_${start_counting_gs_var}.txt",FOUND_FILE="found_gs.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_GS},LIST_DIJ_ARG=${LIST_DIJ_VCF_GS},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh
elif (( ${#indice_var_gs[@]} > 0 ))
then
    echo "Making report for gs files"
    date_gs_report=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --dependency=afterok:$(sqn filter_date_files_gs):$(sqn get_nb_var_gs):$(sqn found_file_gs) --export=REPORT_NAME="report_gs_${date_gs_report}",SAMPLE_TYPE="gs",NB_VAR_FILE="nb_var_gs_${start_counting_gs_var}.txt",FOUND_FILE="found_gs.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_GS},LIST_DIJ_ARG=${LIST_DIJ_VCF_GS},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh"
    sbatch --dependency=afterok:$(sqn filter_date_files_gs):$(sqn get_nb_var_gs):$(sqn found_file_gs) --export=REPORT_NAME="report_gs_${date_gs_report}",SAMPLE_TYPE="gs",NB_VAR_FILE="nb_var_gs_${start_counting_gs_var}.txt",FOUND_FILE="found_gs.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_GS},LIST_DIJ_ARG=${LIST_DIJ_VCF_GS},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh
elif (( ${#indice_vcf_gs[@]} > 0 ))
then
    echo "Making report for gs files"
    LIST_VCFEVAL_ARG_GS=$(IFS=:; echo "${files_vcfeval_gs[*]}")
    date_gs_report=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --dependency=afterok:$(sqn filter_date_files_gs):${dependency_all_vcfeval_gs#:}:$(sqn get_nb_var_gs) --export=REPORT_NAME="report_gs_${date_gs_report}",SAMPLE_TYPE="gs",FILES_TO_ADD=${LIST_VCFEVAL_ARG_GS},NB_VAR_FILE="nb_var_gs_${start_counting_gs_var}.txt",FOUND_FILE="found_gs.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_GS},LIST_DIJ_ARG=${LIST_DIJ_VCF_GS},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh"
    sbatch --dependency=afterok:$(sqn filter_date_files_gs):${dependency_all_vcfeval_gs#:}:$(sqn get_nb_var_gs) --export=REPORT_NAME="report_gs_${date_gs_report}",SAMPLE_TYPE="gs",FILES_TO_ADD=${LIST_VCFEVAL_ARG_GS},NB_VAR_FILE="nb_var_gs_${start_counting_gs_var}.txt",FOUND_FILE="found_gs.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_GS},LIST_DIJ_ARG=${LIST_DIJ_VCF_GS},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh
fi


if (( ${#indice_var_nbs[@]} > 0 ))
then
    echo "Selecting nbs research result files"
    echo "Command : sbatch --dependency=afterok:${dependency_all_research_nbs#:} -J filter_date_files_nbs --export=FILES_NAME_FORM="research_result_nbs_*.log",START_DATE=${start_search_var_nbs},END_DATE=${end_search_var_nbs},SAMPLE_TYPE="nbs" ${PIPELINE_QUALIF}/common/qualification/filter_date_files.sh"
    sbatch --dependency=afterok:${dependency_all_research_nbs#:} -J filter_date_files_nbs --export=FILES_NAME_FORM="research_result_nbs_*.log",START_DATE=${start_search_var_nbs},END_DATE=${end_search_var_nbs},SAMPLE_TYPE="nbs" ${PIPELINE_QUALIF}/common/qualification/filter_date_files.sh

    echo "Creating found nbs file"
    echo "Command : sbatch --dependency=afterok:${dependency_all_research_nbs#:} -J found_file_nbs --export=FILES_NAME_FORM="research_result_nbs_*.log",SAMPLE_TYPE="nbs",START_DATE=${start_search_var_nbs},END_DATE=${end_search_var_nbs} ${PIPELINE_QUALIF}/common/qualification/create_found_file.sh"
    sbatch --dependency=afterok:${dependency_all_research_nbs#:} -J found_file_nbs --export=FILES_NAME_FORM="research_result_nbs_*.log",SAMPLE_TYPE="nbs",START_DATE=${start_search_var_nbs},END_DATE=${end_search_var_nbs} ${PIPELINE_QUALIF}/common/qualification/create_found_file.sh
fi


LIST_DIJ_VCF_NBS=$(IFS=:; echo "${list_dij_vcf_nbs[*]}")
LIST_SUMMARY_VCF_NBS=$(IFS=:; echo "${summary_vcfeval_nbs[*]}")

if (( ${#indice_vcf_nbs[@]} > 0 && ${#indice_var_nbs[@]} > 0 ))
then
    echo "Making report for nbs files"
    LIST_VCFEVAL_ARG_NBS=$(IFS=:; echo "${files_vcfeval_nbs[*]}")
    date_nbs_report=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --dependency=afterok:$(sqn filter_date_files_nbs):${dependency_all_vcfeval_nbs#:}:$(sqn get_nb_var_nbs):$(sqn found_file_nbs) --export=REPORT_NAME="report_nbs_${date_nbs_report}",SAMPLE_TYPE="nbs",FILES_TO_ADD=${LIST_VCFEVAL_ARG_NBS},NB_VAR_FILE="nb_var_nbs_${start_counting_nbs_var}.txt",FOUND_FILE="found_nbs.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_NBS},LIST_DIJ_ARG=${LIST_DIJ_VCF_NBS},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh"
    sbatch --dependency=afterok:$(sqn filter_date_files_nbs):${dependency_all_vcfeval_nbs#:}:$(sqn get_nb_var_nbs):$(sqn found_file_nbs) --export=REPORT_NAME="report_nbs_${date_nbs_report}",SAMPLE_TYPE="nbs",FILES_TO_ADD=${LIST_VCFEVAL_ARG_NBS},NB_VAR_FILE="nb_var_nbs_${start_counting_nbs_var}.txt",FOUND_FILE="found_nbs.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_NBS},LIST_DIJ_ARG=${LIST_DIJ_VCF_NBS},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh
elif (( ${#indice_var_nbs[@]} > 0 ))
then
    echo "Making report for nbs files"
    date_nbs_report=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --dependency=afterok:$(sqn filter_date_files_nbs):$(sqn get_nb_var_nbs):$(sqn found_file_nbs) --export=REPORT_NAME="report_nbs_${date_nbs_report}",SAMPLE_TYPE="nbs",NB_VAR_FILE="nb_var_nbs_${start_counting_nbs_var}.txt",FOUND_FILE="found_nbs.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_NBS},LIST_DIJ_ARG=${LIST_DIJ_VCF_NBS},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh"
    sbatch --dependency=afterok:$(sqn filter_date_files_nbs):$(sqn get_nb_var_nbs):$(sqn found_file_nbs) --export=REPORT_NAME="report_nbs_${date_nbs_report}",SAMPLE_TYPE="nbs",NB_VAR_FILE="nb_var_nbs_${start_counting_nbs_var}.txt",FOUND_FILE="found_nbs.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_NBS},LIST_DIJ_ARG=${LIST_DIJ_VCF_NBS},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh
elif (( ${#indice_vcf_nbs[@]} > 0 ))
then
    echo "Making report for nbs files"
    LIST_VCFEVAL_ARG_NBS=$(IFS=:; echo "${files_vcfeval_nbs[*]}")
    date_nbs_report=$(date +"%F_%H-%M-%S")
    echo "Command : sbatch --dependency=afterok:${dependency_all_vcfeval_nbs#:}:$(sqn get_nb_var_nbs) --export=REPORT_NAME="report_nbs_${date_nbs_report}",SAMPLE_TYPE="nbs",FILES_TO_ADD=${LIST_VCFEVAL_ARG_NBS},NB_VAR_FILE="nb_var_nbs_${start_counting_nbs_var}.txt",FOUND_FILE="found_nbs.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_NBS},LIST_DIJ_ARG=${LIST_DIJ_VCF_NBS},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh"
    sbatch --dependency=afterok:${dependency_all_vcfeval_nbs#:}:$(sqn get_nb_var_nbs) --export=REPORT_NAME="report_nbs_${date_nbs_report}",SAMPLE_TYPE="nbs",FILES_TO_ADD=${LIST_VCFEVAL_ARG_NBS},NB_VAR_FILE="nb_var_nbs_${start_counting_nbs_var}.txt",FOUND_FILE="found_nbs.txt",LIST_SUMMARY_FILES=${LIST_SUMMARY_VCF_NBS},LIST_DIJ_ARG=${LIST_DIJ_VCF_NBS},PIPELINE_QUALIF=${PIPELINE_QUALIF} ${PIPELINE_QUALIF}/common/qualification/wrapper_report_maker.sh
fi



# endregion

if [[ ${UPDATE} == "True" ]]
then

dependency_update_var=""

# region update of es variations table in database

if (( ${#indice_var_es[@]} > 0 ))
then


len_indice_var_es=${#indice_var_es[@]}

echo "Getting data to update es variations table in database 0"
echo "Command : sbatch --dependency=afterok:$(sqn found_file_es):$(sqn get_nb_var_es) -J get_data_var_es_0 --export=DIJEXN=${dijex[${indice_var_es[0]}]},DATE=${start_search_var_es},SEARCH_FILE=${INPUTDIR}/qualif_2_12/es/${PED_es[${indice_var_es[0]}]}/${dijex[${indice_var_es[0]}]}/$(echo ${files_es[${indice_var_es[0]}]}),SEARCHED_VARIATION=${variations_es[${indice_var_es[0]}]},SAMPLE_TYPE="es",FOUND_FILE=found_es.txt,HTML_REPORT="report_es_${date_es_report}.html",NB_VAR_FOUND_FILE=nb_var_es_${start_counting_es_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_variations.sh"
sbatch --dependency=afterok:$(sqn found_file_es):$(sqn get_nb_var_es) -J get_data_var_es_0 --export=DIJEXN=${dijex[${indice_var_es[0]}]},DATE=${start_search_var_es},SEARCH_FILE=${INPUTDIR}/qualif_2_12/es/${PED_es[${indice_var_es[0]}]}/${dijex[${indice_var_es[0]}]}/$(echo ${files_es[${indice_var_es[0]}]}),SEARCHED_VARIATION=${variations_es[${indice_var_es[0]}]},SAMPLE_TYPE="es",FOUND_FILE=found_es.txt,HTML_REPORT="report_es_${date_es_report}.html",NB_VAR_FOUND_FILE=nb_var_es_${start_counting_es_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_variations.sh

echo "Updating es variations table in database 0"
echo "Command : sbatch --dependency=afterok:$(sqn get_data_var_es_0) -J update_tinydb_es_0 --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",VAR="True",DATA_VAR_FILE="data_variations_es.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh"
sbatch --dependency=afterok:$(sqn get_data_var_es_0) -J update_tinydb_es_0 --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",VAR="True",DATA_VAR_FILE="data_variations_es.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh


for ((i=1; i<len_indice_var_es; i++))
do
    echo "Getting data to update es variations table in database $i"
    echo "Command : sbatch --dependency=afterok:$(sqn found_file_es):$(sqn update_tinydb_es_$((i - 1))):$(sqn get_nb_var_es) -J get_data_var_es_${i} --export=DIJEXN=${dijex[${indice_var_es[$i]}]},DATE=${start_search_var_es},SEARCH_FILE=${INPUTDIR}/qualif_2_12/es/${PED_es[${indice_var_es[$i]}]}/${dijex[${indice_var_es[$i]}]}/$(echo ${files_es[${indice_var_es[$i]}]}),SEARCHED_VARIATION=${variations_es[${indice_var_es[$i]}]},SAMPLE_TYPE="es",FOUND_FILE=found_es.txt,HTML_REPORT="report_es_${date_es_report}.html",NB_VAR_FOUND_FILE=nb_var_es_${start_counting_es_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_variations.sh"
    sbatch --dependency=afterok:$(sqn found_file_es):$(sqn update_tinydb_es_$((i - 1))):$(sqn get_nb_var_es) -J get_data_var_es_${i} --export=DIJEXN=${dijex[${indice_var_es[$i]}]},DATE=${start_search_var_es},SEARCH_FILE=${INPUTDIR}/qualif_2_12/es/${PED_es[${indice_var_es[$i]}]}/${dijex[${indice_var_es[$i]}]}/$(echo ${files_es[${indice_var_es[$i]}]}),SEARCHED_VARIATION=${variations_es[${indice_var_es[$i]}]},SAMPLE_TYPE="es",FOUND_FILE=found_es.txt,HTML_REPORT="report_es_${date_es_report}.html",NB_VAR_FOUND_FILE=nb_var_es_${start_counting_es_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_variations.sh

    echo "Updating es variations table in database $i"
    echo "Command : sbatch --dependency=afterok:$(sqn get_data_var_es_${i}) -J update_tinydb_es_${i} --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",VAR="True",DATA_VAR_FILE="data_variations_es.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh"
    sbatch --dependency=afterok:$(sqn get_data_var_es_${i}) -J update_tinydb_es_${i} --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",VAR="True",DATA_VAR_FILE="data_variations_es.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh

done

dependency_update_var=$(printf "${dependency_update_var}:$(sqn update_tinydb_es_$((len_indice_var_es - 1)))")

fi

# endregion

# region update of gs variations table in database

if (( ${#indice_var_gs[@]} > 0 ))
then

len_indice_var_gs=${#indice_var_gs[@]}


echo "Getting data to update gs variations table in database 0"
echo "Command : sbatch --dependency=afterok:$(sqn found_file_gs):$(sqn get_nb_var_gs) -J get_data_var_gs_0 --export=DIJEXN=${dijen[${indice_var_gs[0]}]},DATE=${start_search_var_es},SEARCH_FILE=${INPUTDIR}/qualif_2_12/gs/${PED_gs[${indice_var_gs[0]}]}/${dijen[${indice_var_gs[0]}]}/$(echo ${files_gs[${indice_var_gs[0]}]}),SEARCHED_VARIATION=${variations_gs[${indice_var_gs[0]}]},SAMPLE_TYPE="gs",FOUND_FILE=found_gs.txt,HTML_REPORT="report_gs_${date_gs_report}.html",NB_VAR_FOUND_FILE=nb_var_gs_${start_counting_gs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_variations.sh"
sbatch --dependency=afterok:$(sqn found_file_gs):$(sqn get_nb_var_gs) -J get_data_var_gs_0 --export=DIJEXN=${dijen[${indice_var_gs[0]}]},DATE=${start_search_var_es},SEARCH_FILE=${INPUTDIR}/qualif_2_12/gs/${PED_gs[${indice_var_gs[0]}]}/${dijen[${indice_var_gs[0]}]}/$(echo ${files_gs[${indice_var_gs[0]}]}),SEARCHED_VARIATION=${variations_gs[${indice_var_gs[0]}]},SAMPLE_TYPE="gs",FOUND_FILE=found_gs.txt,HTML_REPORT="report_gs_${date_gs_report}.html",NB_VAR_FOUND_FILE=nb_var_gs_${start_counting_gs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_variations.sh

echo "Updating gs variations table in database 0"
echo "Command : sbatch --dependency=afterok:$(sqn get_data_var_gs_0) -J update_tinydb_gs_0 --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",VAR="True",DATA_VAR_FILE="data_variations_gs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh"
sbatch --dependency=afterok:$(sqn get_data_var_gs_0) -J update_tinydb_gs_0 --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",VAR="True",DATA_VAR_FILE="data_variations_gs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh



for ((i=1; i<len_indice_var_gs; i++))
do
    echo "Getting data to update gs variations table in database $i"
    echo "Command : sbatch --dependency=afterok:$(sqn found_file_gs):$(sqn update_tinydb_gs_$((i - 1))):$(sqn get_nb_var_gs) -J get_data_var_gs_${i} --export=DIJEXN=${dijen[${indice_var_gs[$i]}]},DATE=${start_search_var_es},SEARCH_FILE=${INPUTDIR}/qualif_2_12/gs/${PED_gs[${indice_var_gs[$i]}]}/${dijen[${indice_var_gs[$i]}]}/$(echo ${files_gs[${indice_var_gs[$i]}]}),SEARCHED_VARIATION=${variations_gs[${indice_var_gs[$i]}]},SAMPLE_TYPE="gs",FOUND_FILE=found_gs.txt,HTML_REPORT="report_gs_${date_gs_report}.html",NB_VAR_FOUND_FILE=nb_var_gs_${start_counting_gs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_variations.sh"
    sbatch --dependency=afterok:$(sqn found_file_gs):$(sqn update_tinydb_gs_$((i - 1))):$(sqn get_nb_var_gs) -J get_data_var_gs_${i} --export=DIJEXN=${dijen[${indice_var_gs[$i]}]},DATE=${start_search_var_es},SEARCH_FILE=${INPUTDIR}/qualif_2_12/gs/${PED_gs[${indice_var_gs[$i]}]}/${dijen[${indice_var_gs[$i]}]}/$(echo ${files_gs[${indice_var_gs[$i]}]}),SEARCHED_VARIATION="${variations_gs[${indice_var_gs[$i]}]}",SAMPLE_TYPE="gs",FOUND_FILE=found_gs.txt,HTML_REPORT="report_gs_${date_gs_report}.html",NB_VAR_FOUND_FILE=nb_var_gs_${start_counting_gs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_variations.sh

    echo "Updating gs variations table in database $i"
    echo "Command : sbatch --dependency=afterok:$(sqn get_data_var_gs_${i}) -J update_tinydb_gs_${i} --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",VAR="True",DATA_VAR_FILE="data_variations_gs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh"
    sbatch --dependency=afterok:$(sqn get_data_var_gs_${i}) -J update_tinydb_gs_${i} --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",VAR="True",DATA_VAR_FILE="data_variations_gs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh

done

dependency_update_var=$(printf "${dependency_update_var}:$(sqn update_tinydb_gs_$((len_indice_var_gs - 1)))")

fi

# endregion

# region update of nbs variations table in database

if (( ${#indice_var_nbs[@]} > 0 ))
then

len_indice_var_nbs="${#indice_var_nbs[@]}"

echo "Getting data to update nbs variations table in database 0"
echo "Command : sbatch --dependency=afterok:$(sqn found_file_nbs):$(sqn get_nb_var_nbs) -J get_data_var_nbs_0 --export=DIJEXN=${dijnbs[${indice_var_nbs[0]}]},DATE=${start_search_var_es},SEARCH_FILE=${INPUTDIR}/qualif_2_12/nbs/${PED_nbs[${indice_var_nbs[0]}]}/${dijnbs[${indice_var_nbs[0]}]}/$(echo ${files_nbs[${indice_var_nbs[0]}]}),SEARCHED_VARIATION=${variations_nbs[${indice_var_nbs[0]}]},SAMPLE_TYPE="nbs",FOUND_FILE=found_nbs.txt,HTML_REPORT="report_nbs_${date_nbs_report}.html",NB_VAR_FOUND_FILE=nb_var_nbs_${start_counting_nbs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_variations.sh"
sbatch --dependency=afterok:$(sqn found_file_nbs):$(sqn get_nb_var_nbs) -J get_data_var_nbs_0 --export=DIJEXN=${dijnbs[${indice_var_nbs[0]}]},DATE=${start_search_var_es},SEARCH_FILE=${INPUTDIR}/qualif_2_12/nbs/${PED_nbs[${indice_var_nbs[0]}]}/${dijnbs[${indice_var_nbs[0]}]}/$(echo ${files_nbs[${indice_var_nbs[0]}]}),SEARCHED_VARIATION=${variations_nbs[${indice_var_nbs[0]}]},SAMPLE_TYPE="nbs",FOUND_FILE=found_nbs.txt,HTML_REPORT="report_nbs_${date_nbs_report}.html",NB_VAR_FOUND_FILE=nb_var_nbs_${start_counting_nbs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_variations.sh

echo "Updating gs variations table in database 0"
echo "Command : sbatch --dependency=afterok:$(sqn get_data_var_nbs_0) -J update_tinydb_nbs_0 --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",VAR="True",DATA_VAR_FILE="data_variations_nbs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh"
sbatch --dependency=afterok:$(sqn get_data_var_nbs_0) -J update_tinydb_nbs_0 --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",VAR="True",DATA_VAR_FILE="data_variations_nbs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh


for ((i=1; i<len_nbs; i++))
do
    echo "Getting data to update nbs variations table in database $i"
    echo "Command : sbatch --dependency=afterok:$(sqn found_file_nbs):$(sqn update_tinydb_nbs_$((i - 1))):$(sqn get_nb_var_nbs) -J get_data_var_nbs_${i} --export=DIJEXN=${dijnbs[${indice_var_nbs[$i]}]},DATE=${start_search_var_es},SEARCH_FILE=${INPUTDIR}/qualif_2_12/nbs/${PED_nbs[${indice_var_nbs[$i]}]}/${dijnbs[${indice_var_nbs[$i]}]}/$(echo ${files_nbs[${indice_var_nbs[$i]}]}),SEARCHED_VARIATION=${variations_nbs[${indice_var_nbs[$i]}]},SAMPLE_TYPE="nbs",FOUND_FILE=found_nbs.txt,HTML_REPORT="report_nbs_${date_nbs_report}.html",NB_VAR_FOUND_FILE=nb_var_nbs_${start_counting_nbs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_variations.sh"
    sbatch --dependency=afterok:$(sqn found_file_nbs):$(sqn update_tinydb_nbs_$((i - 1))):$(sqn get_nb_var_nbs) -J get_data_var_nbs_${i} --export=DIJEXN=${dijnbs[${indice_var_nbs[$i]}]},DATE=${start_search_var_es},SEARCH_FILE=${INPUTDIR}/qualif_2_12/nbs/${PED_nbs[${indice_var_nbs[$i]}]}/${dijnbs[${indice_var_nbs[$i]}]}/$(echo ${files_nbs[${indice_var_nbs[$i]}]}),SEARCHED_VARIATION=${variations_nbs[${indice_var_nbs[$i]}]},SAMPLE_TYPE="nbs",FOUND_FILE=found_nbs.txt,HTML_REPORT="report_nbs_${date_nbs_report}.html",NB_VAR_FOUND_FILE=nb_var_nbs_${start_counting_nbs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_variations.sh

    echo "Updating nbs variations table in database $i"
    echo "Command : sbatch --dependency=afterok:$(sqn get_data_var_nbs_${i}) -J update_tinydb_nbs_${i} --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",VAR="True",DATA_VAR_FILE="data_variations_nbs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh"
    sbatch --dependency=afterok:$(sqn get_data_var_nbs_${i}) -J update_tinydb_nbs_${i} --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",VAR="True",DATA_VAR_FILE="data_variations_nbs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh

done

dependency_update_var=$(printf "${dependency_update_var}:$(sqn update_tinydb_nbs_$((len_indice_var_nbs - 1)))")

fi

# endregion

# region update vcfeval_es table in database

dependency_update_vcf=""

if (( ${#indice_vcf_es[@]} > 0 ))
then
len_indice_vcf_es=${#indice_vcf_es[@]}

echo "Getting data to update es vcfeval table in database 0"
echo "Command : sbatch --dependency=afterok:$(sqn vcfeval_dijex_${PED_es[${indice_vcf_es[0]}]}) -J get_data_vcfeval_es_0 --export=SAMPLE_TYPE="es",DIJEXN=${dijex[${indice_vcf_es[0]}]},DATE=${vcfeval_time_es},VCF_TRUTH=${GRCh38benchmark},SDF_REFERENCE=${GRCh38sdf},OPTIONS="BED_REGIONS=${BEDREFSEQ};EVALUATION_REGIONS=${GRCh38bed}",SUMMARY_FILE=${summary_vcfeval_es[0]},HTML_REPORT="report_es_${date_es_report}.html",NB_VAR_FOUND_FILE=nb_var_es_${start_counting_es_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_vcfeval.sh"
sbatch --dependency=afterok:$(sqn vcfeval_dijex_${PED_es[${indice_vcf_es[0]}]}) -J get_data_vcfeval_es_0 --export=SAMPLE_TYPE="es",DIJEXN=${dijex[${indice_vcf_es[0]}]},DATE=${vcfeval_time_es},VCF_TRUTH=${GRCh38benchmark},SDF_REFERENCE=${GRCh38sdf},OPTIONS="BED_REGIONS=${BEDREFSEQ};EVALUATION_REGIONS=${GRCh38bed}",SUMMARY_FILE=${summary_vcfeval_es[0]},HTML_REPORT="report_es_${date_es_report}.html",NB_VAR_FOUND_FILE=nb_var_es_${start_counting_es_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_vcfeval.sh


echo "Updating es vcfeval table in database 0"
echo "Command : sbatch --dependency=afterok:$(sqn get_data_vcfeval_es_0) -J update_vcfeval_es_database_0 --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",VCFEVAL="True",DATA_VCFEVAL_FILE="data_vcfeval_es.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh"
sbatch --dependency=afterok:$(sqn get_data_vcfeval_es_0) -J update_vcfeval_es_database_0 --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",VCFEVAL="True",DATA_VCFEVAL_FILE="data_vcfeval_es.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh

for ((i=1; i<len_indice_vcf_es; i++))
do
    echo "Getting data to update es vcfeval table in database $i"
    echo "Command : sbatch --dependency=afterok:$(sqn vcfeval_dijex_${PED_es[${indice_vcf_es[$i]}]}):$(sqn update_vcfeval_es_database_$((i - 1))) -J get_data_vcfeval_es_$i --export=SAMPLE_TYPE="es",DIJEXN=${dijex[${indice_vcf_es[$i]}]},DATE=${vcfeval_time_es},VCF_TRUTH=${GRCh38benchmark},SDF_REFERENCE=${GRCh38sdf},OPTIONS="BED_REGIONS=${BEDREFSEQ};EVALUATION_REGIONS=${GRCh38bed}",SUMMARY_FILE=${summary_vcfeval_es[$i]},HTML_REPORT="report_es_${date_es_report}.html",NB_VAR_FOUND_FILE=nb_var_es_${start_counting_es_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_vcfeval.sh"
    sbatch --dependency=afterok:$(sqn vcfeval_dijex_${PED_es[${indice_vcf_es[$i]}]}):$(sqn update_vcfeval_es_database_$((i - 1))) -J get_data_vcfeval_es_$i --export=SAMPLE_TYPE="es",DIJEXN=${dijex[${indice_vcf_es[$i]}]},DATE=${vcfeval_time_es},VCF_TRUTH=${GRCh38benchmark},SDF_REFERENCE=${GRCh38sdf},OPTIONS="BED_REGIONS=${BEDREFSEQ};EVALUATION_REGIONS=${GRCh38bed}",SUMMARY_FILE=${summary_vcfeval_es[$i]},HTML_REPORT="report_es_${date_es_report}.html",NB_VAR_FOUND_FILE=nb_var_es_${start_counting_es_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_vcfeval.sh


    echo "Updating es vcfeval table in database $i"
    echo "Command : sbatch --dependency=afterok:$(sqn get_data_vcfeval_es_$i) -J update_vcfeval_es_database_$i --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",VCFEVAL="True",DATA_VCFEVAL_FILE="data_vcfeval_es.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh"
    sbatch --dependency=afterok:$(sqn get_data_vcfeval_es_$i) -J update_vcfeval_es_database_$i --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",VCFEVAL="True",DATA_VCFEVAL_FILE="data_vcfeval_es.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh
done

dependency_update_vcf=$(printf "${dependency_update_vcf}:$(sqn update_vcfeval_es_database_$((len_indice_vcf_es - 1)))")

fi

# endregion

# region update vcfeval_gs table in database

if (( ${#indice_vcf_gs[@]} > 0 ))
then
len_indice_vcf_gs=${#indice_vcf_gs[@]}

echo "Getting data to update gs vcfeval table in database 0"
echo "Command : sbatch --dependency=afterok:$(sqn sqn vcfeval_dijen_${PED_gs[${indice_vcf_gs[0]}]}) -J get_data_vcfeval_gs_0 --export=SAMPLE_TYPE="gs",DIJEXN=${dijen[${indice_vcf_gs[0]}]},DATE=${vcfeval_time_gs},VCF_TRUTH=${GRCh38benchmark},SDF_REFERENCE=${GRCh38sdf},OPTIONS="EVALUATION_REGIONS=${GRCh38bed}",SUMMARY_FILE=${summary_vcfeval_gs[0]},HTML_REPORT="report_gs_${date_gs_report}.html",NB_VAR_FOUND_FILE=nb_var_gs_${start_counting_gs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_vcfeval.sh"
sbatch --dependency=afterok:$(sqn sqn vcfeval_dijen_${PED_gs[${indice_vcf_gs[0]}]}) -J get_data_vcfeval_gs_0 --export=SAMPLE_TYPE="gs",DIJEXN=${dijen[${indice_vcf_gs[0]}]},DATE=${vcfeval_time_gs},VCF_TRUTH=${GRCh38benchmark},SDF_REFERENCE=${GRCh38sdf},OPTIONS="EVALUATION_REGIONS=${GRCh38bed}",SUMMARY_FILE=${summary_vcfeval_gs[0]},HTML_REPORT="report_gs_${date_gs_report}.html",NB_VAR_FOUND_FILE=nb_var_gs_${start_counting_gs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_vcfeval.sh

echo "Updating gs vcfeval table in database"
echo "Command : sbatch --dependency=afterok:$(sqn get_data_vcfeval_gs_0) -J update_vcfeval_gs_database_0 --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",VCFEVAL="True",DATA_VCFEVAL_FILE="data_vcfeval_gs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh"
sbatch --dependency=afterok:$(sqn get_data_vcfeval_gs_0) -J update_vcfeval_gs_database_0 --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",VCFEVAL="True",DATA_VCFEVAL_FILE="data_vcfeval_gs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh

for ((i=1; i<len_indice_vcf_es; i++))
do
    echo "Getting data to update gs vcfeval table in database $i"
    echo "Command : sbatch --dependency=afterok:$(sqn vcfeval_dijen_${PED_gs[${indice_vcf_gs[$i]}]}):$(sqn update_vcfeval_gs_database_$((i - 1))) -J get_data_vcfeval_gs_$i --export=SAMPLE_TYPE="gs",DIJEXN=${dijen[${indice_vcf_gs[$i]}]},DATE=${vcfeval_time_gs},VCF_TRUTH=${GRCh38benchmark},SDF_REFERENCE=${GRCh38sdf},OPTIONS="EVALUATION_REGIONS=${GRCh38bed}",SUMMARY_FILE=${summary_vcfeval_gs[$i]},HTML_REPORT="report_gs_${date_gs_report}.html",NB_VAR_FOUND_FILE=nb_var_gs_${start_counting_gs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_vcfeval.sh"
    sbatch --dependency=afterok:$(sqn vcfeval_dijen_${PED_gs[${indice_vcf_gs[$i]}]}):$(sqn update_vcfeval_gs_database_$((i - 1))) -J get_data_vcfeval_gs_$i --export=SAMPLE_TYPE="gs",DIJEXN=${dijen[${indice_vcf_gs[$i]}]},DATE=${vcfeval_time_gs},VCF_TRUTH=${GRCh38benchmark},SDF_REFERENCE=${GRCh38sdf},OPTIONS="EVALUATION_REGIONS=${GRCh38bed}",SUMMARY_FILE=${summary_vcfeval_gs[$i]},HTML_REPORT="report_gs_${date_gs_report}.html",NB_VAR_FOUND_FILE=nb_var_gs_${start_counting_gs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_vcfeval.sh

    echo "Updating gs vcfeval table in database $i"
    echo "Command : sbatch --dependency=afterok:$(sqn get_data_vcfeval_gs_$i) -J update_vcfeval_gs_database_$i --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",VCFEVAL="True",DATA_VCFEVAL_FILE="data_vcfeval_gs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh"
    sbatch --dependency=afterok:$(sqn get_data_vcfeval_gs_$i) -J update_vcfeval_gs_database_$i --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",VCFEVAL="True",DATA_VCFEVAL_FILE="data_vcfeval_gs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh
done

dependency_update_vcf=$(printf "${dependency_update_vcf}:$(sqn update_vcfeval_gs_database_$((len_indice_vcf_gs - 1)))")

fi

# endregion

# region update vcfeval_nbs table in database

if (( ${#indice_vcf_nbs[@]} > 0 ))
then
len_indice_vcf_nbs="${#indice_vcf_nbs[@]}"

echo "Getting data to update nbs vcfeval table in database 0"
echo "Command : sbatch --dependency=afterok:$(sqn sqn vcfeval_dijnbs_${PED_nbs[${indice_vcf_nbs[0]}]}) -J get_data_vcfeval_nbs_0 --export=SAMPLE_TYPE="nbs",DIJEXN=${dijnbs[${indice_vcf_nbs[0]}]},DATE=${vcfeval_time_nbs},VCF_TRUTH=${GRCh38benchmark},SDF_REFERENCE=${GRCh38sdf},OPTIONS="EVALUATION_REGIONS=${GRCh38bed}",SUMMARY_FILE=${summary_vcfeval_nbs[0]},HTML_REPORT="report_nbs_${date_nbs_report}.html",NB_VAR_FOUND_FILE=nb_var_nbs_${start_counting_nbs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_vcfeval.sh"
sbatch --dependency=afterok:$(sqn sqn vcfeval_dijnbs_${PED_nbs[${indice_vcf_nbs[0]}]}) -J get_data_vcfeval_nbs_0 --export=SAMPLE_TYPE="nbs",DIJEXN=${dijnbs[${indice_vcf_nbs[0]}]},DATE=${vcfeval_time_nbs},VCF_TRUTH=${GRCh38benchmark},SDF_REFERENCE=${GRCh38sdf},OPTIONS="EVALUATION_REGIONS=${GRCh38bed}",SUMMARY_FILE=${summary_vcfeval_nbs[0]},HTML_REPORT="report_nbs_${date_nbs_report}.html",NB_VAR_FOUND_FILE=nb_var_nbs_${start_counting_nbs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_vcfeval.sh

echo "Updating nbs vcfeval table in database 0"
echo "Command : sbatch --dependency=afterok:$(sqn get_data_vcfeval_nbs_0) -J update_vcfeval_nbs_database_0 --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",VCFEVAL="True",DATA_VCFEVAL_FILE="data_vcfeval_nbs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh"
sbatch --dependency=afterok:$(sqn get_data_vcfeval_nbs_0) -J update_vcfeval_nbs_database_0 --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",VCFEVAL="True",DATA_VCFEVAL_FILE="data_vcfeval_nbs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh


for ((i=1; i<len_indice_vcf_nbs; i++))
do
    echo "Getting data to update nbs vcfeval table in database $i"
    echo "Command : sbatch --dependency=afterok:$(sqn vcfeval_dijnbs_${PED_nbs[${indice_vcf_nbs[$i]}]}):$(sqn update_vcfeval_nbs_database_$((i - 1))) -J get_data_vcfeval_nbs_$i --export=SAMPLE_TYPE="nbs",DIJEXN=${dijnbs[${indice_vcf_nbs[$i]}]},DATE=${vcfeval_time_nbs},VCF_TRUTH=${GRCh38benchmark},SDF_REFERENCE=${GRCh38sdf},OPTIONS="EVALUATION_REGIONS=${GRCh38bed}",SUMMARY_FILE=${summary_vcfeval_nbs[$i]},HTML_REPORT="report_nbs_${date_nbs_report}.html",NB_VAR_FOUND_FILE=nb_var_nbs_${start_counting_nbs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_vcfeval.sh"
    sbatch --dependency=afterok:$(sqn vcfeval_dijnbs_${PED_nbs[${indice_vcf_nbs[$i]}]}):$(sqn update_vcfeval_nbs_database_$((i - 1))) -J get_data_vcfeval_nbs_$i --export=SAMPLE_TYPE="nbs",DIJEXN=${dijnbs[${indice_vcf_nbs[$i]}]},DATE=${vcfeval_time_nbs},VCF_TRUTH=${GRCh38benchmark},SDF_REFERENCE=${GRCh38sdf},OPTIONS="EVALUATION_REGIONS=${GRCh38bed}",SUMMARY_FILE=${summary_vcfeval_nbs[$i]},HTML_REPORT="report_nbs_${date_nbs_report}.html",NB_VAR_FOUND_FILE=nb_var_nbs_${start_counting_nbs_var}.txt ${PIPELINE_QUALIF}/common/qualification/get_data_vcfeval.sh

    echo "Updating nbs vcfeval table in database $i"
    echo "Command : sbatch --dependency=afterok:$(sqn get_data_vcfeval_nbs_$i) -J update_vcfeval_nbs_database_$i --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",VCFEVAL="True",DATA_VCFEVAL_FILE="data_vcfeval_nbs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh"
    sbatch --dependency=afterok:$(sqn get_data_vcfeval_nbs_$i) -J update_vcfeval_nbs_database_$i --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",VCFEVAL="True",DATA_VCFEVAL_FILE="data_vcfeval_nbs.txt",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_update_tinydb.sh
done

dependency_update_vcf=$(printf "${dependency_update_vcf}:$(sqn update_vcfeval_nbs_database_$((len_indice_vcf_nbs - 1)))")

fi

# endregion

echo "Drawing graphs from the database"

if [[ -n "$dependency_update_var" ]]
then
    echo "Drawing graph with number of reference variations found by sample type and day"
    echo "Command : sbatch --dependency=afterok:${dependency_update_var#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="all",GRAPH_TYPE="var_ref",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh"
    sbatch --dependency=afterok:${dependency_update_var#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="all",GRAPH_TYPE="var_ref",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh
fi


if [[ -n "$dependency_update_vcf" ]]
then
    echo "Drawing graph of evolution of f-score for each sample"
    echo "Command : sbatch --dependency=afterok:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="all",GRAPH_TYPE="f-measure",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh"
    sbatch --dependency=afterok:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="all",GRAPH_TYPE="f-measure",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh
fi

if (( ${#PED_es[@]} > 0 ))
then
    if [[ -n "$dependency_update_var" ]] && [[ -n "$dependency_update_vcf" ]]
    then
        echo "Drawing graph of evolution of number of var found for each es sample"
        echo "Command : sbatch --dependency=afterok:${dependency_update_var#:}:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh"
        sbatch --dependency=afterok:${dependency_update_var#:}:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh 
    elif [[ -n "$dependency_update_vcf" ]]
    then 
        echo "Drawing graph of evolution of number of var found for each es sample"
        echo "Command : sbatch --dependency=afterok:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh"
        sbatch --dependency=afterok:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh 
    elif [[ -n "$dependency_update_var" ]]
    then
        echo "Drawing graph of evolution of number of var found for each es sample"
        echo "Command : sbatch --dependency=afterok:${dependency_update_var#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh"
        sbatch --dependency=afterok:${dependency_update_var#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="es",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh
    fi
fi

if (( ${#PED_gs[@]} > 0 ))
then
    if [[ -n "$dependency_update_var" ]] && [[ -n "$dependency_update_vcf" ]]
    then
        echo "Drawing graph of evolution of number of var found for each gs sample"
        echo "Command : sbatch --dependency=afterok:${dependency_update_var#:}:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh"
        sbatch --dependency=afterok:${dependency_update_var#:}:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh 
    elif [[ -n "$dependency_update_vcf" ]]
    then 
        echo "Drawing graph of evolution of number of var found for each gs sample"
        echo "Command : sbatch --dependency=afterok:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh"
        sbatch --dependency=afterok:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh 
    elif [[ -n "$dependency_update_var" ]]
    then
        echo "Drawing graph of evolution of number of var found for each gs sample"
        echo "Command : sbatch --dependency=afterok:${dependency_update_var#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh"
        sbatch --dependency=afterok:${dependency_update_var#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="gs",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh
    fi
fi

if (( ${#PED_nbs[@]} > 0 ))
then
    if [[ -n "$dependency_update_var" ]] && [[ -n "$dependency_update_vcf" ]]
    then
        echo "Drawing graph of evolution of number of var found for each nbs sample"
        echo "Command : sbatch --dependency=afterok:${dependency_update_var#:}:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh"
        sbatch --dependency=afterok:${dependency_update_var#:}:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh 
    elif [[ -n "$dependency_update_vcf" ]]
    then 
        echo "Drawing graph of evolution of number of var found for each nbs sample"
        echo "Command : sbatch --dependency=afterok:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh"
        sbatch --dependency=afterok:${dependency_update_vcf#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh 
    elif [[ -n "$dependency_update_var" ]]
    then
        echo "Drawing graph of evolution of number of var found for each nbs sample"
        echo "Command : sbatch --dependency=afterok:${dependency_update_var#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh"
        sbatch --dependency=afterok:${dependency_update_var#:} --export=DATABASE=${DATABASE},SAMPLE_TYPE="nbs",GRAPH_TYPE="nb_var",DIJEXN="all",PIPELINE_QUALIF=${PIPELINE_QUALIF},CONFIGFILE=${CONFIGFILE} ${PIPELINE_QUALIF}/common/qualification/wrapper_create_graph_from_tinydb.sh
    fi
fi


fi
