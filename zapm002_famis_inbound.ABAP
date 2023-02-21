
*&---------------------------------------------------------------------*
*& Modulpool ZAPM002_FAMIS_INBOUND
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
PROGRAM zapm002_famis_inbound.

TYPES : BEGIN OF ty_fields,
          department   TYPE char1,
          division     TYPE char2,
          program_id   TYPE char6,
          appn_type    TYPE char1,
          mof          TYPE char1,
          fund         TYPE char1,
          fiscal_year  TYPE char4,
          fiscal_month TYPE char2,
          revd         TYPE char1,
          expd         TYPE char1,
          chsd         TYPE char1,
          claimd       TYPE char1,
          contrd       TYPE char1,
          beg_cash     TYPE zglt_state_jv-amount,
          reven        TYPE zglt_state_jv-amount,
          expen        TYPE zglt_state_jv-amount,
          cash_trn     TYPE zglt_state_jv-amount,
          ending_chs   TYPE zglt_state_jv-amount,
          data_st      TYPE char20,
        END OF ty_fields.

DATA : gs_field TYPE ty_fields.

DATA : gt_rev TYPE TABLE OF zapt_reven.
DATA : gt_exp TYPE TABLE OF zapt_expend.
DATA : gt_chs TYPE TABLE OF zapt_cashtrn.
DATA : gt_claims TYPE TABLE OF zapt_claims.
DATA : gt_contr TYPE TABLE OF zapt_contracts.
DATA : gt_fieldcat TYPE slis_t_fieldcat_alv,
       gs_layout   TYPE slis_layout_alv,
       gv_pos      TYPE i.

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS'.
  SET TITLEBAR '001'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.
  CASE sy-ucomm.
    WHEN 'BACK'.
      LEAVE PROGRAM.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'EXECUTE'.
      PERFORM get_data.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data .

  DATA : lv_flg TYPE char2.

  IF gs_field-revd = abap_true.

    SELECT *
      FROM zapt_reven
      INTO TABLE gt_rev.
    IF gt_rev[] IS INITIAL.
      MESSAGE 'There is no data for Revenue File.' TYPE 'E'.
    ELSE.
      CLEAR lv_flg.
      lv_flg = 'R'.
      PERFORM fill_fld_cat USING lv_flg.
      PERFORM display_alv USING lv_flg.
    ENDIF.

  ELSEIF gs_field-expd = abap_true.

    SELECT *
      FROM zapt_expend
      INTO TABLE gt_exp.
    IF gt_exp[] IS INITIAL.
      MESSAGE 'There is no data for Expenditure File.' TYPE 'E'.
    ELSE.
      CLEAR lv_flg.
      lv_flg = 'E'.
      PERFORM fill_fld_cat USING lv_flg.
      PERFORM display_alv USING lv_flg.
    ENDIF.

  ELSEIF gs_field-chsd = abap_true.

    SELECT *
      FROM zapt_cashtrn
      INTO TABLE gt_chs.
    IF gt_chs[] IS INITIAL.
      MESSAGE 'There is no data for Cash Transfer File.' TYPE 'E'.
    ELSE.
      CLEAR lv_flg.
      lv_flg = 'C'.
      PERFORM fill_fld_cat USING lv_flg.
      PERFORM display_alv USING lv_flg.
    ENDIF.

  ELSEIF gs_field-claimd = abap_true.

    SELECT *
      FROM zapt_claims
      INTO TABLE gt_claims.

    IF gt_claims[] IS INITIAL.
      MESSAGE 'Ther is no data for Claims details' TYPE 'E'.

    ELSE.
      CLEAR lv_flg.
      lv_flg = 'CL'.
      PERFORM fill_fld_cat USING lv_flg.
      PERFORM display_alv USING lv_flg.

    ENDIF.

  ELSEIF gs_field-contrd = abap_true.

    SELECT *
      FROM zapt_contracts
      INTO TABLE gt_contr.

    IF gt_contr[] IS INITIAL.
      MESSAGE 'There is no data for Contracts details' TYPE 'E'.
    ELSE.
      CLEAR lv_flg.
      lv_flg = 'CO'.
      PERFORM fill_fld_cat USING lv_flg.
      PERFORM display_alv USING lv_flg.

    ENDIF.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fill_fld_cat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_FLG
*&---------------------------------------------------------------------*
FORM fill_fld_cat  USING  uv_flg.

  FREE gt_fieldcat[].
  gv_pos = 0.
  gs_layout-colwidth_optimize = abap_true.
  gs_layout-zebra = abap_true.

  IF uv_flg = 'R'.

    PERFORM fill_field USING 'gt_rev' 'BATCH_TY'     'Batch Type' '1' 'X' ''.
    PERFORM fill_field USING 'gt_rev' 'BATCH_DEPT'   'Batch Department' '2' 'X' ''.
    PERFORM fill_field USING 'gt_rev' 'BATCH_DT'     'Batch Date' '8' 'X' ''.
    PERFORM fill_field USING 'gt_rev' 'BATCH_NO'     'Batch Number' '3' 'X' ''.
    PERFORM fill_field USING 'gt_rev' 'BATCH_SEQ'    'Batch Sequence Number' '5' 'X' ''.
    PERFORM fill_field USING 'gt_rev' 'BATCH_DUP_IND' 'Batch Duplicate Indicator' '1' 'X' ''.
    PERFORM fill_field USING 'gt_rev' 'TRANS_ID'    'Transaction ID' '18' 'X' ''.
    PERFORM fill_field USING 'gt_rev' 'DEPT'        'Department' '1' '' ''.
    PERFORM fill_field USING 'gt_rev' 'DIV'         'Division' '2' '' ''.
    PERFORM fill_field USING 'gt_rev' 'PGM_ID'      'Program Id' '6' '' ''.
    PERFORM fill_field USING 'gt_rev' 'MOF'         'MOF' '1' '' ''.
    PERFORM fill_field USING 'gt_rev' 'APPN_TYPE'   'Appn Type' '1' '' ''.
    PERFORM fill_field USING 'gt_rev' 'TRANS_CODE'  'Transaction Code' '3' '' ''.
    PERFORM fill_field USING 'gt_rev' 'F_FY_ACCT'   'F_FY_ACCT' '8' '' ''.
    PERFORM fill_field USING 'gt_rev' 'OBJ'         'Source Object' '4' '' ''.
    PERFORM fill_field USING 'gt_rev' 'PROJ_NO'     'Project No.' '6' '' ''.
    PERFORM fill_field USING 'gt_rev' 'ACT'         'Activity' '3' '' ''.
    PERFORM fill_field USING 'gt_rev' 'AMOUNT'      'Amount' '13' '' ''.
    PERFORM fill_field USING 'gt_rev' 'SFX'         'SFX' '11' '' ''.
    PERFORM fill_field USING 'gt_rev' 'VENDOR_NO'   'Vendor No.' '10' '' ''.
    PERFORM fill_field USING 'gt_rev' 'VENDOR_NAME' 'Vendor Name' '30' '' ''.
    PERFORM fill_field USING 'gt_rev' 'INVOICE_NO'  'Invoice No.' '12' '' ''.
    PERFORM fill_field USING 'gt_rev' 'INV_DATE'    'Invoice Date' '10' '' ''.
    PERFORM fill_field USING 'gt_rev' 'AGING_DATE'  'Aging Date' '10' '' ''.
    PERFORM fill_field USING 'gt_rev' 'CHECK_DATE'  'Check Date' '10' '' ''.
    PERFORM fill_field USING 'gt_rev' 'CHECK_NO'    'Check No.' '8' '' ''.
    PERFORM fill_field USING 'gt_rev' 'DOC'         'Document' '2' '' ''.
    PERFORM fill_field USING 'gt_rev' 'COMP_NO'     'Comp No.' '8' '' ''.
    PERFORM fill_field USING 'gt_rev' 'DEPT_NO'     'Department No.' '8' '' ''.
    PERFORM fill_field USING 'gt_rev' 'DOC_NO'      'Document No.' '8' '' ''.
    PERFORM fill_field USING 'gt_rev' 'OPT_DATA'    'Opt Data' '25' '' ''.
    PERFORM fill_field USING 'gt_rev' 'IND_1099'    '1099_IND' '1' '' ''.
    PERFORM fill_field USING 'gt_rev' 'FY_FM'       'Fiscal Year/Month' '6' '' ''.
    PERFORM fill_field USING 'gt_rev' 'ENC_FM'      'ENC_FM' '2' '' ''.
    PERFORM fill_field USING 'gt_rev' 'PROC_DATE'   'Proc Date' '10' '' ''.

  ELSEIF uv_flg = 'E'.

    PERFORM fill_field USING 'gt_exp' 'BATCH_TY'     'Batch Type' '1' 'X' ''.
    PERFORM fill_field USING 'gt_exp' 'BATCH_DEPT'   'Batch Department' '2' 'X' ''.
    PERFORM fill_field USING 'gt_exp' 'BATCH_DT'     'Batch Date' '8' 'X' ''.
    PERFORM fill_field USING 'gt_exp' 'BATCH_NO'     'Batch Number' '3' 'X' ''.
    PERFORM fill_field USING 'gt_exp' 'BATCH_SEQ'    'Batch Sequence Number' '5' 'X' ''.
    PERFORM fill_field USING 'gt_exp' 'BATCH_DUP_IND' 'Batch Duplicate Indicator' '1' 'X' ''.
    PERFORM fill_field USING 'gt_exp' 'TRANS_ID'    'Transaction ID' '18' 'X' ''.
    PERFORM fill_field USING 'gt_exp' 'DEPT'        'Department' '1' '' ''.
    PERFORM fill_field USING 'gt_exp' 'DIV'         'Division' '2' '' ''.
    PERFORM fill_field USING 'gt_exp' 'PGM_ID'      'Program Id' '6' '' ''.
    PERFORM fill_field USING 'gt_exp' 'MOF'         'MOF' '1' '' ''.
    PERFORM fill_field USING 'gt_exp' 'APPN_TYPE'   'Appn Type' '1' '' ''.
    PERFORM fill_field USING 'gt_exp' 'TRANS_CODE'  'Transaction Code' '3' '' ''.
    PERFORM fill_field USING 'gt_exp' 'F_FY_ACCT'   'F_FY_ACCT' '8' '' ''.
    PERFORM fill_field USING 'gt_exp' 'OBJ'         'Source Object' '4' '' ''.
    PERFORM fill_field USING 'gt_exp' 'PROJ_NO'     'Project No.' '6' '' ''.
    PERFORM fill_field USING 'gt_exp' 'ACT'         'Activity' '3' '' ''.
    PERFORM fill_field USING 'gt_exp' 'AMOUNT'      'Amount' '13' '' ''.
    PERFORM fill_field USING 'gt_exp' 'SFX'         'SFX' '11' '' ''.
    PERFORM fill_field USING 'gt_exp' 'VENDOR_NO'   'Vendor No.' '10' '' ''.
    PERFORM fill_field USING 'gt_exp' 'VENDOR_NAME' 'Vendor Name' '30' '' ''.
    PERFORM fill_field USING 'gt_exp' 'INVOICE_NO'  'Invoice No.' '12' '' ''.
    PERFORM fill_field USING 'gt_exp' 'INV_DATE'    'Invoice Date' '10' '' ''.
    PERFORM fill_field USING 'gt_exp' 'AGING_DATE'  'Aging Date' '10' '' ''.
    PERFORM fill_field USING 'gt_exp' 'CHECK_DATE'  'Check Date' '10' '' ''.
    PERFORM fill_field USING 'gt_exp' 'CHECK_NO'    'Check No.' '8' '' ''.
    PERFORM fill_field USING 'gt_exp' 'DOC'         'Document' '2' '' ''.
    PERFORM fill_field USING 'gt_exp' 'COMP_NO'     'Comp No.' '8' '' ''.
    PERFORM fill_field USING 'gt_exp' 'DEPT_NO'     'Department No.' '8' '' ''.
    PERFORM fill_field USING 'gt_exp' 'DOC_NO'      'Document No.' '8' '' ''.
    PERFORM fill_field USING 'gt_exp' 'OPT_DATA'    'Opt Data' '25' '' ''.
    PERFORM fill_field USING 'gt_exp' 'IND_1099'    '1099_IND' '1' '' ''.
    PERFORM fill_field USING 'gt_exp' 'FY_FM'       'Fiscal Year/Month' '6' '' ''.
    PERFORM fill_field USING 'gt_exp' 'ENC_FM'      'ENC_FM' '2' '' ''.
    PERFORM fill_field USING 'gt_exp' 'PROC_DATE'   'Proc Date' '10' '' ''.

  ELSEIF uv_flg = 'C'.
    PERFORM fill_field USING 'gt_chs' 'DATE_OF_RUN'      'Date Of Run' '8' 'X' ''.
    PERFORM fill_field USING 'gt_chs' 'BATCH_TY'         'Batch Type' '1' 'X' ''.
    PERFORM fill_field USING 'gt_chs' 'BATCH_DEPT'       'Batch Department' '2' 'X' ''.
    PERFORM fill_field USING 'gt_chs' 'BATCH_DT'         'Batch Date' '6' 'X' ''.
    PERFORM fill_field USING 'gt_chs' 'BATCH_NO'         'Batch Number' '3' 'X' ''.
    PERFORM fill_field USING 'gt_chs' 'BATCH_SEQ'        'Batch Sequence No.' '5' 'X' ''.
    PERFORM fill_field USING 'gt_chs' 'BATCH_DUP_IND'    'Batch Duplicate Indicator' '1' '' ''.
    PERFORM fill_field USING 'gt_chs' 'FM'               'Fiscal Month' '2' '' ''.
    PERFORM fill_field USING 'gt_chs' 'PROC_DATE'        'Proc Date' '10' '' ''.
    PERFORM fill_field USING 'gt_chs' 'TRANS_CD'         'Transaction code' '3' '' ''.
    PERFORM fill_field USING 'gt_chs' 'FUND'             'Fund' '1' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZFUND_DESC'       'Fund Description' '15' '' ''.
    PERFORM fill_field USING 'gt_chs' 'FUND_YR'          'Fiscal Year' '4' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ACCT'             'Apprn Acct' '3' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZDEPT'            'Department' '1' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZDEPT_DESC'       'Department Decription' '15' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ALLOT_CAT'        'Allotment Category' '2' '' ''.
    PERFORM fill_field USING 'gt_chs' 'SRCE_OBJT'        'Source Object' '4' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZMAJOR_OBJECT'    'Major Object' '2' '' ''.
    PERFORM fill_field USING 'gt_chs' 'COST_CENTER'      'Cost Center' '4' '' ''.
    PERFORM fill_field USING 'gt_chs' 'PROJ_NO'          'Project Number' '6' '' ''.
    PERFORM fill_field USING 'gt_chs' 'PROJ_PHASE'       'Project Phase' '2' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ACTV'             'Activity' '3' '' ''.
    PERFORM fill_field USING 'gt_chs' 'TRANS_AMT'        'Transaction Amount' '13' '' ''.
    PERFORM fill_field USING 'gt_chs' 'MODIFIER'         'M_Mod' '1' '' ''.
    PERFORM fill_field USING 'gt_chs' 'REVERSE'          'Reverse' '1' '' ''.
    PERFORM fill_field USING 'gt_chs' 'FUNDS_CTL_OVRD'   'Funds Ctl' '1' '' ''.
    PERFORM fill_field USING 'gt_chs' 'DEPT_BTCH_REF_NO' 'Department Reference No.' '8' '' ''.
    PERFORM fill_field USING 'gt_chs' 'CVN'              'Compt Voucher No.' '8' '' ''.
    PERFORM fill_field USING 'gt_chs' 'GL_ACCT'          'GL Account' '3' '' ''.
    PERFORM fill_field USING 'gt_chs' 'SUBSID_ACCT_NO'   'Subsid Acct No.' '6' '' ''.
    PERFORM fill_field USING 'gt_chs' 'VENDOR_NO'        'Vendor No.' '10' '' ''.
    PERFORM fill_field USING 'gt_chs' 'VENDOR_SFX'       'Vendor Number SFX' '2' '' ''.
    PERFORM fill_field USING 'gt_chs' 'VENDOR_NAME'      'Vendor Name' '30' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZVENDOR_INV_NO'   'Vendor Invoice No.' '13' '' ''.
    PERFORM fill_field USING 'gt_chs' 'INVOICE_DATE'     'Invoice Date' '10' '' ''.
    PERFORM fill_field USING 'gt_chs' 'DOC_NO'           'Document No.' '8' '' ''.
    PERFORM fill_field USING 'gt_chs' 'DOC_NO_SFX'       'Document No. SFX' '2' '' ''.
    PERFORM fill_field USING 'gt_chs' 'DOC_DATE'         'Document Date Raw' '10' '' ''.
    PERFORM fill_field USING 'gt_chs' 'REF_DOC_NO'       'Reference Document No.' '8' '' ''.
    PERFORM fill_field USING 'gt_chs' 'REF_DOC_SFX'      'Reference Document No. SFX' '2' '' ''.
    PERFORM fill_field USING 'gt_chs' 'OPT_DEPT_DATA'    'Opt Dept Data' '25' '' ''.
    PERFORM fill_field USING 'gt_chs' 'OPT_REMITT_DATA'  'OPT REMITT DATA' '25' '' ''.
    PERFORM fill_field USING 'gt_chs' 'WARRANT_NO'       'Warrant No.' '8' '' ''.
    PERFORM fill_field USING 'gt_chs' 'NET_DOC_AMT'      'Net Document Amount' '3' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZDIV'             'Divsion' '2' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZDIV_DESC'        'Division Description' '20' '' ''.
    PERFORM fill_field USING 'gt_chs' 'MOF'              'MOF' '1' '' ''.
    PERFORM fill_field USING 'gt_chs' 'PROG_ID'          'Program Id' '6' '' ''.
    PERFORM fill_field USING 'gt_chs' 'AGING_START_DATE' 'Aging Start Raw' '10' '' ''.
    PERFORM fill_field USING 'gt_chs' 'PAYMENT_TYPE_IND' 'Payment Type Indicator' '1' '' ''.
    PERFORM fill_field USING 'gt_chs' 'FUNCTION'         'Function' '3' '' ''.
    PERFORM fill_field USING 'gt_chs' 'GAAP_FUND'        'Gaap Fund' '1' '' ''.
    PERFORM fill_field USING 'gt_chs' 'GAAP_SUBUND'      'Gaap Subfund' '1' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZFUND_DETAIL'     'Fund Details' '2' '' ''.
    PERFORM fill_field USING 'gt_chs' 'AP_TYPE'          'Appn Type' '1' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZTRANS_YEAR'      'Transaction Year' '4' '' ''.
    PERFORM fill_field USING 'gt_chs' 'TRANS_TY'         'Transaction Type' '4' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZFYYYYMM'         'Fiscal Year Month' '6' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZF_FY_ACCT'       'F_FY_ACCT' '8' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZBATCH_TYPE_SORT' 'Batch Type Sort' '1' '' ''.
    PERFORM fill_field USING 'gt_chs' 'ZTRANS_AMT_NET'   'Transaction Net Amount' '13' '' ''.

  ELSEIF uv_flg = 'CL'.

    PERFORM fill_field USING 'gt_claims' 'DATE_OF_RUN' 'Date of Run' '15' 'X' ''.
    PERFORM fill_field USING 'gt_claims' 'ZCLAIM_NO_SFX' 'Claim No.-SFX' '11' 'X' ''.
    PERFORM fill_field USING 'gt_claims' 'ZDEPT' 'Department' '1' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZDIV' 'Division' '2' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZPGM_ID' 'Program ID' '6' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZMOF' 'MOF' '1' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZAPPN_TYPE' 'Appen Type' '1' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZF_FY_ACCT' 'F-FY-ACCT' '8' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZDOCDATE' 'Document Date' '10' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZVENDOR_NO' 'Vendor No.' '10' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZVENDOR_NAME' 'Vendor Name' '30' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZOBJ_CODE' 'Object Code' '4' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZPROJ_NO' 'Project No.' '6' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZACT' 'Activity' '3' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZENCAMOUNT' 'Enc Amount' '13' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZAMTEXPEND' 'Amt Expend' '13' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZBALANCE' 'Balance' '13' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZORIGENC' 'Orig Enc' '13' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZADJUSTMENT' 'Adjustment' '13' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZLIQUIDATION' 'Liquidation' '13' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZRETAINAGE' 'Retainage' '13' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZENC_FM' 'Enc FM' '2' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZCREATEDATE' 'Create Date' '10' '' ''.
    PERFORM fill_field USING 'gt_claims' 'ZPERIOD' 'Period' '1' '' ''.

  ELSEIF uv_flg = 'CO'.

    PERFORM fill_field USING 'gt_contr' 'DATE_OF_RUN' 'Date of Run' '15' 'X' ''.
    PERFORM fill_field USING 'gt_contr' 'ZCONTR_NO_SFX' 'Contract No/Sfx' '11' 'X' ''.
    PERFORM fill_field USING 'gt_contr' 'ZDEPT' 'Department' '1' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZDIV' 'Division' '2' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZPGM_ID' 'Program ID' '6' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZMOF' 'MOF' '1' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZAPPN_TYPE' 'Appn Type' '1' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZF_FY_ACCT' 'F-FY-ACCT' '8' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZDOCDATE' 'Doc Date' '10' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZVENDOR_NO' 'Vendor No' '10' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZVENDOR_NAME' 'Vendor Name' '30' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZOBJ_CODE' 'Object code' '4' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZCC' 'CC' '4' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZPROJ_NO' 'Project No' '6' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZPH' 'Phase' '2' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZACT' 'Activity' '3' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZENCAMOUNT' 'Enc Amount' '13' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZAMTEXPEND' 'Amount Expend' '13' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZBALANCE' 'Balance' '13' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZORIGENC' 'Orig Enc' '13' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZADJUSTMENT' 'Adjustment' '13' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZLIQUIDATION' 'Liquidation' '13' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZDIRECTEXP' 'Direct Exp' '13' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZRETAINAGE' 'Retainage' '13' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZENC_FM' 'Enc FM' '2' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZCREATEDATE' 'Create Date' '10' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZPERIOD' 'Period' '1' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZDESCRIPTION1' 'Description (1)' '46' '' ''.
    PERFORM fill_field USING 'gt_contr' 'ZDESCRIPTION2' 'Description (2)' '46' '' ''.



  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form fill_field
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
FORM fill_field  USING   uv_tab_field_name
                         uv_ref_field_name
                         uv_short_text1
                         uv_outputlen
                         uv_key_field
                         uv_do_sum.

  DATA: ls_fieldcat TYPE slis_fieldcat_alv.

  CLEAR ls_fieldcat.
  gv_pos = gv_pos + 1.

  ls_fieldcat-col_pos       = gv_pos.
  ls_fieldcat-tabname       = uv_tab_field_name.
  ls_fieldcat-fieldname     = uv_ref_field_name.
  ls_fieldcat-seltext_s     = uv_short_text1.
  ls_fieldcat-seltext_m     = uv_short_text1.
  ls_fieldcat-seltext_l     = uv_short_text1.
  ls_fieldcat-outputlen     = uv_outputlen.
  ls_fieldcat-key           = uv_key_field.
  ls_fieldcat-do_sum        = uv_do_sum.

  APPEND ls_fieldcat TO  gt_fieldcat.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv USING uv_flg.

  IF uv_flg = 'R'.
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program = sy-repid
*       i_callback_top_of_page = 'TOP_OF_PAGE'
        it_fieldcat        = gt_fieldcat
        i_save             = 'A'
        is_layout          = gs_layout
      TABLES
        t_outtab           = gt_rev
      EXCEPTIONS
        program_error      = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
  ELSEIF uv_flg = 'E'.
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program = sy-repid
*       i_callback_top_of_page = 'TOP_OF_PAGE'
        it_fieldcat        = gt_fieldcat
        i_save             = 'A'
        is_layout          = gs_layout
      TABLES
        t_outtab           = gt_exp
      EXCEPTIONS
        program_error      = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
  ELSEIF uv_flg = 'C'.

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program = sy-repid
*       i_callback_top_of_page = 'TOP_OF_PAGE'
        it_fieldcat        = gt_fieldcat
        i_save             = 'A'
        is_layout          = gs_layout
      TABLES
        t_outtab           = gt_chs
      EXCEPTIONS
        program_error      = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
  ELSEIF uv_flg = 'CL'.

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program = sy-repid
*       i_callback_top_of_page = 'TOP_OF_PAGE'
        it_fieldcat        = gt_fieldcat
        i_save             = 'A'
        is_layout          = gs_layout
      TABLES
        t_outtab           = gt_claims
      EXCEPTIONS
        program_error      = 1
        OTHERS             = 2.

  ELSEIF uv_flg = 'CO'.

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program = sy-repid
*       i_callback_top_of_page = 'TOP_OF_PAGE'
        it_fieldcat        = gt_fieldcat
        i_save             = 'A'
        is_layout          = gs_layout
      TABLES
        t_outtab           = gt_contr
      EXCEPTIONS
        program_error      = 1
        OTHERS             = 2.

  ENDIF.
ENDFORM.
