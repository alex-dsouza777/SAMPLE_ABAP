


**********************************************************************************

* 0001  | 10/09/2020 | Sainath M. | 583894 | GST E-Invoice Reverse File Upload

**********************************************************************************



REPORT zfi_gst_einvoice_reverse.



TYPES: BEGIN OF ts_log,

         filename   TYPE char50,

         format     TYPE char3,

         mestyp     TYPE char1,

         messg(150) TYPE c,

       END OF ts_log.



TYPES: tt_table TYPE TABLE OF zfi_gst_einv_rev WITH DEFAULT KEY,

       tt_log   TYPE TABLE OF ts_log           WITH DEFAULT KEY.



DATA: gt_log    TYPE tt_log.



CLASS cl_upload_rev DEFINITION CREATE PUBLIC FINAL.

  PUBLIC SECTION.

    DATA: gt_data     TYPE tt_table,

          gv_tobepath TYPE epsf-epsdirnam,

          gv_sucspath TYPE salfile-longname,

          gv_erropath TYPE salfile-longname,

          gv_septr    TYPE char1 VALUE '|'.

    METHODS:

      constructor,

      read_files,

      upload_data   IMPORTING iv_filename     TYPE epsfilnam

                              iv_format       TYPE char3

                    RETURNING VALUE(rt_value) TYPE char1,

      move_delete   IMPORTING iv_filename TYPE epsfilnam

                              iv_format   TYPE char3

                              iv_filepath TYPE string

                              iv_error    TYPE char1,

      send_email    IMPORTING iv_filename TYPE epsfilnam

                              iv_format   TYPE char3.

ENDCLASS.



CLASS cl_upload_rev IMPLEMENTATION.

  METHOD constructor.

    SELECT * FROM zdms_path

      INTO TABLE @DATA(gt_path)

      WHERE path_for IN ('33', '34', '35').

    IF sy-subrc EQ 0.

      ##WARN_OK

      gv_tobepath = VALUE #( gt_path[ path_for = '33' ]-path OPTIONAL ).

      ##WARN_OK

      gv_sucspath = VALUE #( gt_path[ path_for = '34' ]-path OPTIONAL ).

      ##WARN_OK

      gv_erropath = VALUE #( gt_path[ path_for = '35' ]-path OPTIONAL ).

    ENDIF.

  ENDMETHOD.



  METHOD read_files.

    DATA: lt_file     TYPE STANDARD TABLE OF epsfili,

          lv_filepath TYPE string,

          lv_data     TYPE string,

          ls_rever    TYPE zfi_gst_einv_rev,

          lv_docdate  TYPE char30,

          ls_log      TYPE ts_log,

          lv_filetype TYPE char3.

    IF gv_tobepath IS NOT INITIAL.

      CALL FUNCTION 'EPS_GET_DIRECTORY_LISTING'

        EXPORTING

          dir_name               = gv_tobepath

          file_mask              = '*'

        TABLES

          dir_list               = lt_file

        EXCEPTIONS

          invalid_eps_subdir     = 1

          sapgparam_failed       = 2

          build_directory_failed = 3

          no_authorization       = 4

          read_directory_failed  = 5

          too_many_read_errors   = 6

          empty_directory_list   = 7.

      IF sy-subrc EQ 0.

        DELETE lt_file WHERE name NS 'CSV'.

        IF lt_file IS NOT INITIAL.

          LOOP AT lt_file ASSIGNING FIELD-SYMBOL(<fs_file>).

            CONCATENATE gv_tobepath '\' <fs_file>-name INTO lv_filepath.

            OPEN DATASET lv_filepath FOR INPUT IN TEXT MODE ENCODING DEFAULT IGNORING CONVERSION ERRORS.

            IF sy-subrc EQ 0.

              DO.

                READ DATASET lv_filepath INTO lv_data.

                IF sy-subrc EQ 0.

                  REPLACE ALL OCCURRENCES OF '"' IN lv_data WITH ''.

                  REPLACE ALL OCCURRENCES OF ',' IN lv_data WITH gv_septr.

                  IF sy-index =  1.  "Ignore header text

                    ##NEEDED

                    SPLIT lv_data AT gv_septr INTO DATA(lv_api) DATA(other).

                    lv_api = |{ lv_api CASE = UPPER }|.

                    IF lv_api CS 'APINAME'.

                      lv_filetype = 'B2B'.

                    ELSE.

                      lv_filetype = 'B2C'.

                    ENDIF.

                    CONTINUE.

                  ENDIF.

                  IF lv_filetype = 'B2B'.

                    SPLIT lv_data AT gv_septr INTO

                          ls_rever-apiname

                          ls_rever-tranrefid

                          ls_rever-suppliergstin

                          ls_rever-xblnr

                          lv_docdate

                          ls_rever-gst_doc_type

                          ls_rever-sname

                          ls_rever-bukrs

                          ls_rever-sourceidentifier

                          ls_rever-sourcefilename

                          ls_rever-configcode

                          ls_rever-ackno

                          ls_rever-ackdt

                          ls_rever-irn

                          ls_rever-irngendt

                          ls_rever-signedqrcode

                          ls_rever-signedinvoice

                          ls_rever-einvstatus

                          ls_rever-einvcanceldate

                          ls_rever-einvinfodtls

                          ls_rever-ewbno

                          ls_rever-ewbdate

                          ls_rever-ewbvalidupto

                          ls_rever-ewbalert

                          ls_rever-ewbcanceldate.

                  ELSE.

                    SPLIT lv_data AT gv_septr INTO

                          ls_rever-tranrefid

                          ls_rever-suppliergstin

                          ls_rever-xblnr

                          lv_docdate

                          ls_rever-gst_doc_type

                          ls_rever-sname

                          ls_rever-bukrs

                          ls_rever-sourceidentifier

                          ls_rever-sourcefilename

                          ls_rever-irngendt

                          ls_rever-einvstatus

                          ls_rever-signedqrcode

                          DATA(lv_extra) ##NEEDED.

                  ENDIF.



                  IF ls_rever-bukrs IS INITIAL

                  AND ls_rever-suppliergstin IS NOT INITIAL.

                    SELECT SINGLE bukrs ##WARN_OK

                      FROM j_1bbranch

                      INTO ls_rever-bukrs

                      WHERE gstin = ls_rever-suppliergstin

                      AND   bukrs NE '5998'.

                  ENDIF.

                  IF ls_rever-signedqrcode IS NOT INITIAL.

                    ls_rever-signedqrcode = 'Y'.

                  ELSE.

                    ls_rever-signedqrcode = 'N'.

                  ENDIF.

                  IF ls_rever-signedinvoice IS NOT INITIAL.

                    ls_rever-signedinvoice = 'Y'.

                  ELSE.

                    ls_rever-signedinvoice = 'N'.

                  ENDIF.

                  ls_rever-bldat = |{ lv_docdate(4) }{ lv_docdate+5(2) }{ lv_docdate+8(2) }|.

                  IF ls_rever-bukrs IS NOT INITIAL AND ls_rever-xblnr IS NOT INITIAL

                  AND ls_rever-bldat IS NOT INITIAL.

                    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'

                      EXPORTING

                        date                      = ls_rever-bldat

                      EXCEPTIONS

                        plausibility_check_failed = 1.

                    IF sy-subrc NE 0.

                      ls_log-filename = <fs_file>-name.

                      ls_log-format   = lv_filetype.

                      ls_log-mestyp   = 'E'.

                      ls_log-messg    = |Invalid Document Date Format { ls_rever-bldat }. | &&

                                        |It should be like YYYY-MM-DD|.

                      APPEND ls_log TO gt_log.

                      DATA(lv_datef) = abap_true.

                      EXIT.

                    ELSE.

                      APPEND ls_rever TO gt_data.

                    ENDIF.

                  ENDIF.

                ELSE.

                  EXIT.

                ENDIF.

                CLEAR: ls_rever, lv_data, lv_docdate.

              ENDDO.

              CLOSE DATASET lv_filepath.

            ENDIF.

            IF gt_data IS NOT INITIAL.

              DATA(lv_check) = upload_data( iv_filename = <fs_file>-name iv_format = lv_filetype ).

              move_delete( EXPORTING iv_filename = <fs_file>-name

                                     iv_format   = lv_filetype

                                     iv_filepath = lv_filepath

                                     iv_error    = lv_check ).

              REFRESH: gt_data.

            ELSE.

              IF lv_datef IS INITIAL.

                ls_log-filename = <fs_file>-name.

                ls_log-format   = lv_filetype.

                ls_log-mestyp   = 'E'.

                ls_log-messg    = |No any Data found in the file { <fs_file>-name } | &&

                                  |/ Error While Reading the data / | &&

                                  |File Format Issue|.

                APPEND ls_log TO gt_log.

              ENDIF.

              lv_check = space.

              move_delete( EXPORTING iv_filename = <fs_file>-name

                                     iv_format   = lv_filetype

                                     iv_filepath = lv_filepath

                                     iv_error    = lv_check ).

            ENDIF.

            IF lv_check EQ space.

              send_email( iv_filename = <fs_file>-name iv_format   = lv_filetype ).

            ENDIF.

            CLEAR: lv_filepath, lv_datef, lv_check, lv_filetype, lv_extra.

          ENDLOOP.

        ELSE.

          MESSAGE |There is no any new '.CSV' file found in Path - { gv_tobepath } | TYPE 'I'.

          LEAVE TO LIST-PROCESSING.

        ENDIF.

      ELSE.

        MESSAGE |There is no any new '.CSV' file found in Path - { gv_tobepath } | TYPE 'I'.

        LEAVE TO LIST-PROCESSING.

      ENDIF.

    ELSE.

      MESSAGE |Path does not found in ZDMS_PATH for 33| TYPE 'I'.

      LEAVE TO LIST-PROCESSING.

    ENDIF.

  ENDMETHOD.



  METHOD upload_data.

    DATA: lx_root TYPE REF TO cx_root,

          ls_log  TYPE ts_log.

    TRY.

        INSERT zfi_gst_einv_rev FROM TABLE gt_data.

        IF sy-subrc EQ 0.

          COMMIT WORK.

          rt_value = abap_true.

          ls_log-filename = iv_filename.

          ls_log-format   = iv_format.

          ls_log-mestyp   = 'S'.

          ls_log-messg    = |File Successfully Uploaded to Table|.

          APPEND ls_log TO gt_log.

        ENDIF.

        ##CATCH_ALL

      CATCH cx_root INTO lx_root.

        DATA(err_msg) = lx_root->get_text( ).

        ROLLBACK WORK.

        ls_log-filename = iv_filename.

        ls_log-format   = iv_format.

        ls_log-mestyp   = 'E'.

        ls_log-messg    = |Uploading Error-Same Data Exist / { err_msg }|.

        APPEND ls_log TO gt_log.

    ENDTRY.

  ENDMETHOD.



  METHOD move_delete.

    DATA: lv_src_file TYPE epsfilnam,

          lv_src_dir  TYPE epsdirnam,

          lv_trg_dir  TYPE epsdirnam,

          ls_log      TYPE ts_log.

    lv_src_file = iv_filename.

    lv_src_dir  = gv_tobepath.



    IF iv_error EQ abap_true.

      IF gv_sucspath IS INITIAL.

        MESSAGE |Path does not found in ZDMS_PATH for 34 to copy success file| TYPE 'I'.

        DATA(flgx) = abap_true.

      ENDIF.

      lv_trg_dir  = gv_sucspath.

    ELSE.

      IF gv_erropath IS INITIAL.

        MESSAGE |Path does not found in ZDMS_PATH for 35 to copy error file| TYPE 'I'.

        flgx = abap_true.

      ENDIF.

      lv_trg_dir  = gv_erropath.

    ENDIF.



    IF flgx IS INITIAL.

      CALL METHOD cl_cts_language_file_io=>copy_files_local

        EXPORTING

          im_source_file           = lv_src_file

          im_source_directory      = lv_src_dir

          im_target_file           = lv_src_file

          im_target_directory      = lv_trg_dir

        EXCEPTIONS

          open_input_file_failed   = 1

          open_output_file_failed  = 2

          write_block_failed       = 3

          read_block_failed        = 4

          close_output_file_failed = 5

          OTHERS                   = 6.

      IF sy-subrc EQ 0.

        DELETE DATASET iv_filepath.

        IF sy-subrc NE 0.

          ls_log-filename = lv_src_file.

          ls_log-format   = iv_format.

          ls_log-mestyp   = 'E'.

          ls_log-messg    = |Error while Deleting the File from Path - { iv_filepath }|.

          APPEND ls_log TO gt_log.

        ENDIF.

      ELSE.

        ls_log-filename = lv_src_file.

        ls_log-format   = iv_format.

        ls_log-mestyp   = 'E'.

        ls_log-messg    = |Error while Copying File to Path - { SWITCH #( iv_error WHEN '' THEN gv_erropath ELSE gv_sucspath ) }|.

        APPEND ls_log TO gt_log.

      ENDIF.

    ENDIF.

    CLEAR: lv_src_file.

  ENDMETHOD.



  METHOD send_email.

    DATA: i_text          TYPE soli_tab,   "Body Content

          i_subject       TYPE so_obj_des, "Subject Content

          text1(250),                      "Body Content

          recipient       TYPE REF TO if_recipient_bcs,

          document        TYPE REF TO cl_document_bcs,

          send_request    TYPE REF TO cl_bcs,

          wx_address_bcs  TYPE REF TO cx_address_bcs,

          wx_document_bcs TYPE REF TO cx_document_bcs,

          wx_send_req_bcs TYPE REF TO cx_send_req_bcs,

          bcs_mess        TYPE string      ##NEEDED,

          sent_to_all     TYPE os_boolean  ##NEEDED,

          ls_log          TYPE ts_log.



    "Create Mail subject

    i_subject      = |GST-e-Invoice Reverse file Fail to Update|.



    "Create Mail Body

    text1 = 'Sir,'. APPEND text1 TO i_text.

    text1 = ''. APPEND text1 TO i_text.

    text1 = |GST-e-Invoice Reverse file No.| &&

            |"{ iv_filename }_{ sy-datlo+6(2) }{ sy-datlo+4(2) }{ sy-datlo(4) }{ sy-uzeit }| &&

            |" is failed to update the table and put in Error Folder.|.

    APPEND text1 TO i_text.

    text1 = ''. APPEND text1 TO i_text.

    text1 = 'Thanks'. APPEND text1 TO i_text.



    "Create Mail Document

    TRY.

        send_request = cl_bcs=>create_persistent( ).

      CATCH cx_send_req_bcs INTO wx_send_req_bcs.

        bcs_mess = wx_send_req_bcs->get_text( ).

    ENDTRY.



    TRY.

        document = cl_document_bcs=>create_document(

                        i_type    = 'RAW'

                        i_text    = i_text

                        i_subject = i_subject ).

      CATCH cx_document_bcs INTO wx_document_bcs.

        bcs_mess = wx_document_bcs->get_text( ).

    ENDTRY.



    TRY.

        CALL METHOD send_request->set_document( document ).

      CATCH cx_send_req_bcs INTO wx_send_req_bcs.

        bcs_mess = wx_send_req_bcs->get_text( ).

    ENDTRY.





    "Assign Receiver Email Address

    SELECT * FROM zfi_einv_errmail INTO TABLE @DATA(lt_mailid).

    IF lt_mailid IS NOT INITIAL.

      LOOP AT lt_mailid ASSIGNING FIELD-SYMBOL(<fs_mailid>).

        TRY.

            recipient = cl_cam_address_bcs=>create_internet_address( <fs_mailid>-emailid ).

          CATCH cx_address_bcs INTO wx_address_bcs.

            bcs_mess = wx_address_bcs->get_text( ).

        ENDTRY.



        TRY.

            CALL METHOD send_request->add_recipient

              EXPORTING

                i_recipient = recipient

                i_express   = 'X'.

          CATCH cx_send_req_bcs INTO wx_send_req_bcs.

            bcs_mess = wx_send_req_bcs->get_text( ).

        ENDTRY.

      ENDLOOP.

    ENDIF.



    "Send Email

    TRY.

        CALL METHOD send_request->set_status_attributes( i_requested_status = 'N' ).

      CATCH cx_send_req_bcs INTO wx_send_req_bcs.

        bcs_mess = wx_send_req_bcs->get_text( ).

    ENDTRY.



    TRY.

        CALL METHOD send_request->send(

          EXPORTING

            i_with_error_screen = 'X'

          RECEIVING

            result              = sent_to_all ).

        IF sy-subrc NE 0.

          ls_log-filename = iv_filename.

          ls_log-format   = iv_format.

          ls_log-mestyp   = 'E'.

          ls_log-messg    = |Error While sending Email|.

          APPEND ls_log TO gt_log.

        ELSE.

          COMMIT WORK.

        ENDIF.

      CATCH cx_send_req_bcs INTO wx_send_req_bcs.

        bcs_mess = wx_send_req_bcs->get_text( ).

    ENDTRY.

  ENDMETHOD.



ENDCLASS.



START-OF-SELECTION.

  DATA(lo_obj) = NEW cl_upload_rev( ).

  lo_obj->read_files( ).



END-OF-SELECTION.

  IF gt_log IS NOT INITIAL.

    WRITE:/ 'Filename', AT 42 'Format', AT 49 'MesgType', AT 58 'Message'.

    ULINE.

    LOOP AT gt_log ASSIGNING FIELD-SYMBOL(<fs_log>).

      IF <fs_log>-mestyp EQ 'S'.

        WRITE:/ <fs_log>-filename, AT 42 <fs_log>-format, AT 49 <fs_log>-mestyp, AT 58 <fs_log>-messg COLOR 5.

      ELSE.

        WRITE:/ <fs_log>-filename, AT 42 <fs_log>-format, AT 49 <fs_log>-mestyp, AT 58 <fs_log>-messg COLOR 6.

      ENDIF.

    ENDLOOP.

  ENDIF.



