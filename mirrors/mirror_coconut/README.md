- provide gzipped file here named like 
- https://zenodo.org/record/3778405
- header of the provided csv files:
`coconut_id,molecular_formula,clean_smiles,inchi,inchikey,coconut_id`

```
wget -O COCONUT4MetFrag_april.csv https://zenodo.org/record/3778405/files/COCONUT4MetFrag_april.csv?download=1

csvcut -d , -c "coconut_id","molecular_formula","clean_smiles","inchi","inchikey" |\
csvformat --out-delimiter "|" >COCONUT_metchemcolums.csv
gzip COCONUT_metchemcolums.csv

```

