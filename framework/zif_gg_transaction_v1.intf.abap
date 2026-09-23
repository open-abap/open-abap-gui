INTERFACE zif_gg_transaction_v1 PUBLIC.

* Public metadata for one runnable workbench transaction. The tcode is the
* stable, case-insensitive public identifier and description is user-facing
* text. Implementations must return metadata without requiring a host session
* or changing application state.

  TYPES ty_tcode TYPE zif_gg_session_types_v1=>ty_tcode.
  TYPES: BEGIN OF ty_transaction,
           tcode       TYPE ty_tcode,
           description TYPE string,
         END OF ty_transaction.

  METHODS get_transaction
    RETURNING
      VALUE(rs_transaction) TYPE ty_transaction.

ENDINTERFACE.
