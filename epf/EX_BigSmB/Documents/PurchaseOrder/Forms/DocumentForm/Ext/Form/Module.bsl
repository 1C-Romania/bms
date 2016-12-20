&AtServer
Procedure BSB_OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("AddressCartInTempStorage") Then
		Return;
	EndIf;
	
	ShoppingCart = GetFromTempStorage(Parameters.AddressCartInTempStorage);
	Object.Inventory.Load(ShoppingCart);
	
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
	
	StructureData = New Structure;
	StructureData.Insert("Entity", Object.Entity);
	StructureData.Insert("Nomenclature", Row.Nomenclature);
	StructureData.Insert("Characteristic", Row.Characteristic);
	StructureData.Insert("TaxationVAT", Object.TaxationVAT);
	
	If ValueIsFilled(Object.CounterpartyPriceKinds) Then
		
		StructureData.Insert("ProcessingDate", Object.Date);
		StructureData.Insert("DocumentCurrency", Object.DocumentCurrency);
		StructureData.Insert("AmountIncludesVAT", Object.AmountIncludesVAT);
		StructureData.Insert("CounterpartyPriceKinds", Object.CounterpartyPriceKinds);
		StructureData.Insert("Factor", 1);
		
	EndIf;
	
	StructureData = GetDataNomenclatureOnChange(StructureData);
	
	Row.UnitOfMeasure = StructureData.UnitOfMeasure;
	Row.Price = StructureData.Price;
	Row.VATRate = StructureData.VATRate;
	Row.Content = "";
	
	CalculateAmountInTabularSectionLine(Row);
	
EndProcedure