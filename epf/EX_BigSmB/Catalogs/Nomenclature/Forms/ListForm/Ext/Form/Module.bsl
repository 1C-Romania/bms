#Region FormEvents

&AtServer
Procedure BSB_OnCreateAtServer(Cancel, StandardProcessing)
	
	FilterPriceKind = SmallBusinessReused.GetValueByDefaultUser(Users.CurrentUser(), "MainPriceKindSales");
	
	SetFilterInList();
	ManageForm(ThisForm);
	
EndProcedure

&AtClient
Procedure BSB_OnOpen(Cancel)
	
	UniqueKeyOfOwner = UniqueKey;
	SetInscriptionSelectedNomenclature();
	
EndProcedure

&AtServer
Procedure BSB_OnLoadDataFromSettingsAtServer(Settings)
	
	SetFilterInList();
	ManageForm(ThisForm);
	
EndProcedure

#EndRegion

#Region ItemsEvents

&AtClient
Procedure BSB_PictureShoppingCartClick(Item)
	
	OpenShoppingCart();
	
EndProcedure

&AtClient
Procedure BSB_PictureShoppingCartDrag(Item, DragParameters, StandardProcessing)
	
	StandardProcessing = False;
	
	AddToShoppingCart(DragParameters.Value);
	
EndProcedure

&AtClient
Procedure BSB_PictureShoppingCartDragCheck(Item, DragParameters, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure BSB_SelectedNomenclaturesClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	OpenShoppingCart();
	
EndProcedure

&AtClient
Procedure BSB_FilterHierarchyOnActivateRow(Item)
	
	If Items.FilterHierarchy.CurrentData = Undefined Then
		SmallBusinessClientServer.DeleteListFilterItem(List, "Parent");
	Else
		FilterValue = Items.FilterHierarchy.CurrentData.Ref;
		SmallBusinessClientServer.SetListFilterItem(List, "Parent", FilterValue, True, DataCompositionComparisonType.InHierarchy);
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure BSB_ShowQuantityOnChange(Item)
	
	SetFilterInList();
	
EndProcedure

&AtClient
Procedure BSB_FilterBalanceOnChange(Item)
	
	SetFilterInList();
	
EndProcedure

&AtClient
Procedure BSB_FilterWarehouseOnChange(Item)
	
	SetFilterInList();
	
EndProcedure

&AtClient
Procedure BSB_ShowPricesOnChange(Item)
	
	SetFilterInList();
	SetInscriptionSelectedNomenclature();
	
EndProcedure

&AtClient
Procedure BSB_FilterPriceKindOnChange(Item)
	
	SetFilterInList();
	
EndProcedure

&AtClient
Procedure BSB_FilterMinPriceOnChange(Item)
	
	SetFilterInList();
	
EndProcedure

&AtClient
Procedure BSB_FilterMaxPriceOnChange(Item)
	
	SetFilterInList();
	
EndProcedure

&AtClient
Procedure BSB_FilterMinPriceClearing(Item, StandardProcessing)
	
	SetFilterInList();
	
EndProcedure

&AtClient
Procedure BSB_FilterMaxPriceClearing(Item, StandardProcessing)
	
	SetFilterInList();
	
EndProcedure

&AtClient
Procedure BSB_FilterPriceKindClearing(Item, StandardProcessing)
	
	SetFilterInList();
	
EndProcedure

&AtClient
Procedure BSB_FilterWarehouseClearing(Item, StandardProcessing)
	
	SetFilterInList();
	
EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Procedure BSB_AddToShoppingCart(Command)
	
	AddToShoppingCart(Items.List.SelectedRows);
	
EndProcedure

&AtClient
Procedure BSB_CreateInvoiceForPayment(Command)
	
	CreateDocument("InvoiceForPayment");
	
EndProcedure

&AtClient
Procedure BSB_CreatePurchaseOrder(Command)
	
	CreateDocument("PurchaseOrder");
	
EndProcedure

&AtClient
Procedure BSB_CreateCustomerOrder(Command)
	
	CreateDocument("CustomerOrder");
	
EndProcedure

&AtClient
Procedure BSB_CreateInvoice(Command)
	
	CreateDocument("Invoice");
	
EndProcedure

&AtClient
Procedure BSB_CreatePurchaseInvoiceReceived(Command)
	
	CreateDocument("PurchaseInvoiceReceived");
	
EndProcedure

#EndRegion

#Region InternalProceduresFunctions

&AtClientAtServerNoContext
Procedure ManageForm(Form)
	
	Items = Form.Items;
	If Not Form.ShowQuantity Then
		Form.FilterWarehouse = Undefined;
	EndIf;
	Items.FilterWarehouse.Enabled = Form.ShowQuantity;
	Items.FilterBalance.Enabled = Form.ShowQuantity;
	Items.Quantity.Visible = Form.ShowQuantity;
	
	Items.FilterPriceKind.Enabled = Form.ShowPrices;
	Items.FilterPrice.Enabled = Form.ShowPrices;
	Items.Price.Visible = Form.ShowPrices;
	
EndProcedure

#Region FilterInList

&AtServer
Procedure SetFilterInList()
	
	List.Parameters.SetParameterValue("ShowQuantity", ShowQuantity);
	
	If ValueIsFilled(FilterWarehouse) AND ShowQuantity Then 
		SmallBusinessClientServer.SetListFilterItem(List, "BaseUnit", FilterWarehouse, True);
	Else
		SmallBusinessClientServer.DeleteListFilterItem(List, "BaseUnit");
	EndIf;
	
	If Not ShowQuantity Or FilterBalance = 0 Then
		SmallBusinessClientServer.DeleteListFilterItem(List, "Quantity");
	ElsIf FilterBalance = 1 Then
		SmallBusinessClientServer.SetListFilterItem(List, "Quantity", 0, True, DataCompositionComparisonType.Greater);
	Else
		SmallBusinessClientServer.SetListFilterItem(List, "Quantity", 0, True, DataCompositionComparisonType.LessOrEqual);
	EndIf;
	
	List.Parameters.SetParameterValue("ShowPrices", ShowPrices);
	List.Parameters.SetParameterValue("PricesKind", FilterPriceKind);
	If Not ShowPrices Then 
		SmallBusinessClientServer.DeleteListFilterItem(List, "PriceMin");
		SmallBusinessClientServer.DeleteListFilterItem(List, "PriceMax");
	Else
		If FilterMinPrice = 0 Then 
			SmallBusinessClientServer.DeleteListFilterItem(List, "PriceMin");
		Else
			SmallBusinessClientServer.SetListFilterItem(List, "PriceMin", FilterMinPrice, True, DataCompositionComparisonType.GreaterOrEqual);
		EndIf;
		If FilterMaxPrice = 0 Then 
			SmallBusinessClientServer.DeleteListFilterItem(List, "PriceMax");
		Else
			SmallBusinessClientServer.SetListFilterItem(List, "PriceMax", FilterMaxPrice, True, DataCompositionComparisonType.LessOrEqual);
		EndIf;
	EndIf;
	
	Items.List.Refresh();
	
	ManageForm(ThisForm);
	
EndProcedure

#EndRegion

#Region ShoppingCart

&AtClient
Procedure AddToShoppingCart(SelectedRows)
	
	If TypeOf(SelectedRows) = Type("Array") Then
		For Each SelectedRow In SelectedRows Do
			AddRowToShoppingCart(SelectedRow);
		EndDo;
	ElsIf TypeOf(SelectedRows) = Type("CatalogRef.Nomenclature") Then
		AddRowToShoppingCart(SelectedRow);
	EndIf;
	
	SetInscriptionSelectedNomenclature();
	
EndProcedure

&AtClient
Procedure SetInscriptionSelectedNomenclature()
	
	TotalCount = ShoppingCart.Total("Quantity");
	TotalAmount = ShoppingCart.Total("Amount");
	
	If ShoppingCart.Count() = 0 Then
		SelectedNomenclatures = 
			NStr("ru = 'Перетащите товары в корзину';en='Drag the items to the cart'; ro = 'Trageți articolele în coș'");
		Items.PictureShoppingCart.Visible = True;
		Items.PictureShoppingCartFull.Visible = False;
	Else
		If ShowPrices Then
			SelectedNomenclatures = StringFunctionsClientServer.PlaceParametersIntoString(
				NStr("ru = 'Подобрано: %1 на сумму %2';en='Selected: %1 amount of %2'; ro = 'Selectate: %1 Suma: %2'"), 
				TotalCount,
				TotalAmount);
		Else
			SelectedNomenclatures = StringFunctionsClientServer.PlaceParametersIntoString(
				NStr("ru = 'Подобрано: %1';en='Selected: %1'; ro = 'Selectate: %1'"), TotalCount);
		EndIf;
		Items.PictureShoppingCart.Visible = False;
		Items.PictureShoppingCartFull.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure AddRowToShoppingCart(SelectedRow)
	
	RowData = Items.List.RowData(SelectedRow);
	ChoiceStructure = NewChoiceStructure();
	FillPropertyValues(ChoiceStructure, RowData);
	ChoiceStructure.Nomenclature = RowData.Ref;
	ChoiceStructure.Quantity = 1;
	ChoiceStructure.Type = RowData.NomenclatureType;
	
	AddNomenclatureToShoppingCart(ChoiceStructure);
	
EndProcedure

&AtClient
Procedure AddNomenclatureToShoppingCart(ChoiceStructure)
	
	SearchStructure = New Structure("Nomenclature", ChoiceStructure.Nomenclature);
	FoundRow = ShoppingCart.FindRows(SearchStructure);
	If FoundRow.Count() = 0 Then
		RowShoppingCart = ShoppingCart.Add();
		FillPropertyValues(RowShoppingCart, ChoiceStructure);
	Else
		RowShoppingCart = FoundRow[0];
		RowShoppingCart.Quantity = RowShoppingCart.Quantity + ChoiceStructure.Quantity;
		RowShoppingCart.Price = ChoiceStructure.Price;
	EndIf;
	
	RowShoppingCart.Amount = RowShoppingCart.Quantity * RowShoppingCart.Price;
	
	SetInscriptionSelectedNomenclature();
	
	TextExplanation = StringFunctionsClientServer.PlaceParametersIntoString(
		NStr("ru='Товар %1 добавлен в корзину';en = 'The item %1 is added to shopping cart';ro='Produsul %1 este adaugat in cosul de cumparaturi'"),
		ChoiceStructure.Nomenclature);
	ShowUserNotification(
		NStr("ru = 'Подбор товаров'; en = 'Adding nomenclature'; ro = 'Selecție de produse'")
		,
		,
		TextExplanation);
	
EndProcedure

&AtClient
Function NewChoiceStructure() 
	Return 
		New Structure(
		"Nomenclature,
		|Quantity,
		|Price,
		|Type");
EndFunction

&AtClient
Procedure OpenShoppingCart() 
	
	If ShoppingCart.Count() > 0 Then
		ShoppingCartParameters = SaveSelectedToTempStorage();
		ShoppingCartParameters.Insert("FilterWarehouse", FilterWarehouse);
		ShoppingCartParameters.Insert("FilterPriceKind", FilterPriceKind);
		ShoppingCartParameters.Insert("ShowPrices", ShowPrices);
		
		OpenShoppingCartContinue(ShoppingCartParameters);
	EndIf;
	
EndProcedure

&AtServer
Function SaveSelectedToTempStorage()
	
	AddressCartInTempStorage = PutToTempStorage(ShoppingCart.Unload(), UniqueKeyOfOwner);
	Return New Structure("AddressCartInTempStorage, UniqueKeyOfOwner", AddressCartInTempStorage, UniqueKeyOfOwner);
	
EndFunction

&AtClient
Procedure OpenShoppingCartContinue(ShoppingCartParameters)
	
	NotifyDescription = New NotifyDescription("ShoppingCartClosing", ThisObject);
	OpenForm("DataProcessor.BigSmallBusiness.Form.FormShoppingCart", ShoppingCartParameters, ThisForm,,,,NotifyDescription);
	
EndProcedure

&AtClient
Procedure ShoppingCartClosing(ClosingParameters, Parametrs) Export
	
	ShoppingCart.Clear();
	
	If ClosingParameters <> Undefined Then
		For Each Row In ClosingParameters.ShoppingCart Do
			NewRow = ShoppingCart.Add();
			FillPropertyValues(NewRow, Row);
		EndDo;
	EndIf;
	
	SetInscriptionSelectedNomenclature();
	
EndProcedure

&AtClient
Procedure CreateDocument(DocumentName)
	
	ShoppingCartParameters = SaveSelectedToTempStorage();
	FillingValues = New Structure;
	FillingValues.Insert("BaseUnits", FilterWarehouse);
	FillingValues.Insert("PricesKind");
	If ShowPrices Then 
		FillingValues.PricesKind = FilterPriceKind;
	EndIf;
	ShoppingCartParameters.Insert("FillingValues", FillingValues);
	
	FormNameDocument = "Document." + DocumentName + ".ObjectForm";
	OpenForm(FormNameDocument, ShoppingCartParameters, ThisForm, UniqueKey);
	
	ShoppingCart.Clear();
	SetInscriptionSelectedNomenclature();
	
EndProcedure

#EndRegion

#EndRegion