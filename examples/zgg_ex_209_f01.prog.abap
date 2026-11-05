* Routines of ZGG_EX_209.

FORM fill.
  APPEND VALUE #( name = `Ann` points = 3 ) TO gt_players.
  APPEND VALUE #( name = `Bob` points = 5 ) TO gt_players.
  APPEND VALUE #( name = `Cid` points = 1 ) TO gt_players.
ENDFORM.

FORM point_to USING iv_index TYPE i.
  READ TABLE gt_players ASSIGNING <gs_player> INDEX iv_index.
ENDFORM.

FORM raise_points.
  IF <gs_player> IS ASSIGNED.
    <gs_player>-points = <gs_player>-points + 10.
  ENDIF.
ENDFORM.

FORM show.
  FIELD-SYMBOLS <ls_player> TYPE ty_player.
  LOOP AT gt_players ASSIGNING <ls_player>.
    ASSIGN COMPONENT 'POINTS' OF STRUCTURE <ls_player> TO <gv_field>.
    IF sy-subrc = 0.
      WRITE: / <ls_player>-name, <gv_field>.
    ENDIF.
  ENDLOOP.
ENDFORM.

FORM split_code.
  FIELD-SYMBOLS <ls_code> TYPE ty_code.
  ASSIGN gv_code TO <ls_code> CASTING.
  WRITE: / 'Country:', <ls_code>-country, 'Number:', <ls_code>-number.
ENDFORM.
