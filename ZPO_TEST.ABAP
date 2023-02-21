*&---------------------------------------------------------------------*
*& Report ZPO_TEST
*&---------------------------------------------------------------------*
*& Call report in fiori 
*&---------------------------------------------------------------------*
REPORT ZPO_TEST.

parameters:
      p_ebeln type EBELN.

set parameter id 'BES' field p_ebeln.

CALL transaction 'ME23N' WITH AUTHORITY-CHECK.
