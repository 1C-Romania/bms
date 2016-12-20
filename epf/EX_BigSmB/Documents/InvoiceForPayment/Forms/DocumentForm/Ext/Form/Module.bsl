&AtServer
Procedure BSB_OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("AddressCartInTempStorage") Then
		Return;
	EndIf;
	
	ShoppingCart = GetFromTempStorage(Parameters.AddressCartInTempStorage);
	Object.Inventory.Load(ShoppingCart);
	
	SetExecutionAfterEventHandlers("BSB_OnCreateAtServerContinue", Parameters.FillingValues.PricesKind);
	
EndProcedure

&AtServer
Procedure BSB_OnCreateAtServerContinue(Cancel, StandardProcessing, PricesKind)
	
	If ValueIsFilled(PricesKind) Then
		Object.PricesKind = PricesKind;
		// 
		CurrencyTransactions = Constants.FunctionalOptionCurrencyTransactions.Get();
		LabelStructure = New Structure("PricesKind, DiscountKind, DocumentCurrency, AccountsCurrency, ExchangeRate, AmountIncludesVAT, CurrencyTransactions, RateNationalCurrency, TaxationVAT", Object.PricesKind, Object.DiscountMarkupKind, Object.DocumentCurrency, AccountsCurrency, Object.ExchangeRate, Object.AmountIncludesVAT, CurrencyTransactions, RateNationalCurrency, Object.TaxationVAT);
		PricesAndCurrency = GenerateLabelPricesAndCurrency(LabelStructure);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BSB_OnOpen(Cancel)
	
	If Object.Inventory.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Row In Object.Inventory Do
		OnChangeNomenclature(Row);
	EndDo;
	
EndProcedure

&AtClient
Procedure OnChangeNomenclature(Row)
	
	StructureData = New Structure();
	
	StructureData.Insert("Entity",             Object.Entity);
	StructureData.Insert("ProcessingDate",     Object.Date);
	StructureData.Insert("PricesKind",         Object.PricesKind);
	StructureData.Insert("DocumentCurrency",   Object.DocumentCurrency);
	StructureData.Insert("AmountIncludesVAT",  Object.AmountIncludesVAT);
	StructureData.Insert("Nomenclature",       Row.Nomenclature);
	StructureData.Insert("Characteristic",     Row.Characteristic);
	StructureData.Insert("Price",              Row.Price);
	StructureData.Insert("Factor",             1);
	StructureData.Insert("TaxationVAT",        Object.TaxationVAT);
	StructureData.Insert("DiscountMarkupKind", Object.DiscountMarkupKind);
	
	StructureData = GetDataNomenclatureOnChange(StructureData);
	
	Row.UnitOfMeasure = StructureData.UnitOfMeasure;
	Row.Price = StructureData.Price;
	Row.DiscountMarkupRate = StructureData.DiscountMarkupRate;
	Row.VATRate = StructureData.VATRate;
	Row.Content = "";
	
	CalculateAmountInTabularSectionLine(Row);
	
EndProcedure