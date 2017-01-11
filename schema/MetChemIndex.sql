-- create index compound_structure on compound  using gist (mol_structure);
create unique index compound_id on compound (compound_id);
create index compound_mass on compound (monoisotopic_mass);
create index compound_formula on compound (molecular_formula);                        
create index compound_inchikey on compound (inchi_key);                        


create unique index substance_id on substance (substance_id);
create index substance_compound on substance (compound_id);
create index substance_library on substance (library_id);
create index substance_accession on substance (accession);

create unique index library_id on library (library_id);
create index library_name on library (library_name);         

create index name_id on name (substance_id);         

ALTER TABLE SUBSTANCE ADD FOREIGN KEY (COMPOUND_ID) REFERENCES COMPOUND (COMPOUND_ID) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE SUBSTANCE ADD FOREIGN KEY (LIBRARY_ID) REFERENCES LIBRARY (LIBRARY_ID) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE NAME ADD FOREIGN KEY (SUBSTANCE_ID) REFERENCES SUBSTANCE (SUBSTANCE_ID) ON UPDATE CASCADE ON DELETE CASCADE;

