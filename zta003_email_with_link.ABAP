*&---------------------------------------------------------------------*
*& Report ZTA003_EMAIL_WITH_LINK
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zta003_email_with_link.

DATA : gt_text TYPE bcsy_text. "Table for body
DATA : gs_text LIKE LINE OF gt_text. "work area for message body

DATA binary_content TYPE solix_tab.
DATA size           TYPE so_obj_len.

PARAMETERS : p_ebeln TYPE ebeln.
PARAMETERS : p_email TYPE char80.


START-OF-SELECTION.
  PERFORM send_email.
*&---------------------------------------------------------------------*
*& Form send_email
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM send_email .
*For Email.
  DATA lo_send_request   TYPE REF TO cl_bcs.
  DATA lo_document       TYPE REF TO cl_document_bcs.
  DATA lo_recipient      TYPE REF TO if_recipient_bcs.
  DATA lo_bcs_exception  TYPE REF TO cx_bcs.
  DATA lv_sent_to_all    TYPE os_boolean.
  DATA lv_mailto         TYPE ad_smtpadr.
  DATA lv_sub            TYPE so_obj_des.

  DATA: lo_ex_ref   TYPE REF TO cx_root,
        lv_msg_text TYPE string.

  CONSTANTS: lc_htm  TYPE so_obj_tp VALUE 'HTM',
             lc_tab  TYPE c VALUE cl_bcs_convert=>gc_tab,
             lc_crlf TYPE c VALUE cl_bcs_convert=>gc_crlf.


  PERFORM create_pdf_file.

  TRY.
*     Create persistent send request ------------------------
      lo_send_request = cl_bcs=>create_persistent( ).
*     Create Email body using HTML.
      PERFORM create_email_body.

*     Create document object from internal table with text
      lv_sub = 'PO Details'.
      lo_document = cl_document_bcs=>create_document(
        i_type    = lc_htm
        i_text    = gt_text
        i_subject = lv_sub ).                               "#EC NOTEXT


*    add the PDF as attachment to document object
      lo_document->add_attachment(
        i_attachment_type    = 'PDF'                        "#EC NOTEXT
        i_attachment_subject = 'PO'                 "#EC NOTEXT
        i_attachment_size    = size
        i_att_content_hex    = binary_content ).



*     Add document object to send request
      lo_send_request->set_document( lo_document ).

*--------- add recipient (e-mail address) -----------------------
*      LOOP AT s_email.
*     Create recipient object
      lv_mailto = p_email.
      TRY."Here Recipient is email input p_email
          lo_recipient = cl_cam_address_bcs=>create_internet_address( lv_mailto ). ""#EC CI_SEL_NESTED
        CATCH  cx_address_bcs INTO lo_ex_ref.
          lv_msg_text = lo_ex_ref->get_text( ).
*      Catch exception here
      ENDTRY.
      TRY.
*      Add recipient object to send request
          lo_send_request->add_recipient( lo_recipient ).
        CATCH  cx_send_req_bcs INTO lo_ex_ref.
          lv_msg_text = lo_ex_ref->get_text( ).
*      Catch exception here
      ENDTRY.
*      ENDLOOP.
*     ---------- send document ---------------------------------------
      lv_sent_to_all = lo_send_request->send( i_with_error_screen = 'X' ).
      COMMIT WORK.
      IF lv_sent_to_all IS INITIAL.
        MESSAGE i500(sbcoms) WITH lv_mailto.
      ELSE.
        MESSAGE s022(so).
      ENDIF.

*   ------------ exception handling ----------------------------------
    CATCH cx_bcs INTO lo_bcs_exception.
      MESSAGE i865(so) WITH lo_bcs_exception->error_type.
  ENDTRY.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_email_body
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_email_body .
  DATA: lv_link TYPE string,
        lv_po   TYPE string.


  lv_link = 'https://fiorih4s.dot.hawaii.gov/sap/bc/ui2/flp?sap-client=420&sap-language=EN#ZPO-display?PoNr='.
  lv_link = lv_link && p_ebeln.

  lv_po =  '<a href="' && lv_link &&'">' && p_ebeln && '</a>'.


  gs_text-line = '<html><body>'.
  APPEND gs_text TO gt_text.

  gs_text-line = '<p>Dear Sir/ Madam,</p>'.
  APPEND gs_text TO gt_text.


  gs_text-line = '<p>'.
  APPEND gs_text TO gt_text.
  gs_text-line = 'The Purchase Order - ' && lv_po && ', has been created'.
  APPEND gs_text TO gt_text.
  gs_text-line = '</p>'.
  APPEND gs_text TO gt_text.

  gs_text-line = '<p></p>'.
  APPEND gs_text TO gt_text.

*  gs_text-line = '<p><u>SUMMARY:</u></p>'.
*  APPEND gs_text TO gt_text.
*
*  gs_text-line = '<p></p>'.
*  APPEND gs_text TO gt_text.
*
*
*  gs_text-line = '<table border = "1" cellpadding = "2" style="color:#000">'.
*  APPEND gs_text TO gt_text.
*
*  gs_text-line = '<tr bgcolor="#f3f9ff" >'
*    && '<th>' && 'Total Records'    && '</th>'
*    && '<th>' && 'Successfully updated' && '</th>'
*    && '<th>' && 'Error'  && '</th></tr>'.
*  APPEND gs_text TO gt_text.
*
*  gs_text-line = '<tr bgcolor="#f3f9ff" >'
*    && '<th>' && |{ gv_total   ALPHA = OUT }|  && '</th>'
*    && '<th>' && |{ gv_success ALPHA = OUT }| && '</th>'
*    && '<th>' && |{ gv_error   ALPHA = OUT }| && '</th></tr>'.
*  APPEND gs_text TO gt_text.
*
*  gs_text-line = '</table>'.
*  APPEND gs_text TO gt_text.


  gs_text-line = '<p><br></br></p>'.
  APPEND gs_text TO gt_text.

* Thank you!
  gs_text-line = '<p>Thank You!</p>'.
  APPEND gs_text TO gt_text.

  gs_text-line = '</body></html>'.
  APPEND gs_text TO gt_text.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_pdf_file
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_pdf_file .
  DATA: lv_fname TYPE rs38l_fnam.

  "Internal Tables.
  DATA: lt_otfdata        TYPE ssfcrescl,
        lt_binary_content TYPE solix_tab,
        lt_text           TYPE bcsy_text,
        lt_pdf_tab        TYPE STANDARD TABLE OF tline,
        lt_otf            TYPE STANDARD TABLE OF itcoo.

  "Work Areas
  DATA: ls_ctrlop TYPE ssfctrlop,
        ls_outopt TYPE ssfcompop.

  "Variables
  DATA: lv_bin_filesize TYPE so_obj_len,
        lv_sent_to_all  TYPE os_boolean,
        lv_bin_xstr     TYPE xstring,
        lv_string_text  TYPE string.



  "Control Parameters
  ls_ctrlop-getotf    = 'X'.
  ls_ctrlop-no_dialog = 'X'.
  ls_ctrlop-preview   = space.

  "Output Options
  ls_outopt-tdnoprev  = 'X'.
  ls_outopt-tddest    = 'LP01'.
  ls_outopt-tdnoprint = 'X'.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = 'ZMMSF_PO_PROCUREMENT'
    IMPORTING
      fm_name            = lv_fname
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.
  IF sy-subrc = 0.
    CALL FUNCTION lv_fname
      EXPORTING
        control_parameters = ls_ctrlop
        output_options     = ls_outopt
        iv_pcard           = p_ebeln
        USER_SETTINGS      = space
      IMPORTING
        job_output_info    = lt_otfdata
      EXCEPTIONS
        formatting_error   = 1
        internal_error     = 2
        send_error         = 3
        user_canceled      = 4
        OTHERS             = 5.
    IF sy-subrc = 0.
      lt_otf[] = lt_otfdata-otfdata[].

      CALL FUNCTION 'CONVERT_OTF'
        EXPORTING
          format                = 'PDF'
        IMPORTING
          bin_filesize          = lv_bin_filesize
          bin_file              = lv_bin_xstr
        TABLES
          otf                   = lt_otf[]
          lines                 = lt_pdf_tab[]
        EXCEPTIONS
          err_max_linewidth     = 1
          err_format            = 2
          err_conv_not_possible = 3
          OTHERS                = 4.
      IF sy-subrc = 0.
        CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
          EXPORTING
            buffer     = lv_bin_xstr
          TABLES
            binary_tab = lt_binary_content.

        binary_content[] = lt_binary_content[].
        size = lv_bin_filesize.

      ENDIF.
    ENDIF.

  ELSE.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.
