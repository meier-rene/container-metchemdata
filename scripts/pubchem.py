import os
import subprocess
import datetime

dbname=os.getenv('POSTGRES_DB', 'metchem')
user=os.getenv('POSTGRES_USER', 'postgres')
host=os.getenv('POSTGRES_IP', '127.0.0.1')
password=os.getenv('POSTGRES_PASSWORD', 'DATABASE_PASSWORD')
pubchem_mirror = os.getenv('PUBCHEM_MIRROR', 'pubchem_mirror')

def insert_pubchem():

    def run_psql_command(command):
        return subprocess.check_output(
            f'/usr/bin/psql -c "{command}" -h {host} -U {user} -d {dbname}',
            shell=True, text=True
        ).strip()

    run_psql_command("insert into library(library_name,library_id,last_updated,library_link) values ('pubchem','2',date('1970-01-01'),'https://pubchem.ncbi.nlm.nih.gov');")
    print("generate_pubchem_files")
    library_id = run_psql_command("SELECT library_id FROM library where library_name='pubchem';")
    last_updated = run_psql_command("SELECT last_updated FROM library where library_name='pubchem';")
    dbdatesecs = int(datetime.datetime.strptime(last_updated, '%Y-%m-%d').timestamp())
    mostcurrentsecs = dbdatesecs
    mostcurrent = ""
    print(f"library found -> {library_id}")
    print("cleaning folders")
    print("downloading conversion tool")

    proxy = os.getenv('PROXY')
    if proxy:
        subprocess.run(f"wget --no-check-certificate -e use_proxy=yes -e http_proxy={proxy} -q -O ~/ConvertSDF.jar https://msbi.ipb-halle.de/~cruttkie/tools/ConvertSDF.jar", shell=True)
    else:
        subprocess.run("wget --no-check-certificate -q -O ~/ConvertSDF.jar https://msbi.ipb-halle.de/~cruttkie/tools/ConvertSDF.jar", shell=True)

    if not os.path.exists(f"/data/{pubchem_mirror}"):
        print(f"/data/{pubchem_mirror} not found")
        exit(1)

    for i in os.listdir(f"/data/{pubchem_mirror}"):
        if i.endswith(".gz"):
            print(f"file {i}")
            filedatesecs = int(os.path.getmtime(f"/data/{pubchem_mirror}/{i}"))
            filedate = datetime.datetime.fromtimestamp(filedatesecs).strftime('%Y-%m-%d')
            if filedatesecs > mostcurrentsecs:
                mostcurrentsecs = filedatesecs
                mostcurrent = filedate
            filename = i.replace('.sdf.gz', '')
            subprocess.run(f"gunzip -c -k /data/{pubchem_mirror}/{i} > /tmp/{filename}.sdf", shell=True)
            subprocess.run(f"java -jar ~/ConvertSDF.jar sdf=/tmp/{filename}.sdf out=/tmp/ format=csv fast=true skipEntry=PUBCHEM_EXACT_MASS,PUBCHEM_IUPAC_INCHI,PUBCHEM_IUPAC_INCHIKEY,PUBCHEM_MOLECULAR_FORMULA", shell=True)
            with open(f"/tmp/{filename}.csv") as csv_file:
                lines = csv_file.readlines()
                headers = lines[0].strip().split('|')
                data = [line.strip().split('|') for line in lines[1:]]
                cid_idx = headers.index("PUBCHEM_COMPOUND_CID")
                weight_idx = headers.index("PUBCHEM_MONOISOTOPIC_WEIGHT")
                formula_idx = headers.index("PUBCHEM_MOLECULAR_FORMULA")
                smiles_idx = headers.index("PUBCHEM_OPENEYE_CAN_SMILES")
                inchi_idx = headers.index("PUBCHEM_IUPAC_INCHI")
                inchikey_idx = headers.index("PUBCHEM_IUPAC_INCHIKEY")
                with open(f"/tmp/{filename}.sql", 'w') as sql_file:
                    for row in data:
                        sql_file.write(f"{row[cid_idx]}|{row[weight_idx]}|{row[formula_idx]}|{row[smiles_idx]}|{row[inchi_idx]}|{row[inchikey_idx].replace('-', '|')}\n")
            subprocess.run(f"write_entries /tmp/{filename}.sql {library_id} > /dev/null", shell=True)
            os.remove(f"/tmp/{filename}.sql")
            os.remove(f"/tmp/{filename}.sdf")
            os.remove(f"/tmp/{filename}.csv")

    run_psql_command(f"update library set last_updated='{mostcurrent}' where library_id='{library_id}';")

def update_pubchem():
    dbname = os.getenv('POSTGRES_DB', 'metchem')
    user = os.getenv('POSTGRES_USER', 'postgres')
    host = os.getenv('POSTGRES_IP', '127.0.0.1')
    password = os.getenv('POSTGRES_PASSWORD', 'DATABASE_PASSWORD')
    pubchem_mirror = os.getenv('PUBCHEM_MIRROR', 'pubchem_mirror')

    def run_psql_command(command):
        return subprocess.check_output(
            f'/usr/bin/psql -c "{command}" -h {host} -U {user} -d {dbname}',
            shell=True, text=True
        ).strip()

    last_updated = run_psql_command("SELECT last_updated FROM library where library_name='pubchem';")
    dbdatesecs = int(datetime.datetime.strptime(last_updated, '%Y-%m-%d').timestamp())
    mostcurrentsecs = dbdatesecs
    mostcurrent = ""

    if not os.path.exists(f"/data/{pubchem_mirror}"):
        print(f"/data/{pubchem_mirror} not found")
        exit(1)

    print(f"library found -> {library_id}")
    print("cleaning folders")
    print("downloading conversion tool")

    proxy = os.getenv('PROXY')
    if proxy:
        subprocess.run("wget --no-check-certificate -q -O ~/ConvertSDF.jar http://www.rforrocks.de/wp-content/uploads/2012/10/ConvertSDF.jar", shell=True)

    for i in os.listdir(f"/data/{pubchem_mirror}"):
        if i.endswith(".gz"):
            print(f"file {i}")
            filedatesecs = int(os.path.getmtime(f"/data/{pubchem_mirror}/{i}"))
            filedate = datetime.datetime.fromtimestamp(filedatesecs).strftime('%Y-%m-%d')
        subprocess.run(f"wget --no-check-certificate -e use_proxy=yes -e http_proxy={proxy} -q -O ~/ConvertSDF.jar http://www.rforrocks.de/wp-content/uploads/2012/10/ConvertSDF.jar", shell=True)
    else:
            if dbdatesecs >= filedatesecs:
                break
            if filedatesecs > mostcurrentsecs:
                mostcurrentsecs = filedatesecs
                mostcurrent = filedate
            filename = i.replace('.sdf.gz', '')
            subprocess.run(f"gunzip -c -k /data/{pubchem_mirror}/{i} > /tmp/{filename}.sdf", shell=True)
            subprocess.run(f"java -jar ~/ConvertSDF.jar sdf=/tmp/{filename}.sdf out=/tmp/ format=csv fast=true skipEntry=PUBCHEM_EXACT_MASS,PUBCHEM_IUPAC_INCHI,PUBCHEM_IUPAC_INCHIKEY,PUBCHEM_MOLECULAR_FORMULA", shell=True)
            with open(f"/tmp/{filename}.csv") as csv_file:
                lines = csv_file.readlines()
                headers = lines[0].strip().split('|')
                data = [line.strip().split('|') for line in lines[1:]]
                cid_idx = headers.index("PUBCHEM_COMPOUND_CID")
                weight_idx = headers.index("PUBCHEM_MONOISOTOPIC_WEIGHT")
                formula_idx = headers.index("PUBCHEM_MOLECULAR_FORMULA")
                smiles_idx = headers.index("PUBCHEM_OPENEYE_CAN_SMILES")
                inchi_idx = headers.index("PUBCHEM_IUPAC_INCHI")
                inchikey_idx = headers.index("PUBCHEM_IUPAC_INCHIKEY")
                with open(f"/tmp/{filename}.sql", 'w') as sql_file:
                    for row in data:
                        sql_file.write(f"{row[cid_idx]}|{row[weight_idx]}|{row[formula_idx]}|{row[smiles_idx]}|{row[inchi_idx]}|{row[inchikey_idx].replace('-', '|')}\n")
            subprocess.run(f"write_entries /tmp/{filename}.sql {library_id} > /dev/null", shell=True)
            os.remove(f"/tmp/{filename}.sql")
            os.remove(f"/tmp/{filename}.sdf")
            os.remove(f"/tmp/{filename}.csv")

    run_psql_command(f"update library set last_updated='{mostcurrent}' where library_id='{library_id}';")