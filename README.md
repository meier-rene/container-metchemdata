# container-metchemdata
Docker container to keep your MetChem database container up to date. Retrieve the MetCem database container first from https://github.com/c-ruttkies/container-metchem


#### Install

- build docker image
```bash
docker build -t container-metchemdata .
```

#### Configure

- rename sample environment file
```bash
cp env-file_sample.txt env-file.txt
```

- set needed variables within environment file
```bash
POSTGRES_USER='database username in the metchem container'
POSTGRES_PASSWORD='database user password in the metchem container'
PGDATA='path of database repository within the metchem container'
POSTGRES_DB='name of database to add data to'
POSTGRES_IP='IP address of metchem container'
POSTGRES_PORT=5432
EXEC='on or several of INIT,INDEX,PUBCHEM,KEGG,CHEBI'
KEGG_MIRROR=kegg_mirror
PUBCHEM_MIRROR=pubchem_mirror
CHEBI_MIRROR=chebi_mirror
LOG_FOLDER='log folder within container'
MIRROR_ROOT='define root folder of mirrors'
```
- EXEC defines which operation is performed in the container
```bash
INIT - creates schema in the database
INDEX - creates index on database tables
PUBCHEM - performes PubChem update/insert
KEGG - performes PubChem update/insert
CHEBI - performes PubChem update/insert
```

#### Run

- start the MetChem container first
- run 
```bash
docker run --name metchemdata -v $MIRROR_ROOT:/data/:ro -v $LOG_FOLDER:$LOG_FOLDER --env-file env-file.txt -d container-metchemdata
```
