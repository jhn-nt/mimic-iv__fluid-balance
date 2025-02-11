from google.cloud import bigquery
import google.auth
from pathlib import Path
from argparse import ArgumentParser

DATASET_ID="mimiciv_derived"
RATES_TABLE_ID="fluid_rates"
AMOUNTS_TABLE_ID="fluid_amounts"


if __name__=="__main__":
    parser=ArgumentParser()
    parser.add_argument("-p","--project-id",action="store",required=True)

    args=parser.parse_args()
    PROJECT_ID=args.project_id

    print("1. Connecting to the Client")
    client=bigquery.Client(project=PROJECT_ID)
    fluid_rates_query=open(Path(__file__).parent / "fluid_rates.sql","r").read()
    fluid_amounts_query=open(Path(__file__).parent / "fluid_amounts.sql","r").read()
    
    print("2. Creating the Dataset")
    dataset=bigquery.Dataset(f"{PROJECT_ID}.{DATASET_ID}")
    dataset=client.create_dataset(dataset)

    print("3. Creating the Tables")
    rates_table_ref=client.dataset(DATASET_ID).table(RATES_TABLE_ID)
    amounts_table_ref=client.dataset(DATASET_ID).table(AMOUNTS_TABLE_ID)

    rates_job_config=bigquery.QueryJobConfig()
    amounts_job_config=bigquery.QueryJobConfig()

    rates_job_config.destination=rates_table_ref
    amounts_job_config.destination=amounts_table_ref

    print("4. Loading...")
    query_job=client.query(fluid_rates_query,job_config=rates_job_config)
    query_job.result()

    query_job=client.query(fluid_amounts_query,job_config=amounts_job_config)
    query_job.result()

    print("5. Complete")
    
