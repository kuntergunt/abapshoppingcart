CLASS LHC_ZR_ASHOPCART_GRE DEFINITION INHERITING FROM CL_ABAP_BEHAVIOR_HANDLER.
  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF c_overall_status,
        new       TYPE string VALUE 'New / Composing',
*        composing  TYPE string VALUE 'Composing...',
        submitted TYPE string VALUE 'Submitted / Approved',
        cancelled TYPE string VALUE 'Cancelled',
      END OF c_overall_status.
    METHODS
      GET_GLOBAL_AUTHORIZATIONS FOR GLOBAL AUTHORIZATION
        IMPORTING
           REQUEST requested_authorizations FOR ZrAshopcartGre
        RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR ZrAshopcartGre RESULT result.

    METHODS calculateTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ZrAshopcartGre~calculateTotalPrice.

    METHODS setInitialOrderValues FOR DETERMINE ON MODIFY
      IMPORTING keys FOR ZrAshopcartGre~setInitialOrderValues.

    METHODS checkDeliveryDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZrAshopcartGre~checkDeliveryDate.

    METHODS checkOrderedQuantity FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZrAshopcartGre~checkOrderedQuantity.
ENDCLASS.

CLASS LHC_ZR_ASHOPCART_GRE IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.
  METHOD get_instance_features.

    " read relevant olineShop instance data
    READ ENTITIES OF zr_ashopcart_gre IN LOCAL MODE
      ENTITY ZrAshopcartGre
        FIELDS ( OverallStatus )
        WITH CORRESPONDING #( keys )
      RESULT DATA(OnlineOrders)
      FAILED failed.

    " evaluate condition, set operation state, and set result parameter
    " update and checkout shall not be allowed as soon as purchase requisition has been created
    result = VALUE #( FOR OnlineOrder IN OnlineOrders
                      ( %tky                   = OnlineOrder-%tky
                        %features-%update
                          = COND #( WHEN OnlineOrder-OverallStatus = c_overall_status-submitted  THEN if_abap_behv=>fc-o-disabled
                                    WHEN OnlineOrder-OverallStatus = c_overall_status-cancelled THEN if_abap_behv=>fc-o-disabled
                                    ELSE if_abap_behv=>fc-o-enabled   )
*                         %features-%delete
*                           = COND #( WHEN OnlineOrder-PurchaseRequisition IS NOT INITIAL THEN if_abap_behv=>fc-o-disabled
*                                     WHEN OnlineOrder-OverallStatus = c_overall_status-cancelled THEN if_abap_behv=>fc-o-disabled
*                                     ELSE if_abap_behv=>fc-o-enabled   )
                        %action-Edit
                          = COND #( WHEN OnlineOrder-OverallStatus = c_overall_status-submitted THEN if_abap_behv=>fc-o-disabled
                                    WHEN OnlineOrder-OverallStatus = c_overall_status-cancelled THEN if_abap_behv=>fc-o-disabled
                                    ELSE if_abap_behv=>fc-o-enabled   )

                        ) ).
  ENDMETHOD.

  METHOD calculateTotalPrice.
    DATA total_price TYPE zr_ashopcart_gre-TotalPrice.

    " read transfered instances
    READ ENTITIES OF zr_ashopcart_gre IN LOCAL MODE
      ENTITY ZrAshopcartGre
        FIELDS ( OrderID TotalPrice )
        WITH CORRESPONDING #( keys )
      RESULT DATA(OnlineOrders).

    LOOP AT OnlineOrders ASSIGNING FIELD-SYMBOL(<OnlineOrder>).
      " calculate total value
      <OnlineOrder>-TotalPrice = <OnlineOrder>-Price * <OnlineOrder>-OrderQuantity.
    ENDLOOP.

    "update instances
    MODIFY ENTITIES OF zr_ashopcart_gre IN LOCAL MODE
      ENTITY ZrAshopcartGre
        UPDATE FIELDS ( TotalPrice )
        WITH VALUE #( FOR OnlineOrder IN OnlineOrders (
                          %tky       = OnlineOrder-%tky
                          TotalPrice = <OnlineOrder>-TotalPrice
                        ) ).
  ENDMETHOD.

  METHOD setInitialOrderValues.

    DATA delivery_date TYPE I_PurchaseReqnItemTP-DeliveryDate.
    DATA(creation_date) = cl_abap_context_info=>get_system_date(  ).
    "set delivery date proposal
    delivery_date = cl_abap_context_info=>get_system_date(  ) + 14.
    "read transfered instances
    READ ENTITIES OF zr_ashopcart_gre IN LOCAL MODE
      ENTITY ZrAshopcartGre
        FIELDS ( OrderID OverallStatus  DeliveryDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(OnlineOrders).

    "delete entries with assigned order ID
    DELETE OnlineOrders WHERE OrderID IS NOT INITIAL.
    CHECK OnlineOrders IS NOT INITIAL.

    " **Dummy logic to determine order IDs**
    " get max order ID from the relevant active and draft table entries
    SELECT MAX( order_id ) FROM zashopcart_gre INTO @DATA(max_order_id). "active table
    SELECT SINGLE FROM zashopcart_gre_d FIELDS MAX( orderid ) INTO @DATA(max_orderid_draft). "draft table
    IF max_orderid_draft > max_order_id.
      max_order_id = max_orderid_draft.
    ENDIF.

    "set initial values of new instances
    MODIFY ENTITIES OF zr_ashopcart_gre IN LOCAL MODE
      ENTITY ZrAshopcartGre
        UPDATE FIELDS ( OrderID OverallStatus  DeliveryDate Price  )
        WITH VALUE #( FOR order IN OnlineOrders INDEX INTO i (
                          %tky          = order-%tky
                          OrderID       = max_order_id + i
                          OverallStatus = c_overall_status-new  "'New / Composing'
                          DeliveryDate  = delivery_date
                          CreatedAt     = creation_date
                        ) ).
    .
  ENDMETHOD.

  METHOD checkDeliveryDate.

*   " read transfered instances
    READ ENTITIES OF zr_ashopcart_gre IN LOCAL MODE
      ENTITY ZrAshopcartGre
        FIELDS ( DeliveryDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(OnlineOrders).

    DATA(creation_date) = cl_abap_context_info=>get_system_date(  ).
    "raise msg if 0 > qty <= 10
    LOOP AT OnlineOrders INTO DATA(online_order).


      IF online_order-DeliveryDate IS INITIAL OR online_order-DeliveryDate = ' '.
        APPEND VALUE #( %tky = online_order-%tky ) TO failed-ZrAshopcartGre.
        APPEND VALUE #( %tky         = online_order-%tky
                        %state_area   = 'VALIDATE_DELIVERYDATE'
                        %msg          = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Delivery Date cannot be initial' )
                      ) TO reported-ZrAshopcartGre.

      ELSEIF  ( ( online_order-DeliveryDate ) - creation_date ) < 14.
        APPEND VALUE #(  %tky = online_order-%tky ) TO failed-ZrAshopcartGre.
        APPEND VALUE #(  %tky          = online_order-%tky
                        %state_area   = 'VALIDATE_DELIVERYDATE'
                        %msg          = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Delivery Date should be atleast 14 days after the creation date'  )

                        %element-orderquantity  = if_abap_behv=>mk-on
                      ) TO reported-ZrAshopcartGre.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD checkOrderedQuantity.

    "read relevant order instance data
    READ ENTITIES OF zr_ashopcart_gre IN LOCAL MODE
    ENTITY ZrAshopcartGre
    FIELDS ( OrderID OrderedItem OrderQuantity )
    WITH CORRESPONDING #( keys )
    RESULT DATA(OnlineOrders).

    "raise msg if 0 > qty <= 10
    LOOP AT OnlineOrders INTO DATA(OnlineOrder).
      APPEND VALUE #(  %tky           = OnlineOrder-%tky
                      %state_area    = 'VALIDATE_QUANTITY'
                    ) TO reported-ZrAshopcartGre.

      IF OnlineOrder-OrderQuantity IS INITIAL OR OnlineOrder-OrderQuantity = ' '.
        APPEND VALUE #( %tky = OnlineOrder-%tky ) TO failed-ZrAshopcartGre.
        APPEND VALUE #( %tky          = OnlineOrder-%tky
                        %state_area   = 'VALIDATE_QUANTITY'
                        %msg          = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Quantity cannot be empty' )
                        %element-orderquantity = if_abap_behv=>mk-on
                      ) TO reported-ZrAshopcartGre.

      ELSEIF OnlineOrder-OrderQuantity > 10.
        APPEND VALUE #(  %tky = OnlineOrder-%tky ) TO failed-ZrAshopcartGre.
        APPEND VALUE #(  %tky          = OnlineOrder-%tky
                        %state_area   = 'VALIDATE_QUANTITY'
                        %msg          = new_message_with_text(
                                severity = if_abap_behv_message=>severity-error
                                text     = 'Quantity should be below 10' )

                        %element-orderquantity  = if_abap_behv=>mk-on
                      ) TO reported-ZrAshopcartGre.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
