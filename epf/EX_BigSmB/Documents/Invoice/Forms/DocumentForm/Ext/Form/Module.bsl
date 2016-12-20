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
	StructureData.Insert("TransactionType", Object.TransactionType);
	StructureData.Insert("Nomenclature", Row.Nomenclature);
	StructureData.Insert("Characteristic", Row.Characteristic);
	
	StructureData = GetDataNomenclatureOnChange(StructureData);
	
	FillPropertyValues(Row, StructureData);
	Row.Content = "";
	
	CalculateAmountInTabularSectionLine(Row);
	
EndProcedure