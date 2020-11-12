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


ChEBI can be downloaded via 
```
wget -O ChEBI_complete.sdf.gz ftp://ftp.ebi.ac.uk/pub/databases/chebi/SDF/ChEBI_complete.sdf.gz 
gunzip ChEBI_complete.sdf.gz
```

Next is the conversion to MetChem-compatible form:
```
java -jar ./ConvertSDFtoXLS.jar ChEBI_complete.sdf /tmp/chebi
unoconv -f csv ChEBI_complete.xls
csvcut -d , -c "ChEBI ID","Mass","Formulae","SMILES","InChI","InChIKey","ChEBI Name" ChEBI_complete.csv |\
csvformat --out-delimiter "|" >ChEBI_metchemcolums.csv
gzip ChEBI_metchemcolums.csv

```

