#!/bin/bash
## report_maker.sh
## Version : 1.0
## Description : This script allows the creation of an html report containing the qualification results for one sample type 
## Usage : sbatch --export=REPORT=<"report name" (not mandatory)>,SAMPLE_TYPE=<"es", "gs" or "nbs">,NB_VAR_FILE=<nb_var file>,FOUND_FILE=<found file (not mandatory if qualif contains only vcfeval files)>,LIST_SUMMARY_FILES=<list of summary files for vcfeval files under this format "path/to/summary1:path/to/summary2:path/to/summary3:etc">,LIST_DIJ_ARG=<list of dij corresponding to vcfeval files under this format "dij1:dij2:dij3:etc"> report_maker.sh  <files containing results of search for reference variations> <files containing results for vcfeval>
## Output : html report indicating if the qualif had passed, a summary of which variations were found and f-measures, and more details about what was found or not
## Requirements : analysed dij files (with analysis pipeline), result files for either reference variaitions, vcfeval, or both, nb_var files made by get_nb_var.sh script, found file made by create_found_file.sh script if there are reference variations files

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260617
## Last revision date : 20260720
## Known bugs : None

# SLURM ENV 
#SBATCH --job-name=make_report
#SBATCH --qos=qos_neomics
#SBATCH --partition nompi
#SBATCH -n 1
#SBATCH --mem=2G
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=romane.vauchez@u-bourgogne.fr

#while getopts “n:” OPTION
#do
#     case $OPTION in
#         n)
#             REPORT=$OPTARG
#             ;;
#     esac
#done


# Logging
logbasename=$(date +"%F_%H-%M-%S")
LOGFILE=report_maker.$logbasename.log
exec 1>> ${LOGFILE} 2>&1
echo "$(date +"%F_%H-%M-%S"): START"

if [ -z ${REPORT} ]
then
    REPORT=report.$logbasename.html
fi

if [ ${#} -eq 0 ]
then
    echo "Usage : $0 [-n rapport.html] fichier1.log [fichier2.log ...]"
    exit 1
fi

if [ -z ${SAMPLE_TYPE} ]
then
    echo "Sample type was not specified : execution stopped"
    exit 1
fi


if [ -z ${NB_VAR_FILE} ]
then
    echo "File with the number of variations was not specified : execution stopped"
    exit 1
fi

echo "Creating report header"
{
echo "<!DOCTYPE html>"
echo "<html>"
echo "<head>"
echo "<meta charset='UTF-8'>"
echo "<title>Report $SAMPLE_TYPE $logbasename</title>"
echo "<style>"
echo "body { font-family: monospace; }"
echo "table { border-collapse: collapse; margin-bottom: 20px; }"
echo "th, td { border: 1px solid black; padding: 4px 10px; }"
echo "th { background-color: #f0f0f0; }"
echo ".true { color: green; font-weight: bold; }"
echo ".false { color: red; font-weight: bold; }"
echo ".average { color: orange; font-weight: bold; }"
echo "</style>"
echo "</head>"
echo "<body>"
echo "<h1>Report $SAMPLE_TYPE $logbasename</h1>"
echo "<hr>"
} > ${REPORT}

nb_found=0
nb_tot=0
mean_f_measure=-1
prop_found=-1

if [[ -n ${LIST_SUMMARY_FILES} ]]
then
    IFS=: read -ra LIST_SUMMARY <<< ${LIST_SUMMARY_FILES}
else
    LIST_SUMMARY=()
fi

if [[ -n $LIST_DIJ_ARG ]]
then
    IFS=: read -ra LIST_DIJ <<< ${LIST_DIJ_ARG}
else
    LIST_DIJ=()
fi


if [ ${SAMPLE_TYPE} == "es" ]
then

    if (( ${#LIST_SUMMARY[@]} > 0 ))
    then
        mean_f_measure=0
        for i in ${!LIST_SUMMARY[@]}
        do
        SUMMARY=${LIST_SUMMARY[$i]}
        f_measure=$(awk 'NR==4 {print $8}' ${SUMMARY})
        mean_f_measure=$(awk "BEGIN {print ${mean_f_measure} + ${f_measure}}")
        done

        mean_f_measure=$(awk -v sum=${mean_f_measure} -v n=${#LIST_SUMMARY[@]} 'BEGIN { print sum / n }')
    fi
    

    if [[ -f ${FOUND_FILE} ]]
    then
        while read dijex found
        do
        if [ ${found} = "True" ]
        then
            ((nb_found+=1))
        fi
        ((nb_tot+=1))
        done < ${FOUND_FILE}

        if (( nb_tot > 0 ))
        then
        prop_found=$(awk -v found=${nb_found} -v total=${nb_tot} 'BEGIN { print found / total }')
        fi

    fi

    if awk -v x=${mean_f_measure} -v y=${prop_found} 'BEGIN { exit !(x >= 0 && y >= 0) }'
    then
        if awk -v x=${mean_f_measure} -v y=${prop_found} 'BEGIN { exit !(x >= 0.97 && y >= 0.9) }'
        then
            class="true"
            text="Qualif passed ✅"
        elif awk -v x=${mean_f_measure} -v y=${prop_found} 'BEGIN { exit !(x >= 0.95 && y >= 0.8) }'
        then
            class="average"
            text="Qualif could be better 🟠"
        else
            class="false"
            text="Qualif failed ❌"
        fi
    elif awk -v x=${mean_f_measure} 'BEGIN { exit !(x >= 0) }'
    then 
        if awk -v x=${mean_f_measure} 'BEGIN { exit !(x >= 0.97) }'
        then
            class="true"
            text="Qualif passed ✅"
        elif awk -v x=${mean_f_measure} 'BEGIN { exit !(x >= 0.95) }'
        then
            class="average"
            text="Qualif could be better 🟠"
        else
            class="false"
            text="Qualif failed ❌"
        fi
    elif awk -v x=${prop_found} 'BEGIN { exit !(x >= 0) }'
    then
        if awk -v x=${prop_found} 'BEGIN { exit !(x >= 0.9) }'
        then
            class="true"
            text="Qualif passed ✅"
        elif awk -v x=${prop_found} 'BEGIN { exit !(x >= 0.8) }'
        then
            class="average"
            text="Qualif could be better 🟠"
        else
            class="false"
            text="Qualif failed ❌"
        fi
    fi

    echo "<h1 class=\"${class}\">${text}</h1>" >> ${REPORT}
    echo "<hr>" >> ${REPORT}

    nb_found=0
    nb_tot=0

    if [[ -f ${FOUND_FILE} ]]
    then
        echo "Creating reference variations summary table"
        while read dijex found
        do
        if [ ${found} = "True" ]
        then
            ((nb_found+=1))
        fi
        ((nb_tot+=1))
        done < ${FOUND_FILE}

        echo "<p><strong>${nb_found} reference variations found out of ${nb_tot}</strong></p>" >> ${REPORT}

        {
        echo "<table>"
        echo "<tr><th>Dijex</th><th>Found</th></tr>"

        while read dijex found
        do
        if [ ${found} = "True" ]
        then
            class="true"
        else
            class="false"
        fi

        echo "<tr><td>${dijex}</td><td class=\"${class}\">${found}</td></tr>"
        done < ${FOUND_FILE}

        echo "</table>"
        echo "<hr>"
        } >> ${REPORT}
    fi

    if (( ${#LIST_SUMMARY[@]} > 0 ))
    then
        echo "Creating vcfeval summary table"
        {
        echo "<table>"
        echo "<tr><th>Dijex</th><th>F-measure</th></tr>"

        for i in ${!LIST_SUMMARY[@]}
        do
        SUMMARY=${LIST_SUMMARY[$i]}
        dijex=${LIST_DIJ[$i]}

        f_measure=$(awk 'NR==4 {print $8}' ${SUMMARY})

        if awk -v f=${f_measure} 'BEGIN {exit !(f > 0.97)}'
        then
            class="true"
        else
            class="false"
        fi

        echo "<tr><td>${dijex}</td><td class=\"$class\">${f_measure}</td></tr>"
        done

        echo "</table>"
        echo "<hr>"
        } >> ${REPORT}
    fi

    echo "Copying files content in report"
    for file in ${@}
    do
        dijex=$(grep -oE 'dijex[0-9]{4}' ${file} | head -n1)
        echo "fichier : ${file}"
        echo "dijex avant grep = ${dijex}"
        NB_VAR_FOUND=$(awk -v dijex=${dijex} '$1==dijex {print $2}' ${NB_VAR_FILE})
        echo "<h2>${dijex}</h2>" >> ${REPORT}
        echo "<pre>" >> ${REPORT}
        cat ${file} >> ${REPORT}
        echo "Number of variations found : ${NB_VAR_FOUND}" >> ${REPORT}
        echo "</pre><br>" >> ${REPORT}
    done
fi


if [ ${SAMPLE_TYPE} == "gs" ]
then

    if (( ${#LIST_SUMMARY[@]} > 0 ))
    then
        mean_f_measure=0
        for i in ${!LIST_SUMMARY[@]}
        do
        SUMMARY=${LIST_SUMMARY[$i]}
        f_measure=$(awk 'NR==4 {print $8}' ${SUMMARY})
        mean_f_measure=$(awk "BEGIN {print ${mean_f_measure} + ${f_measure}}")
        done

        mean_f_measure=$(awk -v sum=${mean_f_measure} -v n=${#LIST_SUMMARY[@]} 'BEGIN { print sum / n }')
    fi
    

    if [[ -f ${FOUND_FILE} ]]
    then
        while read dijen found
        do
        if [ ${found} = "True" ]
        then
            ((nb_found+=1))
        fi
        ((nb_tot+=1))
        done < ${FOUND_FILE}

        if (( nb_tot > 0 ))
        then
        prop_found=$(awk -v found=${nb_found} -v total=${nb_tot} 'BEGIN { print found / total }')
        fi

    fi

    if awk -v x=${mean_f_measure} -v y=${prop_found} 'BEGIN { exit !(x >= 0 && y >= 0) }'
    then
        if awk -v x=${mean_f_measure} -v y=${prop_found} 'BEGIN { exit !(x >= 0.97 && y >= 0.9) }'
        then
            class="true"
            text="Qualif passed ✅"
        elif awk -v x=${mean_f_measure} -v y=${prop_found} 'BEGIN { exit !(x >= 0.95 && y >= 0.8) }'
        then
            class="average"
            text="Qualif could be better 🟠"
        else
            class="false"
            text="Qualif failed ❌"
        fi
    elif awk -v x=${mean_f_measure} 'BEGIN { exit !(x >= 0) }'
    then 
        if awk -v x=${mean_f_measure} 'BEGIN { exit !(x >= 0.97) }'
        then
            class="true"
            text="Qualif passed ✅"
        elif awk -v x=${mean_f_measure} 'BEGIN { exit !(x >= 0.95) }'
        then
            class="average"
            text="Qualif could be better 🟠"
        else
            class="false"
            text="Qualif failed ❌"
        fi
    elif awk -v x=${prop_found} 'BEGIN { exit !(x >= 0) }'
    then
        if awk -v x=${prop_found} 'BEGIN { exit !(x >= 0.9) }'
        then
            class="true"
            text="Qualif passed ✅"
        elif awk -v x=${prop_found} 'BEGIN { exit !(x >= 0.8) }'
        then
            class="average"
            text="Qualif could be better 🟠"
        else
            class="false"
            text="Qualif failed ❌"
        fi
    fi

    echo "<h1 class=\"${class}\">$text</h1>" >> ${REPORT}
    echo "<hr>" >> ${REPORT}

    nb_found=0
    nb_tot=0

    if [[ -f ${FOUND_FILE} ]]
    then
        while read dijen found
        do
        if [ ${found} = "True" ]
        then
            ((nb_found+=1))
        fi
        ((nb_tot+=1))
        done < ${FOUND_FILE}

        echo "<p><strong>${nb_found} reference variations found out of ${nb_tot}</strong></p>" >> ${REPORT}

        {
        echo "<table>"
        echo "<tr><th>Dijen</th><th>Found</th></tr>"

        while read dijen found
        do
        if [ ${found} = "True" ]
        then
            class="true"
        else
            class="false"
        fi

        echo "<tr><td>${dijen}</td><td class=\"${class}\">${found}</td></tr>"
        done < ${FOUND_FILE}

        echo "</table>"
        echo "<hr>"
        } >> ${REPORT}
    fi

    if (( ${#LIST_SUMMARY[@]} > 0 ))
    then
        echo "Creating vcfeval summary table"
        {
        echo "<table>"
        echo "<tr><th>Dijen</th><th>F-measure</th></tr>"

        for i in ${!LIST_SUMMARY[@]}
        do
        SUMMARY=${LIST_SUMMARY[$i]}
        dijex=${LIST_DIJ[$i]}

        f_measure=$(awk 'NR==4 {print $8}' ${SUMMARY})

        if awk -v f=${f_measure} 'BEGIN {exit !(f > 0.97)}'
        then
            class="true"
        else
            class="false"
        fi

        echo "<tr><td>${dijex}</td><td class=\"${class}\">${f_measure}</td></tr>"
        done

        echo "</table>"
        echo "<hr>"
        } >> ${REPORT}
    fi
    
    echo "Copying files content in report"
    for file in ${@}
    do
        dijen=$(grep -oE 'dijen[0-9]{3,4}' ${file} | head -n1)
        NB_VAR_FOUND=$(awk -v dijen=${dijen} '$1==dijen {print $2}' ${NB_VAR_FILE})
        echo "<h2>${dijen}</h2>" >> ${REPORT}
        echo "<pre>" >> ${REPORT}
        cat ${file} >> ${REPORT}
        echo "Number of variations found : ${NB_VAR_FOUND}" >> ${REPORT}
        echo "</pre><br>" >> ${REPORT}
    done
fi


if [ ${SAMPLE_TYPE} == "nbs" ]
then

    if (( ${#LIST_SUMMARY[@]} > 0 ))
    then
        mean_f_measure=0
        for i in ${!LIST_SUMMARY[@]}
        do
        SUMMARY=${LIST_SUMMARY[$i]}
        f_measure=$(awk 'NR==4 {print $8}' $SUMMARY)
        mean_f_measure=$(awk "BEGIN {print ${mean_f_measure} + ${f_measure}}")
        done

        mean_f_measure=$(awk -v sum=${mean_f_measure} -v n=${#LIST_SUMMARY[@]} 'BEGIN { print sum / n }')
    fi
    

    if [[ -f ${FOUND_FILE} ]]
    then
        while read dijnbs found
        do
        if [ ${found} = "True" ]
        then
            ((nb_found+=1))
        fi
        ((nb_tot+=1))
        done < ${FOUND_FILE}

        if (( nb_tot > 0 ))
        then
        prop_found=$(awk -v found=${nb_found} -v total=${nb_tot} 'BEGIN { print found / total }')
        fi

    fi

    echo "mean f-measure : ${mean_f_measure}"
    echo "proportion of variations found : ${prop_found}"

    if awk -v x=${mean_f_measure} -v y=${prop_found} 'BEGIN { exit !(x >= 0 && y >= 0) }'
    then
        if awk -v x=${mean_f_measure} -v y=${prop_found} 'BEGIN { exit !(x >= 0.97 && y >= 0.9) }'
        then
            class="true"
            text="Qualif passed ✅"
        elif awk -v x=${mean_f_measure} -v y=${prop_found} 'BEGIN { exit !(x >= 0.95 && y >= 0.8) }'
        then
            class="average"
            text="Qualif could be better 🟠"
        else
            class="false"
            text="Qualif failed ❌"
        fi
    elif awk -v x=${mean_f_measure} 'BEGIN { exit !(x >= 0) }'
    then 
        if awk -v x=${mean_f_measure} 'BEGIN { exit !(x >= 0.97) }'
        then
            class="true"
            text="Qualif passed ✅"
        elif awk -v x=${mean_f_measure} 'BEGIN { exit !(x >= 0.95) }'
        then
            class="average"
            text="Qualif could be better 🟠"
        else
            class="false"
            text="Qualif failed ❌"
        fi
    elif awk -v x=${prop_found} 'BEGIN { exit !(x >= 0) }'
    then
        if awk -v x=${prop_found} 'BEGIN { exit !(x >= 0.9) }'
        then
            class="true"
            text="Qualif passed ✅"
        elif awk -v x=${prop_found} 'BEGIN { exit !(x >= 0.8) }'
        then
            class="average"
            text="Qualif could be better 🟠"
        else
            class="false"
            text="Qualif failed ❌"
        fi
    fi

    echo "<h1 class=\"${class}\">${text}</h1>" >> ${REPORT}
    echo "<hr>" >> ${REPORT}

    nb_found=0
    nb_tot=0

    if [[ -f ${FOUND_FILE} ]]
    then
        while read dijnbs found
        do
        if [ ${found} = "True" ]
        then
            ((nb_found+=1))
        fi
        ((nb_tot+=1))
        done < ${FOUND_FILE}

        echo "<p><strong>${nb_found} reference variations found out of ${nb_tot}</strong></p>" >> ${REPORT}

        {
        echo "<table>"
        echo "<tr><th>Dijen,dijnbs</th><th>Found</th></tr>"

        while read dijnbs found
        do
        if [ ${found} = "True" ]
        then
            class="true"
        else
            class="false"
        fi

        echo "<tr><td>${dijnbs}</td><td class=\"${class}\">${found}</td></tr>"
        done < ${FOUND_FILE}

        echo "</table>"
        echo "<hr>"
        } >> ${REPORT}
    fi

    if (( ${#LIST_SUMMARY[@]} > 0 ))
    then
        echo "Creating vcfeval summary table"
        {
        echo "<table>"
        echo "<tr><th>Dijen,dijnbs</th><th>F-measure</th></tr>"

        for i in ${!LIST_SUMMARY[@]}
        do
        SUMMARY=${LIST_SUMMARY[$i]}
        dijex=${LIST_DIJ[$i]}

        f_measure=$(awk 'NR==4 {print $8}' ${SUMMARY})

        if awk -v f=${f_measure} 'BEGIN {exit !(f > 0.97)}'
        then
            class="true"
        else
            class="false"
        fi

        echo "<tr><td>${dijex}</td><td class=\"${class}\">${f_measure}</td></tr>"
        done

        echo "</table>"
        echo "<hr>"
        } >> ${REPORT}
    fi

    echo "Copying files content in report"
    for file in ${@}
    do
        dijnbs=$(grep -oEm1 'dijnbs[0-9]{3,4}|dijen[0-9]{3,4}' ${file} | head -n1)
        NB_VAR_FOUND=$(awk -v dijnbs=${dijnbs} '$1==dijnbs {print $2}' ${NB_VAR_FILE})
        echo "<h2>${dijnbs}</h2>" >> ${REPORT}
        echo "<pre>" >> ${REPORT}
        cat ${file} >> ${REPORT}
        echo "Number of variations found : ${NB_VAR_FOUND}" >> ${REPORT}
        echo "</pre><br>" >> ${REPORT}
    done
fi

echo "$(date +"%F_%H-%M-%S"): END"