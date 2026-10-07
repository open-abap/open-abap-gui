REPORT zgg_ex_066.

* The title, the function text and the list texts hold right-to-left script,
* combining characters, an emoji and markup characters. They live in the GUI
* status and the text pool and must reach the browser as text.

START-OF-SELECTION.
  SET PF-STATUS 'SHELL66'.
  SET TITLEBAR 'T66'.
  WRITE / TEXT-001.

AT USER-COMMAND.
  IF sy-ucomm = 'RUN66'.
    WRITE / TEXT-002.
  ENDIF.
