#!/usr/bin/python
## create_tinydb.py
## Version : 1.0
## Description : This script allows user to create a tinyDB database to store qualification results
## Usage : python3 create_tinydb.py -n database_name
## Output : tinyDB database named db_qualif.json to store qualification results
## Requirements : python environment with tinyDB

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260623
## Last revision date : 20260805
## Known bugs : None

from tinydb import TinyDB
import getopt
import sys

database_name="db_qualif"

try:
    opts, args = getopt.getopt(sys.argv[1:], 'n:')  
    for opt, arg in opts:
        if opt in ("-n"):
            database_name = arg
except getopt.GetoptError:
    print('usage : python3 create_tinydb.py -n <database name>')
    sys.exit(2) 


db_qualif = TinyDB(f"{database_name}.json")

variations_es = db_qualif.table("variations_es")
vcfeval_es = db_qualif.table("vcfeval_es")
variations_gs = db_qualif.table("variations_gs")
vcfeval_gs = db_qualif.table("vcfeval_gs")
variations_nbs = db_qualif.table("variations_nbs")
vcfeval_nbs = db_qualif.table("vcfeval_nbs")