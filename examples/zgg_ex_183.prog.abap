REPORT zgg_ex_183.

* A SELECT without INTO that reads into the TABLES work area across clients.

TABLES varid.

START-OF-SELECTION.
  SELECT SINGLE * FROM varid CLIENT SPECIFIED WHERE report = 'ZGG_EX_183'.
  WRITE / varid-variant.
