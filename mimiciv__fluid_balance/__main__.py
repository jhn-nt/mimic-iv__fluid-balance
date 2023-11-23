from google.cloud import bigquery
import google.auth
from pathlib import Path
from argparse import ArgumentParser

DATASET_ID="mimiciv_derived"
TABLE_ID="fluid_balance"


if __name__=="__main__":
    parser=ArgumentParser()
    parser.add_argument("-p","--project-id",action="store",required=True)

    args=parser.parse_args()
    PROJECT_ID=args.project_id

    print("1. Connecting to the Client")
    client=bigquery.Client(project=PROJECT_ID)
    fluid_balance_query=open(Path(__file__).parent / "fluid_balance.sql","r").read()
    
    print("2. Creating the Dataset")
    dataset=bigquery.Dataset(f"{PROJECT_ID}.{DATASET_ID}")
    dataset=client.create_dataset(dataset)

    print("3. Creating the Table")
    table_ref=client.dataset(DATASET_ID).table(TABLE_ID)

    job_config=bigquery.QueryJobConfig()
    job_config.destination=table_ref

    print("4. Loading...")
    query_job=client.query(fluid_balance_query,job_config=job_config)
    query_job.result()

    print("5. Complete")
    
