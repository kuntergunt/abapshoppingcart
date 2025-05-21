@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_ASHOPCART_GRE
  provider contract TRANSACTIONAL_QUERY
  as projection on ZR_ASHOPCART_GRE
{
  key OrderUuid,
  OrderId,
  OrderedItem,
  Price,
  TotalPrice,
  @Semantics.currencyCode: true
  Currency,
  OrderQuantity,
  DeliveryDate,
  OverallStatus,
  Notes,
  CreatedBy,
  CreatedAt,
  LastChangedBy,
  LastChangedAt,
  LocalLastChangedAt,
  PurchaseRequisition,
  PrCreationDate
  
}
