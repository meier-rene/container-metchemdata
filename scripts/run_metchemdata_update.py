from functions import *
from pubchem import *

dbname=os.getenv('POSTGRES_DB', 'metchem')
user=os.getenv('POSTGRES_USER', 'postgres')
host=os.getenv('POSTGRES_IP', '127.0.0.1')
password=os.getenv('POSTGRES_PASSWORD', 'DATABASE_PASSWORD')

def main():
    wait_for_database()

    if not check_database_exists():
        print(f"database {dbname} not found")
        exit(1)

    exec_commands = os.getenv('EXEC', '').split(',')

    if 'INIT' in exec_commands:
        init_database()
        print("database initialised")

    if 'PUBCHEM' in exec_commands:
        insert_pubchem()
        print("pubchem inserted")

    # if 'HMDB' in exec_commands:
    #     log_folder = check_log_folder('hmdb')
    #     with open(os.path.join(log_folder, 'output.log'), 'a') as out, open(os.path.join(log_folder, 'output.err'), 'a') as err:
    #         subprocess.run(insert_hmdb, stdout=out, stderr=err)
    #     print("hmdb inserted")
    #
    # if 'KEGG_DERIVATISED' in exec_commands:
    #     log_folder = check_log_folder('kegg_derivatised')
    #     with open(os.path.join(log_folder, 'output.log'), 'a') as out, open(os.path.join(log_folder, 'output.err'), 'a') as err:
    #         subprocess.run(insert_kegg_derivatised, stdout=out, stderr=err)
    #     print("kegg_derivatised inserted")
    #
    # if 'KEGG' in exec_commands:
    #     log_folder = check_log_folder('kegg')
    #     with open(os.path.join(log_folder, 'output.log'), 'a') as out, open(os.path.join(log_folder, 'output.err'), 'a') as err:
    #         subprocess.run(insert_kegg, stdout=out, stderr=err)
    #     print("kegg inserted")
    #
    # if 'LIPIDMAPS' in exec_commands:
    #     log_folder = check_log_folder('lipidmaps')
    #     with open(os.path.join(log_folder, 'output.log'), 'a') as out, open(os.path.join(log_folder, 'output.err'), 'a') as err:
    #         subprocess.run(insert_lipidmaps, stdout=out, stderr=err)
    #     print("lipidmaps inserted")
    #
    # if 'CHEBI' in exec_commands:
    #     log_folder = check_log_folder('chebi')
    #     with open(os.path.join(log_folder, 'output.log'), 'a') as out, open(os.path.join(log_folder, 'output.err'), 'a') as err:
    #         subprocess.run(insert_chebi, stdout=out, stderr=err)
    #     print("chebi inserted")
    #
    # if 'SWISSLIPIDS' in exec_commands:
    #     log_folder = check_log_folder('swisslipids')
    #     with open(os.path.join(log_folder, 'output.log'), 'a') as out, open(os.path.join(log_folder, 'output.err'), 'a') as err:
    #         subprocess.run(insert_swisslipids, stdout=out, stderr=err)
    #     print("swisslipids inserted")
    #
    # if 'COCONUT' in exec_commands:
    #     log_folder = check_log_folder('coconut')
    #     with open(os.path.join(log_folder, 'output.log'), 'a') as out, open(os.path.join(log_folder, 'output.err'), 'a') as err:
    #         subprocess.run(insert_coconut, stdout=out, stderr=err)
    #     print("COCONUT inserted")
    #
    # if 'INDEX' in exec_commands:
    #     log_folder = check_log_folder('create_index')
    #     with open(os.path.join(log_folder, 'output.log'), 'a') as out, open(os.path.join(log_folder, 'output.err'), 'a') as err:
    #         subprocess.run(create_index, stdout=out, stderr=err)
    #     print("index created")
    #
    # if 'DUPLICATES' in exec_commands:
    #     log_folder = check_log_folder('duplicates')
    #     with open(os.path.join(log_folder, 'output.log'), 'a') as out, open(os.path.join(log_folder, 'output.err'), 'a') as err:
    #         subprocess.run(remove_duplicates, stdout=out, stderr=err)
    #     print("duplicates removed")

if __name__ == "__main__":
    main()
