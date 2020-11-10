- provide gzipped file here named like lipidmaps.csv.gz

- header of the provided csv files:
```
identifier|inchi|monoisotopicmass|molecularformula|inchikey1|inchikey2|inchikey3|smiles|name
```
- columns need to be pipe separated

- As of 2020, LipidMaps has a REST interface:

```
wget -O lipidmaps.csv https://www.lipidmaps.org/rest/compound/lm_id/LM/all/download
gzip lipidmaps.csv
```
