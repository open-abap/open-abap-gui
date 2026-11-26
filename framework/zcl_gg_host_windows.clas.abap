CLASS zcl_gg_host_windows DEFINITION PUBLIC FINAL CREATE PRIVATE.

* The GUI sessions of the host, each one SAP GUI session: a window of the
* browser preview's shell, or a browser tab of a host that serves the pages
* directly. The host keeps the controls,
* ALV trees and screen attributes of the running program statically, so a
* session has its own copy of them here, like the roll area of a session in
* SAP, and the copy of the window a request comes from is put in place before
* the request runs. The host programs a window starts belong to it, and end
* with it.
*
* The shell names the window of each request in a header. A browser tab
* sends it as the form field or query parameter gg_window, which script() on
* every page adds; a request that names none belongs to the first window.
* Only the unit tests enter no window at all: nothing is swapped then.

  PUBLIC SECTION.
    CONSTANTS c_first_window TYPE string VALUE 'W0'.
    CONSTANTS c_parameter TYPE string VALUE 'gg_window'.
* What a shell sends for its first window: the host opens a new one, so the
* shells of several browser tabs never share a window.
    CONSTANTS c_new_window TYPE string VALUE 'new'.

* The window a request names, or the first one. The name goes into the page
* script, so anything but letters, digits, _ and - names the first window.
    CLASS-METHODS normalize
      IMPORTING
        iv_window        TYPE string
      RETURNING
        VALUE(rv_window) TYPE string.

* The script a page served to a browser tab carries: it names the current
* window in every form and same-site link of the page, and sends /o to a new
* tab, where the new session shows.
    CLASS-METHODS script
      RETURNING
        VALUE(rv_html) TYPE string.

* Puts the state of the window in place. A window the host has not seen yet
* starts empty.
    CLASS-METHODS enter
      IMPORTING
        iv_window TYPE string.

* Opens a new window, empty, and makes it the current one. It belongs to the
* same shell as the current window, or starts a shell of its own.
    CLASS-METHODS open
      IMPORTING
        iv_own_shell     TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(rv_window) TYPE string.

* Ends the window and every host program running in it. The last window of
* a shell stays open.
    CLASS-METHODS end
      IMPORTING
        iv_window       TYPE string
      RETURNING
        VALUE(rv_error) TYPE string.

    CLASS-METHODS current
      RETURNING
        VALUE(rv_window) TYPE string.

* Whether the request named a GUI session, so several can be open.
    CLASS-METHODS enabled
      RETURNING
        VALUE(rv_enabled) TYPE abap_bool.

* The windows of the current window's shell.
    CLASS-METHODS count
      RETURNING
        VALUE(rv_count) TYPE i.

* The windows of all shells.
    CLASS-METHODS total
      RETURNING
        VALUE(rv_total) TYPE i.

    CLASS-METHODS clear.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_window,
             window TYPE string,
* The first window of the shell or browser the window shows in.
             shell  TYPE string,
             state  TYPE REF TO data,
           END OF ty_window.
    TYPES ty_windows TYPE STANDARD TABLE OF ty_window WITH DEFAULT KEY.

    CLASS-DATA mt_windows TYPE ty_windows.
    CLASS-DATA mv_current TYPE string.
    CLASS-DATA mv_next TYPE i.

    CLASS-METHODS save.

    CLASS-METHODS reset.

ENDCLASS.

CLASS zcl_gg_host_windows IMPLEMENTATION.

  METHOD enter.
    IF iv_window IS INITIAL.
      CLEAR mv_current.
      RETURN.
    ENDIF.
    IF iv_window = mv_current.
      RETURN.
    ENDIF.
    save( ).
    mv_current = iv_window.
    READ TABLE mt_windows INTO DATA(ls_window) WITH KEY window = iv_window.
    IF sy-subrc <> 0.
      reset( ).
      APPEND VALUE #( window = iv_window shell = iv_window ) TO mt_windows.
      RETURN.
    ENDIF.
    zcl_gg_host_runtime=>restore_gui_state( ls_window-state ).
  ENDMETHOD.

  METHOD open.
    DATA lv_shell TYPE string.

    IF iv_own_shell = abap_false.
      lv_shell = VALUE #( mt_windows[ window = mv_current ]-shell OPTIONAL ).
    ENDIF.
    save( ).
    DO.
      mv_next = mv_next + 1.
      rv_window = |W{ mv_next }|.
      IF NOT line_exists( mt_windows[ window = rv_window ] ).
        EXIT.
      ENDIF.
    ENDDO.
    reset( ).
    IF lv_shell IS INITIAL.
      lv_shell = rv_window.
    ENDIF.
    APPEND VALUE #( window = rv_window shell = lv_shell ) TO mt_windows.
    mv_current = rv_window.
  ENDMETHOD.

  METHOD end.
    DATA lv_shell TYPE string.
    DATA lv_windows TYPE i.

    lv_shell = VALUE #( mt_windows[ window = iv_window ]-shell OPTIONAL ).
    LOOP AT mt_windows TRANSPORTING NO FIELDS WHERE shell = lv_shell.
      lv_windows = lv_windows + 1.
    ENDLOOP.
    IF lv_windows <= 1.
      rv_error = 'The last session cannot be ended.'.
      RETURN.
    ENDIF.
    zcl_gg_host_runtime=>close_window( iv_window ).
    DELETE mt_windows WHERE window = iv_window.
    IF mv_current = iv_window.
      reset( ).
      CLEAR mv_current.
    ENDIF.
  ENDMETHOD.

  METHOD normalize.
    rv_window = iv_window.
    IF rv_window IS INITIAL
        OR strlen( rv_window ) > 32
        OR rv_window CN 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-'.
      rv_window = c_first_window.
    ENDIF.
  ENDMETHOD.

  METHOD script.
    IF mv_current IS INITIAL.
      RETURN.
    ENDIF.
* The first window is the one a request names by naming none, so its pages
* send nothing extra; the pages of other windows name theirs in every form
* and same-site link. form.submit() skips the submit event, so the forms are
* stamped on load and submit() stamps as well; the guard keeps a second page
* in the same window object, as in the preview's frames, from wrapping it
* again.
    rv_html = |<meta name="gg-window" content="{ mv_current }">| &&
      '<script>(function(){var id="' && mv_current && '";var name="' && c_parameter && '";var named=id!=="' && c_first_window && '";' &&
      'var stamp=function(form){if(!named){return;}var field=form.querySelector("input[name=" + name + "]");if(!field){field=document["cr"+"eateElement"]("input");field.type="hidden";field.name=name;form.appendChild(field);}field.value=id;};' &&
      'var stampAll=function(){Array.prototype.forEach.call(document.forms,stamp);};' &&
      'if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",stampAll);}else{stampAll();}' &&
      'var proto=HTMLFormElement.prototype;if(named&&!proto.submit.ggWindow){var submit=proto.submit;proto.submit=function(){stamp(this);return submit.call(this);};proto.submit.ggWindow=true;}' &&
      'document.addEventListener("submit",function(event){var form=event.target;if(!form||form.tagName!=="FORM"){return;}stamp(form);' &&
      'var field=form.querySelector("input[name=command]");' &&
      'if(field&&!event.defaultPrevented&&/^\s*\/o/i.test(field.value)){form.target="_blank";setTimeout(function(){form.removeAttribute("target");field.value="";},0);}},true);' &&
      'document.addEventListener("click",function(event){if(!named){return;}var link=event.target&&event.target.closest?event.target.closest("a[href]"):null;if(!link){return;}' &&
      'var url=new URL(link.getAttribute("href"),location.href);if(url.origin!==location.origin||url.protocol==="javascript:"){return;}' &&
      'url.searchParams.set(name,id);link.setAttribute("href",url.pathname+url.search+url.hash);},true);' &&
      '}());</script>'.
  ENDMETHOD.

  METHOD current.
    rv_window = mv_current.
  ENDMETHOD.

  METHOD enabled.
    rv_enabled = xsdbool( mv_current IS NOT INITIAL ).
  ENDMETHOD.

  METHOD count.
    DATA lv_shell TYPE string.

    lv_shell = VALUE #( mt_windows[ window = mv_current ]-shell OPTIONAL ).
    LOOP AT mt_windows TRANSPORTING NO FIELDS WHERE shell = lv_shell.
      rv_count = rv_count + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD total.
    rv_total = lines( mt_windows ).
  ENDMETHOD.

  METHOD clear.
    CLEAR: mt_windows, mv_current, mv_next.
  ENDMETHOD.

  METHOD save.
    IF mv_current IS INITIAL.
      RETURN.
    ENDIF.
    READ TABLE mt_windows ASSIGNING FIELD-SYMBOL(<ls_window>) WITH KEY window = mv_current.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    <ls_window>-state = zcl_gg_host_runtime=>save_gui_state( ).
  ENDMETHOD.

  METHOD reset.
    zcl_gg_host_runtime=>restore_gui_state( ).
  ENDMETHOD.

ENDCLASS.
