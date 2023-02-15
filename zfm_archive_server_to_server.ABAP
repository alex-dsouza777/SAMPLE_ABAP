FUNCTION zfm_archive_server_to_server.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SOURCEPATH) TYPE  SAEPATHFUL
*"     VALUE(TARGETPATH) TYPE  SAEPATHFUL
*"     VALUE(REMOVE_SOURCEFILE) TYPE  C DEFAULT 'X'
*"  EXPORTING
*"     VALUE(LENGTH) LIKE  SAPB-LENGTH
*"  EXCEPTIONS
*"      ERROR
*"----------------------------------------------------------------------
  DATA: BEGIN OF int_file OCCURS 1,
          line(1000) TYPE x,
        END OF int_file.
  DATA:
    ilength      TYPE p,
    count_table  TYPE p,
    line         LIKE int_file-line,
    bin_filesize TYPE p.

  FIELD-SYMBOLS: <f1>.

  OPEN DATASET sourcepath FOR INPUT
                    IN BINARY MODE.
  IF sy-subrc <> 0.
    MESSAGE e414(oa) WITH sourcepath RAISING error.
  ENDIF.
* read in Information File
  FREE int_file.
  bin_filesize = 0.
  DO.
    READ DATASET sourcepath INTO int_file LENGTH ilength.
    IF sy-subrc = 0.
      APPEND int_file.
      bin_filesize = bin_filesize + ilength.
    ELSE.
      IF sy-subrc = 8.
* open of file failed
        MESSAGE e414(oa) WITH sourcepath RAISING error.
      ELSE.
* end of file reached
        APPEND int_file.
        bin_filesize = bin_filesize + ilength.
        EXIT.
      ENDIF.
    ENDIF.
  ENDDO.
* close file on application server
  CLOSE DATASET sourcepath.
* correct content of last line
  DESCRIBE TABLE int_file LINES count_table.
  IF count_table <> 0.
    READ TABLE int_file INDEX count_table.
    CLEAR line.
    IF ilength > 0.
      ASSIGN int_file-line(ilength) TO <f1>.
      line = <f1>.
    ELSE.
      CLEAR line.
    ENDIF.
    CLEAR int_file-line.
    int_file-line = line.
    MODIFY int_file INDEX count_table.
  ENDIF.


* transfer to targetfile
* open file on application server
  OPEN DATASET targetpath FOR OUTPUT
                    IN BINARY MODE.
  IF sy-subrc <> 0.
    MESSAGE e415(oa) WITH targetpath space RAISING error.
  ENDIF.
* correction content of lat line
  DESCRIBE TABLE int_file LINES count_table.
  ilength = bin_filesize MOD 1000.
* Length file
  length = bin_filesize.
* write to file
  LOOP AT int_file.
    IF sy-tabix <> count_table.
      TRANSFER int_file TO targetpath.
    ELSE.
      TRANSFER int_file TO targetpath LENGTH ilength.
    ENDIF.
    IF sy-subrc <> 0.
      MESSAGE e415(oa) WITH targetpath space RAISING error.
    ENDIF.
  ENDLOOP.
* close file on application server
  CLOSE DATASET targetpath.

* Delete Source file.
  DATA : lt_string TYPE TABLE OF string.
  DATA : lv_arch_file TYPE epsf-epsfilnam,
         lv_arch_path TYPE epsf-epsdirnam,
         lv_e_path    TYPE epsf-epspath.

  IF remove_sourcefile =  abap_true.
    SPLIT sourcepath AT '/' INTO TABLE lt_string.
    lv_arch_file = lt_string[ lines( lt_string ) ].

    lv_arch_path = replace( val = sourcepath
                      regex = lv_arch_file
                      with  = space
                      occ   = 0 ).

    CALL FUNCTION 'EPS_DELETE_FILE'
      EXPORTING
        file_name              = lv_arch_file
        dir_name               = lv_arch_path
      IMPORTING
        file_path              = lv_e_path
      EXCEPTIONS
        invalid_eps_subdir     = 1
        sapgparam_failed       = 2
        build_directory_failed = 3
        no_authorization       = 4
        build_path_failed      = 5
        delete_failed          = 6
        OTHERS                 = 7.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 RAISING ERROR.
    ENDIF.
  ENDIF.

ENDFUNCTION.
