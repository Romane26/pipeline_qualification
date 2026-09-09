#!/usr/bin/python
## create_graph_from_tinydb.py
## Version : 1.0
## Description : This script allows user to draw graphs from searched variations and vcfeval analysis from a tinyDB database
## Usage : python3 create_graph_from_tinydb.py -d <path/to/tinyDB/database> -s <"es","gs","nbs","all"> -t <"var_ref","nb_var","f-measure"> -l <not_mandatory_logfile_name> -j <dijex.n.nbs, mandatory for f-measure (in the not all samples case) ans nb_var graphs> -a <"variations" or "vcfeval", mandatory argument for nb_var graph type if dijexn != "all">
## Output : graph saved under html format
## Requirements : python environment with tinyDB and plotly, data file made with get_data_variations.sh or get_data_vcfeval.sh depending on the case

## Author : romane.vauchez@u-bourgogne.fr
## Creation Date : 20260629
## Last revision date : 20260720
## Known bugs : None

from tinydb import TinyDB, Query
import getopt
import sys
import plotly.graph_objects as go
import datetime
from collections import defaultdict
import logging


database = None
sample_type = None
graph_type = None
logfile = None
dijexn = None
table_type = None

# Manage options
try:
    opts, args = getopt.getopt(sys.argv[1:], 'd:s:t:l:j:a:')  
    for opt, arg in opts:
        if opt in ("-d"):
            database = arg
        if opt in ("-s"):
            sample_type = arg
        if opt in ("-t") :
            graph_type = arg
        if opt in ("-l"):
            logfile = arg
        if opt in ("-j"):
            dijexn = arg
        if opt in ("-a"):
            table_type = arg
except getopt.GetoptError:
    print('usage : python research_result.py -d <mandatory_database> -s <sample_type> -t <mandatory_graph_type> -l <logfile>')
    sys.exit(2) 

if sample_type is None :
    print('Missing sample type (-s option)')
    sys.exit(2)

if graph_type is None :
    print('Missing graph type (-t option)')
    sys.exit(2)

if database is None :
    print('Missing database (-d option)')
    sys.exit(2)

timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
if logfile is None :
    logfile = f"graph_log_{timestamp}.log"

logging.basicConfig(filename = '%s' % (logfile), filemode = 'w', level = logging.INFO, format = '%(asctime)s %(levelname)s - %(message)s')
logging.info('Start')

logging.info(f"Getting {database} database (tinydb)")
db = TinyDB(database)

# region variations

if graph_type == "var_ref" :
    if sample_type == "all" :
        logging.info("Graph type : variations, all sample types")
        tables = {"ES": "variations_es", "GS": "variations_gs", "NBS": "variations_nbs"}
        stats = {}
        all_dates = set()
        for label, table_name in tables.items():
            logging.info(f"Getting {table_name} table")
            table = db.table(table_name)
            found = defaultdict(int)
            not_found = defaultdict(int)
            logging.info(f"Getting data from {table_name} table")
            for item in table.all():
                date = datetime.datetime.strptime(item["date"],"%Y-%m-%d_%H-%M-%S")
                all_dates.add(date)
                if item["found"] == "True":
                    found[date] += 1
                elif item["found"] == "False":
                    not_found[date] += 1
            stats[label] = {"found": found,"not_found": not_found}
        dates = sorted(all_dates)[-10:]
        
        logging.info("Tracing graph : Number of found/not found variations by sample type and by date")

        x_es = [f"{j}\nES" for j in dates]
        x_gs = [f"{j}\nGS" for j in dates]
        x_nbs = [f"{j}\nNBS" for j in dates]

        fig = go.Figure()

        fig.add_bar(x=x_es,
            y=[stats["ES"]["found"][j] for j in dates],name="ES found",marker_color="blue")

        fig.add_bar(x=x_es,y=[stats["ES"]["not_found"][j] for j in dates],name="ES not found",marker_color="lightblue")

        fig.add_bar(x=x_gs,y=[stats["GS"]["found"][j] for j in dates],name="GS found",marker_color="orange")

        fig.add_bar(x=x_gs,y=[stats["GS"]["not_found"][j] for j in dates],name="GS not found",marker_color="moccasin")

        fig.add_bar(x=x_nbs,y=[stats["NBS"]["found"][j] for j in dates],name="NBS found",marker_color="green")

        fig.add_bar(x=x_nbs,y=[stats["NBS"]["not_found"][j] for j in dates],name="NBS not found",marker_color="lightgreen")

        categories = []
        for j in dates:
            categories.extend([f"{j}\nES",f"{j}\nGS",f"{j}\nNBS",])

        fig.update_layout(barmode="stack")

        fig.update_layout(title="Variations found/not found by date",xaxis_title="Date and sample type",yaxis_title="Number of variations",)
        
        fig.update_xaxes(type="category",categoryorder="array",categoryarray=categories,)

        timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        logging.info(f"Saving graph as variations_{sample_type}_{timestamp}.html")
        fig.write_html(f"var_ref_{sample_type}_{timestamp}.html")

    else :
        if sample_type == "es" :
            logging.info("Graph type : variations, es sample type")
            logging.info(f"Getting variations_es table")
            table = db.table("variations_es")
        if sample_type == "gs" :
            logging.info("Graph type : variations, gs sample type")
            logging.info(f"Getting variations_gs table")
            table = db.table("variations_gs")
        if sample_type == "nbs" :
            logging.info("Graph type : variations, nbs sample type")
            logging.info(f"Getting variations_nbs table")
            table = db.table("variations_nbs")

        logging.info("Getting data from table")
        donnees = table.all()

        found_count = defaultdict(int)
        not_found_count = defaultdict(int)
        dates_set = set()

        for item in donnees:
            date = datetime.datetime.strptime(item["date"], "%Y-%m-%d_%H-%M-%S")

            dates_set.add(date)

            if item["found"] == "True":
                found_count[date] += 1
            elif item["found"] == "False":
                not_found_count[date] += 1
    
        dates = sorted(dates_set)[-10:]
        found_values = [found_count[d] for d in dates]
        not_found_values = [not_found_count[d] for d in dates]

        logging.info("Tracing graph : Number of found/not found variations by date")
        fig = go.Figure()

        fig.add_trace(go.Bar(x=dates, y=found_values, name="Found",marker_color="green"))

        fig.add_trace(go.Bar(x=dates, y=not_found_values, name="Not found",marker_color="red"))

        fig.update_layout(barmode="stack", title=f"Variations found/not found by date in {sample_type}", xaxis_title="Date", yaxis_title="Nb of variations")

        timestamp = datetime.datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        logging.info(f"Saving graph as variations_{sample_type}_{timestamp}.html")
        fig.write_html(f"var_ref_{sample_type}_{timestamp}.html")


# endregion
    
# region nb_var

if graph_type == "nb_var" :
    if dijexn == None :
        logging.info("Missing dijexn")
        sys.exit(2)

    if dijexn != "all" :
        logging.info(f"Graph type : nb_var for {dijexn}")
        if table_type == None :
            logging.info("Missing table_type")
            sys.exit(2)
    
        logging.info(f"Getting {table_type}_{sample_type} table")
        table = db.table(f"{table_type}_{sample_type}")

        logging.info("Getting data from the table")
        dij = Query()
        if sample_type == "es" :
            data = table.search(dij.dijex == dijexn)
        if sample_type == "gs" :
            data = table.search(dij.dijen == dijexn)
        if sample_type == "nbs" :
            data = table.search(dij.dijnbs == dijexn)
    
        dates = [datetime.datetime.strptime(d["date"], "%Y-%m-%d_%H-%M-%S")for d in data]    
        number_of_variations = [d["nb_var_found"] for d in data]

        sorted_data = sorted(zip(dates, number_of_variations),key=lambda x: x[0])
        sorted_data = sorted_data[-100:]
        dates, number_of_variations = zip(*sorted_data)

        logging.info(f"Tracing graph : Number of variations found as a fucntion of date for {dijexn}")
        fig = go.Figure()

        fig.add_trace(go.Scatter(x=dates,y=number_of_variations,mode="lines+markers",name=dijexn))

        fig.update_layout(title=f"Number of variations found for {dijexn}",xaxis_title="Date",yaxis_title="Number of variations found")
        logging.info(f"Saving graph as nb_var_found_{dijexn}_{timestamp}.html")
        fig.write_html(f"nb_var_found_{dijexn}_{timestamp}.html")

    else :
        logging.info(f"Graph type : nb_var, all {sample_type} samples")

        if sample_type == "es" :
            TABLES = {"variations_es": "dijex","vcfeval_es": "dijex",}
        if sample_type == "gs" :
            TABLES = {"variations_gs": "dijen","vcfeval_gs": "dijen",}
        if sample_type == "nbs" :
            TABLES = {"variations_nbs": "dijnbs","vcfeval_nbs": "dijnbs",}
        
        all_records = []
        
        for table_name, sample_field in TABLES.items():
            logging.info(f"Getting {table_name} table")
            for rec in db.table(table_name).all():
                all_records.append({"sample": rec[sample_field],"date": datetime.datetime.strptime(rec["date"], "%Y-%m-%d_%H-%M-%S"),"nb_var": rec["nb_var_found"],})
        
        last_dates = sorted({r["date"] for r in all_records})[-100:]
        last_dates = set(last_dates)
        
        filtered_records = [r for r in all_records if r["date"] in last_dates]
        
        samples = defaultdict(list)
        
        for rec in filtered_records:
            samples[rec["sample"]].append((rec["date"], rec["nb_var"]))
        
        
        logging.info(f"Tracing graph : Number of variations found as a function of date for all {sample_type} samples")
        fig = go.Figure()
        
        for sample, values in sorted(samples.items()):
            values.sort(key=lambda x: x[0])
            fig.add_trace(go.Scatter(x=[v[0] for v in values],y=[v[1] for v in values],mode="lines+markers",name=sample,))
        
        
        fig.update_layout(title=f"Evolution of number of variations found by date for each {sample_type} sample",xaxis_title="Date",yaxis_title="Number of variations found",template="plotly_white",hovermode="x unified",height=800,)
        
        logging.info(f"Saving graph as evolution_nb_var_{sample_type}_{timestamp}.html")
        fig.write_html(f"evolution_nb_var_{sample_type}_{timestamp}.html")

# endregion

# region f-measure

if graph_type == "f-measure" :
    if sample_type != "all" :
        if dijexn == None :
            logging.info("Missing dijexn")

        logging.info("Graph type : f-measure")
        logging.info(f"Getting vcfeval_{sample_type} table")
        table = db.table(f"vcfeval_{sample_type}")

        logging.info("Getting data from the table")
        dij = Query()
        if sample_type == "es" :
            data = table.search(dij.dijex == dijexn)
        if sample_type == "gs" :
            data = table.search(dij.dijen == dijexn)
        if sample_type == "nbs" :
            data = table.search(dij.dijnbs == dijexn)

        dates = [datetime.datetime.strptime(d["date"], "%Y-%m-%d_%H-%M-%S")for d in data]    
        f_measures = [d["F-measure"] for d in data]

        sorted_data = sorted(zip(dates, f_measures),key=lambda x: x[0])
        sorted_data = sorted_data[-100:]
        dates, f_measures = zip(*sorted_data)

        logging.info(f"Tracing graph : F-measure as a fucntion of date for {dijexn}")
        fig = go.Figure()

        fig.add_trace(go.Scatter(x=dates,y=f_measures,mode="lines+markers",name=dijexn))

        fig.update_layout(title=f"Evolution of F-measure for {dijexn}",xaxis_title="Date",yaxis_title="F-measure")
        logging.info(f"Saving graph as evolution_f_measure_{dijexn}_{timestamp}.html")
        fig.write_html(f"evolution_f_measure_{dijexn}_{timestamp}.html")

    else :
        logging.info("Graph type : f-measure, all sample types")
        TABLES = {"vcfeval_es": "dijex","vcfeval_gs": "dijen","vcfeval_nbs": "dijnbs",}

        all_records = []

        for table_name, sample_field in TABLES.items():
            logging.info(f"Getting {table_name} table")
            for rec in db.table(table_name).all():
                all_records.append({"sample": rec[sample_field],"date": datetime.datetime.strptime(rec["date"], "%Y-%m-%d_%H-%M-%S"),"f-measure": rec["F-measure"],})

        last_dates = sorted({r["date"] for r in all_records})[-100:]
        last_dates = set(last_dates)

        filtered_records = [r for r in all_records if r["date"] in last_dates]

        samples = defaultdict(list)

        for rec in filtered_records:
            samples[rec["sample"]].append((rec["date"], rec["f-measure"]))


        logging.info(f"Tracing graph : F-measure as a function of date for all samples")
        fig = go.Figure()

        for sample, values in sorted(samples.items()):
            values.sort(key=lambda x: x[0])
            fig.add_trace(go.Scatter(x=[v[0] for v in values],y=[v[1] for v in values],mode="lines+markers",name=sample,))


        fig.update_layout(title="Evolution of F-measure by date for each sample",xaxis_title="Date",yaxis_title="F-measure",template="plotly_white",hovermode="x unified",height=800,)

        logging.info(f"Saving graph as evolution_f_measure_all_{timestamp}.html")
        fig.write_html(f"evolution_f_measure_all_{timestamp}.html")