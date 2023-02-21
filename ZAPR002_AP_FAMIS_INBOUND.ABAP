*&---------------------------------------------------------------------*
*& Report ZAPR002_AP_FAMIS_INBOUND
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zapr002_ap_famis_inbound.
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
*    Program   : Updates Tables (  )    Downloads data (  )
*                Outputs List   (  )    Generate File ( X )
*
*    Module                    : AP
*    WRICEF Object Id          : AP-I002
*    SAP Release               : S4HANA 2020
*    Logical DB                : NA
*    Transport No              : H4DK902997
*    Functional Specifications : FSD_AP-I002_FAMIS Data Update Inbound Interface
*    Technical Spec No         : TSD_AP-I002_FAMIS Data Update Inbound Interface
*    Functional Consultant     : Hwee Yeo
*    Date Created (mm-dd-yyyy) : 01-06-2022
*    Technical Consultant      : Anvit Mandke
*    Client                    : 410
*    Project Name              : DOTH
*    Company                   : InvenioLsi
*---------------------------------------------------------------------*
*    OBJECTIVE                                                        *
*---------------------------------------------------------------------*

*---------------------------------------------------------------------*
*    ASSUMPTIONS/EXCEPTIONS                                           *
*---------------------------------------------------------------------*
*
*---------------------------------------------------------------------*
*    AMENDMENT HISTORY
*---------------------------------------------------------------------*
*    SAP Release               : S4HANA 2020
*    Author                    : who has done the changes             *
*    Date                      : Date when change has done            *
*    Ticket                    : Incident/CR No                       *
*    Transport No              :                                      *
*    Reason                    : Reason for Change                    *
*---------------------------------------------------------------------*

*---------------------------------------------------------------------*
* Types
*---------------------------------------------------------------------*

TYPES : BEGIN OF ty_log_exprev,
          batch_type    TYPE char10,
          batch_dept    TYPE char16,
          batch_date    TYPE char15,
          batch_number  TYPE char13,
          batch_seq_no  TYPE char25,
          batch_dup_ind TYPE char25,
          trans_id      TYPE zapt_expend-trans_id,
          status        TYPE char30,
        END OF ty_log_exprev.

TYPES : BEGIN OF ty_log_chstrn,
          batch_type   TYPE char10,
          batch_dept   TYPE char16,
          batch_date   TYPE zapt_cashtrn-batch_dt,
          batch_number TYPE char13,
          batch_seq_no TYPE char25,
          status       TYPE char30,
        END OF ty_log_chstrn.

*TYPES : BEGIN OF ty_log_clco,
*          batch_type    TYPE char10,
*          batch_dept    TYPE char16,
*          batch_date    TYPE zapt_cashtrn-batch_dt,
*          batch_number  TYPE char13,
*          batch_seq_no  TYPE char25,
*          batch_dup_ind TYPE char25,
*          status        TYPE char30,
*        END OF ty_log_clco.

*---------------------------------------------------------------------*
* Global Data
*---------------------------------------------------------------------*
TABLES : zapt_cashtrn, zapt_expend, zapt_reven, zapt_mbp405.

DATA : gv_string TYPE string.

DATA : gt_chstrn TYPE TABLE OF zapt_cashtrn,
       gs_chstrn TYPE zapt_cashtrn.

DATA : gt_exp TYPE TABLE OF zapt_expend,
       gs_exp TYPE zapt_expend.

DATA : gt_rev TYPE TABLE OF zapt_reven,
       gs_rev TYPE zapt_reven.

DATA : gt_mbp405 TYPE TABLE OF zapt_mbp405,
       gs_mbp405 TYPE zapt_mbp405.

DATA : gt_claims TYPE TABLE OF zapt_claims,
       gs_claims TYPE zapt_claims.

DATA : gt_contr TYPE TABLE OF zapt_contracts,
       gs_contr TYPE zapt_contracts.

DATA : tty_log_exprev TYPE TABLE OF ty_log_exprev,
       tty_log_chs    TYPE TABLE OF ty_log_chstrn.
*       tty_log_clco   TYPE TABLE OF ty_log_clco.

DATA: attname    TYPE so_obj_des, "Attached File Name
      i_text     TYPE soli_tab,   "Body Content
      i_subject  TYPE so_obj_des, "Subject Content
      text1(250).                 "Body Content

DATA: pdf             TYPE rcl_bag_tline,
      wx_document_bcs TYPE REF TO cx_document_bcs,
      wx_send_req_bcs TYPE REF TO cx_send_req_bcs,
      wx_address_bcs  TYPE REF TO cx_address_bcs,
      bcs_mess        TYPE string.

DATA: gv_chs_ar    TYPE text256,
      gv_exprev_ar TYPE text256,
      gv_mbp_ar    TYPE text256,
      gv_stamp     TYPE ertsp.

*---------------------------------------------------------------------*
* Constants
*---------------------------------------------------------------------*
DATA : gc_chsfile   TYPE string VALUE '/usr/sap/trans/cash_transfer.csv',
       gc_revexp    TYPE string VALUE '/usr/sap/trans/rev_exp.csv',
       gc_mbp405    TYPE string VALUE '/usr/sap/trans/mbp405_daily.csv',
       gc_def_path  TYPE string VALUE '/usr/sap/interfaces/',
       gc_claims    TYPE string VALUE '/usr/sap/trans//claims.csv',
       gc_contracts TYPE string VALUE '/usr/sap/trans/contracts.csv',
       gc_archive   TYPE string VALUE '/FAMIS/archive/',
       gc_match     TYPE string VALUE 'Matched Successfully',
       gc_ntmatch   TYPE string VALUE 'Unable To Match',
       gc_yy        TYPE c LENGTH 2 VALUE '20',
       gc_sep       TYPE c LENGTH 1 VALUE '|',
       gc_split     TYPE c LENGTH 1 VALUE '-',
       gc_slash     TYPE c LENGTH 1 VALUE '/',
       gc_dot       TYPE c LENGTH 1 VALUE '.',
       gc_tr_typ    TYPE c LENGTH 1 VALUE 'E',
       gc_yes       TYPE c LENGTH 3 VALUE 'YES',
       gc_no        TYPE c LENGTH 2 VALUE 'NO',
       gc_na        TYPE c LENGTH 2 VALUE 'NA'.
*---------------------------------------------------------------------*
* Selection screen
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    pc_chs  AS CHECKBOX DEFAULT 'X',
    pc_rvxp AS CHECKBOX DEFAULT 'X',
    pc_mbp  AS CHECKBOX DEFAULT 'X',
    pc_clm  AS CHECKBOX DEFAULT 'X',
    pc_cont AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b1.
*---------------------------------------------------------------------*
* Start of Selection
*---------------------------------------------------------------------*
START-OF-SELECTION.
  DATA(gv_chs_flg) = abap_false.
  DATA(gv_exprev_flg) = abap_false.
  DATA(gv_mbp_flg) = abap_false.
  DATA(gv_clm_flg) = abap_false.
  DATA(gv_cont_flg) = abap_false.

  GET TIME STAMP FIELD gv_stamp.

  IF pc_chs EQ abap_true.
*    PERFORM read_chstrn.
  ELSE.
    MESSAGE 'Dont want to read Cash Transfer file data?' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF pc_rvxp EQ abap_true.
    PERFORM read_revexp.
  ELSE.
    MESSAGE 'Dont want to read Revenue Expenditure file data?' TYPE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.

**  IF pc_mbp EQ abap_true.
**    PERFORM read_mbp405.
**  ELSE.
**    MESSAGE 'Dont want to read MBP405 file data?' TYPE 'I'.
**    EXIT.
**  ENDIF.
*
*  IF pc_clm EQ abap_true.
*    PERFORM read_claims.
*  ELSE.
*    MESSAGE 'Dont want to read Claims file data?' TYPE 'I'.
*    EXIT.
*  ENDIF.
*
*  IF pc_cont EQ abap_true.
*    PERFORM read_contracts.
*  ELSE.
*    MESSAGE 'Dont want to read Contracts file data?' TYPE 'I'.
*    EXIT.
*  ENDIF.



  " To generate Logs.
  PERFORM update_log.
*&---------------------------------------------------------------------*
*& Form read_chstrn
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM read_chstrn .

  OPEN DATASET gc_chsfile FOR INPUT IN TEXT MODE ENCODING DEFAULT.
  CLEAR gv_string.
  IF sy-subrc NE 0.
    gv_chs_flg = abap_true.
    WRITE : /1 TEXT-002.
  ELSE.
    DO.
      READ DATASET gc_chsfile INTO gv_string.
      IF sy-subrc NE 0.
        EXIT.
      ELSE.
        gs_chstrn-mandt = sy-mandt.
        gs_chstrn-date_of_run = sy-datum.
        SPLIT gv_string AT gc_sep INTO gs_chstrn-batch_ty gs_chstrn-batch_dept DATA(lv_date) gs_chstrn-batch_no gs_chstrn-batch_seq gs_chstrn-batch_dup_ind gs_chstrn-fm DATA(lv_proc_dt) gs_chstrn-trans_cd
        gs_chstrn-fund gs_chstrn-zfund_desc gs_chstrn-fund_yr gs_chstrn-acct gs_chstrn-zdept gs_chstrn-zdept_desc gs_chstrn-allot_cat gs_chstrn-srce_obj gs_chstrn-zmajor_object gs_chstrn-cost_center gs_chstrn-proj_no gs_chstrn-proj_phase
        gs_chstrn-actv DATA(lv_tr) gs_chstrn-modifier gs_chstrn-reverse gs_chstrn-funds_ctl_ovrd gs_chstrn-dept_batch_refno gs_chstrn-cvn gs_chstrn-gl_acct gs_chstrn-gl_acct gs_chstrn-vendor_no gs_chstrn-vendor_sfx
        gs_chstrn-vendor_name gs_chstrn-zvendor_inv_no DATA(lv_inv_dt) gs_chstrn-doc_no gs_chstrn-doc_sfx DATA(lv_doc_dt) gs_chstrn-ref_doc_no gs_chstrn-ref_doc_sfx gs_chstrn-opt_dept_data gs_chstrn-opt_remitt_data
        gs_chstrn-warrant_no DATA(lv_net_doc) gs_chstrn-zdiv gs_chstrn-zdiv_desc gs_chstrn-mof gs_chstrn-prog_id DATA(lv_aging_sdate) gs_chstrn-payment_type_ind gs_chstrn-function gs_chstrn-gaap_fund gs_chstrn-gaap_sfund gs_chstrn-zfund_detail
        gs_chstrn-ap_type gs_chstrn-ztrans_year gs_chstrn-trans_ty gs_chstrn-zfyyyymm gs_chstrn-zf_fy_acct gs_chstrn-zbatch_type_sort DATA(lv_net_tr).

        IF gs_chstrn-batch_ty = 'B'.
          CONTINUE.
        ELSE.

          gs_chstrn-batch_seq = |{ gs_chstrn-batch_seq ALPHA = OUT  }|.

          CONCATENATE gc_yy lv_date INTO DATA(lv_batch_dt).
          CONDENSE lv_batch_dt NO-GAPS.
          gs_chstrn-batch_dt = lv_batch_dt.

          IF lv_proc_dt IS NOT INITIAL.
            REPLACE ALL OCCURRENCES OF gc_slash IN lv_proc_dt WITH gc_dot.
            CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
              EXPORTING
                date_external            = lv_proc_dt
                accept_initial_date      = abap_true
              IMPORTING
                date_internal            = gs_chstrn-proc_date
              EXCEPTIONS
                date_external_is_invalid = 1
                OTHERS                   = 2.
          ENDIF.

          IF lv_inv_dt IS NOT INITIAL.
            REPLACE ALL OCCURRENCES OF gc_slash IN lv_inv_dt WITH gc_dot.
            CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
              EXPORTING
                date_external            = lv_inv_dt
                accept_initial_date      = abap_true
              IMPORTING
                date_internal            = gs_chstrn-invoice_date
              EXCEPTIONS
                date_external_is_invalid = 1
                OTHERS                   = 2.
          ENDIF.

          IF lv_doc_dt IS NOT INITIAL.
            REPLACE ALL OCCURRENCES OF gc_slash IN lv_doc_dt WITH gc_dot.
            CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
              EXPORTING
                date_external            = lv_doc_dt
                accept_initial_date      = abap_true
              IMPORTING
                date_internal            = gs_chstrn-doc_date
              EXCEPTIONS
                date_external_is_invalid = 1
                OTHERS                   = 2.
          ENDIF.

          IF lv_aging_sdate IS NOT INITIAL.
            REPLACE ALL OCCURRENCES OF gc_slash IN lv_aging_sdate WITH gc_dot.
            CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
              EXPORTING
                date_external            = lv_aging_sdate
                accept_initial_date      = abap_true
              IMPORTING
                date_internal            = gs_chstrn-aging_start_date
              EXCEPTIONS
                date_external_is_invalid = 1
                OTHERS                   = 2.
          ENDIF.

          gs_chstrn-trans_amt = lv_tr.
          gs_chstrn-net_doc_amt = lv_net_doc.
          gs_chstrn-ztrans_amt_net = lv_net_tr.

          APPEND gs_chstrn TO gt_chstrn.
          CLEAR : gs_chstrn,
                  lv_tr,
                  lv_net_doc,
                  lv_net_tr,
                  lv_proc_dt,
                  lv_inv_dt,
                  lv_doc_dt,
                  lv_aging_sdate.
        ENDIF.
      ENDIF.
    ENDDO.
  ENDIF.
  CLOSE DATASET gc_chsfile.
*  cl_demo_output=>display_data( gt_chstrn ).

  IF gt_chstrn[] IS NOT INITIAL.
    DELETE FROM zapt_cashtrn CLIENT SPECIFIED WHERE mandt = sy-mandt.
    COMMIT WORK.
    INSERT zapt_cashtrn FROM TABLE gt_chstrn ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDIF.
  IF gt_chstrn[] IS NOT INITIAL
  AND gv_chs_flg = abap_false.

    DATA(lv_file) = 'C'.

*    PERFORM archive USING lv_file.

  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form read_revexp
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM read_revexp .

  DATA : lv_batch_ty   TYPE zapt_reven-batch_ty,
         lv_batch_dept TYPE zapt_reven-batch_dept,
         lv_batch_dt   TYPE zapt_reven-batch_dt,
         lv_batch_no   TYPE zapt_reven-batch_no,
         lv_batch_seq  TYPE zapt_reven-batch_seq,
         lv_batch_dup  TYPE zapt_reven-batch_dup_ind.

  OPEN DATASET gc_revexp FOR INPUT IN TEXT MODE ENCODING DEFAULT.
  CLEAR gv_string.
  IF sy-subrc NE 0.
    gv_exprev_flg = abap_true.
    WRITE : /1 TEXT-003.
  ELSE.
    DO.
      READ DATASET gc_revexp INTO gv_string.
      IF sy-subrc NE 0.
        EXIT.
      ELSE.
        DATA(lv_exprev) = gv_string(1).
        CASE lv_exprev.
          WHEN '1'.

            gs_rev-mandt = sy-mandt.
            SPLIT gv_string AT gc_sep INTO gs_rev-revexp gs_rev-dept gs_rev-div gs_rev-pgm_id gs_rev-mof gs_rev-appn_type gs_rev-trans_code gs_rev-f_fy_acct gs_rev-obj gs_rev-proj_no gs_rev-act DATA(lv_rev_amt) gs_rev-sfx gs_rev-vendor_no
            gs_rev-vendor_name gs_rev-invoice_no DATA(lv_rev_invdt) DATA(lv_rev_agdt) DATA(lv_rev_chdt) gs_rev-check_no gs_rev-doc gs_rev-comp_no gs_rev-dept_no gs_rev-doc_no gs_rev-opt_data gs_rev-ind_1099 gs_rev-fy_fm gs_rev-enc_fm
            DATA(lv_rev_prdt) gs_rev-trans_id.

            IF lv_rev_invdt IS NOT INITIAL.

              REPLACE ALL OCCURRENCES OF gc_slash IN lv_rev_invdt WITH gc_dot.
              CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
                EXPORTING
                  date_external            = lv_rev_invdt
                  accept_initial_date      = abap_true
                IMPORTING
                  date_internal            = gs_rev-inv_date
                EXCEPTIONS
                  date_external_is_invalid = 1
                  OTHERS                   = 2.

            ENDIF.
            IF lv_rev_agdt IS NOT INITIAL.

              REPLACE ALL OCCURRENCES OF gc_slash IN lv_rev_agdt WITH gc_dot.
              CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
                EXPORTING
                  date_external            = lv_rev_agdt
                  accept_initial_date      = abap_true
                IMPORTING
                  date_internal            = gs_rev-aging_date
                EXCEPTIONS
                  date_external_is_invalid = 1
                  OTHERS                   = 2.

            ENDIF.

            IF lv_rev_chdt IS NOT INITIAL.

              REPLACE ALL OCCURRENCES OF gc_slash IN lv_rev_chdt WITH gc_dot.
              CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
                EXPORTING
                  date_external            = lv_rev_chdt
                  accept_initial_date      = abap_true
                IMPORTING
                  date_internal            = gs_rev-check_date
                EXCEPTIONS
                  date_external_is_invalid = 1
                  OTHERS                   = 2.

            ENDIF.

            IF lv_rev_prdt IS NOT INITIAL.

              REPLACE ALL OCCURRENCES OF gc_slash IN lv_rev_prdt WITH gc_dot.
              CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
                EXPORTING
                  date_external            = lv_rev_prdt
                  accept_initial_date      = abap_true
                IMPORTING
                  date_internal            = gs_rev-proc_date
                EXCEPTIONS
                  date_external_is_invalid = 1
                  OTHERS                   = 2.

            ENDIF.

            gs_rev-amount = lv_rev_amt.
            gs_rev-batch_dept = gs_rev-trans_id(2).
            gs_rev-batch_ty = gs_rev-trans_id+2(1).
            CONCATENATE gc_yy gs_rev-trans_id+3(6) INTO lv_batch_dt.
            CONDENSE lv_batch_dt NO-GAPS.
            gs_rev-batch_dt = lv_batch_dt.
            gs_rev-batch_no = gs_rev-trans_id+9(3).
            gs_rev-batch_seq = gs_rev-trans_id+12(5).
            gs_rev-batch_seq = |{ gs_rev-batch_seq ALPHA = OUT  }|.
            gs_rev-batch_dup_ind = gs_rev-trans_id+17(1).

            APPEND gs_rev TO gt_rev.
            CLEAR : gs_rev,
                    lv_batch_dt,
                    lv_rev_amt,
                    lv_rev_chdt,
                    lv_rev_invdt,
                    lv_rev_agdt,
                    lv_rev_prdt.

          WHEN '2'.

            gs_exp-mandt = sy-mandt.
            SPLIT gv_string AT gc_sep INTO gs_exp-revexp gs_exp-dept gs_exp-div gs_exp-pgm_id gs_exp-mof gs_exp-appn_type gs_exp-trans_code gs_exp-f_fy_acct gs_exp-obj gs_exp-proj_no gs_exp-act DATA(lv_exp_amt) gs_exp-sfx gs_exp-vendor_no
            gs_exp-vendor_name gs_exp-invoice_no DATA(lv_exp_invdt) DATA(lv_exp_agdt) DATA(lv_exp_chdt) gs_exp-check_no gs_exp-doc gs_exp-comp_no gs_exp-dept_no gs_exp-doc_no gs_exp-opt_data gs_exp-ind_1099 gs_exp-fy_fm gs_exp-enc_fm
            DATA(lv_exp_prdt) gs_exp-trans_id.

            IF lv_exp_invdt IS NOT INITIAL.

              REPLACE ALL OCCURRENCES OF gc_slash IN lv_exp_invdt WITH gc_dot.
              CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
                EXPORTING
                  date_external            = lv_exp_invdt
                  accept_initial_date      = abap_true
                IMPORTING
                  date_internal            = gs_exp-inv_date
                EXCEPTIONS
                  date_external_is_invalid = 1
                  OTHERS                   = 2.

            ENDIF.
            IF lv_exp_agdt IS NOT INITIAL.

              REPLACE ALL OCCURRENCES OF gc_slash IN lv_exp_agdt WITH gc_dot.
              CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
                EXPORTING
                  date_external            = lv_exp_agdt
                  accept_initial_date      = abap_true
                IMPORTING
                  date_internal            = gs_exp-aging_date
                EXCEPTIONS
                  date_external_is_invalid = 1
                  OTHERS                   = 2.

            ENDIF.

            IF lv_exp_chdt IS NOT INITIAL.

              REPLACE ALL OCCURRENCES OF gc_slash IN lv_exp_chdt WITH gc_dot.
              CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
                EXPORTING
                  date_external            = lv_exp_chdt
                  accept_initial_date      = abap_true
                IMPORTING
                  date_internal            = gs_exp-check_date
                EXCEPTIONS
                  date_external_is_invalid = 1
                  OTHERS                   = 2.

            ENDIF.

            IF lv_exp_prdt IS NOT INITIAL.

              REPLACE ALL OCCURRENCES OF gc_slash IN lv_exp_prdt WITH gc_dot.
              CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
                EXPORTING
                  date_external            = lv_exp_prdt
                  accept_initial_date      = abap_true
                IMPORTING
                  date_internal            = gs_exp-proc_date
                EXCEPTIONS
                  date_external_is_invalid = 1
                  OTHERS                   = 2.

            ENDIF.


            gs_exp-amount = lv_exp_amt.
            gs_exp-batch_dept = gs_exp-trans_id(2).
            gs_exp-batch_ty = gs_exp-trans_id+2(1).
            CONCATENATE gc_yy gs_exp-trans_id+3(6) INTO lv_batch_dt.
            CONDENSE lv_batch_dt NO-GAPS.
            gs_exp-batch_dt = lv_batch_dt.
            gs_exp-batch_no = gs_exp-trans_id+9(3).
            gs_exp-batch_seq = gs_exp-trans_id+12(5).
            gs_exp-batch_seq = |{ gs_exp-batch_seq ALPHA = OUT  }|.
            gs_exp-batch_dup_ind = gs_exp-trans_id+17(1).

            APPEND gs_exp TO gt_exp.
            CLEAR: gs_exp,
                   lv_batch_dt,
                   lv_exp_amt,
                   lv_exp_agdt,
                   lv_exp_chdt,
                   lv_exp_invdt,
                   lv_exp_prdt.

          WHEN OTHERS.
        ENDCASE.
      ENDIF.
    ENDDO.
  ENDIF.
  CLOSE DATASET gc_revexp.
  IF gt_rev[] IS NOT INITIAL.
    DELETE FROM zapt_reven CLIENT SPECIFIED WHERE mandt = sy-mandt.
    COMMIT WORK.
    INSERT zapt_reven FROM TABLE gt_rev ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDIF.
  IF gt_exp[] IS NOT INITIAL.
    DELETE FROM zapt_expend CLIENT SPECIFIED WHERE mandt = sy-mandt.
    COMMIT WORK.
    INSERT zapt_expend FROM TABLE gt_exp ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDIF.

  IF gt_rev[] IS NOT INITIAL
    AND gt_exp[] IS NOT INITIAL
    AND gv_exprev_flg = abap_false.

    DATA(lv_file) = 'E'.

*    PERFORM archive USING lv_file.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form read_mbp405
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM read_mbp405 .

  OPEN DATASET gc_mbp405 FOR INPUT IN TEXT MODE ENCODING DEFAULT.
  CLEAR gv_string.
  IF sy-subrc NE 0.
    gv_mbp_flg = abap_true.
    WRITE : /1 TEXT-004.
  ELSE.
    DO.
      READ DATASET gc_mbp405 INTO gv_string.
      IF sy-subrc NE 0.
        EXIT.
      ELSE.
        gs_mbp405-mandt = sy-mandt.
        gs_mbp405-date_of_run = gv_stamp.
        SPLIT gv_string AT gc_sep INTO gs_mbp405-batch_type gs_mbp405-batch_dept DATA(lv_date) gs_mbp405-batch_number gs_mbp405-batch_seq_no gs_mbp405-batch_dup_ind gs_mbp405-fiscal_month DATA(lv_proc_dt) gs_mbp405-trans_code
        gs_mbp405-fund gs_mbp405-fund_desc gs_mbp405-fy gs_mbp405-apprn_acct gs_mbp405-dept gs_mbp405-dept_desc gs_mbp405-allot_cat gs_mbp405-srce_objt gs_mbp405-major_object gs_mbp405-cost_center gs_mbp405-proj_no gs_mbp405-proj_ph
        gs_mbp405-activity DATA(lv_trans_amt) gs_mbp405-m_mod gs_mbp405-r_reverse gs_mbp405-f_funds_ctl gs_mbp405-dept_btch_ref_no gs_mbp405-compt_vouch_no gs_mbp405-gl_acct gs_mbp405-sl_acct gs_mbp405-vendor_no gs_mbp405-vendor_no_sfx
        gs_mbp405-vendor_name gs_mbp405-vendor_inv_no DATA(lv_inv_dt) gs_mbp405-curr_doc_no gs_mbp405-curr_doc_no_sfx DATA(lv_doc_dt) gs_mbp405-ref_doc_no gs_mbp405-ref_doc_no_sfx gs_mbp405-opt_dept_data gs_mbp405-opt_remitt_data
        gs_mbp405-warrant_no DATA(lv_doc_amt) gs_mbp405-div gs_mbp405-div_desc gs_mbp405-mof gs_mbp405-program_id DATA(lv_asd_dt) gs_mbp405-pti gs_mbp405-function gs_mbp405-gaap_fund gs_mbp405-gaap_subfund gs_mbp405-fund_detail
        gs_mbp405-appn_type gs_mbp405-trans_year gs_mbp405-trans_type gs_mbp405-fyyyymm gs_mbp405-f_fy_acct gs_mbp405-batch_type_sort gs_mbp405-id.

        IF gs_mbp405-batch_type = 'B'.
          CONTINUE.
        ELSE.

          gs_mbp405-batch_seq_no = |{ gs_mbp405-batch_seq_no ALPHA = OUT  }|.

          CONCATENATE gc_yy lv_date INTO DATA(lv_batch_dt).
          CONDENSE lv_batch_dt NO-GAPS.
          gs_mbp405-batch_date = lv_batch_dt.

          IF lv_proc_dt IS NOT INITIAL.
            REPLACE ALL OCCURRENCES OF gc_slash IN lv_proc_dt WITH gc_dot.
            CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
              EXPORTING
                date_external            = lv_proc_dt
                accept_initial_date      = abap_true
              IMPORTING
                date_internal            = gs_mbp405-proc_date_raw
              EXCEPTIONS
                date_external_is_invalid = 1
                OTHERS                   = 2.
          ENDIF.

          IF lv_inv_dt IS NOT INITIAL.
            REPLACE ALL OCCURRENCES OF gc_slash IN lv_inv_dt WITH gc_dot.
            CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
              EXPORTING
                date_external            = lv_inv_dt
                accept_initial_date      = abap_true
              IMPORTING
                date_internal            = gs_mbp405-invoice_date
              EXCEPTIONS
                date_external_is_invalid = 1
                OTHERS                   = 2.
          ENDIF.

          IF lv_doc_dt IS NOT INITIAL.
            REPLACE ALL OCCURRENCES OF gc_slash IN lv_doc_dt WITH gc_dot.
            CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
              EXPORTING
                date_external            = lv_doc_dt
                accept_initial_date      = abap_true
              IMPORTING
                date_internal            = gs_mbp405-doc_date_raw
              EXCEPTIONS
                date_external_is_invalid = 1
                OTHERS                   = 2.
          ENDIF.

          IF lv_asd_dt IS NOT INITIAL.
            REPLACE ALL OCCURRENCES OF gc_slash IN lv_asd_dt WITH gc_dot.
            CALL FUNCTION 'CONVERT_DATE_TO_INTERNAL'
              EXPORTING
                date_external            = lv_asd_dt
                accept_initial_date      = abap_true
              IMPORTING
                date_internal            = gs_mbp405-asd_raw
              EXCEPTIONS
                date_external_is_invalid = 1
                OTHERS                   = 2.
          ENDIF.

          gs_mbp405-trans_amt = lv_trans_amt.
          gs_mbp405-net_doc_amt = lv_doc_amt.

          APPEND gs_mbp405 TO gt_mbp405.
          CLEAR gs_mbp405.
        ENDIF.
      ENDIF.
    ENDDO.
  ENDIF.
  CLOSE DATASET gc_mbp405.
*  DELETE gt_mbp405 INDEX 1.
*  cl_demo_output=>display_data( gt_mbp405 ).
  IF gt_mbp405[] IS NOT INITIAL.
    DELETE FROM zapt_mbp405 CLIENT SPECIFIED WHERE mandt = sy-mandt.
    COMMIT WORK.
    INSERT zapt_mbp405 FROM TABLE gt_mbp405 ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDIF.
  IF gt_mbp405[] IS NOT INITIAL
  AND gv_mbp_flg = abap_false.

    DATA(lv_file) = 'M'.

*    PERFORM archive USING lv_file.

  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form read_claims
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM read_claims .

  OPEN DATASET gc_claims FOR INPUT IN TEXT MODE ENCODING DEFAULT.
  CLEAR gv_string.
  IF sy-subrc NE 0.
    gv_clm_flg = abap_true.
    WRITE : /1 TEXT-015.
  ELSE.
    DO.
      READ DATASET gc_claims INTO gv_string.
      IF sy-subrc NE 0.
        EXIT.
      ELSE.
        gs_claims-mandt = sy-mandt.
        gs_claims-date_of_run = gv_stamp.
        SPLIT gv_string AT gc_sep INTO gs_claims-zdept gs_claims-zdiv gs_claims-zpgm_id gs_claims-zmof gs_claims-zappn_type gs_claims-zf_fy_acct gs_claims-zclaim_no_sfx gs_claims-zdocdate gs_claims-zvendor_no gs_claims-zvendor_name gs_claims-zobj_code
        gs_claims-zproj_no gs_claims-zact DATA(lv_encamt) DATA(lv_expndamt) DATA(lv_balance) gs_claims-zorigenc gs_claims-zadjustment gs_claims-zliquidation gs_claims-zretainage gs_claims-zenc_fm gs_claims-zcreatedate gs_claims-zperiod.

        IF gs_claims-zclaim_no_sfx = 'Claim No/Sf'.
          CONTINUE.
        ELSE.

          gs_claims-zencamount = lv_encamt.
          gs_claims-zamtexpend = lv_expndamt.
          gs_claims-zbalance = lv_balance.

          APPEND gs_claims TO gt_claims.
          CLEAR: gs_claims,
                lv_encamt,
                lv_expndamt,
                lv_balance.

        ENDIF.
      ENDIF.
    ENDDO.
  ENDIF.
  CLOSE DATASET gc_claims.
*  DELETE gt_claims INDEX 1.

  IF gt_claims[] IS NOT INITIAL.
    DELETE FROM zapt_claims CLIENT SPECIFIED WHERE mandt = sy-mandt.
    COMMIT WORK.
    INSERT zapt_claims FROM TABLE gt_claims ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form read_contracts
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM read_contracts .

  OPEN DATASET gc_contracts FOR INPUT IN TEXT MODE ENCODING DEFAULT.
  CLEAR gv_string.
  IF sy-subrc NE 0.
    gv_cont_flg = abap_true.
    WRITE : /1 TEXT-016.
  ELSE.
    DO.
      READ DATASET gc_contracts INTO gv_string.
      IF sy-subrc NE 0.
        EXIT.
      ELSE.
        gs_contr-mandt = sy-mandt.
        gs_contr-date_of_run = gv_stamp.
        SPLIT gv_string AT gc_sep INTO gs_contr-zdept gs_contr-zdiv gs_contr-zpgm_id gs_contr-zmof gs_contr-zappn_type gs_contr-zf_fy_acct gs_contr-zcontr_no_sfx gs_contr-zdocdate gs_contr-zvendor_no gs_contr-zvendor_name gs_contr-zobj_code gs_contr-zcc
        gs_contr-zproj_no gs_contr-zph gs_contr-zact DATA(lv_encamt) DATA(lv_expndamt) DATA(lv_balance) gs_contr-zorigenc gs_contr-zadjustment gs_contr-zliquidation gs_contr-zdirectexp gs_contr-zretainage gs_contr-zenc_fm gs_contr-zcreatedate
        gs_contr-zperiod gs_contr-zdescription1 gs_contr-zdescription2.

        IF gs_contr-zcontr_no_sfx = 'Contract No'.
          CONTINUE.
        ELSE.

          gs_contr-zencamount = lv_encamt.
          gs_contr-zamtexpend = lv_expndamt.
          gs_contr-zbalance = lv_balance.

          APPEND gs_contr TO gt_contr.
          CLEAR: gs_contr,
                 lv_encamt,
                 lv_expndamt,
                 lv_balance.

        ENDIF.
      ENDIF.
    ENDDO.
  ENDIF.
  CLOSE DATASET gc_contracts.
*  DELETE gt_contr INDEX 1.

  IF gt_contr[] IS NOT INITIAL.
    DELETE FROM zapt_contracts CLIENT SPECIFIED WHERE mandt = sy-mandt.
    COMMIT WORK.
    INSERT zapt_contracts FROM TABLE gt_contr ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form update_log
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM update_log .

  DATA : lt_log_exp TYPE TABLE OF ty_log_exprev,
         ls_log_exp TYPE ty_log_exprev.

  DATA : lt_log_rev TYPE TABLE OF ty_log_exprev,
         ls_log_rev TYPE ty_log_exprev.

  DATA : lt_chstrn TYPE TABLE OF zapt_cashtrn,
         ls_chstrn TYPE zapt_cashtrn.

  DATA : lt_rev TYPE TABLE OF zapt_reven,
         ls_rev TYPE zapt_reven.

  DATA : lt_exp TYPE TABLE OF zapt_expend,
         ls_exp TYPE zapt_expend.

  DATA : lt_log_chs TYPE TABLE OF ty_log_chstrn,
         ls_log_chs TYPE ty_log_chstrn.

  DATA : lt_log_claims TYPE TABLE OF ty_log_chstrn,
         ls_log_claims TYPE ty_log_chstrn.

  DATA : lt_log_contr TYPE TABLE OF ty_log_chstrn,
         ls_log_contr TYPE ty_log_chstrn.

  DATA : lt_famis_jv TYPE TABLE OF zfid_famis_jv,
         ls_famis_jv TYPE zfid_famis_jv.

  DATA : lv_fund TYPE zglt_state_jv-fund,
         lv_fy   TYPE zglt_state_jv-fyear,
         lv_acct TYPE zglt_state_jv-appn_acct,
         lv_year TYPE char4.

  DATA : ls_claims      TYPE zapt_mbp405,
         ls_contr       TYPE zapt_mbp405,
         ls_datamart_re TYPE zmmd_datamart_re.

  FREE : lt_rev[],
         lt_exp[],
         lt_chstrn,
         lt_log_rev[],
         lt_log_exp[],
         lt_log_chs[].


  SELECT
    belnr,
    dept_no,
    sfx,
    fund,
    fyear,
    appn_acct,
    rec_date,
    transcode,
    source_obj,
    proj_number,
    proj_phase,
    dept_act,
    amount
  FROM zglt_state_jv
  INTO TABLE @DATA(lt_jvfrm).                           "#EC CI_NOWHERE

*****************************Generating log for Revenue File*********************************************

  IF gt_rev[] IS NOT INITIAL.
    lt_rev[] = gt_rev[].

    LOOP AT lt_rev INTO ls_rev.
      CLEAR: ls_log_rev,
             lv_fund,
             lv_fy,
             lv_acct.

      SPLIT ls_rev-f_fy_acct AT gc_split INTO : lv_fund lv_fy lv_acct.

      ls_log_rev-batch_type = ls_rev-batch_ty.
      ls_log_rev-batch_dept = ls_rev-batch_dept.

*      CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
*        EXPORTING
*          date_internal            = ls_rev-batch_dt
*        IMPORTING
*          date_external            = ls_log_rev-batch_date
*        EXCEPTIONS
*          date_internal_is_invalid = 1
*          OTHERS                   = 2.

      ls_log_rev-batch_date = ls_rev-batch_dt+2(6).
      ls_log_rev-batch_number = ls_rev-batch_no.
      ls_log_rev-batch_seq_no = |{ ls_rev-batch_seq ALPHA = IN WIDTH = 5 }|.
      ls_log_rev-batch_dup_ind = ls_rev-batch_dup_ind.
      ls_log_rev-trans_id = ls_rev-trans_id.

      IF line_exists( lt_jvfrm[ dept_no = ls_rev-dept_no
                                transcode = ls_rev-trans_code
                                fund = lv_fund
                                fyear = lv_fy
                                appn_acct = lv_acct
                                source_obj = ls_rev-obj
                                proj_number = ls_rev-proj_no
                                dept_act = ls_rev-act
                                amount = ls_rev-amount ] ).

        ls_log_rev-status = gc_match.
        CLEAR ls_famis_jv.
        MOVE-CORRESPONDING ls_rev TO ls_famis_jv.
        ls_famis_jv-prog_id  = ls_rev-pgm_id.
        ls_famis_jv-ap_type = ls_rev-appn_type.
        ls_famis_jv-trans_cd = ls_rev-trans_code.
        ls_famis_jv-fund = lv_fund.
        ls_famis_jv-fund_yr = lv_fy.
        ls_famis_jv-acct = lv_acct.
        ls_famis_jv-srce_obj = ls_rev-obj.
        ls_famis_jv-proj = ls_rev-proj_no.
        ls_famis_jv-actv = ls_rev-act.
        ls_famis_jv-trans_amt = ls_rev-amount.
        ls_famis_jv-invoice_date = ls_rev-inv_date.
        ls_famis_jv-aging_start_date = ls_rev-aging_date.
        ls_famis_jv-doc_cc = ls_rev-doc.
        ls_famis_jv-comp_voucher_no = ls_rev-comp_no.
        ls_famis_jv-opt_remit_data = ls_rev-opt_data.

        " Updating FAMIS JV table with matching entries
        MODIFY zfid_famis_jv FROM ls_famis_jv.

      ELSE.
        ls_log_rev-status = gc_ntmatch.
      ENDIF.
      APPEND ls_log_rev TO lt_log_rev.
    ENDLOOP.

  ENDIF.

*****************************Generating log for Revenue File*********************************************

*****************************Generating log for Expenditure file*****************************************

  IF gt_exp[] IS NOT INITIAL.
    lt_exp[] = gt_exp[].
    FREE lt_famis_jv.
    DATA(lv_flg) = abap_false.
    SELECT
      zhdepbatchref,
      ztransid,
      zhtranscode,
      zhyrapprd,
      zlobj,
      zlproj,
      zlph,
      zlact,
      zlamt
      FROM zapt_swv_custom
      INTO TABLE @DATA(lt_swv).                         "#EC CI_NOWHERE

    LOOP AT lt_exp INTO ls_exp.
      CLEAR: ls_log_exp,
             lv_fund,
             lv_fy,
             lv_acct.

      SPLIT ls_exp-f_fy_acct AT gc_split INTO : lv_fund lv_fy lv_acct.

      ls_log_exp-batch_type = ls_exp-batch_ty.
      ls_log_exp-batch_dept = ls_exp-batch_dept.
*
*      CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
*        EXPORTING
*          date_internal            = ls_exp-batch_dt
*        IMPORTING
*          date_external            = ls_log_exp-batch_date
*        EXCEPTIONS
*          date_internal_is_invalid = 1
*          OTHERS                   = 2.

      ls_log_exp-batch_date = ls_exp-batch_dt+2(6).
      ls_log_exp-batch_number = ls_exp-batch_no.
      ls_log_exp-batch_seq_no = |{ ls_exp-batch_seq ALPHA = IN WIDTH = 5 }|.
      ls_log_exp-batch_dup_ind = ls_exp-batch_dup_ind.
      ls_log_exp-trans_id = ls_exp-trans_id.

      IF line_exists( lt_swv[ zhdepbatchref = ls_exp-dept_no
                              ztransid = ls_exp-trans_id
                              zhtranscode = ls_exp-trans_code
                              zhyrapprd = ls_exp-f_fy_acct
                              zlobj = ls_exp-obj
                              zlproj = ls_exp-proj_no
                              zlact = ls_exp-act
                              zlamt = ls_exp-amount ] ).

        ls_log_exp-status = gc_match.

        CLEAR ls_famis_jv.
        MOVE-CORRESPONDING ls_exp TO ls_famis_jv.
        ls_famis_jv-prog_id  = ls_exp-pgm_id.
        ls_famis_jv-ap_type = ls_exp-appn_type.
        ls_famis_jv-trans_cd = ls_exp-trans_code.
        ls_famis_jv-fund = lv_fund.
        ls_famis_jv-fund_yr = lv_fy.
        ls_famis_jv-acct = lv_acct.
        ls_famis_jv-srce_obj = ls_exp-obj.
        ls_famis_jv-proj = ls_exp-proj_no.
        ls_famis_jv-actv = ls_exp-act.
        ls_famis_jv-trans_amt = ls_exp-amount.
        ls_famis_jv-invoice_date = ls_exp-inv_date.
        ls_famis_jv-aging_start_date = ls_exp-aging_date.
        ls_famis_jv-doc_cc = ls_exp-doc.
        ls_famis_jv-comp_voucher_no = ls_exp-comp_no.
        ls_famis_jv-opt_remit_data = ls_exp-opt_data.

        APPEND ls_famis_jv TO lt_famis_jv.

        lv_flg = abap_true.

      ELSE.
        ls_log_exp-status = gc_ntmatch.
      ENDIF.
      APPEND ls_log_exp TO lt_log_exp.
    ENDLOOP.

    IF lv_flg = abap_false.
      FREE : lt_log_exp[],
             lt_famis_jv[].

      LOOP AT lt_exp INTO ls_exp.
        CLEAR: ls_log_exp,
               lv_fund,
               lv_fy,
               lv_acct.

        SPLIT ls_exp-f_fy_acct AT gc_split INTO : lv_fund lv_fy lv_acct.


        ls_log_exp-batch_type = ls_exp-batch_ty.
        ls_log_exp-batch_dept = ls_exp-batch_dept.

*        CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
*          EXPORTING
*            date_internal            = ls_exp-batch_dt
*          IMPORTING
*            date_external            = ls_log_exp-batch_date
*          EXCEPTIONS
*            date_internal_is_invalid = 1
*            OTHERS                   = 2.

        ls_log_exp-batch_date = ls_exp-batch_dt+2(6).
        ls_log_exp-batch_number = ls_exp-batch_no.
        ls_log_exp-batch_seq_no = |{ ls_exp-batch_seq ALPHA = IN WIDTH = 5 }|.
        ls_log_exp-batch_dup_ind = ls_exp-batch_dup_ind.

        ls_log_exp-trans_id = ls_exp-trans_id.
        IF line_exists( lt_jvfrm[ dept_no = ls_exp-dept_no
                                  transcode = ls_exp-trans_code
                                  fund = lv_fund
                                  fyear = lv_fy
                                  appn_acct = lv_acct
                                  source_obj = ls_exp-obj
                                  proj_number = ls_exp-proj_no
                                  dept_act = ls_exp-act
                                  amount = ls_exp-amount ] ).

          ls_log_exp-status = gc_match.

          CLEAR ls_famis_jv.
          MOVE-CORRESPONDING ls_exp TO ls_famis_jv.
          ls_famis_jv-prog_id  = ls_exp-pgm_id.
          ls_famis_jv-ap_type = ls_exp-appn_type.
          ls_famis_jv-trans_cd = ls_exp-trans_code.
          ls_famis_jv-fund = lv_fund.
          ls_famis_jv-fund_yr = lv_fy.
          ls_famis_jv-acct = lv_acct.
          ls_famis_jv-srce_obj = ls_exp-obj.
          ls_famis_jv-proj = ls_exp-proj_no.
          ls_famis_jv-actv = ls_exp-act.
          ls_famis_jv-trans_amt = ls_exp-amount.
          ls_famis_jv-invoice_date = ls_exp-inv_date.
          ls_famis_jv-aging_start_date = ls_exp-aging_date.
          ls_famis_jv-doc_cc = ls_exp-doc.
          ls_famis_jv-comp_voucher_no = ls_exp-comp_no.
          ls_famis_jv-opt_remit_data = ls_exp-opt_data.

          APPEND ls_famis_jv TO lt_famis_jv.

        ELSE.
          ls_log_exp-status = gc_ntmatch.
        ENDIF.
        APPEND ls_log_exp TO lt_log_exp.
      ENDLOOP.

    ENDIF.

    IF lt_famis_jv IS NOT INITIAL.
      MODIFY zfid_famis_jv FROM TABLE lt_famis_jv.
    ENDIF.

  ENDIF.



*****************************Generating log for Expenditure file*****************************************

*****************************Generating lof for Cash Transfer File***************************************

  IF gt_chstrn[] IS NOT INITIAL.
    lt_chstrn[] = gt_chstrn[].

    LOOP AT lt_chstrn INTO ls_chstrn.
      CLEAR: ls_log_chs,
             lv_fund,
             lv_fy,
             lv_acct.

      SPLIT ls_chstrn-zf_fy_acct AT gc_split INTO : lv_fund lv_fy lv_acct.

      ls_log_chs-batch_type = ls_chstrn-batch_ty.
      ls_log_chs-batch_dept = ls_chstrn-batch_dept.
      ls_log_chs-batch_date = ls_chstrn-batch_dt+2(6).
      ls_log_chs-batch_number = ls_chstrn-batch_no.
      ls_log_chs-batch_seq_no = ls_chstrn-batch_seq.

      IF line_exists( lt_jvfrm[ transcode = ls_chstrn-trans_cd
                                fund = lv_fund
                                fyear = lv_fy
                                appn_acct = lv_acct
                                source_obj = ls_chstrn-srce_obj
                                proj_number = ls_chstrn-proj_no
                                amount = ls_chstrn-ztrans_amt_net ] ).

        ls_log_chs-status = gc_match.
        CLEAR ls_famis_jv.
        CONCATENATE gc_yy ls_chstrn-batch_dt INTO DATA(lv_batch_dt).
        CONDENSE lv_batch_dt NO-GAPS.
        MOVE-CORRESPONDING ls_chstrn TO ls_famis_jv.
        ls_famis_jv-batch_dt = lv_batch_dt.
        MODIFY zfid_famis_jv FROM ls_famis_jv.
      ELSE.
        ls_log_chs-status = gc_ntmatch.
      ENDIF.
      APPEND ls_log_chs TO lt_log_chs.
    ENDLOOP.
  ENDIF.

*****************************Generating lof for Cash Transfer File***************************************



*****************************Generating Log for Claims and contracts file********************************


*---------------------------------------------------------------------*
* Claims data
*---------------------------------------------------------------------*
  " Getting data for comparison
  SELECT
    tech_batch_id,
    trans_code,
    fund,
    fy,
    acct,
    srce_obj,
    proj,
    proj_phase,
    actv,
    amt
    FROM zmmd_fampo_recon
    INTO TABLE @DATA(lt_fampo).                         "#EC CI_NOWHERE

  SELECT *
    FROM zapt_mbp405
    INTO TABLE @DATA(lt_claims)
    WHERE trans_type = @gc_tr_typ
    AND trans_code IN ('621','622','661') .

  IF sy-subrc EQ 0.

    LOOP AT lt_claims INTO ls_claims.
      CLEAR : ls_log_claims.

      ls_log_claims-batch_type = ls_claims-batch_type.
      ls_log_claims-batch_dept = ls_claims-batch_dept.
      ls_log_claims-batch_date = ls_claims-batch_date+2(6).
      ls_log_claims-batch_number = ls_claims-batch_number.
      ls_log_claims-batch_seq_no = ls_claims-batch_seq_no.

      DATA(lv_batch_seq_no) = |{ ls_claims-batch_seq_no ALPHA = IN  }|.
      CONCATENATE ls_claims-batch_dept ls_claims-batch_type ls_claims-batch_date+2(6) ls_claims-batch_number lv_batch_seq_no ls_claims-batch_dup_ind INTO DATA(lv_tech_batch_id).
      SPLIT ls_rev-f_fy_acct AT gc_split INTO : lv_fund lv_fy lv_acct.
      CONCATENATE gc_yy lv_fy INTO lv_year.
      IF line_exists( lt_fampo[ tech_batch_id = lv_tech_batch_id
                                trans_code = ls_claims-trans_code
                                fund = lv_fund
                                fy = lv_year
                                acct = lv_acct
                                srce_obj = ls_claims-srce_objt
                                proj = ls_claims-proj_no
                                proj_phase = ls_claims-proj_ph
                                actv = ls_claims-activity
                                amt = ls_claims-trans_amt ] ).

        ls_log_claims-status = gc_yes.
        MOVE-CORRESPONDING ls_claims TO ls_datamart_re.
        ls_datamart_re-date_of_run = gv_stamp.
        ls_datamart_re-zmatch = gc_yes.
        MODIFY zmmd_datamart_re FROM ls_datamart_re.

      ELSE.

        ls_log_claims-status = gc_no.
        MOVE-CORRESPONDING ls_claims TO ls_datamart_re.
        ls_datamart_re-date_of_run = gv_stamp.
        ls_datamart_re-zmatch = gc_no.
        MODIFY zmmd_datamart_re FROM ls_datamart_re.

      ENDIF.

      APPEND ls_log_claims TO lt_log_claims.
      CLEAR : ls_claims,
              ls_datamart_re,
              lv_batch_seq_no,
              lv_tech_batch_id,
              lv_fund,
              lv_fy,
              lv_acct,
              lv_year,
              ls_log_claims.

    ENDLOOP.
  ENDIF.

*---------------------------------------------------------------------*
* Contracts data
*---------------------------------------------------------------------*
  SELECT *
    FROM zapt_mbp405
    INTO TABLE @DATA(lt_contr)
    WHERE trans_type = @gc_tr_typ
    AND trans_code IN ('631','632','651','231','232').

  IF sy-subrc EQ 0.

    LOOP AT lt_contr INTO ls_contr.

      CLEAR : ls_log_contr.
      ls_log_contr-batch_type = ls_contr-batch_type.
      ls_log_contr-batch_dept = ls_contr-batch_dept.
      ls_log_contr-batch_date = ls_contr-batch_date+2(6).
      ls_log_contr-batch_number = ls_contr-batch_number.
      ls_log_contr-batch_seq_no = ls_contr-batch_seq_no.

      lv_batch_seq_no = |{ ls_contr-batch_seq_no ALPHA = IN  }|.
      CONCATENATE ls_contr-batch_dept ls_contr-batch_type ls_contr-batch_date+2(6) ls_contr-batch_number lv_batch_seq_no ls_contr-batch_dup_ind INTO lv_tech_batch_id.
      SPLIT ls_rev-f_fy_acct AT gc_split INTO : lv_fund lv_fy lv_acct.
      CONCATENATE gc_yy lv_fy INTO lv_year.

      IF line_exists( lt_fampo[ tech_batch_id = lv_tech_batch_id
                                trans_code = ls_contr-trans_code
                                fund = lv_fund
                                fy = lv_year
                                acct = lv_acct
                                srce_obj = ls_contr-srce_objt
                                proj = ls_contr-proj_no
                                proj_phase = ls_contr-proj_ph
                                actv = ls_contr-activity
                                amt = ls_contr-trans_amt ] ).

        ls_log_contr-status = gc_match.
        MOVE-CORRESPONDING ls_contr TO ls_datamart_re.
        ls_datamart_re-date_of_run = gv_stamp.
        ls_datamart_re-zmatch = gc_yes.
        MODIFY zmmd_datamart_re FROM ls_datamart_re.
      ELSE.
        ls_log_contr-status = gc_ntmatch.
      ENDIF.

      APPEND ls_log_contr TO lt_log_contr.

      CLEAR : ls_contr,
              ls_datamart_re,
              lv_batch_seq_no,
              lv_tech_batch_id,
              lv_fund,
              lv_fy,
              lv_acct,
              lv_year.

    ENDLOOP.

  ENDIF.

*****************************Generating Log for Claims and contracts file********************************

  " Send log files through Email
  PERFORM send_mail USING lt_log_rev lt_log_exp lt_log_chs lt_log_claims lt_log_contr.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form send_mail
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LT_LOG_REV
*&      --> LT_LOG_EXP
*&      --> LT_LOG_CHS
*&      --> LT_LOG_CLAIMS
*&      --> LT_LOG_CONTR
*&---------------------------------------------------------------------*
FORM send_mail   USING   ut_log_rev    LIKE tty_log_exprev
                         ut_log_exp    LIKE tty_log_exprev
                         ut_log_chs    LIKE tty_log_chs
                         ut_log_claims LIKE tty_log_chs
                         ut_log_contr  LIKE tty_log_chs.

  DATA: send_request   TYPE REF TO cl_bcs.
  DATA: binary_content TYPE solix_tab.
  DATA: lo_document       TYPE REF TO cl_document_bcs.
  DATA: sender         TYPE REF TO cl_sapuser_bcs.
  DATA: recipient      TYPE REF TO if_recipient_bcs.
  DATA: bcs_exception  TYPE REF TO cx_bcs.
  DATA: sent_to_all    TYPE os_boolean.
  DATA: xl_content TYPE xstring,
        l_content  TYPE string.
  DATA: ip_subject TYPE string,
        s          TYPE string.
  DATA: ls_log_rev    TYPE ty_log_exprev,
        ls_log_exp    TYPE ty_log_exprev,
        ls_log_chstr  TYPE ty_log_chstrn,
        ls_log_claims TYPE ty_log_chstrn,
        ls_log_contr  TYPE ty_log_chstrn.
  CLEAR i_text.
  CLEAR i_subject.

************************Create Mail Body************************
  " Subject of mail
  i_subject = |Summary For Inbound Interface|.
  CONCATENATE 'Cash transfer, Revenue, Expenditure, Claims and Contracts Files Summary For ' sy-datum INTO ip_subject RESPECTING BLANKS.
  text1 = '<html>'.
  APPEND text1 TO i_text.

  text1 = '<body>'.
  APPEND text1 TO i_text.

  text1 = '<p>'.
  APPEND text1 TO i_text.
  text1 = 'Dear Sir/Madam,'.
  APPEND text1 TO i_text.
  text1 = '</p>'.
  APPEND text1 TO i_text.

  text1 = '<p>'.
  APPEND text1 TO i_text.
  text1 = 'FAMIS Data Update Inbound Interface run is executed and here is the summary of the results.'.
  APPEND text1 TO i_text.
  text1 = '</p>'.
  APPEND text1 TO i_text.

  text1 = '<p></p>'.
  APPEND text1 TO i_text.

  text1 = '<p><u>FILE SUMMARY:</u></p>'.
  APPEND text1 TO i_text.
  text1 = '<p></p>'.
  APPEND text1 TO i_text.

  IF gv_chs_flg = abap_true.

    text1 = '<p><b>'.
    APPEND text1 TO i_text.
    text1 = TEXT-002.
    APPEND text1 TO i_text.
    text1 = '</b></p>'.
    APPEND text1 TO i_text.

  ELSE.

    text1 = '<p><b>'.
    APPEND text1 TO i_text.
    text1 = TEXT-005.
    APPEND text1 TO i_text.
    text1 = '</b></p>'.
    APPEND text1 TO i_text.

  ENDIF.

  IF gv_exprev_flg = abap_true.

    text1 = '<p><b>'.
    APPEND text1 TO i_text.
    text1 = TEXT-003.
    APPEND text1 TO i_text.
    text1 = '</b></p>'.
    APPEND text1 TO i_text.

  ELSE.

    text1 = '<p><b>'.
    APPEND text1 TO i_text.
    text1 = TEXT-006.
    APPEND text1 TO i_text.
    text1 = '</b></p>'.
    APPEND text1 TO i_text.

  ENDIF.

  IF gv_mbp_flg = abap_true.

    text1 = '<p><b>'.
    APPEND text1 TO i_text.
    text1 = TEXT-004.
    APPEND text1 TO i_text.
    text1 = '</b></p>'.
    APPEND text1 TO i_text.

  ELSE.


    text1 = '<p><b>'.
    APPEND text1 TO i_text.
    text1 = TEXT-007.
    APPEND text1 TO i_text.
    text1 = '</b></p>'.
    APPEND text1 TO i_text.

  ENDIF.

  text1 = '<p><u>LOG SUMMARY:</u></p>'.
  APPEND text1 TO i_text.
  text1 = '<p></p>'.
  APPEND text1 TO i_text.

  IF ut_log_rev[] IS INITIAL.

    text1 = '<p><b>'.
    APPEND text1 TO i_text.
    text1 = TEXT-008.
    APPEND text1 TO i_text.
    text1 = '</b></p>'.
    APPEND text1 TO i_text.

  ELSE.

    text1 = '<p><b>'.
    APPEND text1 TO i_text.
    text1 = TEXT-009.
    APPEND text1 TO i_text.
    text1 = '</b></p>'.
    APPEND text1 TO i_text.

  ENDIF.

  IF ut_log_exp[] IS INITIAL.

    text1 = '<p><b>'.
    APPEND text1 TO i_text.
    text1 = TEXT-010.
    APPEND text1 TO i_text.
    text1 = '</b></p>'.
    APPEND text1 TO i_text.

  ELSE.
    text1 = '<p><b>'.
    APPEND text1 TO i_text.
    text1 = TEXT-011.
    APPEND text1 TO i_text.
    text1 = '</b></p>'.
    APPEND text1 TO i_text.

  ENDIF.

  IF ut_log_chs[] IS INITIAL.

    text1 = '<p><b>'.
    APPEND text1 TO i_text.
    text1 = TEXT-012.
    APPEND text1 TO i_text.
    text1 = '</b></p>'.
    APPEND text1 TO i_text.

  ELSE.

    text1 = '<p><b>'.
    APPEND text1 TO i_text.
    text1 = TEXT-013.
    APPEND text1 TO i_text.
    text1 = '</b></p>'.
    APPEND text1 TO i_text.

  ENDIF.

  text1 = '<p></p>'.
  APPEND text1 TO i_text.
  text1 = '<p><u>'.
  APPEND text1 TO i_text.
  text1 = 'Also find Log Files Attached to this mail.'.
  APPEND text1 TO i_text.
  text1 = '</u></p>'.
  APPEND text1 TO i_text.

  text1 = '<p></p>'.
  APPEND text1 TO i_text.
  text1 = '<p>'.
  APPEND text1 TO i_text.
  text1 = 'Thank You,'.
  APPEND text1 TO i_text.
  text1 = '</p>'.
  APPEND text1 TO i_text.

  text1 = '</body>'.
  APPEND text1 TO i_text.
  text1 = '</html>'.
  APPEND text1 TO i_text.

************************Create Mail Body************************

************************Create Mail document************************
  TRY.
      send_request = cl_bcs=>create_persistent( ).

      lo_document = cl_document_bcs=>create_document(
                      i_type    = 'HTM'
                      i_text    = i_text
                      i_subject = i_subject ).
    CATCH cx_send_req_bcs INTO wx_send_req_bcs.
      bcs_mess = wx_send_req_bcs->get_text( ).

***Set Subject Long Text.
      DATA: ob_bcs TYPE REF TO cl_bcs.
      CALL METHOD ob_bcs->set_message_subject
        EXPORTING
          ip_subject = ip_subject.
  ENDTRY.
************************Create Mail document************************

  "Revenue log file attachment
  IF ut_log_rev[] IS NOT INITIAL.
    CLEAR : l_content,
            s,
            xl_content,
            binary_content.

    LOOP AT ut_log_rev INTO ls_log_rev.
      AT FIRST.
        CONCATENATE 'Batch_Type' 'Batch_Department' 'Batch_Date' 'Batch_Number' 'Batch_Sequence_Number' 'Batch_Duplicate_Indicator' 'Transaction ID' 'Status' cl_abap_char_utilities=>cr_lf INTO s SEPARATED BY cl_abap_char_utilities=>horizontal_tab.
        CONCATENATE l_content s INTO l_content.
      ENDAT.
      CONCATENATE ls_log_rev-batch_type ls_log_rev-batch_dept ls_log_rev-batch_date ls_log_rev-batch_number ls_log_rev-batch_seq_no ls_log_rev-batch_dup_ind ls_log_rev-trans_id ls_log_rev-status cl_abap_char_utilities=>cr_lf INTO s SEPARATED
BY
cl_abap_char_utilities=>horizontal_tab.
      CONCATENATE l_content s INTO l_content.
      CLEAR ls_log_rev.
    ENDLOOP.

**************generate excel FILE attachment************************ xls
    CALL FUNCTION 'HR_KR_STRING_TO_XSTRING'
      EXPORTING
        codepage_to      = '1100'
        unicode_string   = l_content
        out_len          = 0
      IMPORTING
        xstring_stream   = xl_content
      EXCEPTIONS
        invalid_codepage = 1
        invalid_string   = 2
        OTHERS           = 3.

    IF sy-subrc NE 0.
      CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
        EXPORTING
          text   = l_content
        IMPORTING
          buffer = xl_content
        EXCEPTIONS
          failed = 1
          OTHERS = 2.
    ENDIF.
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer     = xl_content
      TABLES
        binary_tab = binary_content.
    CLEAR attname.
    CONCATENATE 'REVENUE_LOG' sy-datum INTO attname SEPARATED BY '_'.
    TRY.
        CALL METHOD lo_document->add_attachment
          EXPORTING
            i_attachment_type    = 'XLS'
            i_attachment_subject = attname
            i_att_content_hex    = binary_content.
        CALL METHOD send_request->set_document( lo_document ).
      CATCH cx_document_bcs INTO wx_document_bcs.
        bcs_mess = wx_document_bcs->get_text( ).
    ENDTRY.
  ENDIF.

**************GENERATE EXCEL FILE ATTACHMENT************************ XLS

  "Expenditure log file attachment
  IF ut_log_exp[] IS NOT INITIAL.
    CLEAR : l_content,
           s,
           xl_content.
    LOOP AT ut_log_exp INTO ls_log_exp.
      AT FIRST.
        CONCATENATE 'Batch_Type' 'Batch_Department' 'Batch_Date' 'Batch_Number' 'Batch_Sequence_Number' 'Batch_Duplicate_Indicator' 'Transaction ID' 'Status' cl_abap_char_utilities=>cr_lf INTO s SEPARATED BY cl_abap_char_utilities=>horizontal_tab.
        CONCATENATE l_content s INTO l_content.
      ENDAT.

      CONCATENATE ls_log_exp-batch_type ls_log_exp-batch_dept ls_log_exp-batch_date ls_log_exp-batch_number ls_log_exp-batch_seq_no ls_log_exp-batch_dup_ind ls_log_exp-trans_id ls_log_exp-status cl_abap_char_utilities=>cr_lf INTO s SEPARATED BY
cl_abap_char_utilities=>horizontal_tab.
      CONCATENATE l_content s INTO l_content.
      CLEAR ls_log_exp.
    ENDLOOP.
**************generate excel FILE attachment************************ xls
    CALL FUNCTION 'HR_KR_STRING_TO_XSTRING'
      EXPORTING
        codepage_to      = '1100'
        unicode_string   = l_content
        out_len          = 0
      IMPORTING
        xstring_stream   = xl_content
      EXCEPTIONS
        invalid_codepage = 1
        invalid_string   = 2
        OTHERS           = 3.

    IF sy-subrc NE 0.
      CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
        EXPORTING
          text   = l_content
        IMPORTING
          buffer = xl_content
        EXCEPTIONS
          failed = 1
          OTHERS = 2.
    ENDIF.
    REFRESH: binary_content.
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer     = xl_content
      TABLES
        binary_tab = binary_content.
    CLEAR attname.
    CONCATENATE 'EXPENDITURE_LOG' sy-datum INTO attname SEPARATED BY '_'.
    TRY.
        CALL METHOD lo_document->add_attachment
          EXPORTING
            i_attachment_type    = 'XLS'
            i_attachment_subject = attname
            i_att_content_hex    = binary_content.
        CALL METHOD send_request->set_document( lo_document ).
      CATCH cx_document_bcs INTO wx_document_bcs.
        bcs_mess = wx_document_bcs->get_text( ).
    ENDTRY.
  ENDIF.

**************GENERATE EXCEL FILE ATTACHMENT************************ XLS

  " Cash Transfer log file attachment
  IF ut_log_chs[] IS NOT INITIAL.
    CLEAR : l_content,
            s,
            xl_content.
    LOOP AT ut_log_chs INTO ls_log_chstr.
      AT FIRST.
        CONCATENATE 'Batch_Type' 'Batch_Department' 'Batch_Date' 'Batch_Number' 'Batch_Sequence_Number' 'Status' cl_abap_char_utilities=>cr_lf INTO s SEPARATED BY cl_abap_char_utilities=>horizontal_tab.
        CONCATENATE l_content s INTO l_content.
      ENDAT.

      CONCATENATE ls_log_chstr-batch_type ls_log_chstr-batch_dept ls_log_chstr-batch_date ls_log_chstr-batch_number ls_log_chstr-batch_seq_no ls_log_chstr-status cl_abap_char_utilities=>cr_lf INTO s SEPARATED BY cl_abap_char_utilities=>horizontal_tab.
      CONCATENATE l_content s INTO l_content.
    ENDLOOP.
**************generate excel FILE attachment************************ xls
    CALL FUNCTION 'HR_KR_STRING_TO_XSTRING'
      EXPORTING
        codepage_to      = '1100'
        unicode_string   = l_content
        out_len          = 0
      IMPORTING
        xstring_stream   = xl_content
      EXCEPTIONS
        invalid_codepage = 1
        invalid_string   = 2
        OTHERS           = 3.

    IF sy-subrc NE 0.
      CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
        EXPORTING
          text   = l_content
        IMPORTING
          buffer = xl_content
        EXCEPTIONS
          failed = 1
          OTHERS = 2.
    ENDIF.
    REFRESH: binary_content.
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer     = xl_content
      TABLES
        binary_tab = binary_content.
    CLEAR attname.
    CONCATENATE 'CASH_TRANSFER_LOG' sy-datum INTO attname SEPARATED BY '_'.
    TRY.
        CALL METHOD lo_document->add_attachment
          EXPORTING
            i_attachment_type    = 'XLS'
            i_attachment_subject = attname
            i_att_content_hex    = binary_content.
        CALL METHOD send_request->set_document( lo_document ).
      CATCH cx_document_bcs INTO wx_document_bcs.
        bcs_mess = wx_document_bcs->get_text( ).
    ENDTRY.
  ENDIF.



**************GENERATE EXCEL FILE ATTACHMENT************************ XLS


**************GENERATE EXCEL FILE ATTACHMENT************************ XLS

  " Claims log file attachment
  IF ut_log_claims[] IS NOT INITIAL.
    CLEAR : l_content,
            s,
            xl_content.
    LOOP AT ut_log_claims INTO ls_log_claims.
      AT FIRST.
        CONCATENATE 'Batch_Type' 'Batch_Department' 'Batch_Date' 'Batch_Number' 'Batch_Sequence_Number' 'Status' cl_abap_char_utilities=>cr_lf INTO s SEPARATED BY cl_abap_char_utilities=>horizontal_tab.
        CONCATENATE l_content s INTO l_content.
      ENDAT.

      CONCATENATE ls_log_chstr-batch_type ls_log_chstr-batch_dept ls_log_chstr-batch_date ls_log_chstr-batch_number ls_log_chstr-batch_seq_no ls_log_chstr-status cl_abap_char_utilities=>cr_lf INTO s SEPARATED BY cl_abap_char_utilities=>horizontal_tab.
      CONCATENATE l_content s INTO l_content.
    ENDLOOP.
**************generate excel FILE attachment************************ xls
    CALL FUNCTION 'HR_KR_STRING_TO_XSTRING'
      EXPORTING
        codepage_to      = '1100'
        unicode_string   = l_content
        out_len          = 0
      IMPORTING
        xstring_stream   = xl_content
      EXCEPTIONS
        invalid_codepage = 1
        invalid_string   = 2
        OTHERS           = 3.

    IF sy-subrc NE 0.
      CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
        EXPORTING
          text   = l_content
        IMPORTING
          buffer = xl_content
        EXCEPTIONS
          failed = 1
          OTHERS = 2.
    ENDIF.
    REFRESH: binary_content.
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer     = xl_content
      TABLES
        binary_tab = binary_content.
    CLEAR attname.
    CONCATENATE 'CLAIMS_LOG' sy-datum INTO attname SEPARATED BY '_'.
    TRY.
        CALL METHOD lo_document->add_attachment
          EXPORTING
            i_attachment_type    = 'XLS'
            i_attachment_subject = attname
            i_att_content_hex    = binary_content.
        CALL METHOD send_request->set_document( lo_document ).
      CATCH cx_document_bcs INTO wx_document_bcs.
        bcs_mess = wx_document_bcs->get_text( ).
    ENDTRY.

**************GENERATE EXCEL FILE ATTACHMENT************************ XLS
  ENDIF.

************************Create Mail document************************

  "Contracts log file attachment
  IF ut_log_contr[] IS NOT INITIAL.
    CLEAR : l_content,
            s,
            xl_content,
            binary_content.

    LOOP AT ut_log_contr INTO ls_log_contr.
      AT FIRST.
        CONCATENATE 'Batch_Type' 'Batch_Department' 'Batch_Date' 'Batch_Number' 'Batch_Sequence_Number' 'Status' cl_abap_char_utilities=>cr_lf INTO s SEPARATED BY cl_abap_char_utilities=>horizontal_tab.
        CONCATENATE l_content s INTO l_content.
      ENDAT.
      CONCATENATE ls_log_contr-batch_type ls_log_contr-batch_dept ls_log_contr-batch_date ls_log_contr-batch_number ls_log_contr-batch_seq_no ls_log_contr-status cl_abap_char_utilities=>cr_lf INTO s
SEPARATED
BY
cl_abap_char_utilities=>horizontal_tab.
      CONCATENATE l_content s INTO l_content.
      CLEAR ls_log_contr.
    ENDLOOP.

**************generate excel FILE attachment************************ xls
    CALL FUNCTION 'HR_KR_STRING_TO_XSTRING'
      EXPORTING
        codepage_to      = '1100'
        unicode_string   = l_content
        out_len          = 0
      IMPORTING
        xstring_stream   = xl_content
      EXCEPTIONS
        invalid_codepage = 1
        invalid_string   = 2
        OTHERS           = 3.

    IF sy-subrc NE 0.
      CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
        EXPORTING
          text   = l_content
        IMPORTING
          buffer = xl_content
        EXCEPTIONS
          failed = 1
          OTHERS = 2.
    ENDIF.
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING
        buffer     = xl_content
      TABLES
        binary_tab = binary_content.
    CLEAR attname.
    CONCATENATE 'CCONTRACTS_LOG' sy-datum INTO attname SEPARATED BY '_'.
    TRY.
        CALL METHOD lo_document->add_attachment
          EXPORTING
            i_attachment_type    = 'XLS'
            i_attachment_subject = attname
            i_att_content_hex    = binary_content.
        CALL METHOD send_request->set_document( lo_document ).
      CATCH cx_document_bcs INTO wx_document_bcs.
        bcs_mess = wx_document_bcs->get_text( ).
    ENDTRY.
  ENDIF.

**************GENERATE EXCEL FILE ATTACHMENT************************ XLS


**********ASSIGN SENDER MAIL ADDRESS*****************************************
  DATA: lo_sender TYPE REF TO if_sender_bcs VALUE IS INITIAL.
  TRY.
      lo_sender = cl_cam_address_bcs=>create_internet_address( i_address_string = 'abc@gmail.com'
       i_address_name = 'TEST' ).

      send_request->set_sender(
      EXPORTING
      i_sender = lo_sender ).
    CATCH cx_address_bcs INTO wx_address_bcs.
      bcs_mess = wx_address_bcs->get_text( ).
  ENDTRY.

  TRY.
      recipient = cl_cam_address_bcs=>create_internet_address( 'abc@gmail.com' ).
      CALL METHOD send_request->add_recipient
        EXPORTING
          i_recipient = recipient
          i_express   = 'X'.
    CATCH cx_address_bcs INTO wx_address_bcs.
      bcs_mess = wx_address_bcs->get_text( ).
  ENDTRY.
**********ASSIGN SENDER MAIL ADDRESS*****************************************



**********Send Mail*****************************************

  TRY.
      CALL METHOD send_request->send(
        EXPORTING
          i_with_error_screen = 'X'
        RECEIVING
          result              = sent_to_all ).
      COMMIT WORK.
      IF sy-subrc = 0.
        WRITE : /1 'Mail sent successfully!!'.
      ELSE.
      ENDIF.
    CATCH cx_send_req_bcs INTO wx_send_req_bcs.
      bcs_mess = wx_send_req_bcs->get_text( ).
  ENDTRY.
**********Send Mail*****************************************

ENDFORM.
*&---------------------------------------------------------------------*
*& Form archive
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_FILE
*&---------------------------------------------------------------------*
FORM archive  USING uv_file.

  DATA : lv_target TYPE saepathful,
         lv_source TYPE saepathful.
  DATA : lv_file  TYPE string.

  CLEAR: lv_target, lv_source, lv_file, gv_exprev_ar, gv_chs_ar, gv_mbp_ar.

  IF uv_file = 'E'.

    lv_source = gc_revexp.
    lv_target = gc_def_path && sy-mandt && gc_archive.
    lv_file = gv_stamp.
    CONDENSE lv_file NO-GAPS.
    CONCATENATE 'REV_EXP_ARCH_' lv_file '.CSV' INTO lv_file.
    lv_target = lv_target && lv_file.

    gv_exprev_ar = lv_target.

    CALL FUNCTION 'ZFM_ARCHIVE_SERVER_TO_SERVER'
      EXPORTING
        sourcepath        = lv_source
        targetpath        = lv_target
        remove_sourcefile = 'X'
*     IMPORTING
*       LENGTH            =
      EXCEPTIONS
        error             = 1
        OTHERS            = 2.
    IF sy-subrc = 0.
      WRITE : /1 TEXT-014, 16 gv_exprev_ar.
    ENDIF.

  ELSEIF uv_file = 'C'.

    lv_source = gc_chsfile.
    lv_target = gc_def_path && sy-mandt && gc_archive.
    lv_file = gv_stamp.
    CONDENSE lv_file NO-GAPS.
    CONCATENATE 'CASH_TRANSFER_ARCH_' lv_file '.CSV' INTO lv_file.
    lv_target = lv_target && lv_file.

    gv_chs_ar = lv_target.

    CALL FUNCTION 'ZFM_ARCHIVE_SERVER_TO_SERVER'
      EXPORTING
        sourcepath        = lv_source
        targetpath        = lv_target
        remove_sourcefile = 'X'
*     IMPORTING
*       LENGTH            =
      EXCEPTIONS
        error             = 1
        OTHERS            = 2.
    IF sy-subrc = 0.
      WRITE : /1 TEXT-014, 16 gv_chs_ar.
    ENDIF.

  ELSEIF uv_file = 'M'.

    lv_source = gc_mbp405.
    lv_target = gc_def_path && sy-mandt && gc_archive.
    lv_file = gv_stamp.
    CONDENSE lv_file NO-GAPS.
    CONCATENATE 'MBP405_ARCH_' lv_file '.CSV' INTO lv_file.
    lv_target = lv_target && lv_file.

    gv_mbp_ar = lv_target.

    CALL FUNCTION 'ZFM_ARCHIVE_SERVER_TO_SERVER'
      EXPORTING
        sourcepath        = lv_source
        targetpath        = lv_target
        remove_sourcefile = 'X'
*     IMPORTING
*       LENGTH            =
      EXCEPTIONS
        error             = 1
        OTHERS            = 2.
    IF sy-subrc = 0.
      WRITE : /1 TEXT-014, 16 gv_mbp_ar.
    ENDIF.

  ENDIF.

ENDFORM.
