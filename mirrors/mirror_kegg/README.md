- provide gzipped files here named like kegg_'startid'_'endid'.csv.gz
- 'startid' and 'endid' provide information about the candidate ID range within the file
- e.g. kegg_C00001_C05000.csv.gz
- once added to the metchem container keep the filenames as they are
- just update the content and add files with higher ID ranges

- header of the provided csv files:
```
Identifier|InChI|ExactMass|MolecularFormula|InChIKey1|InChIKey2|SMILES|Name|InChIKey3
```
- columns need to be tab separated
