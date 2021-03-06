﻿///////////////////////////////////////////////////
//
// Preparation external print form
//
/////////////////////////////////////////////////// 
Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	RegistrationParametrs.Insert("Type", "PrintForm"); 
	
	DestinationArray = New Array();
	DestinationArray.Add("Document.InventoryTransfer");

	RegistrationParametrs.Insert("Presentation", DestinationArray);
	
	// Parameters for registration ExtProc in Application
	RegistrationParametrs.Insert("Description",  "NIR_DE_TRANSFER");
	RegistrationParametrs.Insert("Version",      "1.6");
	RegistrationParametrs.Insert("SafeMode",     True);
	RegistrationParametrs.Insert("Information",  "NIR");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
		"NIR",
		"NIR",
		"CallOfServerMethod",
		False,
		"MXLPrint");
		
	RegistrationParametrs.Insert("Commands", CommandTable);
	
	Return RegistrationParametrs;
	
EndFunction

Function GetCommandTable()
	
	Commands = New ValueTable;
	Commands.Columns.Add("Presentation",	New TypeDescription("String"));
	Commands.Columns.Add("ID",				New TypeDescription("String"));
	Commands.Columns.Add("Use",				New TypeDescription("String"));
	Commands.Columns.Add("ShowNotification",New TypeDescription("Boolean"));
	Commands.Columns.Add("Modifier",		New TypeDescription("String"));
	
	Return Commands;
	
EndFunction

Procedure AddCommand(CommandTable, Presentation, ID, Use, ShowNotification = False, Modifier = "")
	
	NewCommand	= CommandTable.Add();
	NewCommand.Presentation 	= Presentation;
	NewCommand.ID				= ID;
	NewCommand.Use				= Use;
	NewCommand.ShowNotification	= ShowNotification;
	NewCommand.Modifier			= Modifier;
	
EndProcedure

/////////////////////////////////////////////////////
//
// Preparing of Print Form 
//
/////////////////////////////////////////////////////
Procedure Print(ObjectArray, PrintFormsCollection, PrintObjects, OutputParametrs)  Export 
	
	Try
		TemplateName = PrintFormsCollection[0].DesignName;
	Except
		Message("en = 'TemplateName is empty!'; ro = 'TemplateName este goala!'; ru = 'TemplateName este goala!'");
		Return;
	EndTry;
	
	PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"NIR",
			"NIR",
			CreatePrintForm(ObjectArray, PrintObjects, TemplateName)
	);
	
EndProcedure

Function CreatePrintForm(ObjectsArray, PrintObjects, TemplateName) Export

	Var Errors;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_InventoryTransfer";
	
	// ЭтотОбъект - объект обработки где расположен Template
	// ThisObject - the Object of procedure where Template is placed
	Template = GetTemplate("MXLNIR");
	InsertPageBreak = False;

	For Each Object In ObjectsArray Do
		
		Recipient = Object.BaseUnitPayee;
		If Recipient.BaseUnitType <> Enums.StructuralUnitTypes.RetailAccrualAccounting Then
			Continue;
		EndIf;
		
		If InsertPageBreak Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
	
		Query = New Query();
		Query.Text = QueryText();
		Query.SetParameter("Object",     Object);
		Query.SetParameter("Period",     Object.Date);
		Query.SetParameter("PricesKind", Recipient.RetailPriceKind);
		
		TableGoods = Query.Execute().Unload();
		////////////////////Adelin
		
		Query = New Query();
		Query.Text =
			
"SELECT
|	InventoryTransfer.BaseUnit AS Sender,
|	InventoryTransfer.BaseUnitPayee AS Recipient,
|	InventoryTransfer.DocumentBasis,
|	InventoryTransfer.Date AS Date,
|	InventoryTransfer.Number,
|	InventoryTransfer.Entity.Description AS Entity,
|	InventoryTransfer.Entity.TIN AS ORC,
|	InventoryTransfer.Entity.CIO AS CUI
|FROM
|	Document.InventoryTransfer AS InventoryTransfer";

		Result		= Query.Execute();
		Selection	= Result.Choose();

		Selection.Next();
		
			
	//InfoAboutVendor  	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Entity, Selection.Date, ,);

		
		
		TemplateArea = Template.GetArea("Caption");
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Header");
		TemplateArea.Parameters.Fill(Selection);
	//TemplateArea.Parameters.Address		= SmallBusinessServer.EntitiesLongDescription(InfoAboutVendor, "LegalAddress,");

		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Header1");
		TemplateArea.Parameters.Fill(Selection);

		SpreadsheetDocument.Put(TemplateArea);
				
		TemplateArea = Template.GetArea("TitleTable");
		SpreadsheetDocument.Put(TemplateArea);
				////////////////////Adelin

		Number	 	 = 0;
  		Total		 = 0;
		TAdaos		 = 0;
		AVFaraTVA	 = 0;
		AValoareTVAT = 0;
		TotalFaraTVA = 0;
		
		For Each Row In TableGoods Do
			
			Number = Number + 1;
			TemplateArea = Template.GetArea("TableRow");
			StructureOfRow = NewStructureOfRow();
			FillPropertyValues(StructureOfRow, Row);
			StructureOfRow.Number = Number;
			StructureOfRow.SellingWithVAT = StructureOfRow.QuantityReal * StructureOfRow.SellingPrice * (StructureOfRow.VATRate / 100) + StructureOfRow.QuantityReal * StructureOfRow.SellingPrice;
			StructureOfRow.UnitaryValue = StructureOfRow.SellingValueWithoutVAT - StructureOfRow.ReceivedValueWithoutVAT;
			StructureOfRow.Excees = (StructureOfRow.UnitaryValue * 100 / StructureOfRow.ReceivedValueWithoutVAT);
			TemplateArea.Parameters.Fill(StructureOfRow);
			SpreadsheetDocument.Put(TemplateArea);
			
			Total		 = Total        + StructureOfRow.SellingWithVAT;
			TAdaos		 = TAdaos       + StructureOfRow.UnitaryValue;
			AVFaraTVA	 = AVFaraTVA    + StructureOfRow.ReceivedValueWithoutVAT;
			AValoareTVAT = AValoareTVAT + StructureOfRow.ReceivedVAT;
			TotalFaraTVA = TotalFaraTVA + StructureOfRow.SellingValueWithoutVAT;
		EndDo;
		
		TemplateArea = Template.GetArea("Totals");
		////TemplateArea.Parameters.Fill(Selection);


		TemplateArea.Parameters.Total	     = Total;
		TemplateArea.Parameters.TAdaos	     = TAdaos;
	    TemplateArea.Parameters.AVFaraTVA    = AVFaraTVA;
		TemplateArea.Parameters.AValoareTVAT = AValoareTVAT;
		TemplateArea.Parameters.TotalFaraTVA = TotalFaraTVA;
	
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Gestionari");
		TemplateArea.Parameters.Fill(Selection);

		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Footer");
		SpreadsheetDocument.Put(TemplateArea);

		InsertPageBreak = True;
		SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_" + TemplateName + "_" + TemplateName;
		CommonUseClientServer.ShowErrorsToUser(Errors);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction

Function QueryText()
	
	Text = 
	"SELECT
	|	Inventory.Nomenclature AS Nomenclature,
	|	Inventory.Characteristic AS Characteristic,
	|	Inventory.Quantity,
	|	Inventory.Amount,
	|	Inventory.VATRate
	|INTO ReceivedPrice
	|FROM
	|	AccumulationRegister.Inventory AS Inventory
	|WHERE
	|	Inventory.Recorder = &Object
	|
	|INDEX BY
	|	Nomenclature,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryTransferInventory.Ref,
	|	InventoryTransferInventory.Nomenclature,
	|	InventoryTransferInventory.Characteristic,
	|	InventoryTransferInventory.UnitOfMeasure AS Measure,
	|	InventoryTransferInventory.Quantity AS QuantityAccording,
	|	ReceivedPrice.Quantity AS QuantityReal,
	|	ReceivedPrice.Amount / InventoryTransferInventory.Quantity AS AquisitionPrice,
	|	ReceivedPrice.Amount AS ReceivedValueWithoutVAT,
	|	ReceivedPrice.Amount * (InventoryTransferInventory.Nomenclature.VATRate.Rate / 100) AS ReceivedVAT,
	|	InventoryTransferInventory.Nomenclature.VATRate.Rate AS VATRate,
	|	NomenclaturePricesSliceLast.Price AS SellingPrice,
	|	InventoryTransferInventory.Quantity * NomenclaturePricesSliceLast.Price AS SellingValueWithoutVAT
	|FROM
	|	Document.InventoryTransfer.Inventory AS InventoryTransferInventory
	|		LEFT JOIN ReceivedPrice AS ReceivedPrice
	|		ON InventoryTransferInventory.Nomenclature = ReceivedPrice.Nomenclature
	|			AND InventoryTransferInventory.Characteristic = ReceivedPrice.Characteristic
	|		LEFT JOIN InformationRegister.NomenclaturePrices.SliceLast(&Period, PricesKind = &PricesKind) AS NomenclaturePricesSliceLast
	|		ON InventoryTransferInventory.Nomenclature = NomenclaturePricesSliceLast.Nomenclature
	|			AND InventoryTransferInventory.Characteristic = NomenclaturePricesSliceLast.Characteristic
	|WHERE
	|	InventoryTransferInventory.Ref = &Object";
	Return Text;
	
EndFunction

Function NewStructureOfRow()
	Structure = New Structure;
	Structure.Insert("Number");
	Structure.Insert("Nomenclature");
	Structure.Insert("Measure");
	Structure.Insert("QuantityAccording", 0);
	Structure.Insert("QuantityReal", 0);
	Structure.Insert("AquisitionPrice", 0);
	Structure.Insert("ReceivedValueWithoutVAT", 0);
	Structure.Insert("ReceivedVAT", 0);
	Structure.Insert("VATRate");
	Structure.Insert("Excees", 0);
	Structure.Insert("UnitaryValue", 0);
	Structure.Insert("SellingPrice", 0);
	Structure.Insert("SellingValueWithoutVAT", 0);
	Structure.Insert("SellingWithVAT", 0);
	Return Structure;
	
EndFunction