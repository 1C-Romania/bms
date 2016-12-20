#Region FormEvents

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AddressCartInTempStorage") And ValueIsFilled(Parameters.AddressCartInTempStorage) Then
		ShoppingCart.Load(GetFromTempStorage(Parameters.AddressCartInTempStorage));
	EndIf;
	If Parameters.Property("UniqueKeyOfOwner") And ValueIsFilled(Parameters.UniqueKeyOfOwner) Then
		UniqueKeyOfOwner = Parameters.UniqueKeyOfOwner;
	EndIf;
	If Parameters.Property("FilterWarehouse") And ValueIsFilled(Parameters.FilterWarehouse) Then
		FilterWarehouse = Parameters.FilterWarehouse;
	EndIf;
	If Parameters.Property("FilterPriceKind") And ValueIsFilled(Parameters.FilterPriceKind) Then
		FilterPriceKind = Parameters.FilterPriceKind;
	EndIf;
	
	ShowPrices = Parameters.ShowPrices;
	Items.ShoppingCartPrice.Visible = ShowPrices;
	Items.ShoppingCartAmount.Visible = ShowPrices;
	
	SetInscriptionSelectedNomenclature(ThisForm);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If Not AccessClose Then
		Cancel = True;
		AttachIdleHandler("CloseFormMoveToCart", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Procedure Clear(Command)
	
	ShoppingCart.Clear();
	Close();
	
EndProcedure

&AtClient
Procedure Browse(Command)
	
	CloseStructure = New Structure;
	CloseStructure.Insert("ShoppingCart", ShoppingCart);
	CloseStructure.Insert("MoveIntoDocument", MoveIntoDocument);
	Close(CloseStructure);
	
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

#Region ListEvents

&AtClient
Procedure ShoppingCartOnChange(Item)
	
	SetInscriptionSelectedNomenclature(ThisForm);
	
EndProcedure

&AtClient
Procedure ShoppingCartCountOnChange(Item)
	
	CurrentRow = Items.ShoppingCart.CurrentData;
	CurrentRow.Amount = CurrentRow.Quantity * CurrentRow.Price;
	
EndProcedure

#EndRegion

#Region InternalProceduresFunctions

&AtClientAtServerNoContext
Procedure SetInscriptionSelectedNomenclature(Form)
	
	TotalCount = Form.ShoppingCart.Total("Quantity");
	TotalAmount = Form.ShoppingCart.Total("Amount");
	
	If Form.ShoppingCart.Count() = 0 Then
		Form.SelectedNomenclatures = 
			NStr("ru = 'Перетащите товары в корзину';en='Drag the items to the cart'; ro = 'Trageți articolele coș'");
	Else
		If Form.ShowPrices Then
			Form.SelectedNomenclatures = StringFunctionsClientServer.PlaceParametersIntoString(
				NStr("ru = 'Подобрано: %1 на сумму %2';en='Selected: %1 amount of %2'; ro = 'Selectate: %1 Suma: %2'"), 
				TotalCount,
				TotalAmount);
		Else
			Form.SelectedNomenclatures = StringFunctionsClientServer.PlaceParametersIntoString(
				NStr("ru = 'Подобрано: %1';en='Selected: %1'; ro = 'Selectate: %1'"), TotalCount);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseFormMoveToCart() Export
	
	AccessClose = True;
	If MoveIntoDocument Then
		Close();
	Else
		Close(New Structure("ShoppingCart", ShoppingCart));
	EndIf;
	
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
	MoveIntoDocument = True;
	
	Close();
	
EndProcedure

&AtServer
Function SaveSelectedToTempStorage()
	
	AddressCartInTempStorage = PutToTempStorage(ShoppingCart.Unload(), UniqueKeyOfOwner);
	Return New Structure("AddressCartInTempStorage, UniqueKeyOfOwner", AddressCartInTempStorage, UniqueKeyOfOwner);
	
EndFunction

&AtClient
Procedure ShoppingCartPriceOnChange(Item)
	
	CurrentRow = Items.ShoppingCart.CurrentData;
	CurrentRow.Amount = CurrentRow.Quantity * CurrentRow.Price;
	
EndProcedure

#EndRegion