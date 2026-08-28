# Scaffold coverage plan

Goal: prove that `zif_gg_report_v1` and its neighbours can carry every feature of a
classic ABAP report. The method is one *atomic feature* at a time — a minimal
report that uses exactly one language construct, paired with the class that
expresses the same thing through the scaffold interfaces.

An atom is normally one interface member. Where one ABAP statement maps onto a
group of members that are meaningless apart (`SKIP`/`ULINE`/`NEW-LINE`), the
group is one atom.

## Conventions

Report `scaffold/examples/zgg_ex_<nn>.prog.abap`, class
`scaffold/examples/zcl_gg_ex_<nn>.clas.abap`.

Each example class is self contained. It implements `zif_gg_report_v1`
directly, with no superclass and no shared helper, so one file shows the whole
program the way the report next to it does. The cost is that every class spells
out all eighteen interface methods and leaves the ones the feature does not use
empty. That is accepted deliberately: these are read one at a time as
specimens, not maintained as a family, and an inherited no-op would hide the
event surface the example is supposed to demonstrate.

```abap
CLASS zcl_gg_ex_nn DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_gg_report_v1.

ENDCLASS.

CLASS zcl_gg_ex_nn IMPLEMENTATION.

  METHOD zif_gg_report_v1~start_of_selection.
    " the feature under test
  ENDMETHOD.

* the other seventeen methods, each empty

ENDCLASS.
```

The sections below show only the methods that carry the feature; the empty
remainder is implied every time.

An example that needs classic-list events states
`INTERFACES zif_gg_list_processing_v1` as well, returns `me` from
`get_list_processing`, and carries that interface's seven methods on the same
terms. An example that calls a nested screen states
`INTERFACES zif_gg_resumable_v1`.

Shorthand used throughout: `lo_writer = io_session->get_list( )->get_writer( )`.

The test for item 3 lives in `zcl_gg_ex_<nn>.clas.testclasses.abap`, one
`ltcl_ex_<nn>` per example.

Two things that bite and are not caught where you would expect:

- Pass parameters by name whenever a method has more than one, optional ones
  included. The transpiler does not resolve positional passing in that case,
  and it fails at runtime rather than at lint time.
- A call with a single parameter must stay on one line, including a `VALUE #( )`
  argument, or `keep_single_parameter_on_one_line` rejects it.

## Definition of done

A feature's box is ticked when all four hold:

1. `zgg_ex_<nn>.prog.abap` exists and states the feature in one construct.
2. `zcl_gg_ex_<nn>.clas.abap` exists and expresses the same thing.
3. A unit test runs the class through `zcl_gg_host` and asserts the output.
   There is no classic list renderer here to diff against, so the report is the
   specification for what that output should be, not a second thing to execute.
4. `npm test` is green — abaplint and the transpiled run.

A feature whose operations the host does not drive yet cannot reach item 3. Do
items 1, 2 and 4, leave the box open, and say in the section which host
operation is missing.

## Prerequisites

- [x] **P1 — a host.** Done, `scaffold/host/`. `zcl_gg_host=>run( io_report )`
      drives LOAD-OF-PROGRAM, the screen definition and its defaults,
      INITIALIZATION, START-OF-SELECTION, END-OF-SELECTION, STOP and MESSAGE,
      and renders the classic list to right-trimmed text. Seven unit tests in
      `zcl_gg_host.clas.testclasses.abap` cover it.
      The host grows with the phases. It describes a selection screen but never
      displays one, and the interactive list, navigation and logical-database
      operations raise `zcx_gg_control_flow` with `kind_unsupported` naming the
      ABAP statement, so an example that runs ahead of the host fails loudly
      instead of silently doing nothing.
P1 was the only real prerequisite. What were P2 and P3 are not artefacts that
can be built up front — see the next section.

## Per-feature obligations

Neither of these can be created ahead of the feature that uses it. Both were
tried as prerequisites and both fail lint on their own.

- **Message class `zgg_ex`.** It must land in the same change as feature 40,
  not before it. `message_exists` rejects `MESSAGE nnn(id)` against a missing
  class, but `easy_to_find_messages` equally rejects a message that no code
  references — a message class with no consumer reports
  `Message 001 not statically referenced`. The XML abaplint parses is given in
  the feature 40 section, so it does not have to be worked out again.
- **Text pools.** `selection_screen_texts_missing` and `check_text_elements`
  fire per report, on the report that has the untranslated `PARAMETERS` or the
  bare `TEXT-001`. So each report from phase 3 onward brings its own texts;
  there is nothing to build in advance. This is also open scaffold gap #5, the
  scaffold having no text-element model at all.

## Checklist

### Phase 1 — Basic list, no selection screen

- [x] 01 `WRITE` literal
- [x] 02 `WRITE AT <pos>(<len>)`, `NO-GAP`
- [x] 03 `SKIP` / `ULINE` / `NEW-LINE` / `SET LEFT COLUMN`
- [ ] 04 `WRITE` numeric and mask additions
- [ ] 05 `FORMAT` colour and attributes
- [ ] 06 `WRITE ... AS CHECKBOX` / `AS ICON` / `AS SYMBOL`
- [ ] 07 `REPORT ... LINE-SIZE / LINE-COUNT / NO STANDARD PAGE HEADING`
- [ ] 08 `NEW-PAGE` / `RESERVE` / `SET BLANK LINES`
- [ ] 09 `TOP-OF-PAGE`
- [ ] 10 `END-OF-PAGE`

### Phase 2 — Program events

- [x] 11 `LOAD-OF-PROGRAM`
- [x] 12 `INITIALIZATION`
- [x] 13 `START-OF-SELECTION` / `END-OF-SELECTION`
- [x] 14 `STOP`

### Phase 3 — Selection screen definition

- [x] 15 `PARAMETERS` with `DEFAULT`
- [ ] 16 `PARAMETERS` attribute additions
- [x] 17 `PARAMETERS ... AS CHECKBOX`
- [x] 18 `PARAMETERS ... RADIOBUTTON GROUP`
- [x] 19 `PARAMETERS ... AS LISTBOX`
- [ ] 20 `SELECT-OPTIONS`
- [ ] 21 `SELECTION-SCREEN COMMENT` / `ULINE` / `SKIP`
- [ ] 22 `SELECTION-SCREEN BEGIN OF BLOCK ... WITH FRAME TITLE`
- [ ] 23 `SELECTION-SCREEN BEGIN OF LINE` and `POSITION`
- [ ] 24 `SELECTION-SCREEN PUSHBUTTON ... USER-COMMAND`
- [ ] 25 `SELECTION-SCREEN FUNCTION KEY`
- [ ] 26 `SELECTION-SCREEN BEGIN OF TABBED BLOCK` and `TAB`
- [ ] 27 `SELECTION-SCREEN BEGIN OF SCREEN nnn`

### Phase 4 — Selection screen events

- [ ] 28 `AT SELECTION-SCREEN OUTPUT` with `LOOP AT SCREEN`
- [ ] 29 `AT SELECTION-SCREEN OUTPUT` writing a parameter
- [ ] 30 `AT SELECTION-SCREEN`
- [ ] 31 `AT SELECTION-SCREEN ON <field>`
- [ ] 32 `AT SELECTION-SCREEN ON END OF <selopt>`
- [ ] 33 `AT SELECTION-SCREEN ON BLOCK`
- [ ] 34 `AT SELECTION-SCREEN ON RADIOBUTTON GROUP`
- [ ] 35 `AT SELECTION-SCREEN ON VALUE-REQUEST`
- [ ] 36 `AT SELECTION-SCREEN ON HELP-REQUEST`
- [ ] 37 `AT SELECTION-SCREEN ON EXIT-COMMAND`
- [ ] 38 `sscrfields-ucomm` driven suppression

### Phase 5 — Messages

- [x] 39 `MESSAGE <text> TYPE`
- [x] 40 `MESSAGE nnn(id) WITH`
- [x] 41 `MESSAGE ... TYPE 'A'` and `'X'`
- [x] 42 `MESSAGE ... DISPLAY LIKE`

### Phase 6 — Interactive lists

- [ ] 43 `HIDE` and `AT LINE-SELECTION`
- [ ] 44 `SET PF-STATUS` and `AT USER-COMMAND`
- [x] 45 `SET TITLEBAR`
- [ ] 46 `READ LINE` / `MODIFY LINE`
- [ ] 47 `GET CURSOR`
- [ ] 48 `TOP-OF-PAGE DURING LINE-SELECTION`
- [ ] 49 `AT PFnn`
- [ ] 50 `LEAVE TO LIST-PROCESSING` / `LEAVE LIST-PROCESSING`

### Phase 7 — Navigation and nesting

- [ ] 51 `CALL SELECTION-SCREEN`
- [ ] 52 `CALL SCREEN`
- [ ] 53 `SUBMIT`
- [ ] 54 `SUBMIT ... AND RETURN` with `WITH` and `USING SELECTION-SET`
- [ ] 55 `SUBMIT ... EXPORTING LIST TO MEMORY`
- [ ] 56 `CALL TRANSACTION`
- [ ] 57 `LEAVE TO TRANSACTION` / `LEAVE PROGRAM`
- [ ] 58 `SET SCREEN` / `LEAVE SCREEN` / `LEAVE TO SCREEN`

### Phase 8 — Logical database

- [ ] 59 `NODES` and `GET`
- [ ] 60 `GET LATE`

### Blocked

These cannot reach the definition of done until the named scaffold gap is
closed. Write the report anyway — it documents the target.

| Feature | Blocked on |
|---|---|
| 04, 15, 16, 19, 20 | #7 — values are `string`, no internal/external conversion contract |
| 07 | #6 — no print or spool parameters |
| 16, 28 | #8 — `ty_state` lacks `input`/`output` split and `group1..group4` |
| 21 | #5 — no text elements, so `TEXT-001` has no counterpart |
| 35 | #18 — F4 cannot update fields other than the one requested |
| 46 | #10 — `read_line` returns hidden fields only, not editable field values |
| 50 | #10 — no `sy-lsind` control, no `DESCRIBE LIST` |
| 54 | #3 — `ty_submit-variant` exists but variants are not managed anywhere |
| 59, 60 | #11 — no `get_nodes( )`, so the host cannot know which subtrees to read |

---

## Phase 1 — Basic list, no selection screen

### 01 — `WRITE` literal

Exercises `zif_gg_list_writer_v1~write_field`.

```abap
REPORT zgg_ex_01.

START-OF-SELECTION.
  WRITE 'hello world'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_list( )->get_writer( )->write_field( VALUE #( text = 'hello world' ) ).
ENDMETHOD.
```

### 02 — `WRITE AT <pos>(<len>)`, `NO-GAP`

Exercises `ty_write_field-placement`.

```abap
REPORT zgg_ex_02.

START-OF-SELECTION.
  WRITE AT 10(5) 'abcdefgh'.
  WRITE 'x' NO-GAP.
  WRITE 'y'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  DATA(lo_writer) = io_session->get_list( )->get_writer( ).

  lo_writer->write_field( VALUE #(
    text      = 'abcdefgh'
    placement = VALUE #( position = 10 length = 5 ) ) ).
  lo_writer->write_field( VALUE #(
    text      = 'x'
    placement = VALUE #( no_gap = abap_true ) ) ).
  lo_writer->write_field( VALUE #( text = 'y' ) ).
ENDMETHOD.
```

### 03 — `SKIP` / `ULINE` / `NEW-LINE` / `SET LEFT COLUMN`

Exercises `skip`, `uline`, `new_line`, `set_position`.

```abap
REPORT zgg_ex_03.

START-OF-SELECTION.
  WRITE 'first'.
  SKIP 2.
  ULINE AT 1(20).
  WRITE / 'second'.
```

`WRITE /` is the transpiler-compatible spelling of the explicit line break;
the class counterpart calls `new_line( )` and `set_position( )` directly.

```abap
METHOD zif_gg_report_v1~start_of_selection.
  DATA(lo_writer) = io_session->get_list( )->get_writer( ).

  lo_writer->write_field( VALUE #( text = 'first' ) ).
  lo_writer->skip( 2 ).
  lo_writer->uline( VALUE #( position = 1 length = 20 ) ).
  lo_writer->new_line( ).
  lo_writer->set_position( 5 ).
  lo_writer->write_field( VALUE #( text = 'second' ) ).
ENDMETHOD.
```

### 04 — `WRITE` numeric and mask additions

Exercises `ty_write_format`. **Blocked on #7** — the amount arrives as a
`string`, so who applies `DECIMALS` and the currency shift is undefined.

The report and class specimens are present, but this checkbox stays open until
gap #7 defines numeric conversion for writer text.

```abap
REPORT zgg_ex_04.

DATA gv_amount TYPE p LENGTH 8 DECIMALS 2 VALUE '1234.5'.

START-OF-SELECTION.
  WRITE gv_amount DECIMALS 2 RIGHT-JUSTIFIED NO-ZERO.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_list( )->get_writer( )->write_field( VALUE #(
    text         = |1234.5|
    write_format = VALUE #(
      decimals      = 2
      justification = zif_gg_list_processing_types_v1=>justify_right
      no_zero       = abap_true ) ) ).
ENDMETHOD.
```

### 05 — `FORMAT` colour and attributes

Exercises `set_format` and `reset_format`.

The report and class specimens are present. The report is excluded from the
runtime transpile until that toolchain supports `FORMAT`; lint still checks it,
so this checkbox stays open until the report can run through the full gate.

```abap
REPORT zgg_ex_05.

START-OF-SELECTION.
  FORMAT COLOR 4 INTENSIFIED ON.
  WRITE 'key column'.
  FORMAT RESET.
  WRITE 'plain'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  DATA(lo_writer) = io_session->get_list( )->get_writer( ).

  lo_writer->set_format( VALUE #(
    color       = zif_gg_list_processing_types_v1=>color_key
    intensified = abap_true ) ).
  lo_writer->write_field( VALUE #( text = 'key column' ) ).
  lo_writer->reset_format( ).
  lo_writer->write_field( VALUE #( text = 'plain' ) ).
ENDMETHOD.
```

### 06 — `WRITE ... AS CHECKBOX` / `AS ICON` / `AS SYMBOL`

Exercises `write_checkbox`, `write_icon`, `write_symbol`.

The report and class specimens are present. The report is excluded from the
runtime transpile until the toolchain supports the required list statements;
this checkbox stays open until it can run through the full gate.

```abap
REPORT zgg_ex_06.

START-OF-SELECTION.
  WRITE abap_true AS CHECKBOX.
  WRITE icon_green_light AS ICON.
  WRITE sym_phone AS SYMBOL.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  DATA(lo_writer) = io_session->get_list( )->get_writer( ).

  lo_writer->write_checkbox( VALUE #( name = 'FLAG' value = abap_true ) ).
  lo_writer->write_icon( VALUE #( name = 'ICON_GREEN_LIGHT' ) ).
  lo_writer->write_symbol( VALUE #( name = 'SYM_PHONE' ) ).
ENDMETHOD.
```

### 07 — `REPORT ... LINE-SIZE / LINE-COUNT / NO STANDARD PAGE HEADING`

Exercises `zif_gg_list_processing_v1~get_settings`. **Blocked on #6** for the
print half of the same statement group.

```abap
REPORT zgg_ex_07 LINE-SIZE 120 LINE-COUNT 65(3) NO STANDARD PAGE HEADING.

START-OF-SELECTION.
  WRITE 'body'.
```

```abap
METHOD zif_gg_report_v1~get_list_processing.
  ro_list_processing = me.
ENDMETHOD.

METHOD zif_gg_list_processing_v1~get_settings.
  rs_settings = VALUE #(
    line_size             = 120
    line_count            = 65
    footer_lines          = 3
    no_standard_page_head = abap_true ).
ENDMETHOD.
```

### 08 — `NEW-PAGE` / `RESERVE` / `SET BLANK LINES`

Exercises `new_page`, `reserve`, `set_blank_lines`.

The report and class specimens are present. The report is excluded from the
runtime transpile until the toolchain supports `SET BLANK LINES`; this
checkbox stays open until it can run through the full gate.

```abap
REPORT zgg_ex_08.

START-OF-SELECTION.
  SET BLANK LINES ON.
  WRITE 'page one'.
  RESERVE 5 LINES.
  NEW-PAGE NO-TITLE LINE-SIZE 80.
  WRITE 'page two'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  DATA(lo_writer) = io_session->get_list( )->get_writer( ).

  lo_writer->set_blank_lines( abap_true ).
  lo_writer->write_field( VALUE #( text = 'page one' ) ).
  lo_writer->reserve( 5 ).
  lo_writer->new_page( VALUE #( no_title = abap_true line_size = 80 ) ).
  lo_writer->write_field( VALUE #( text = 'page two' ) ).
ENDMETHOD.
```

### 09 — `TOP-OF-PAGE`

Exercises `zif_gg_list_processing_v1~top_of_page`.

The report and class specimens are present. The report is excluded from the
runtime transpile until the toolchain supports `TOP-OF-PAGE`; this checkbox
stays open until it can run through the full gate.

```abap
REPORT zgg_ex_09.

TOP-OF-PAGE.
  WRITE 'header'.

START-OF-SELECTION.
  WRITE 'body'.
```

```abap
METHOD zif_gg_report_v1~get_list_processing.
  ro_list_processing = me.
ENDMETHOD.

METHOD zif_gg_list_processing_v1~top_of_page.
  io_session->get_list( )->get_writer( )->write_field(
    VALUE #( text = 'header' ) ).
ENDMETHOD.

METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_list( )->get_writer( )->write_field(
    VALUE #( text = 'body' ) ).
ENDMETHOD.
```

### 10 — `END-OF-PAGE`

Exercises `end_of_page`, together with the `footer_lines` from feature 07.

The report and class specimens are present. The report is excluded from the
runtime transpile until the toolchain supports `END-OF-PAGE`; this checkbox
stays open until it can run through the full gate.

```abap
REPORT zgg_ex_10 LINE-COUNT 10(2).

END-OF-PAGE.
  WRITE 'footer'.

START-OF-SELECTION.
  DO 30 TIMES.
    WRITE / sy-index.
  ENDDO.
```

```abap
METHOD zif_gg_list_processing_v1~get_settings.
  rs_settings = VALUE #( line_count = 10 footer_lines = 2 ).
ENDMETHOD.

METHOD zif_gg_list_processing_v1~end_of_page.
  io_session->get_list( )->get_writer( )->write_field(
    VALUE #( text = 'footer' ) ).
ENDMETHOD.
```

---

## Phase 2 — Program events

### 11 — `LOAD-OF-PROGRAM`

Exercises `load_of_program`, and pins that it runs before `initialization`.

```abap
REPORT zgg_ex_11.

LOAD-OF-PROGRAM.
  WRITE 'loaded'.

START-OF-SELECTION.
  WRITE 'started'.
```

```abap
METHOD zif_gg_report_v1~load_of_program.
  io_session->get_list( )->get_writer( )->write_field(
    VALUE #( text = 'loaded' ) ).
ENDMETHOD.
```

### 12 — `INITIALIZATION`

Exercises `initialization` and its `ct_values`.

```abap
REPORT zgg_ex_12.

PARAMETERS p_date TYPE d.

INITIALIZATION.
  p_date = '20260101'.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->add_parameter( VALUE #(
    name      = 'P_DATE'
    text      = 'Date'
    data_type = VALUE #( typ = 'D' length = 8 ) ) ).
ENDMETHOD.

METHOD zif_gg_report_v1~initialization.
  ct_values[ name = 'P_DATE' ]-value = '20260101'.
ENDMETHOD.
```

### 13 — `START-OF-SELECTION` / `END-OF-SELECTION`

Exercises both, and pins that `END-OF-SELECTION` continues the same basic list.

```abap
REPORT zgg_ex_13.

START-OF-SELECTION.
  WRITE 'select'.

END-OF-SELECTION.
  WRITE / 'done'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_list( )->get_writer( )->write_field(
    VALUE #( text = 'select' ) ).
ENDMETHOD.

METHOD zif_gg_report_v1~end_of_selection.
  io_session->get_list( )->get_writer( )->write_field( VALUE #(
    text      = 'done'
    placement = VALUE #( new_line = abap_true ) ) ).
ENDMETHOD.
```

### 14 — `STOP`

Exercises `zif_gg_session_v1~stop`, and pins that the call does not return but
`END-OF-SELECTION` still runs.

```abap
REPORT zgg_ex_14.

START-OF-SELECTION.
  WRITE 'before'.
  STOP.
  WRITE 'never reached'.

END-OF-SELECTION.
  WRITE / 'end'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_list( )->get_writer( )->write_field(
    VALUE #( text = 'before' ) ).
  io_session->stop( ).
  " unreachable, the host unwinds at the callback boundary
ENDMETHOD.
```

---

## Phase 3 — Selection screen definition

### 15 — `PARAMETERS` with `DEFAULT`

Exercises `add_parameter` and `ty_parameter-default`. **Blocked on #7** for
anything but character types.

```abap
REPORT zgg_ex_15.

PARAMETERS p_carr TYPE c LENGTH 3 DEFAULT 'LH'.

START-OF-SELECTION.
  WRITE p_carr.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->add_parameter( VALUE #(
    name      = 'P_CARR'
    text      = 'Carrier'
    data_type = VALUE #( typ = 'C' length = 3 )
    default   = 'LH' ) ).
ENDMETHOD.

METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_list( )->get_writer( )->write_field(
    VALUE #( text = it_values[ name = 'P_CARR' ]-value ) ).
ENDMETHOD.
```

### 16 — `PARAMETERS` attribute additions

Exercises the flag block of `ty_parameter`. **Blocked on #8** for the
`modif_id`/`group1..group4` half.

```abap
REPORT zgg_ex_16.

PARAMETERS p_name TYPE c LENGTH 20 OBLIGATORY LOWER CASE
                  MEMORY ID zgg MATCHCODE OBJECT zgg_sh MODIF ID abc.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->add_parameter( VALUE #(
    name        = 'P_NAME'
    text        = 'Name'
    data_type   = VALUE #( typ = 'C' length = 20 )
    obligatory  = abap_true
    lower_case  = abap_true
    memory_id   = 'ZGG'
    search_help = 'ZGG_SH'
    modif_id    = 'ABC' ) ).
ENDMETHOD.
```

### 17 — `PARAMETERS ... AS CHECKBOX`

Exercises `add_checkbox`.

```abap
REPORT zgg_ex_17.

PARAMETERS p_test AS CHECKBOX DEFAULT 'X' USER-COMMAND flip.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->add_checkbox( VALUE #(
    name    = 'P_TEST'
    text    = 'Test run'
    default = abap_true
    ucomm   = 'FLIP' ) ).
ENDMETHOD.
```

### 18 — `PARAMETERS ... RADIOBUTTON GROUP`

Exercises `add_radiobutton`, and pins that exactly one member carries the
default.

```abap
REPORT zgg_ex_18.

PARAMETERS p_all RADIOBUTTON GROUP g1 DEFAULT 'X'.
PARAMETERS p_one RADIOBUTTON GROUP g1.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->add_radiobutton( VALUE #(
    name        = 'P_ALL'
    text        = 'All'
    radio_group = 'G1'
    default     = abap_true ) ).
  io_builder->add_radiobutton( VALUE #(
    name        = 'P_ONE'
    text        = 'Single'
    radio_group = 'G1' ) ).
ENDMETHOD.
```

### 19 — `PARAMETERS ... AS LISTBOX`

Exercises `add_listbox` and `ty_fixed_values`. **Blocked on #7** for values
derived from a DDIC domain rather than listed inline.

```abap
REPORT zgg_ex_19.

PARAMETERS p_mode TYPE c LENGTH 1 AS LISTBOX VISIBLE LENGTH 10 DEFAULT 'A'.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->add_listbox( VALUE #(
    name         = 'P_MODE'
    text         = 'Mode'
    data_type    = VALUE #( typ = 'C' length = 1 visible_length = 10 )
    default      = 'A'
    fixed_values = VALUE #(
      ( key = 'A' text = 'Add' )
      ( key = 'D' text = 'Delete' ) ) ) ).
ENDMETHOD.
```

### 20 — `SELECT-OPTIONS`

Exercises `add_select_option` and `ty_select_option-default`.

The default range is implemented and tested; the checkbox stays open because
the general value conversion contract remains gap #7.

```abap
REPORT zgg_ex_20.

TABLES sflight.

SELECT-OPTIONS s_carr FOR sflight-carrid
  DEFAULT 'AA' TO 'LH' NO-EXTENSION NO INTERVALS.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->add_select_option( VALUE #(
    name         = 'S_CARR'
    text         = 'Carrier'
    data_type    = VALUE #( rollname = 'S_CARR_ID' typ = 'C' length = 3 )
    default      = VALUE #(
      sign   = zif_gg_selection_screen_types=>sign_include
      option = zif_gg_selection_screen_types=>option_bt
      low    = 'AA'
      high   = 'LH' )
    no_extension = abap_true
    no_intervals = abap_true ) ).
ENDMETHOD.
```

### 21 — `SELECTION-SCREEN COMMENT` / `ULINE` / `SKIP`

Exercises `add_comment`, `add_uline`, `add_skip`. **Blocked on #5** — the report
form uses `TEXT-001`, which has no counterpart in the scaffold.

```abap
REPORT zgg_ex_21.

SELECTION-SCREEN COMMENT /1(30) TEXT-001.
SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN ULINE /1(40).
PARAMETERS p_a TYPE c LENGTH 1.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->add_comment( VALUE #(
    name           = 'CMT1'
    text           = 'Selection criteria'
    position       = 1
    visible_length = 30 ) ).
  io_builder->add_skip( 1 ).
  io_builder->add_uline( VALUE #( position = 1 length = 40 ) ).
  io_builder->add_parameter( VALUE #(
    name      = 'P_A'
    text      = 'A'
    data_type = VALUE #( typ = 'C' length = 1 ) ) ).
ENDMETHOD.
```

### 22 — `SELECTION-SCREEN BEGIN OF BLOCK ... WITH FRAME TITLE`

Exercises `begin_block` / `end_block`, and pins that nesting is by call order.

The specimen and value-path test are present, but the checkbox remains open:
the host accepts and discards screen layout, so block nesting is not observable.

```abap
REPORT zgg_ex_22.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
  PARAMETERS p_a TYPE c LENGTH 1.
SELECTION-SCREEN END OF BLOCK b1.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->begin_block( VALUE #(
    name       = 'B1'
    title      = 'Options'
    with_frame = abap_true ) ).
  io_builder->add_parameter( VALUE #(
    name      = 'P_A'
    text      = 'A'
    data_type = VALUE #( typ = 'C' length = 1 ) ) ).
  io_builder->end_block( ).
ENDMETHOD.
```

### 23 — `SELECTION-SCREEN BEGIN OF LINE` and `POSITION`

Exercises `begin_line` / `end_line` / `set_position`.

```abap
REPORT zgg_ex_23.

SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(10) TEXT-c01.
  PARAMETERS p_low TYPE i.
  SELECTION-SCREEN POSITION 40.
  PARAMETERS p_high TYPE i.
SELECTION-SCREEN END OF LINE.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->begin_line( ).
  io_builder->add_comment( VALUE #(
    name           = 'C01'
    text           = 'Range'
    position       = 1
    visible_length = 10 ) ).
  io_builder->add_parameter( VALUE #(
    name      = 'P_LOW'
    data_type = VALUE #( typ = 'I' ) ) ).
  io_builder->set_position( 40 ).
  io_builder->add_parameter( VALUE #(
    name      = 'P_HIGH'
    data_type = VALUE #( typ = 'I' ) ) ).
  io_builder->end_line( ).
ENDMETHOD.
```

### 24 — `SELECTION-SCREEN PUSHBUTTON ... USER-COMMAND`

Exercises `add_pushbutton`, and feeds feature 30 with the `ucomm`.

```abap
REPORT zgg_ex_24.

SELECTION-SCREEN PUSHBUTTON /1(20) TEXT-p01 USER-COMMAND load.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->add_pushbutton( VALUE #(
    name     = 'PB_LOAD'
    text     = 'Load defaults'
    position = 1
    length   = 20
    ucomm    = 'LOAD' ) ).
ENDMETHOD.
```

### 25 — `SELECTION-SCREEN FUNCTION KEY`

Exercises `add_function_key`.

```abap
REPORT zgg_ex_25.

SELECTION-SCREEN FUNCTION KEY 1.

INITIALIZATION.
  sscrfields-functxt_01 = 'Extras'.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->add_function_key( VALUE #(
    number = 1
    text   = 'Extras'
    ucomm  = 'FC01' ) ).
ENDMETHOD.
```

### 26 — `SELECTION-SCREEN BEGIN OF TABBED BLOCK` and `TAB`

Exercises `begin_tabbed_block` / `add_tab` / `end_tabbed_block`, and depends on
feature 27 for the subscreens.

```abap
REPORT zgg_ex_26.

SELECTION-SCREEN BEGIN OF TABBED BLOCK tb FOR 10 LINES.
  SELECTION-SCREEN TAB (20) tab1 USER-COMMAND ut1 DEFAULT SCREEN 0100.
  SELECTION-SCREEN TAB (20) tab2 USER-COMMAND ut2 DEFAULT SCREEN 0200.
SELECTION-SCREEN END OF BLOCK tb.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->begin_tabbed_block( VALUE #( name = 'TB' lines = 10 ) ).
  io_builder->add_tab( VALUE #(
    name      = 'TAB1'
    text      = 'General'
    subscreen = '0100'
    ucomm     = 'UT1' ) ).
  io_builder->add_tab( VALUE #(
    name      = 'TAB2'
    text      = 'Detail'
    subscreen = '0200'
    ucomm     = 'UT2' ) ).
  io_builder->end_tabbed_block( ).
ENDMETHOD.
```

### 27 — `SELECTION-SCREEN BEGIN OF SCREEN nnn`

Exercises `begin_screen` / `end_screen`, both `AS WINDOW` and `AS SUBSCREEN`.

```abap
REPORT zgg_ex_27.

SELECTION-SCREEN BEGIN OF SCREEN 0500 AS WINDOW TITLE TEXT-t01.
  PARAMETERS p_b TYPE c LENGTH 1.
SELECTION-SCREEN END OF SCREEN 0500.
```

```abap
METHOD zif_gg_report_v1~build_screen.
  io_builder->begin_screen( VALUE #( number = '0500' as_window = abap_true ) ).
  io_builder->add_parameter( VALUE #(
    name      = 'P_B'
    text      = 'B'
    data_type = VALUE #( typ = 'C' length = 1 ) ) ).
  io_builder->end_screen( ).
ENDMETHOD.
```

---

## Phase 4 — Selection screen events

### 28 — `AT SELECTION-SCREEN OUTPUT` with `LOOP AT SCREEN`

Exercises `at_selection_screen_output` and `ct_states`. **Blocked on #8** —
`SCREEN-INPUT = 0` and `SCREEN-ACTIVE = 0` both collapse onto `enabled`.

```abap
REPORT zgg_ex_28.

PARAMETERS p_a TYPE c LENGTH 1.
PARAMETERS p_b TYPE c LENGTH 1 MODIF ID hid.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-group1 = 'HID'.
      screen-invisible = '1'.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
```

```abap
METHOD zif_gg_report_v1~at_selection_screen_output.
  LOOP AT ct_states ASSIGNING FIELD-SYMBOL(<ls_state>) WHERE name = 'P_B'.
    <ls_state>-visible = abap_false.
  ENDLOOP.
ENDMETHOD.
```

### 29 — `AT SELECTION-SCREEN OUTPUT` writing a parameter

Exercises `ct_values` being CHANGING on the output event, and pins that the new
value reaches the screen.

```abap
REPORT zgg_ex_29.

PARAMETERS p_cnt TYPE i.

AT SELECTION-SCREEN OUTPUT.
  p_cnt = p_cnt + 1.
```

```abap
METHOD zif_gg_report_v1~at_selection_screen_output.
  ct_values[ name = 'P_CNT' ]-value = |{ ct_values[ name = 'P_CNT' ]-value + 1 }|.
ENDMETHOD.
```

### 30 — `AT SELECTION-SCREEN`

Exercises `at_selection_screen`, its `iv_ucomm`, and that an error message
redisplays the screen.

```abap
REPORT zgg_ex_30.

PARAMETERS p_n TYPE i.

AT SELECTION-SCREEN.
  IF p_n < 0.
    MESSAGE 'must not be negative' TYPE 'E'.
  ENDIF.
```

```abap
METHOD zif_gg_report_v1~at_selection_screen.
  IF ct_values[ name = 'P_N' ]-value < 0.
    io_session->message( VALUE #(
      type = zif_gg_session_types_v1=>message_type_error
      text = 'must not be negative' ) ).
  ENDIF.
ENDMETHOD.
```

### 31 — `AT SELECTION-SCREEN ON <field>`

Exercises `at_selection_screen_on_field`, and pins that it runs before
feature 30's event and that its `ct_values` edits are visible there.

```abap
REPORT zgg_ex_31.

PARAMETERS p_carr TYPE c LENGTH 3.

AT SELECTION-SCREEN ON p_carr.
  TRANSLATE p_carr TO UPPER CASE.
```

```abap
METHOD zif_gg_report_v1~at_selection_screen_on_field.
  IF iv_name = 'P_CARR'.
    ct_values[ name = 'P_CARR' ]-value =
      to_upper( ct_values[ name = 'P_CARR' ]-value ).
  ENDIF.
ENDMETHOD.
```

### 32 — `AT SELECTION-SCREEN ON END OF <selopt>`

Exercises `at_selection_screen_on_end_of`, and that the whole range table is
available.

```abap
REPORT zgg_ex_32.

TABLES sflight.
SELECT-OPTIONS s_carr FOR sflight-carrid.

AT SELECTION-SCREEN ON END OF s_carr.
  IF lines( s_carr ) > 5.
    MESSAGE 'at most five entries' TYPE 'E'.
  ENDIF.
```

```abap
METHOD zif_gg_report_v1~at_selection_screen_on_end_of.
  IF iv_name = 'S_CARR' AND lines( ct_values[ name = 'S_CARR' ]-ranges ) > 5.
    io_session->message( VALUE #(
      type = zif_gg_session_types_v1=>message_type_error
      text = 'at most five entries' ) ).
  ENDIF.
ENDMETHOD.
```

### 33 — `AT SELECTION-SCREEN ON BLOCK`

Exercises `at_selection_screen_on_block`, using the block from feature 22.

```abap
REPORT zgg_ex_33.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
  PARAMETERS p_a TYPE c LENGTH 1.
  PARAMETERS p_b TYPE c LENGTH 1.
SELECTION-SCREEN END OF BLOCK b1.

AT SELECTION-SCREEN ON BLOCK b1.
  IF p_a IS INITIAL AND p_b IS INITIAL.
    MESSAGE 'fill one of the two' TYPE 'E'.
  ENDIF.
```

```abap
METHOD zif_gg_report_v1~at_selection_screen_on_block.
  IF iv_block = 'B1'
      AND ct_values[ name = 'P_A' ]-value IS INITIAL
      AND ct_values[ name = 'P_B' ]-value IS INITIAL.
    io_session->message( VALUE #(
      type = zif_gg_session_types_v1=>message_type_error
      text = 'fill one of the two' ) ).
  ENDIF.
ENDMETHOD.
```

### 34 — `AT SELECTION-SCREEN ON RADIOBUTTON GROUP`

Exercises `at_selection_screen_on_radio`, using the group from feature 18.

```abap
REPORT zgg_ex_34.

PARAMETERS p_all RADIOBUTTON GROUP g1 DEFAULT 'X'.
PARAMETERS p_one RADIOBUTTON GROUP g1.
PARAMETERS p_key TYPE c LENGTH 3.

AT SELECTION-SCREEN ON RADIOBUTTON GROUP g1.
  IF p_one = abap_true AND p_key IS INITIAL.
    MESSAGE 'key required for single mode' TYPE 'E'.
  ENDIF.
```

```abap
METHOD zif_gg_report_v1~at_selection_screen_on_radio.
  IF iv_group = 'G1'
      AND ct_values[ name = 'P_ONE' ]-value = abap_true
      AND ct_values[ name = 'P_KEY' ]-value IS INITIAL.
    io_session->message( VALUE #(
      type = zif_gg_session_types_v1=>message_type_error
      text = 'key required for single mode' ) ).
  ENDIF.
ENDMETHOD.
```

### 35 — `AT SELECTION-SCREEN ON VALUE-REQUEST`

Exercises `at_selection_screen_value_req`. **Blocked on #18** — the report form
routinely writes back to other fields too.

```abap
REPORT zgg_ex_35.

PARAMETERS p_carr TYPE c LENGTH 3.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_carr.
  p_carr = 'LH'.
```

```abap
METHOD zif_gg_report_v1~at_selection_screen_value_req.
  IF iv_name = 'P_CARR'.
    rt_values = VALUE #( (
      sign   = zif_gg_selection_screen_types=>sign_include
      option = zif_gg_selection_screen_types=>option_eq
      low    = 'LH' ) ).
  ENDIF.
ENDMETHOD.
```

### 36 — `AT SELECTION-SCREEN ON HELP-REQUEST`

Exercises `at_selection_screen_help_req`.

```abap
REPORT zgg_ex_36.

PARAMETERS p_carr TYPE c LENGTH 3.

AT SELECTION-SCREEN ON HELP-REQUEST FOR p_carr.
  WRITE 'Two character IATA code'.
```

```abap
METHOD zif_gg_report_v1~at_selection_screen_help_req.
  IF iv_name = 'P_CARR'.
    rv_text = 'Two character IATA code'.
  ENDIF.
ENDMETHOD.
```

### 37 — `AT SELECTION-SCREEN ON EXIT-COMMAND`

Exercises `at_selection_screen_on_exit`, and pins that the values are the
pre-transport snapshot, hence IMPORTING.

```abap
REPORT zgg_ex_37.

PARAMETERS p_a TYPE c LENGTH 1.

AT SELECTION-SCREEN ON EXIT-COMMAND.
  IF sy-ucomm = 'ECAN'.
    LEAVE PROGRAM.
  ENDIF.
```

```abap
METHOD zif_gg_report_v1~at_selection_screen_on_exit.
  IF iv_ucomm = 'ECAN'.
    io_session->get_navigation( )->leave_program( ).
  ENDIF.
ENDMETHOD.
```

### 38 — `sscrfields-ucomm` driven suppression

Exercises `suppress_dialog`, the background path through a selection screen.

```abap
REPORT zgg_ex_38.

PARAMETERS p_a TYPE c LENGTH 1 DEFAULT 'X'.

INITIALIZATION.
  sscrfields-ucomm = 'ONLI'.

AT SELECTION-SCREEN OUTPUT.
  IF sy-batch = abap_true.
    " screen is not displayed
  ENDIF.
```

```abap
METHOD zif_gg_report_v1~at_selection_screen_output.
  IF io_session->get_context( )-program-batch = abap_true.
    io_session->get_dialog( )->suppress_dialog( ).
  ENDIF.
ENDMETHOD.
```

---

## Phase 5 — Messages

### 39 — `MESSAGE <text> TYPE`

Exercises `ty_message-text` with an initial `id`.

```abap
REPORT zgg_ex_39.

START-OF-SELECTION.
  MESSAGE 'free text' TYPE 'I'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->message( VALUE #(
    type = zif_gg_session_types_v1=>message_type_info
    text = 'free text' ) ).
ENDMETHOD.
```

### 40 — `MESSAGE nnn(id) WITH`

Exercises `id`, `number` and `v1..v4`. The message class ships in this same
change, as `zgg_ex.msag.xml` next to the report — this is the exact shape
abaplint parses, and a message with no consumer does not lint, so the two
cannot be split.

```xml
<?xml version="1.0" encoding="utf-8"?>
<abapGit version="v1.0.0" serializer="LCL_OBJECT_MSAG" serializer_version="v1.0.0">
 <asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">
  <asx:values>
   <T100A>
    <ARBGB>ZGG_EX</ARBGB>
    <MASTERLANG>E</MASTERLANG>
    <STEXT>Scaffold coverage examples</STEXT>
   </T100A>
   <T100>
    <T100>
     <SPRSL>E</SPRSL>
     <ARBGB>ZGG_EX</ARBGB>
     <MSGNR>001</MSGNR>
     <TEXT>&amp;1 &amp;2</TEXT>
    </T100>
   </T100>
  </asx:values>
 </asx:abap>
</abapGit>
```

```abap
REPORT zgg_ex_40.

START-OF-SELECTION.
  MESSAGE i001(zgg_ex) WITH 'alpha' 'beta'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->message( VALUE #(
    type   = zif_gg_session_types_v1=>message_type_info
    id     = 'ZGG_EX'
    number = '001'
    v1     = 'alpha'
    v2     = 'beta' ) ).
ENDMETHOD.
```

### 41 — `MESSAGE ... TYPE 'A'` and `'X'`

Exercises the terminal message types, and pins that neither returns.

```abap
REPORT zgg_ex_41.

START-OF-SELECTION.
  MESSAGE 'giving up' TYPE 'A'.
  WRITE 'never reached'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->message( VALUE #(
    type = zif_gg_session_types_v1=>message_type_abort
    text = 'giving up' ) ).
  " unreachable, the program ends
ENDMETHOD.
```

### 42 — `MESSAGE ... DISPLAY LIKE`

Exercises `display_like`, and pins that behaviour follows `type` while
rendering follows `display_like`.

```abap
REPORT zgg_ex_42.

START-OF-SELECTION.
  MESSAGE 'looks like an error' TYPE 'S' DISPLAY LIKE 'E'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->message( VALUE #(
    type         = zif_gg_session_types_v1=>message_type_success
    text         = 'looks like an error'
    display_like = zif_gg_session_types_v1=>message_type_error ) ).
ENDMETHOD.
```

---

## Phase 6 — Interactive lists

### 43 — `HIDE` and `AT LINE-SELECTION`

Exercises `ty_write_field-hide` and `at_line_selection`, the core of the
interactive list.

```abap
REPORT zgg_ex_43.

DATA gv_id TYPE i.

START-OF-SELECTION.
  DO 3 TIMES.
    gv_id = sy-index.
    WRITE / gv_id.
    HIDE gv_id.
  ENDDO.

AT LINE-SELECTION.
  WRITE / gv_id.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  DATA(lo_writer) = io_session->get_list( )->get_writer( ).

  DO 3 TIMES.
    lo_writer->write_field( VALUE #(
      text      = |{ sy-index }|
      placement = VALUE #( new_line = abap_true )
      hide      = VALUE #( ( name = 'GV_ID' value = |{ sy-index }| ) ) ) ).
  ENDDO.
ENDMETHOD.

METHOD zif_gg_list_processing_v1~at_line_selection.
  io_session->get_list( )->get_writer( )->write_field( VALUE #(
    text      = is_line-fields[ name = 'GV_ID' ]-value
    placement = VALUE #( new_line = abap_true ) ) ).
ENDMETHOD.
```

The report and counterpart are present, but the checkbox stays open until the
transpiler supports `HIDE` and the host drives a line-selection event while
retaining HIDE fields on rendered lines.

### 44 — `SET PF-STATUS` and `AT USER-COMMAND`

Exercises `zif_gg_list_session_v1~set_status` and `at_user_command`, including
the excluded function codes.

```abap
REPORT zgg_ex_44.

START-OF-SELECTION.
  SET PF-STATUS 'LIST' EXCLUDING 'DEL'.
  WRITE 'body'.

AT USER-COMMAND.
  CASE sy-ucomm.
    WHEN 'REFR'.
      WRITE / 'refreshed'.
  ENDCASE.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_list( )->set_status( VALUE #(
    status         = 'LIST'
    excluded_ucomm = VALUE #( ( 'DEL' ) ) ) ).
  io_session->get_list( )->get_writer( )->write_field(
    VALUE #( text = 'body' ) ).
ENDMETHOD.

METHOD zif_gg_list_processing_v1~at_user_command.
  IF iv_ucomm = 'REFR'.
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text      = 'refreshed'
      placement = VALUE #( new_line = abap_true ) ) ).
  ENDIF.
ENDMETHOD.
```

The report and counterpart are present, but the checkbox stays open until the
transpiler supports `AT USER-COMMAND`, the host drives that event, and it
exposes the recorded PF-STATUS to a test.

### 45 — `SET TITLEBAR`

Exercises `zif_gg_list_session_v1~set_title`, and its static counterpart in
`ty_settings-title`.

```abap
REPORT zgg_ex_45.

START-OF-SELECTION.
  SET TITLEBAR 'MAIN'.
  WRITE 'body'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_list( )->set_title( 'MAIN' ).
  io_session->get_list( )->get_writer( )->write_field(
    VALUE #( text = 'body' ) ).
ENDMETHOD.
```

### 46 — `READ LINE` / `MODIFY LINE`

Exercises `read_line` and `modify_line`. **Blocked on #10** — `ty_line` carries
hidden fields and text, so an editable list field cannot be read back and a
per-field format cannot be rewritten.

```abap
REPORT zgg_ex_46.

START-OF-SELECTION.
  WRITE / 'row one'.

AT LINE-SELECTION.
  READ LINE 1.
  MODIFY LINE 1 LINE FORMAT INTENSIFIED ON.
```

```abap
METHOD zif_gg_list_processing_v1~at_line_selection.
  DATA(ls_line) = io_session->get_list( )->read_line( iv_index = 1 ).
  io_session->get_list( )->modify_line( ls_line ).
ENDMETHOD.
```

The report and counterpart are present, but the checkbox stays open because
the host does not drive line selection and `ty_line` lacks editable field
values; see scaffold gap #10.

### 47 — `GET CURSOR`

Exercises `zif_gg_list_session_v1~get_cursor`.

```abap
REPORT zgg_ex_47.

DATA gv_field TYPE c LENGTH 30.
DATA gv_line  TYPE i.

AT LINE-SELECTION.
  GET CURSOR FIELD gv_field LINE gv_line.
  WRITE: / gv_field, gv_line.
```

```abap
METHOD zif_gg_list_processing_v1~at_line_selection.
  DATA(ls_cursor) = io_session->get_list( )->get_cursor( ).
  DATA(lo_writer) = io_session->get_list( )->get_writer( ).

  lo_writer->write_field( VALUE #(
    text      = ls_cursor-field
    placement = VALUE #( new_line = abap_true ) ) ).
  lo_writer->write_field( VALUE #( text = |{ ls_cursor-line }| ) ).
ENDMETHOD.
```

The report and counterpart are present, but the checkbox stays open until the
host drives a line-selection event with cursor context.

### 48 — `TOP-OF-PAGE DURING LINE-SELECTION`

Exercises `top_of_page_during_line_sel`, and pins that it replaces
`top_of_page` once `level` is above zero.

```abap
REPORT zgg_ex_48.

TOP-OF-PAGE DURING LINE-SELECTION.
  WRITE 'detail header'.

START-OF-SELECTION.
  WRITE / 'row'.

AT LINE-SELECTION.
  WRITE / 'detail'.
```

```abap
METHOD zif_gg_list_processing_v1~top_of_page_during_line_sel.
  io_session->get_list( )->get_writer( )->write_field(
    VALUE #( text = |detail header, level { iv_level }| ) ).
ENDMETHOD.
```

The report and counterpart are present, but the checkbox stays open until the
transpiler supports `TOP-OF-PAGE DURING LINE-SELECTION` and the host drives
nested line selection with the corresponding page-header event.

### 49 — `AT PFnn`

Exercises `at_pf`.

```abap
REPORT zgg_ex_49.

START-OF-SELECTION.
  WRITE 'body'.

AT PF5.
  WRITE / 'pf5'.
```

```abap
METHOD zif_gg_list_processing_v1~at_pf.
  IF iv_key = 5.
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text      = 'pf5'
      placement = VALUE #( new_line = abap_true ) ) ).
ENDIF.
ENDMETHOD.
```

The report and counterpart are present, but the checkbox stays open until the
transpiler supports `AT PFnn` and the host drives the PF5 event.

### 50 — `LEAVE TO LIST-PROCESSING` / `LEAVE LIST-PROCESSING`

Exercises `enter_list_processing` and `leave_list_processing`. **Blocked on
#10** — the usual pairing with `sy-lsind` has no counterpart.

```abap
REPORT zgg_ex_50.

START-OF-SELECTION.
  LEAVE TO LIST-PROCESSING AND RETURN TO SCREEN 0.
  WRITE 'inside the list processor'.
  LEAVE LIST-PROCESSING.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  DATA(lo_list) = io_session->get_list( ).

  lo_list->enter_list_processing( ).
  lo_list->get_writer( )->write_field(
    VALUE #( text = 'inside the list processor' ) ).
  lo_list->leave_list_processing( ).
ENDMETHOD.
```

The report and counterpart are present, but the checkbox stays open because
the host intentionally reports list-processing transfers as unsupported and
does not model `sy-lsind` or list depth; see scaffold gap #10.

---

## Phase 7 — Navigation and nesting

### 51 — `CALL SELECTION-SCREEN`

Exercises `call_selection_screen` and `zif_gg_resumable_v1~resume`. This is the
first example where the class shape genuinely differs from the report: the code
after the call becomes a continuation branch.

```abap
REPORT zgg_ex_51.

SELECTION-SCREEN BEGIN OF SCREEN 0500 AS WINDOW.
  PARAMETERS p_b TYPE c LENGTH 1.
SELECTION-SCREEN END OF SCREEN 0500.

START-OF-SELECTION.
  CALL SELECTION-SCREEN 0500 STARTING AT 10 5.
  IF sy-subrc = 0.
    WRITE p_b.
  ENDIF.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_dialog( )->call_selection_screen(
    is_call         = VALUE #(
      screen = '0500'
      modal  = VALUE #( start_row = 10 start_column = 5 ) )
    is_continuation = VALUE #( id = 'AFTER_0500' ) ).
ENDMETHOD.

METHOD zif_gg_resumable_v1~resume.
  CASE is_resume-continuation-id.
    WHEN 'AFTER_0500'.
      IF is_resume-subrc = 0.
        io_session->get_list( )->get_writer( )->write_field(
          VALUE #( text = mv_p_b ) ).
      ENDIF.
  ENDCASE.
ENDMETHOD.
```

`mv_p_b` is captured in `at_selection_screen` for screen `0500`; see gap #17,
`ty_resume` returns only `subrc`.

The report and counterpart are present, but the checkbox stays open until the
transpiler supports `CALL SELECTION-SCREEN` and the host drives its resumable
continuation.

### 52 — `CALL SCREEN`

Exercises `call_screen` against a `zif_gg_dynpro_v1` program, and the modal
position.

```abap
REPORT zgg_ex_52.

START-OF-SELECTION.
  CALL SCREEN 0100 STARTING AT 5 5 ENDING AT 60 15.
  WRITE 'back'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_dialog( )->call_screen(
    is_call         = VALUE #(
      screen = '0100'
      modal  = VALUE #(
        start_row    = 5
        start_column = 5
        end_row      = 15
        end_column   = 60 ) )
    is_continuation = VALUE #( id = 'AFTER_0100' ) ).
ENDMETHOD.

METHOD zif_gg_resumable_v1~resume.
  IF is_resume-continuation-id = 'AFTER_0100'.
    io_session->get_list( )->get_writer( )->write_field(
      VALUE #( text = 'back' ) ).
  ENDIF.
ENDMETHOD.
```

### 53 — `SUBMIT`

Exercises `zif_gg_navigation_v1~submit`, and pins that it is terminal.

```abap
REPORT zgg_ex_53.

START-OF-SELECTION.
  SUBMIT zgg_ex_01.
  WRITE 'never reached'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_navigation( )->submit( VALUE #( program = 'ZGG_EX_01' ) ).
  " unreachable, the current program ends
ENDMETHOD.
```

The report and counterpart are present, but the checkbox stays open until the
host can execute the submitted program and model terminal navigation.

### 54 — `SUBMIT ... AND RETURN` with `WITH` and `USING SELECTION-SET`

Exercises `submit_and_return` and `ty_submit`. **Blocked on #3** for the variant
half — the name is carried but nothing manages variants.

```abap
REPORT zgg_ex_54.

START-OF-SELECTION.
  SUBMIT zgg_ex_20
    USING SELECTION-SET 'STANDARD'
    WITH s_carr IN VALUE #( ( sign = 'I' option = 'EQ' low = 'LH' ) )
    AND RETURN.
  WRITE 'back'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_navigation( )->submit_and_return(
    is_submit       = VALUE #(
      program = 'ZGG_EX_20'
      variant = 'STANDARD'
      values  = VALUE #( ( name   = 'S_CARR'
                           ranges = VALUE #( (
                             sign   = zif_gg_selection_screen_types=>sign_include
                             option = zif_gg_selection_screen_types=>option_eq
                             low    = 'LH' ) ) ) ) )
    is_continuation = VALUE #( id = 'AFTER_SUBMIT' ) ).
ENDMETHOD.

METHOD zif_gg_resumable_v1~resume.
  IF is_resume-continuation-id = 'AFTER_SUBMIT'.
    io_session->get_list( )->get_writer( )->write_field(
      VALUE #( text = 'back' ) ).
  ENDIF.
ENDMETHOD.
```

### 55 — `SUBMIT ... EXPORTING LIST TO MEMORY`

Exercises `list_to_memory` and `get_list_from_memory`.

```abap
REPORT zgg_ex_55.

DATA gt_list TYPE TABLE OF abaplist.

START-OF-SELECTION.
  SUBMIT zgg_ex_01 EXPORTING LIST TO MEMORY AND RETURN.
  CALL FUNCTION 'LIST_FROM_MEMORY'
    TABLES
      listobject = gt_list.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_navigation( )->submit_and_return(
    is_submit       = VALUE #(
      program        = 'ZGG_EX_01'
      list_to_memory = abap_true )
    is_continuation = VALUE #( id = 'AFTER_SUBMIT' ) ).
ENDMETHOD.

METHOD zif_gg_resumable_v1~resume.
  IF is_resume-continuation-id = 'AFTER_SUBMIT'.
    DATA(lt_lines) = io_session->get_navigation( )->get_list_from_memory( ).
    LOOP AT lt_lines INTO DATA(lv_line).
      io_session->get_list( )->get_writer( )->write_field( VALUE #(
        text      = lv_line
        placement = VALUE #( new_line = abap_true ) ) ).
    ENDLOOP.
ENDIF.
ENDMETHOD.
```

The report and counterpart are present, but the checkbox stays open until the
host executes the submitted program and implements `LIST_FROM_MEMORY`.

### 56 — `CALL TRANSACTION`

Exercises `call_transaction` and its continuation.

```abap
REPORT zgg_ex_56.

START-OF-SELECTION.
  CALL TRANSACTION 'SE38' AND SKIP FIRST SCREEN.
  WRITE 'back'.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  io_session->get_navigation( )->call_transaction(
    is_call         = VALUE #( tcode = 'SE38' skip_first_screen = abap_true )
    is_continuation = VALUE #( id = 'AFTER_TCODE' ) ).
ENDMETHOD.

METHOD zif_gg_resumable_v1~resume.
  IF is_resume-continuation-id = 'AFTER_TCODE'.
    io_session->get_list( )->get_writer( )->write_field(
      VALUE #( text = 'back' ) ).
ENDIF.
ENDMETHOD.
```

The report and counterpart are present, but the checkbox stays open until the
host executes the transaction and invokes its resumable continuation.

### 57 — `LEAVE TO TRANSACTION` / `LEAVE PROGRAM`

Exercises the two terminal navigation methods.

```abap
REPORT zgg_ex_57.

PARAMETERS p_go AS CHECKBOX.

START-OF-SELECTION.
  IF p_go = abap_true.
    LEAVE TO TRANSACTION 'SE38'.
  ELSE.
    LEAVE PROGRAM.
  ENDIF.
```

```abap
METHOD zif_gg_report_v1~start_of_selection.
  DATA(lo_nav) = io_session->get_navigation( ).

  IF it_values[ name = 'P_GO' ]-value = abap_true.
    lo_nav->leave_to_transaction( VALUE #( tcode = 'SE38' ) ).
  ELSE.
    lo_nav->leave_program( ).
  ENDIF.
ENDMETHOD.
```

### 58 — `SET SCREEN` / `LEAVE SCREEN` / `LEAVE TO SCREEN`

Exercises `set_next_screen`, `leave_screen` and `leave_to_screen`, and pins the
difference between the three. Belongs to a `zif_gg_dynpro_v1` program rather
than a report, so the report side is a dialog program.

```abap
PROGRAM zgg_ex_58.

MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'NEXT'.
      SET SCREEN 0200.
      LEAVE SCREEN.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
```

```abap
METHOD zif_gg_dynpro_v1~process_input_module.
  DATA(lo_dialog) = io_session->get_dialog( ).

  CASE is_context-ucomm.
    WHEN 'NEXT'.
      lo_dialog->set_next_screen( '0200' ).
      lo_dialog->leave_screen( ).
    WHEN 'BACK'.
      lo_dialog->leave_to_screen( '0000' ).
  ENDCASE.
ENDMETHOD.
```

---

## Phase 8 — Logical database

### 59 — `NODES` and `GET`

Exercises `get_logical_database` and `at_get`. **Blocked on #11** — without a
`get_nodes( )` the host cannot know which subtrees the program wants, so it
either over-reads or guesses.

```abap
REPORT zgg_ex_59.

NODES spfli.

GET spfli.
  WRITE / spfli-carrid.
```

```abap
METHOD zif_gg_report_v1~get_logical_database.
  rv_logical_database = 'F1S'.
ENDMETHOD.

METHOD zif_gg_report_v1~at_get.
  IF iv_node = 'SPFLI'.
    FIELD-SYMBOLS <ls_spfli> TYPE any.
    ASSIGN ir_record->* TO <ls_spfli>.
    ASSIGN COMPONENT 'CARRID' OF STRUCTURE <ls_spfli> TO FIELD-SYMBOL(<lv_carrid>).
    io_session->get_list( )->get_writer( )->write_field( VALUE #(
      text      = <lv_carrid>
      placement = VALUE #( new_line = abap_true ) ) ).
ENDIF.
ENDMETHOD.
```

The report, DDIC fixture, and counterpart are present, but the checkbox stays
open until the host exposes logical-database nodes and drives `GET` events.
The report is file-scoped out of lint issue reporting because the current
implicit-start rule classifies `NODES` as executable content, and it is excluded
from transpilation because `NODES` is unsupported there.

### 60 — `GET LATE`

Exercises `at_get_late`, and pins the ordering against `at_get` for a nested
node.

```abap
REPORT zgg_ex_60.

NODES: spfli, sflight.

GET spfli.
  WRITE / 'spfli'.

GET sflight.
  WRITE / 'sflight'.

GET spfli LATE.
  WRITE / 'spfli late'.
```

```abap
METHOD zif_gg_report_v1~at_get.
  io_session->get_list( )->get_writer( )->write_field( VALUE #(
    text      = to_lower( iv_node )
    placement = VALUE #( new_line = abap_true ) ) ).
ENDMETHOD.

METHOD zif_gg_report_v1~at_get_late.
  io_session->get_list( )->get_writer( )->write_field( VALUE #(
    text      = |{ to_lower( iv_node ) } late|
    placement = VALUE #( new_line = abap_true ) ) ).
ENDMETHOD.
```

The report, DDIC-backed node declarations, and counterpart are present, but
the checkbox stays open until the host exposes logical-database nodes and
drives the ordered `GET`/`GET LATE` events. The report is file-scoped out of
lint issue reporting for the same implicit-start classifier limitation as item
59, and excluded from transpilation because `NODES` is unsupported there.
