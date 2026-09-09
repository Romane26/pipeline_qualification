#!/usr/bin/python
## research_result.py
## Version : 1.0
## Description : This script allows user to search for a variation in a chosen file
## Usage : python research_result.py -f <path/to/file/to/search/in> -r <"result_to_look_for_in_file"> -l <"not_mandatory_logfile_name"> -n <"not_mandatory_resultfile_name"> -s <sample type : "es", "gs" or "nbs">
## Output : resultfile that says if the variation was found, and if yes, in which line of the file
## Requirements : None

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260615
## Last revision date : 20260717
## Known bugs : None

import getopt
import sys
import csv
import logging
from datetime import datetime

timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
file = None
result = None
sample_type = None
logfile = None
resultfile = None


# Manage options
try:
    opts, args = getopt.getopt(sys.argv[1:], 'f:r:l:n:s:')  
    for opt, arg in opts:
        if opt in ("-f"):
            file = arg
        elif opt in ("-r"):
            result = arg
        elif opt in ("-l"):
            logfile = arg
        elif opt in ("-n"):
            resultfile = arg
        elif opt in ("-s"):
            sample_type = arg
except getopt.GetoptError:
    print('usage : python research_result.py -f <mandatory_input_file.tsv> -r <mandatory_result_expected_as_character_chain> -s <mandatory_sample_type> -l <logfile> -n <result log name>')
    sys.exit(2) 

if file is None or result is None :
    print('usage1 : python research_result.py -f <mandatory_input_file.tsv> -r <mandatory_result_expected_as_character_chain> -s <mandatory_sample_type> -l <logfile> -n <result log name>')
    sys.exit(2)


if logfile is None :
    logfile = f"research_log_{timestamp}.log"
else :
    logfile=f"{logfile}.log"

if resultfile is None :
    if sample_type is None :
        print('usage : python research_result.py -f <mandatory_input_file.tsv> -r <mandatory_result_expected_as_character_chain> -s <mandatory_sample_type> -l <logfile> -n <result log name>')
        sys.exit(2)
    resultfile=f"research_result_{sample_type}_{timestamp}.log"
else :
    resultfile=f"{resultfile}.log"

# Logging    
logging.basicConfig(filename = '%s' % (logfile), filemode = 'w', level = logging.INFO, format = '%(asctime)s %(levelname)s - %(message)s')
logging.info('start')

resultlog = logging.getLogger("resultlog")
resultlog.setLevel(logging.INFO)
resultlog.propagate=False
handler=logging.FileHandler(resultfile)
resultlog.addHandler(handler)
resultlog.info(f"Result {result} sought in file {file}")

found = False

with open(file, newline="") as f:
    reader = csv.reader(f, delimiter="\t")
    if "SMN" not in file :
        for row in reader:
            if any(result in cell for cell in row):
                found = True
                logging.info('Result found in following line : %s', row)
                resultlog.info(f'Result {result} found in following line :')
                resultlog.info(row)
    else :
        lines=list(reader)
        if lines[1][1] == "True" :
            found = True
            logging.info('Result found in following line : %s', lines[1])
            resultlog.info(f'Result {result} found in following line :')
            resultlog.info(lines[1])

if found == False :
    logging.info('Result not found')
    resultlog.info(f'Result {result} not found in file {file}')

print(found)

logging.info('end')