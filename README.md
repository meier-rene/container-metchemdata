# container-metchemdata
Docker container to generate your own local MetChem database. 

#### Configure

- you need to have docker-compose version installed (version 1.9.0 worked for me)
- rename sample docker-compose file
```bash
cp docker-compose-sample.yml docker-compose.yml
```

- set needed variables within docker-compose.yml file
```bash
metchem:
 environment:
  POSTGRES_USER='database username in the metchem container'
  POSTGRES_PASSWORD='database user password in the metchem container'
  PGDATA='path of database repository within the metchem container'
  POSTGRES_DB='name of database to add data to'

metchemdata:
 environment:
  POSTGRES_USER='database username in the metchem container'
  POSTGRES_PASSWORD='database user password in the metchem container'
  POSTGRES_DB='name of database to add data to'
  POSTGRES_IP='IP address/host name of metchem container'
  METCHEMRO_PASSWORD='define passwor for read-only user metchemro used to query data after data import'
  EXEC='on or several of INIT,INDEX,PUBCHEM,KEGG,CHEBI,LIPIDMAPS,INDEX,REMOVE_DUPLICATES'
  MIRROR_ROOT='define root folder of local file mirrors'
  KEGG_MIRROR=kegg_mirror # folder name of kegg located within the root folder
  PUBCHEM_MIRROR=pubchem_mirror # folder name of pubchem located within the root folder
  CHEBI_MIRROR=chebi_mirror # folder name of chebi located within the root folder
  LIPIDMAPS_MIRROR=lipidmaps_mirror # folder name of lipidmaps located within the root folder
 volumes:
   - 'define root folder of local file mirrors':/data/:ro

```

- EXEC defines which operation is performed in the container
```bash
INIT - creates schema in the database
INDEX - creates index on database tables
PUBCHEM - performes PubChem insert
LIPIDMAPS - performes LipidMaps insert
KEGG - performes KEGG insert
CHEBI - performes ChEBI insert
```

- provide the data within the mirror folders

#### Run

- start the containers by running docker-compose
```bash
docker-compose build
docker-compose up
```
