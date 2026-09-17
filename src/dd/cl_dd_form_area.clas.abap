CLASS cl_dd_form_area DEFINITION PUBLIC INHERITING FROM cl_dd_area.
  PUBLIC SECTION.

    METHODS add_button
      IMPORTING
        label    TYPE string OPTIONAL
        sap_icon TYPE any OPTIONAL
        tooltip  TYPE string OPTIONAL
        name     TYPE any OPTIONAL
        sub_area TYPE REF TO cl_dd_area OPTIONAL
        tabindex TYPE i OPTIONAL
        hotkey   TYPE any OPTIONAL
      EXPORTING
        button   TYPE REF TO cl_dd_button_element.

    METHODS add_input_element
      IMPORTING
        value         TYPE any OPTIONAL
        name          TYPE any OPTIONAL
        size          TYPE i OPTIONAL
        maxlength     TYPE i OPTIONAL
        sub_area      TYPE REF TO cl_dd_area OPTIONAL
        tooltip       TYPE string OPTIONAL
        tabindex      TYPE i OPTIONAL
        hotkey        TYPE any OPTIONAL
        a11y_label    TYPE string OPTIONAL
      EXPORTING
        input_element TYPE REF TO cl_dd_input_element.

    METHODS add_select_element
      IMPORTING
        name           TYPE sdydo_element_name OPTIONAL
        value          TYPE sdydo_value OPTIONAL
        options        TYPE sdydo_option_tab OPTIONAL
        sub_area       TYPE REF TO cl_dd_area OPTIONAL
        tooltip        TYPE string OPTIONAL
        tabindex       TYPE i OPTIONAL
        hotkey         TYPE sdydo_c1 OPTIONAL
        a11y_label     TYPE string OPTIONAL
      EXPORTING
        select_element TYPE REF TO cl_dd_select_element.
ENDCLASS.

CLASS cl_dd_form_area IMPLEMENTATION.
  METHOD add_input_element.
    DATA lv_start TYPE i.
    DATA lv_fragment TYPE string.
    lv_start = strlen( html_content ).
    input_element = NEW cl_dd_input_element( ).
    input_element->name = name.
    input_element->value = value.
    input_element->size = size.
    input_element->maxlength = maxlength.
    input_element->tooltip = tooltip.
    input_element->a11y_label = a11y_label.
    html_content = html_content && |<label>{ escape_html( a11y_label ) }<input type="text" name="{ escape_html( CONV string( name ) ) }" value="{ escape_html( CONV string( value ) ) }" size="{ size }" maxlength="{ maxlength }" title="{ escape_html( tooltip ) }"></label>|.
    lv_fragment = substring(
      val = html_content
      off = lv_start ).
    IF parent_area IS BOUND.
      parent_area->html_content = parent_area->html_content && lv_fragment.
    ENDIF.
  ENDMETHOD.

  METHOD add_select_element.
    DATA lv_start TYPE i.
    DATA lv_fragment TYPE string.
    lv_start = strlen( html_content ).
    select_element = NEW cl_dd_select_element( ).
    select_element->name = name.
    select_element->value = value.
    select_element->options = options.
    select_element->tooltip = tooltip.
    select_element->a11y_label = a11y_label.
    html_content = html_content && |<label>{ escape_html( a11y_label ) }<select name="{ escape_html( CONV string( name ) ) }" title="{ escape_html( tooltip ) }">|.
    LOOP AT options INTO DATA(ls_option).
      html_content = html_content && |<option value="{ escape_html( CONV string( ls_option-value ) ) }"{ COND string( WHEN ls_option-value = value THEN ` selected` ELSE `` ) }>{ escape_html( ls_option-text ) }</option>|.
    ENDLOOP.
    html_content = html_content && `</select></label>`.
    lv_fragment = substring(
      val = html_content
      off = lv_start ).
    IF parent_area IS BOUND.
      parent_area->html_content = parent_area->html_content && lv_fragment.
    ENDIF.
  ENDMETHOD.

  METHOD add_button.
    DATA lv_start TYPE i.
    DATA lv_fragment TYPE string.
    DATA lv_icon_html TYPE string.
    lv_start = strlen( html_content ).
    button = NEW cl_dd_button_element( ).
    button->name = name.
    button->label = label.
    button->tooltip = tooltip.
    button->a11y_label = label.
    IF sap_icon IS SUPPLIED AND sap_icon IS NOT INITIAL.
      lv_icon_html = render_icon_html(
        sap_icon         = sap_icon
        alternative_text = tooltip ).
    ENDIF.
    html_content = html_content && |<button type="submit" name="{ escape_html( CONV string( name ) ) }" title="{ escape_html( tooltip ) }">{ lv_icon_html }<span>{ escape_html( label ) }</span></button>|.
    lv_fragment = substring(
      val = html_content
      off = lv_start ).
    IF parent_area IS BOUND.
      parent_area->html_content = parent_area->html_content && lv_fragment.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
