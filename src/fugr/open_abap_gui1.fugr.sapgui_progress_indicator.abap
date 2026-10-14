FUNCTION sapgui_progress_indicator.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(PERCENTAGE) DEFAULT 0
*"     VALUE(TEXT) DEFAULT SPACE
*"----------------------------------------------------------------------

* do nothing, the progress indicator is not rendered, but background logic might indicate progress
  RETURN.

ENDFUNCTION.
