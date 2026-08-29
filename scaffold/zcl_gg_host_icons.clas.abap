CLASS zcl_gg_host_icons DEFINITION PUBLIC FINAL CREATE PUBLIC.

* Local, dependency-free SVG sprite based on the Tabler Icons outline set.
* Keep callers on semantic names so the icon set can be changed centrally.

  PUBLIC SECTION.
    CLASS-METHODS sprite
      RETURNING
        VALUE(rv_html) TYPE string.

    CLASS-METHODS icon
      IMPORTING
        iv_name        TYPE string
        iv_label       TYPE string OPTIONAL
      RETURNING
        VALUE(rv_html) TYPE string.
ENDCLASS.

CLASS zcl_gg_host_icons IMPLEMENTATION.

  METHOD sprite.
    rv_html = '<svg class="wb-icon-sprite" aria-hidden="true" focusable="false" xmlns="http://www.w3.org/2000/svg">' &&
      '<symbol id="wb-icon-player-play" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 4v16l13 -8l-13 -8" /></symbol>' &&
      '<symbol id="wb-icon-arrow-left" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l14 0" /><path d="M5 12l6 6" /><path d="M5 12l6 -6" /></symbol>' &&
      '<symbol id="wb-icon-arrow-right" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12l14 0" /><path d="M13 18l6 -6" /><path d="M13 6l6 6" /></symbol>' &&
      '<symbol id="wb-icon-logout" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 8v-2a2 2 0 0 0 -2 -2h-5a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h5a2 2 0 0 0 2 -2v-2" /><path d="M9 12h12" /><path d="M18 9l3 3l-3 3" /></symbol>' &&
      '<symbol id="wb-icon-device-floppy" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 4h10l4 4v10a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2" /><path d="M10 14a2 2 0 1 0 4 0a2 2 0 1 0 -4 0" /><path d="M14 4l0 4l-6 0l0 -4" /></symbol>' &&
      '<symbol id="wb-icon-arrow-back-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 14l-4 -4l4 -4" /><path d="M5 10h11a4 4 0 1 1 0 8h-1" /></symbol>' &&
      '<symbol id="wb-icon-arrow-forward-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 14l4 -4l-4 -4" /><path d="M19 10h-11a4 4 0 1 0 0 8h1" /></symbol>' &&
      '<symbol id="wb-icon-printer" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 17h2a2 2 0 0 0 2 -2v-4a2 2 0 0 0 -2 -2h-14a2 2 0 0 0 -2 2v4a2 2 0 0 0 2 2h2" /><path d="M17 9v-4a2 2 0 0 0 -2 -2h-6a2 2 0 0 0 -2 2v4" /><path d="M7 15a2 2 0 0 1 2 -2h6a2 2 0 0 1 2 2v4a2 2 0 0 1 -2 2h-6a2 2 0 0 1 -2 -2l0 -4" /></symbol>' &&
      '<symbol id="wb-icon-search" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10a7 7 0 1 0 14 0a7 7 0 1 0 -14 0" /><path d="M21 21l-6 -6" /></symbol>' &&
      '<symbol id="wb-icon-binoculars" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 16a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M14 16a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M16.346 9.17l-.729 -1.261c-.16 -.248 -1.056 -.203 -1.117 .091l-.177 1.38" /><path d="M19.761 14.813l-2.84 -5.133c-.189 -.31 -.592 -.68 -1.421 -.68c-.828 0 -1.5 .448 -1.5 1v6" /><path d="M7.654 9.17l.729 -1.261c.16 -.249 1.056 -.203 1.117 .091l.177 1.38" /><path d="M4.239 14.813l2.84 -5.133c.189 -.31 .592 -.68 1.421 -.68c.828 0 1.5 .448 1.5 1v6" /><path d="M10 12h4v2h-4l0 -2" /></symbol>' &&
      '<symbol id="wb-icon-binoculars-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 16a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M14 16a3 3 0 1 0 6 0a3 3 0 1 0 -6 0" /><path d="M16.346 9.17l-.729 -1.261c-.16 -.248 -1.056 -.203 -1.117 .091l-.177 1.38" /><path d="M19.761 14.813l-2.84 -5.133c-.189 -.31 -.592 -.68 -1.421 -.68c-.828 0 -1.5 .448 -1.5 1v6" /><path d="M7.654 9.17l.729 -1.261c.16 -.249 1.056 -.203 1.117 .091l.177 1.38" /><path d="M4.239 14.813l2.84 -5.133c-.189 -.31 -.592 -.68 -1.421 -.68c-.828 0 -1.5 .448 -1.5 1v6" /><path d="M10 12h4v2h-4l0 -2" /><path d="M20 3v4" /><path d="M18 5h4" /></symbol>' &&
      '<symbol id="wb-icon-help-circle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M12 16v.01" /><path d="M12 13a2 2 0 0 0 .914 -3.782a1.98 1.98 0 0 0 -2.414 .483" /></symbol>' &&
      '<symbol id="wb-icon-arrow-bar-to-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16" /><path d="M12 20v-12" /><path d="M7 13l5 -5l5 5" /></symbol>' &&
      '<symbol id="wb-icon-arrow-bar-to-down" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 20h16" /><path d="M12 4v12" /><path d="M7 11l5 5l5 -5" /></symbol>' &&
      '<symbol id="wb-icon-file-arrow-up" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M12 17v-6" /><path d="M9 14l3 -3l3 3" /></symbol>' &&
      '<symbol id="wb-icon-file-arrow-down" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M12 11v6" /><path d="M9 14l3 3l3 -3" /></symbol>' &&
      '<symbol id="wb-icon-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5l0 14" /><path d="M5 12l14 0" /></symbol>' &&
      '<symbol id="wb-icon-folder" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 4h4l3 3h7a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2" /></symbol>' &&
      '<symbol id="wb-icon-folder-open" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 19l2.757 -7.351a1 1 0 0 1 .936 -.649h12.307a1 1 0 0 1 .986 1.164l-.996 5.211a2 2 0 0 1 -1.964 1.625h-14.026a2 2 0 0 1 -2 -2v-11a2 2 0 0 1 2 -2h4l3 3h7a2 2 0 0 1 2 2v2" /></symbol>' &&
      '<symbol id="wb-icon-file-code" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 3v4a1 1 0 0 0 1 1h4" /><path d="M17 21h-10a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2h7l5 5v11a2 2 0 0 1 -2 2" /><path d="M10 13l-1 2l1 2" /><path d="M14 13l1 2l-1 2" /></symbol>' &&
      '<symbol id="wb-icon-star" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 17.75l-6.172 3.245l1.179 -6.873l-5 -4.867l6.9 -1l3.086 -6.253l3.086 6.253l6.9 1l-5 4.867l1.179 6.873l-6.158 -3.245" /></symbol>' &&
      '<symbol id="wb-icon-device-desktop" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 5a1 1 0 0 1 1 -1h16a1 1 0 0 1 1 1v10a1 1 0 0 1 -1 1h-16a1 1 0 0 1 -1 -1v-10" /><path d="M7 20h10" /><path d="M9 16v4" /><path d="M15 16v4" /></symbol>' &&
      '<symbol id="wb-icon-database" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6a8 3 0 1 0 16 0a8 3 0 1 0 -16 0" /><path d="M4 6v6a8 3 0 0 0 16 0v-6" /><path d="M4 12v6a8 3 0 0 0 16 0v-6" /></symbol>' &&
      '<symbol id="wb-icon-refresh" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 11a8.1 8.1 0 0 0 -15.5 -2m-.5 -4v4h4" /><path d="M4 13a8.1 8.1 0 0 0 15.5 2m.5 4v-4h-4" /></symbol>' &&
      '<symbol id="wb-icon-edit" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 7h-1a2 2 0 0 0 -2 2v9a2 2 0 0 0 2 2h9a2 2 0 0 0 2 -2v-1" /><path d="M20.385 6.585a2.1 2.1 0 0 0 -2.97 -2.97l-8.415 8.385v3h3l8.385 -8.415" /><path d="M16 5l3 3" /></symbol>' &&
      '<symbol id="wb-icon-circle-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M9 12l2 2l4 -4" /></symbol>' &&
      '<symbol id="wb-icon-circle-x" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M10 10l4 4m0 -4l-4 4" /></symbol>' &&
      '<symbol id="wb-icon-alert-triangle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 9v4" /><path d="M10.363 3.591l-8.106 13.534a1.914 1.914 0 0 0 1.636 2.871h16.214a1.914 1.914 0 0 0 1.636 -2.87l-8.106 -13.536a1.914 1.914 0 0 0 -3.274 0" /><path d="M12 16h.01" /></symbol>' &&
      '<symbol id="wb-icon-info-circle" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0" /><path d="M12 9h.01" /><path d="M11 12h1v4h1" /></symbol>' &&
      '<symbol id="wb-icon-trash" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 7l16 0" /><path d="M10 11l0 6" /><path d="M14 11l0 6" /><path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12" /><path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" /></symbol>' &&
      '<symbol id="wb-icon-search-plus" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 10a7 7 0 1 0 14 0a7 7 0 1 0 -14 0" /><path d="M21 21l-6 -6" /><path d="M19 3v4" /><path d="M17 5h4" /></symbol>' &&
      '</svg>'.
  ENDMETHOD.

  METHOD icon.
    DATA lv_name TYPE string.

    lv_name = iv_name.
    TRANSLATE lv_name TO LOWER CASE.
    REPLACE ALL OCCURRENCES OF '@' IN lv_name WITH ``.
    CASE lv_name.
      WHEN 'go' OR 'execute' OR 'icon_execute' OR 'player-play'.
        lv_name = 'player-play'.
      WHEN 'back' OR 'icon_back' OR 'arrow-left'.
        lv_name = 'arrow-left'.
      WHEN 'forward' OR 'icon_forward' OR 'arrow-right'.
        lv_name = 'arrow-right'.
      WHEN 'exit' OR 'logout' OR 'icon_exit'.
        lv_name = 'logout'.
      WHEN 'save' OR 'icon_save' OR 'device-floppy'.
        lv_name = 'device-floppy'.
      WHEN 'undo' OR 'icon_undo' OR 'arrow-back-up'.
        lv_name = 'arrow-back-up'.
      WHEN 'redo' OR 'icon_redo' OR 'arrow-forward-up'.
        lv_name = 'arrow-forward-up'.
      WHEN 'print' OR 'icon_print' OR 'printer'.
        lv_name = 'printer'.
      WHEN 'find' OR 'search' OR 'icon_find'.
        lv_name = 'search'.
      WHEN 'binoculars' OR 'find-more' OR 'icon_find_more'.
        lv_name = 'search'.
      WHEN 'search-plus' OR 'binoculars-plus' OR 'find-next' OR 'icon_find_next'.
        lv_name = 'search-plus'.
      WHEN 'help' OR 'icon_help' OR 'help-circle'.
        lv_name = 'help-circle'.
      WHEN 'first-page' OR 'arrow-bar-to-up'.
        lv_name = 'arrow-bar-to-up'.
      WHEN 'previous-page' OR 'file-arrow-up'.
        lv_name = 'file-arrow-up'.
      WHEN 'next-page' OR 'file-arrow-down'.
        lv_name = 'file-arrow-down'.
      WHEN 'last-page' OR 'arrow-bar-to-down'.
        lv_name = 'arrow-bar-to-down'.
      WHEN 'create' OR 'plus' OR 'icon_create'.
        lv_name = 'plus'.
      WHEN 'folder' OR 'icon_folder'.
        lv_name = 'folder'.
      WHEN 'folder-open' OR 'icon_open_folder'.
        lv_name = 'folder-open'.
      WHEN 'program' OR 'file-code' OR 'icon_program'.
        lv_name = 'file-code'.
      WHEN 'favorite' OR 'star' OR 'icon_favorite'.
        lv_name = 'star'.
      WHEN 'screen' OR 'device-desktop' OR 'icon_display'.
        lv_name = 'device-desktop'.
      WHEN 'database' OR 'icon_database'.
        lv_name = 'database'.
      WHEN 'refresh' OR 'icon_refresh'.
        lv_name = 'refresh'.
      WHEN 'edit' OR 'icon_change'.
        lv_name = 'edit'.
      WHEN 'delete' OR 'trash' OR 'icon_delete'.
        lv_name = 'trash'.
      WHEN 'success' OR 'circle-check' OR 'icon_green_light'.
        lv_name = 'circle-check'.
      WHEN 'error' OR 'circle-x' OR 'icon_red_light'.
        lv_name = 'circle-x'.
      WHEN 'warning' OR 'alert-triangle' OR 'icon_yellow_light'.
        lv_name = 'alert-triangle'.
      WHEN 'information' OR 'info-circle' OR 'icon_information'.
        lv_name = 'info-circle'.
      WHEN OTHERS.
        lv_name = 'help-circle'.
    ENDCASE.

    IF iv_label IS INITIAL.
      rv_html = |<svg class="wb-icon" aria-hidden="true" focusable="false"><use href="#wb-icon-{ lv_name }"></use></svg>|.
    ELSE.
      rv_html = |<svg class="wb-icon" role="img" aria-label="{ zcl_gg_host_html=>escape_attribute( iv_label ) }" focusable="false"><use href="#wb-icon-{ lv_name }"></use></svg>|.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
