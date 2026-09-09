#!/usr/bin/python
## update_tinyDB.py
## Version : 1.0
## Description : This script allows user to update a tinyDB database containg searched variations and vcfeval data
## Usage : python3 update_tinyDB.py <-v or -e> -f <path/to/file/with/data> -t <"es", "gs" or "nbs"> -b <path/to/tinyDB/database/to/update>
## Output : updated database
## Requirements : python envrionment with tinyDB, data file made with get_data_variations.sh or get_data_vcfeval.sh depending on the case

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260624
## Last revision date : 20260720
## Known bugs : None

import getopt
import sys
from tinydb import TinyDB
from filelock import FileLock

var = False
vcfeval = False
sample_type = None
database = None
vcfeval_data = None
var_data = None

# Manage options
try:
    opts, args = getopt.getopt(sys.argv[1:], 'ved:t:f:b:')  
    for opt, arg in opts:
        if opt == "-v" :
            var = True
        elif opt == "-e":
            vcfeval = True
        elif opt == "-d":
            vcfeval_data = arg
        elif opt == "-f":
            var_data = arg
        elif opt == "-t":
            sample_type = arg
        elif opt == "-b":
            database = arg
except getopt.GetoptError:
    print('usage : python update_tinyDB.py -v -e -d <data_vcfeval.txt> -f <data_variations.txt> -t <sample type (es, gs, nbs)>')
    sys.exit(2) 

if sample_type is None :
    print('Missing sample type (-t option)')
    sys.exit(2)

if database is None :
    print('Missing database (-b option)')
    sys.exit(2)

lock = FileLock(database + ".lock")

with lock :
    with TinyDB(database) as db :

        if vcfeval == True :
            table=db.table(f"vcfeval_{sample_type}")
            if vcfeval_data is None :
                print('Missing file with vcfeval data (-d option)')
                sys.exit(2)

            with open(vcfeval_data,"r",encoding="utf-8") as f :
                lines = f.readlines()

            if sample_type == "es" :
                table.insert({"dijex": lines[0].strip(), "date": lines[1].strip(), "vcf_truth": lines[2].strip(), "sdf_reference": lines[3].strip(), "options": lines[4].strip(), "Threshold": lines[5].strip(), "True-pos-baseline": int(lines[6].strip()), "True-pos-call": int(lines[7].strip()), "False-pos": int(lines[8].strip()), "False-neg": int(lines[9].strip()), "Precision": float(lines[10].strip()), "Sensitivity": float(lines[11].strip()), "F-measure": float(lines[12].strip()), "nb_var_found": int(lines[13].strip()), "html_report": lines[14].strip()})
            elif sample_type == "gs" or sample_type == "nbs" :
                table.insert({"dijen": lines[0].strip(), "date": lines[1].strip(), "vcf_truth": lines[2].strip(), "sdf_reference": lines[3].strip(), "options": lines[4].strip(), "Threshold": lines[5].strip(), "True-pos-baseline": int(lines[6].strip()), "True-pos-call": int(lines[7].strip()), "False-pos": int(lines[8].strip()), "False-neg": int(lines[9].strip()), "Precision": float(lines[10].strip()), "Sensitivity": float(lines[11].strip()), "F-measure": float(lines[12].strip()), "nb_var_found": int(lines[13].strip()), "html_report": lines[14].strip()})


        if var == True :
            table=db.table(f"variations_{sample_type}")
            if var_data is None :
                print('Missing file with variation data (-f option)')
                sys.exit(2)

            with open(var_data,"r",encoding="utf-8") as f :
                lines = f.readlines()

            if sample_type == "es" :
                table.insert({"dijex": lines[0].strip(), "date": lines[1].strip(), "search_file": lines[2].strip(), "searched_variation": lines[3].strip(), "found": lines[4].strip(), "nb_var_found": int(lines[5].strip()), "html_report": lines[6].strip()})
            elif sample_type == "gs" :
                table.insert({"dijen": lines[0].strip(), "date": lines[1].strip(), "search_file": lines[2].strip(), "searched_variation": lines[3].strip(), "found": lines[4].strip(), "nb_var_found": int(lines[5].strip()), "html_report": lines[6].strip()})
            elif sample_type == "nbs" :
                table.insert({"dijnbs": lines[0].strip(), "date": lines[1].strip(), "search_file": lines[2].strip(), "searched_variation": lines[3].strip(), "found": lines[4].strip(), "nb_var_found": int(lines[5].strip()), "html_report": lines[6].strip()})