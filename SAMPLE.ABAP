*&---------------------------------------------------------------------*
*& Include          ZFIR_CASH_JOURNAL_SIMPLE_C01

*---------------------------------------------------------------------*
CLASS lcl_application_main IMPLEMENTATION.
  METHOD show_alv.
    init_alv( CHANGING pt_fieldcat = gt_fieldcat
                       pt_outtab   = gt_outtab[] ).
  ENDMETHOD.                    "show_alv

  METHOD register_events.
    DATA: lt_f4 TYPE lvc_t_f4,
          ls_f4 LIKE LINE OF lt_f4.

* Register F4 Event.
    CLEAR lt_f4.

    ls_f4-fieldname = 'RECEIPT_KEY'.
    ls_f4-register = abap_true.
    ls_f4-getbefore = abap_true.
    ls_f4-chngeafter = abap_true.
    APPEND ls_f4 TO lt_f4.

    go_grid->register_f4_for_fields( EXPORTING it_f4 = lt_f4 ).

* register events for abap objects (backend)
    CREATE OBJECT go_onf4.
    SET HANDLER go_onf4->on_f4 FOR go_grid. " ACTIVATION abap_true.

* Register On Enter Event.
    go_grid->register_edit_event( EXPORTING i_event_id = cl_gui_alv_grid=>mc_evt_enter ).

  ENDMETHOD.                    "register_events

  METHOD exclude_tb_functions.
    DATA ls_exclude TYPE ui_func.

    REFRESH pt_exclude.

    ls_exclude = cl_gui_alv_grid=>mc_fc_loc_insert_row.
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_loc_undo.
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_loc_copy_row.
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_sort_asc.
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_sort_dsc.
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_loc_paste_new_row.
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_subtot.
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_sum.
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_maximum.
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_minimum.
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_filter .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_average .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_print .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_loc_cut .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_loc_copy .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_loc_paste .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_pc_file .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_find .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_find_more .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_detail  .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_call_xxl  .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_check .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_html.
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_to_office.
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_view_excel  .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_view_grid  .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_word_processor  .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_send  .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_call_abc  .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_graph  .
    APPEND ls_exclude TO pt_exclude.
    ls_exclude = cl_gui_alv_grid=>mc_fc_info  .
    APPEND ls_exclude TO pt_exclude.

    IF gv_display = abap_true.
      ls_exclude = cl_gui_alv_grid=>mc_fc_loc_append_row  .
      APPEND ls_exclude TO pt_exclude.
      ls_exclude = cl_gui_alv_grid=>mc_fc_loc_delete_row  .
      APPEND ls_exclude TO pt_exclude.
    ENDIF.
  ENDMETHOD.                    "exclude_tb_functions
  METHOD build_fieldcat.

    DATA lv_out_len TYPE dd03p-outputlen VALUE '8'.

    FIELD-SYMBOLS: <fs_fcat> TYPE lvc_s_fcat.

    REFRESH: pt_fieldcat.

    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name   = 'ZFI_CR_ITEM'
        i_bypassing_buffer = 'X'
      CHANGING
        ct_fieldcat        = pt_fieldcat
      EXCEPTIONS
        OTHERS             = 1.

    CHECK sy-subrc = 0.

    IF gv_edit = abap_true OR gv_create = abap_true.
      LOOP AT pt_fieldcat ASSIGNING <fs_fcat>.
        IF <fs_fcat>-fieldname = 'RECEIPT_KEY'.
          <fs_fcat>-f4availabl = abap_true.
          <fs_fcat>-edit = abap_true.
          <fs_fcat>-outputlen = lv_out_len.
        ENDIF.

        IF <fs_fcat>-fieldname = 'AMOUNT'.
          <fs_fcat>-edit = abap_true.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.                    "build_fieldcat

  METHOD init_alv.
    DATA: lt_exclude TYPE ui_functions,
          ls_variant TYPE disvariant.

    CREATE OBJECT go_custom_container
      EXPORTING
        container_name = g_container.

    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_custom_container.

* Create Objekt to verify input values.
* (This object is already needed in form SELECT_DATA).
    CREATE OBJECT go_verifier.
    SET HANDLER go_verifier->handle_data_changed FOR go_grid.

* Build fieldcat and set columns PLANETYPE and SEATSOCC
* edit enabled.
    me->build_fieldcat( CHANGING pt_fieldcat = pt_fieldcat ).

    me->exclude_tb_functions( CHANGING pt_exclude = lt_exclude ).

    gs_layout-stylefname = 'CELLTAB'.
*    gs_layout-cwidth_opt = abap_true.
    gs_layout-col_opt = abap_true.

    ls_variant-report = sy-repid.
    ls_variant-username = sy-uname.


    CALL METHOD go_grid->set_table_for_first_display
      EXPORTING
*       i_structure_name     = 'ZFI_CR_ITEM'
        it_toolbar_excluding = lt_exclude
        is_layout            = gs_layout
        is_variant           = ls_variant
        i_save               = 'A'
      CHANGING
        it_fieldcatalog      = pt_fieldcat
        it_outtab            = pt_outtab[].

* Hide tool bar
    IF gv_edit = abap_false.

*      CALL METHOD g_grid->SET_TOOLBAR_VISIBLE
*        EXPORTING
*          VISIBLE = 0.
    ENDIF.

* register f4 for field CLASS
    register_events( ).

* Set editable cells to ready for input initially
    go_grid->set_ready_for_input( EXPORTING i_ready_for_input = 1 ).

  ENDMETHOD.                    "init_alv
ENDCLASS.                    "lcl_application_main IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS lcl_event_receiver IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_event_receiver IMPLEMENTATION.

  METHOD handle_data_changed.
* Update editable fields.
    me->update_editable_fields( er_data_changed ).

  ENDMETHOD.                    "handle_data_changed

  METHOD update_editable_fields.
    DATA: ls_good             TYPE lvc_s_modi,
          lv_receipt_key      TYPE z_receipt_key,
          lv_posting_key      TYPE bschl,
          lv_customer         TYPE kunnr,
          lv_country          TYPE land1,
          lv_one_time_account TYPE xcpdk,
          lv_style            TYPE raw4,
          lv_koart            TYPE koart,
          lv_vendor           TYPE lfa1-lifnr,
          lv_fieldname        TYPE lvc_fname,
          lv_no_val           TYPE abap_bool.

    DATA: ls_changed_data LIKE LINE OF lt_rec_buff,
          lo_struct_desc  TYPE REF TO cl_abap_structdescr,
          ls_default_val  LIKE LINE OF gt_zfi_cr_def_val,
          ls_def_item     TYPE lty_outtab.

    FIELD-SYMBOLS: <fs_change_data> LIKE LINE OF lt_rec_buff,
                   <fs_del_row>     TYPE lvc_s_moce,
                   <fs_component>   TYPE abap_compdescr,
                   <fs_val>         TYPE any,
                   <fs_cr_def_val>  LIKE LINE OF gt_zfi_cr_def_val.

    BREAK macleos.
    LOOP AT pr_data_changed->mt_deleted_rows ASSIGNING <fs_del_row>.
      DELETE lt_rec_buff WHERE row_id = <fs_del_row>-row_id.
    ENDLOOP.

    LOOP AT pr_data_changed->mt_good_cells INTO ls_good.
      CLEAR: lv_no_val.

      CASE ls_good-fieldname.
        WHEN 'POSTING_KEY'.
          CALL METHOD pr_data_changed->get_cell_value
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = ls_good-fieldname
            IMPORTING
              e_value     = lv_posting_key.
          IF lv_posting_key IS NOT INITIAL.
            SELECT SINGLE koart
              FROM tbsl
              INTO lv_koart
             WHERE bschl = lv_posting_key.
            IF sy-subrc = 0.
              IF lv_koart = 'D'.
                CALL METHOD pr_data_changed->modify_style
                  EXPORTING
                    i_row_id    = ls_good-row_id
                    i_fieldname = 'CUSTOMER'
                    i_style     = cl_gui_alv_grid=>mc_style_enabled.

                CALL METHOD pr_data_changed->modify_style
                  EXPORTING
                    i_row_id    = ls_good-row_id
                    i_fieldname = 'REF_INVOICE'
                    i_style     = cl_gui_alv_grid=>mc_style_enabled.

*                call method pr_data_changed->modify_style
*                  exporting
*                    i_row_id    = ls_good-row_id
*                    i_fieldname = 'FUND'
*                    i_style     = cl_gui_alv_grid=>mc_style_enabled.
*
*                call method pr_data_changed->modify_style
*                  exporting
*                    i_row_id    = ls_good-row_id
*                    i_fieldname = 'GRANT_NBR'
*                    i_style     = cl_gui_alv_grid=>mc_style_enabled.

*                call method pr_data_changed->modify_style
*                  exporting
*                    i_row_id    = ls_good-row_id
*                    i_fieldname = 'BUSINESS_AREA'
*                    i_style     = cl_gui_alv_grid=>mc_style_enabled.


              ELSEIF lv_koart = 'K'.
                CALL METHOD pr_data_changed->modify_style
                  EXPORTING
                    i_row_id    = ls_good-row_id
                    i_fieldname = 'VENDOR'
                    i_style     = cl_gui_alv_grid=>mc_style_enabled.

                CALL METHOD pr_data_changed->modify_style
                  EXPORTING
                    i_row_id    = ls_good-row_id
                    i_fieldname = 'REF_INVOICE'
                    i_style     = cl_gui_alv_grid=>mc_style_enabled.
              ELSEIF lv_koart = 'S'.
                CALL METHOD pr_data_changed->modify_style
                  EXPORTING
                    i_row_id    = ls_good-row_id
                    i_fieldname = 'CUSTOMER'
                    i_style     = cl_gui_alv_grid=>mc_style_disabled.

                CALL METHOD pr_data_changed->modify_style
                  EXPORTING
                    i_row_id    = ls_good-row_id
                    i_fieldname = 'VENDOR'
                    i_style     = cl_gui_alv_grid=>mc_style_disabled.

                CALL METHOD pr_data_changed->modify_style
                  EXPORTING
                    i_row_id    = ls_good-row_id
                    i_fieldname = 'REF_INVOICE'
                    i_style     = cl_gui_alv_grid=>mc_style_disabled.
              ENDIF.
            ELSE.

            ENDIF.
          ENDIF.
        WHEN 'RECEIPT_KEY'.

          CALL METHOD pr_data_changed->get_cell_value
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = ls_good-fieldname
            IMPORTING
              e_value     = lv_receipt_key.

*         Check if value for receipt key on this row has changed or not
          READ TABLE lt_rec_buff WITH TABLE KEY row_id = ls_good-row_id
            ASSIGNING <fs_change_data>.

*         We have not encountered the row, add it to the table
          IF sy-subrc <> 0.
            ls_changed_data-row_id = ls_good-row_id.
            ls_changed_data-receipt_key = lv_receipt_key.
            INSERT ls_changed_data INTO TABLE lt_rec_buff.

*         We only care if the value has changed or if it is blank
          ELSE.
            IF <fs_change_data>-receipt_key NE lv_receipt_key.
              DELETE lt_rec_buff WHERE row_id = ls_good-row_id.
              ls_changed_data-row_id = ls_good-row_id.
              ls_changed_data-receipt_key = lv_receipt_key.
              INSERT ls_changed_data INTO TABLE lt_rec_buff.
            ELSEIF <fs_change_data>-receipt_key EQ lv_receipt_key.
              CONTINUE.
            ENDIF.
          ENDIF.

*         Check to see if the receipt key exists
          READ TABLE gt_zfi_cr_def_val ASSIGNING <fs_cr_def_val>
                                       WITH KEY receipt_key = lv_receipt_key.

          IF sy-subrc <> 0.
            IF lv_receipt_key IS NOT INITIAL.
              MESSAGE i013(zfi_cj) WITH lv_receipt_key.
            ENDIF.

            lv_style = cl_gui_alv_grid=>mc_style_disabled.
            lv_no_val = abap_true.
          ELSE.
            IF <fs_cr_def_val>-editable = abap_true.
              lv_style = cl_gui_alv_grid=>mc_style_enabled.
            ELSE.
              lv_style = cl_gui_alv_grid=>mc_style_disabled.
            ENDIF.
          ENDIF.

*         When the key is changed we need to initialize the fields within the row

          lo_struct_desc ?= cl_abap_typedescr=>describe_by_name( 'ZFIT_CR_DEF_VAL' ).

          LOOP AT lo_struct_desc->components ASSIGNING <fs_component>.
            CASE <fs_component>-name.
              WHEN 'MANDT' OR 'EDITABLE' OR 'RECEIPT_KEY'.
                CONTINUE.
              WHEN OTHERS.
                lv_fieldname = <fs_component>-name.

                IF lv_no_val = abap_true.
                  ASSIGN COMPONENT <fs_component>-name OF STRUCTURE ls_default_val TO <fs_val>.
                  CHECK sy-subrc = 0.
                ELSE.
                  ASSIGN COMPONENT <fs_component>-name OF STRUCTURE <fs_cr_def_val> TO <fs_val>.
                  CHECK sy-subrc = 0.
                ENDIF.

                CALL METHOD pr_data_changed->modify_cell
                  EXPORTING
                    i_row_id    = ls_good-row_id
*                   i_tabix     =
                    i_fieldname = lv_fieldname
                    i_value     = <fs_val>.
            ENDCASE.
          ENDLOOP.


*         When the key is cleared, clear all the values in the cells and initialize them
          IF lv_receipt_key IS INITIAL.
            lo_struct_desc ?= cl_abap_typedescr=>describe_by_name( 'ZFI_CR_ITEM' ).

            LOOP AT lo_struct_desc->components ASSIGNING <fs_component>.
              IF <fs_component>-name EQ 'RECEIPT_KEY' OR <fs_component>-name EQ 'AMOUNT'.
                CONTINUE.
              ENDIF.

              lv_fieldname = <fs_component>-name.

              CALL METHOD pr_data_changed->modify_style
                EXPORTING
                  i_row_id    = ls_good-row_id
                  i_fieldname = lv_fieldname
                  i_style     = cl_gui_alv_grid=>mc_style_disabled.

              ASSIGN COMPONENT <fs_component>-name OF STRUCTURE ls_def_item TO <fs_val>.
              CHECK sy-subrc = 0.

              CALL METHOD pr_data_changed->modify_cell
                EXPORTING
                  i_row_id    = ls_good-row_id
*                 i_tabix     =
                  i_fieldname = lv_fieldname
                  i_value     = <fs_val>.
            ENDLOOP.

            CONTINUE.
          ENDIF.

*         BOC TEMP-AVADHUT
          CALL METHOD pr_data_changed->modify_cell
            EXPORTING
              i_row_id    = ls_good-row_id
*             i_tabix     =
              i_fieldname = 'BUDGET_PD'
              i_value     = ''.
*         EOC TEMP-AVADHUT

          "Clear on recp key
          CALL METHOD pr_data_changed->modify_cell
            EXPORTING
              i_row_id    = ls_good-row_id
*             i_tabix     =
              i_fieldname = 'AMOUNT'
              i_value     = ''.

          CALL METHOD pr_data_changed->modify_cell
            EXPORTING
              i_row_id    = ls_good-row_id
*             i_tabix     =
              i_fieldname = 'FKBER'
              i_value     = ''.


          CALL METHOD pr_data_changed->modify_cell
            EXPORTING
              i_row_id    = ls_good-row_id
*             i_tabix     =
              i_fieldname = 'WBS'
              i_value     = ''.

          CALL METHOD pr_data_changed->modify_cell
            EXPORTING
              i_row_id    = ls_good-row_id
*             i_tabix     =
              i_fieldname = 'CUSTOMER'
              i_value     = ''.

          CALL METHOD pr_data_changed->modify_cell
            EXPORTING
              i_row_id    = ls_good-row_id
*             i_tabix     =
              i_fieldname = 'REF_INVOICE'
              i_value     = ''.


          CALL METHOD pr_data_changed->modify_cell
            EXPORTING
              i_row_id    = ls_good-row_id
*             i_tabix     =
              i_fieldname = 'INTERNAL_ORDER'
              i_value     = ''.

          CALL METHOD pr_data_changed->modify_cell
            EXPORTING
              i_row_id    = ls_good-row_id
*             i_tabix     =
              i_fieldname = 'FISTL'
              i_value     = ''.

          CALL METHOD pr_data_changed->modify_cell
            EXPORTING
              i_row_id    = ls_good-row_id
*             i_tabix     =
              i_fieldname = 'SGTXT'
              i_value     = ''.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'SPECIAL_GL_IND'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'OTA_DATA'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'COST_CENTER'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'INTERNAL_ORDER'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'WBS'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'GL_ACCOUNT'
              i_style     = lv_style.

*          if lv_receipt_key = '0005'.
          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'FUND'
              i_style     = lv_style.  "cl_gui_alv_grid=>mc_style_enabled.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'GRANT_NBR'
              i_style     = lv_style.   "cl_gui_alv_grid=>mc_style_enabled.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'BUSINESS_AREA'
              i_style     = lv_style.   "cl_gui_alv_grid=>mc_style_enabled.

          "For New Additional Fields.
          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'FKBER'
              i_style     = lv_style.   "cl_gui_alv_grid=>mc_style_enabled.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'FISTL'
              i_style     = lv_style.   "cl_gui_alv_grid=>mc_style_enabled.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'BUDGET_PD'
              i_style     = lv_style.   "cl_gui_alv_grid=>mc_style_enabled.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'SGTXT'
              i_style     = lv_style.   "cl_gui_alv_grid=>mc_style_enabled.


*          endif.

        WHEN 'CUSTOMER'.
          CALL METHOD pr_data_changed->get_cell_value
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = ls_good-fieldname
            IMPORTING
              e_value     = lv_customer.
          IF lv_customer IS NOT INITIAL.
            SELECT SINGLE xcpdk
              FROM kna1
              INTO lv_one_time_account
             WHERE kunnr = lv_customer.
            IF sy-subrc = 0.
              IF lv_one_time_account = abap_true.
                lv_style = cl_gui_alv_grid=>mc_style_enabled.
              ELSE.
                lv_style = cl_gui_alv_grid=>mc_style_disabled.
              ENDIF.
            ELSE.
              lv_style = cl_gui_alv_grid=>mc_style_disabled.
            ENDIF.
          ELSE.
            lv_style = cl_gui_alv_grid=>mc_style_disabled.
          ENDIF.


          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'NAME1'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'NAME2'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'STREET'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'CITY'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'POSTAL_CODE'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'REGION'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'COUNTRY'
              i_style     = lv_style.

* Default to country to US if there is no value.
          CALL METHOD pr_data_changed->get_cell_value
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'COUNTRY'
            IMPORTING
              e_value     = lv_country.
          IF lv_country IS INITIAL.
            CALL METHOD pr_data_changed->modify_cell
              EXPORTING
                i_row_id    = ls_good-row_id
*               i_tabix     =
                i_fieldname = 'COUNTRY'
                i_value     = 'US'.

          ENDIF.

        WHEN 'VENDOR'.
          CLEAR: lv_vendor, lv_one_time_account.

          CALL METHOD pr_data_changed->get_cell_value
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = ls_good-fieldname
            IMPORTING
              e_value     = lv_vendor.

          IF lv_vendor IS NOT INITIAL.
            SELECT SINGLE xcpdk
              FROM lfa1
              INTO lv_one_time_account
             WHERE lifnr = lv_vendor.

            IF sy-subrc = 0.
              IF lv_one_time_account = abap_true.
                lv_style = cl_gui_alv_grid=>mc_style_enabled.
              ELSE.
                lv_style = cl_gui_alv_grid=>mc_style_disabled.
              ENDIF.
            ELSE.
              lv_style = cl_gui_alv_grid=>mc_style_disabled.
            ENDIF.
          ELSE.
            lv_style = cl_gui_alv_grid=>mc_style_disabled.
          ENDIF.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'NAME1'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'NAME2'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'STREET'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'CITY'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'POSTAL_CODE'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'REGION'
              i_style     = lv_style.

          CALL METHOD pr_data_changed->modify_style
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'COUNTRY'
              i_style     = lv_style.

* Default to country to US if there is no value.
          CALL METHOD pr_data_changed->get_cell_value
            EXPORTING
              i_row_id    = ls_good-row_id
              i_fieldname = 'COUNTRY'
            IMPORTING
              e_value     = lv_country.

          IF lv_country IS INITIAL.
            CALL METHOD pr_data_changed->modify_cell
              EXPORTING
                i_row_id    = ls_good-row_id
*               i_tabix     =
                i_fieldname = 'COUNTRY'
                i_value     = 'US'.
          ENDIF.

      ENDCASE.
    ENDLOOP.
  ENDMETHOD.                    "update_editable_fields

  METHOD clear_rec_buffer.
    CLEAR lt_rec_buff.
  ENDMETHOD.                    "clear_rec_buffer
*------------------------------------------------------
ENDCLASS.                    "lcl_event_receiver IMPLEMENTATION

****************************************************************
* LOCAL CLASSES: Implementation
****************************************************************
*===============================================================
* class lcl_application_f4 (Implementation)
*
CLASS lcl_application_f4 IMPLEMENTATION.

*§2. Implement an event handler method for event ONF4.

  METHOD on_f4.

    DATA: lt_return     TYPE tfw_ddshretval_tab,
          lv_rec_key    TYPE zfit_cr_def_val-receipt_key,
          lv_fieldvalue TYPE help_info-fldvalue.

    FIELD-SYMBOLS: <fs_return> LIKE LINE OF lt_return.

* Save event parameter as global attributes of this class
* (maybe solved differently if you use a function module!)
    f4_params-c_fieldname = e_fieldname.
    f4_params-cs_row_no = es_row_no.
    f4_params-cr_event_data = er_event_data.
    f4_params-ct_bad_cells = et_bad_cells.
    f4_params-c_display = e_display.

    IF gv_display = abap_true.
      er_event_data->m_event_handled = abap_true.
      RETURN.
    ENDIF.

    lv_fieldvalue = e_fieldvalue.

    CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
      EXPORTING
        tabname           = space
        fieldname         = space
        searchhelp        = 'ZFI_RECEIPT_KEY'
        value             = lv_fieldvalue
      TABLES
        return_tab        = lt_return
      EXCEPTIONS
        field_not_found   = 1
        no_help_for_field = 2
        inconsistent_help = 3
        no_values_found   = 4
        OTHERS            = 5.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    IF lines( lt_return ) > 0.
      READ TABLE lt_return ASSIGNING <fs_return> INDEX 1.
      lv_rec_key = <fs_return>-fieldval.

      me->populate_alv( lv_rec_key ).
    ENDIF.

*§7. Inform the ALV Grid Control that an own f4 help has been processed
*    to suppress the standard f4 help.
    er_event_data->m_event_handled = abap_true.

  ENDMETHOD.                                                "on_f4

  METHOD populate_alv.

    DATA: ls_modi          TYPE lvc_s_modi,
          lv_baseline_date TYPE char10.

    FIELD-SYMBOLS: <fs_itab>    TYPE lvc_t_modi,
                   <fs_def_val> TYPE zfit_cr_def_val.

**§  6b. Dereference attribute M_DATA into your field symbol and add
**       the selected value to the table to which this symbol points to.
    ASSIGN f4_params-cr_event_data->m_data->* TO <fs_itab>.
    CHECK sy-subrc = 0.

    ls_modi-row_id = f4_params-cs_row_no-row_id.

    READ TABLE gt_zfi_cr_def_val ASSIGNING <fs_def_val> WITH KEY receipt_key = iv_rec_key.
    CHECK sy-subrc = 0.

    ls_modi-fieldname = 'RECEIPT_KEY'.
    ls_modi-value = <fs_def_val>-receipt_key.
    APPEND ls_modi TO <fs_itab>.

    ls_modi-fieldname = 'RECEIPT_KEY_DESC'.
    ls_modi-value = <fs_def_val>-receipt_key_desc.
    APPEND ls_modi TO <fs_itab>.

    ls_modi-fieldname = 'POSTING_KEY'.
    ls_modi-value = <fs_def_val>-posting_key.
    APPEND ls_modi TO <fs_itab>.

    ls_modi-fieldname = 'GL_ACCOUNT'.
    ls_modi-value = <fs_def_val>-gl_account.
    APPEND ls_modi TO <fs_itab>.

    ls_modi-fieldname = 'SPECIAL_GL_IND'.
    ls_modi-value = <fs_def_val>-special_gl_ind.
    APPEND ls_modi TO <fs_itab>.

    ls_modi-fieldname = 'COST_CENTER'.
    ls_modi-value = <fs_def_val>-cost_center.
    APPEND ls_modi TO <fs_itab>.

    ls_modi-fieldname = 'FUND'.
    ls_modi-value = <fs_def_val>-fund.
    APPEND ls_modi TO <fs_itab>.

    ls_modi-fieldname = 'GRANT_NBR'.
    ls_modi-value = <fs_def_val>-grant_nbr.
    APPEND ls_modi TO <fs_itab>.

    ls_modi-fieldname = 'BUSINESS_AREA'.
    ls_modi-value = <fs_def_val>-business_area.
    APPEND ls_modi TO <fs_itab>.

* Convert Dates to proper format
    CALL FUNCTION 'CONVERSION_EXIT_PDATE_OUTPUT'
      EXPORTING
        input  = <fs_def_val>-baseline_date
      IMPORTING
        output = lv_baseline_date.

    ls_modi-fieldname = 'BASELINE_DATE'.
    ls_modi-value = lv_baseline_date.
    APPEND ls_modi TO <fs_itab>.
    UNASSIGN <fs_itab>.

  ENDMETHOD.                    "populate_alv

ENDCLASS.                    "lcl_application_f4 IMPLEMENTATION
*&---------------------------------------------------------------------*
*&      Module  F4_DOC_TYPE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_doc_type INPUT.
  TYPES: BEGIN OF ty_t003t,
           blart TYPE blart,
           ltext TYPE ltext_003t,
         END OF ty_t003t.

  DATA: ls_dynpread TYPE dynpread,
        lt_dynpread TYPE dynpread_t,
        lt_return   TYPE tinv_ddshretval,
        ls_t003     TYPE ty_t003t,
        lt_t003     TYPE STANDARD TABLE OF ty_t003t.

  CLEAR: lt_dynpread.

  SELECT blart, ltext
    FROM t003t INTO TABLE @lt_t003
    WHERE spras = @sy-langu.


  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
*     DDIC_STRUCTURE  = ' '
      retfield        = 'BLART'
*     PVALKEY         = ' '
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = '0100_I_DOCUMENT_TYPE'
*     stepl           = lv_dynindex
*     WINDOW_TITLE    =
*     VALUE           = ' '
      value_org       = 'S'
*     MULTIPLE_CHOICE = ' '
*     DISPLAY         = ' '
*     CALLBACK_PROGRAM       = ' '
*     CALLBACK_FORM   = ' '
*     CALLBACK_METHOD =
*     MARK_TAB        =
*   IMPORTING
*     USER_RESET      =
    TABLES
      value_tab       = lt_t003
*     FIELD_TAB       =
      return_tab      = lt_return
*     DYNPFLD_MAPPING =
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
  IF NOT lt_return IS INITIAL.
    TRY.
        DATA(lv_return) = lt_return[ 1 ]-fieldval.
      CATCH cx_sy_itab_line_not_found.
        RETURN.
    ENDTRY.
  ENDIF.

  ls_t003-blart = lv_return.

  ls_dynpread-fieldname = '0100_I_DOCUMENT_TYPE'.
  ls_dynpread-fieldvalue = ls_t003-blart.
  APPEND ls_dynpread TO lt_dynpread.


  CALL FUNCTION 'DYNP_VALUES_UPDATE'
    EXPORTING
      dyname               = sy-repid
      dynumb               = sy-dynnr
    TABLES
      dynpfields           = lt_dynpread
    EXCEPTIONS
      invalid_abapworkarea = 1
      invalid_dynprofield  = 2
      invalid_dynproname   = 3
      invalid_dynpronummer = 4
      invalid_request      = 5
      no_fielddescription  = 6
      undefind_error       = 7
      OTHERS               = 8.

  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.
ENDMODULE.
