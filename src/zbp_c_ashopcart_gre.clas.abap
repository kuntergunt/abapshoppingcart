class ZBP_C_ASHOPCART_GRE definition
  public
  abstract
  final
  for behavior of ZC_ASHOPCART_GRE .

public section.
protected section.
private section.
ENDCLASS.



CLASS ZBP_C_ASHOPCART_GRE IMPLEMENTATION.
  METHOD Edit.
    RAISE EXCEPTION TYPE cx_static_check.
  ENDMETHOD.

  METHOD Activate.
    RAISE EXCEPTION TYPE cx_static_check.
  ENDMETHOD.

  METHOD Discard.
    RAISE EXCEPTION TYPE cx_static_check.
  ENDMETHOD.

  METHOD Resume.
    RAISE EXCEPTION TYPE cx_static_check.
  ENDMETHOD.

  METHOD Prepare.
    RAISE EXCEPTION TYPE cx_static_check.
  ENDMETHOD.
ENDCLASS.
