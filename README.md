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
- setting LOG_FOLDER is optional and defines the location of the log files that will be generated
- if LOG_FOLDER is not set, logs will go to stdout

#### Run

- start the MetChem container first
- run (with log location defined)
```bash
MIRROR_ROOT='define root folder of mirrors'
docker run --name metchemdata -v $MIRROR_ROOT:/data/:ro -v $LOG_FOLDER:$LOG_FOLDER --env-file env-file.txt -d container-metchemdata
```

- run (without log location defined)
```bash
MIRROR_ROOT='define root folder of mirrors'
docker run --name metchemdata -v $MIRROR_ROOT:/data/:ro --env-file env-file.txt -d container-metchemdata
```

#### Example Workflow
##### PubChem
- start container-metchem instance (https://github.com/c-ruttkies/container-metchem)
- set environment variables
```bash
touch env-file.txt
echo "POSTGRES_USER=postgres" >> env-file.txt
echo "POSTGRES_PASSWORD=mypassword" >> env-file.txt # define valid postgres password here
echo "PGDATA=/vol/postgres" >> env-file.txt 
echo "POSTGRES_DB=metchem" >> env-file.txt 
echo "POSTGRES_IP=172.17.0.3" >> env-file.txt # define valid IP address of container-metchem
echo "POSTGRES_PORT=5432" >> env-file.txt 
echo "EXEC=INIT" >> env-file.txt # first init database schema
echo "PUBCHEM_MIRROR=pubchem_mirror" >> env-file.txt # pubchem folder within $MIRROT_ROOT
echo "MIRROR_ROOT=/vol/data" >> env-file.txt # define the location of the data on the physical host
```

- run metchemdata container (initialises database schema)
```bash
MIRROR_ROOT=/vol/data # define the location of the data on the physical host
docker run --name metchemdata -v $MIRROR_ROOT:/data/:ro --env-file env-file.txt -d container-metchemdata
docker rm metchemdata
```

- define next exec step (import of PubChem database) and run the container
- this may take several days for the complete PubChem database
```bash
sed -i "s/^EXEC=.*/EXEC=PUBCHEM/" 
MIRROR_ROOT=/vol/data # define the location of the data on the physical host
docker run --name metchemdata -v $MIRROR_ROOT:/data/:ro --env-file env-file.txt -d container-metchemdata
docker rm metchemdata
```

- define next exec step (creating index on tables) and run the container
```bash
sed -i "s/^EXEC=.*/EXEC=INDEX/" 
MIRROR_ROOT=/vol/data # define the location of the data on the physical host
docker run --name metchemdata -v $MIRROR_ROOT:/data/:ro --env-file env-file.txt -d container-metchemdata
docker rm metchemdata
```
