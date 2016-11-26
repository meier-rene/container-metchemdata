-- create index compound_structure on compound  using gist (mol_structure);
create index compound_mass on compound (monoisotopic_mass);
create index compound_formula on compound (molecular_formula);                        
create index compound_inchikey1 on compound (inchi_key_1);                        

create index substance_compound on substance (compound_id);
create index substance_library on substance (library_id);
create index substance_accession on substance (accession);

create index library_name on library (library_name);         

create index name_compound on name (substance_id);         
