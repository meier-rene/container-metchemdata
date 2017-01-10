- provide gzipped files here named like chebi_'startid'_'endid'.csv.gz
- 'startid' and 'endid' provide information about the candidate ID range within the file
- e.g. chebi_1_20000.csv.gz
- once added to the metchem container keep the filenames as they are
- just update the content and add files with higher ID ranges

- header of the provided csv files:
```
identifier|inchi|monoisotopicmass|molecularformula|inchikey1|inchikey2|inchikey3|smiles|name
```
- columns need to be pipe separated
