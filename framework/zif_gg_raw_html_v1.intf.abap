INTERFACE zif_gg_raw_html_v1 PUBLIC.

* Small transport-neutral contract for classes that emit a complete raw HTML
* document.

  METHODS get_html
    RETURNING
      VALUE(rv_html) TYPE string.
ENDINTERFACE.
