
Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	RegistrationParametrs.Insert("Type", "PrintForm"); 
	
	DestinationArray = New Array();
	DestinationArray.Add("Document.Production");

	RegistrationParametrs.Insert("Presentation", DestinationArray);
	
	RegistrationParametrs.Insert("Description", "Forma de listare Bon de consum - productie");
	RegistrationParametrs.Insert("Version", "1.0"); 
	RegistrationParametrs.Insert("SafeMode", False);
	RegistrationParametrs.Insert("Information", "Forma de listare Bon de consum - productie");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
		"Bon de consum",						   
		"BonDeConsum_Productie",   					 	  
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

Procedure Print(ObjectArray, PrintFormsCollection, PrintObjects, OutputParametrs)  Export 
	
	Try
		TemplateName = PrintFormsCollection[0].DesignName;
	Except
		Message("en = 'Template name is empty!'; ro = 'Numele șablonului este gol!'; ru = 'Template name is empty!'");
		Return;
	EndTry;
	
	PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			TemplateName,  												
			TemplateName,   											
			CreatePrintForm(ObjectArray, PrintObjects, TemplateName));
	
EndProcedure

Function CreatePrintForm(ObjectsArray, PrintObjects, TemplateName)	

	Var Errors; 
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_Production"; 

	Template	= ThisObject.GetTemplate(TemplateName);
	
	FirstDocument = True;
	
	For Each CurrentDocument In ObjectsArray Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		FirstRowNumber = SpreadsheetDocument.TableHeight + 1;
		
			
	Query = New Query();
	Query.SetParameter("CurrentDocument", CurrentDocument);
	If CurrentDocument.TransactionType = Enums.TransactionTypesProduction.Assembly Then
				
	Query.Text =
	"SELECT
		|	Production.Date						 	AS DocumentDate,
		|	Production.BaseUnit						AS WarehousePresentation,
		|	Production.Cell 						AS CellPresentation,
		|	Production.Number 						AS Number,
		|	Production.Entity.Prefix 				AS Prefix,
		|	Production.Inventory.(
		|		LineNumber 							AS LineNumber,
		|		Nomenclature.Warehouse 				AS Warehouse,
		|		Nomenclature.Cell 					AS Cell,
		|		CASE
		|			WHEN (CAST(Production.Inventory.Nomenclature.DescriptionFull AS STRING(100))) = """"
		|				THEN Production.Inventory.Nomenclature.Description
		|			ELSE Production.Inventory.Nomenclature.DescriptionFull
		|		END 								AS InventoryItem,
		|		Nomenclature.SKU 					AS SKU,
		|		Nomenclature.Code 					AS Code,
		|		UnitOfMeasure.Description 			AS UnitOfMeasure,
		|		Quantity 							AS Quantity,
		|		Characteristic,
		|		Nomenclature.NomenclatureType 		AS NomenclatureType
		|	)
		|FROM
		|	Document.Production 					AS Production
		|WHERE
		|	Production.Ref = &CurrentDocument
		|
		|ORDER  BY
		|	LineNumber";
				
		Header = Query.Execute().Select();
		Header.Next();
				
		LinesSelectionInventory = Header.Inventory.Select();
				
		Else
				
		Query.Text = 
		"SELECT
		|	Production.Date 						AS DocumentDate,
		|	Production.BaseUnit 					AS WarehousePresentation,
		|	Production.Cell 						AS CellPresentation,
		|	Production.Number 						AS Number,
		|	Production.Entity.Prefix 				AS Prefix,
		|	Production.FinishedGoods.(
		|		LineNumber 							AS LineNumber,
		|		Nomenclature.Warehouse 				AS Warehouse,
		|		Nomenclature.Cell 					AS Cell,
		|		CASE
		|			WHEN (CAST(Production.FinishedGoods.Nomenclature.DescriptionFull AS STRING(100))) = """"
		|				THEN Production.FinishedGoods.Nomenclature.Description
		|			ELSE Production.FinishedGoods.Nomenclature.DescriptionFull
		|		END 								AS InventoryItem,
		|		Nomenclature.SKU 					AS SKU,
		|		Nomenclature.Code 					AS Code,
		|		UnitOfMeasure.Description 			AS UnitOfMeasure,
		|		Quantity 							AS Quantity,
		|		Characteristic 						AS Characteristic,
		|		Nomenclature.NomenclatureType 		AS NomenclatureType
		|	)
		|FROM
		|	Document.Production 					AS Production
		|WHERE
		|	Production.Ref = &CurrentDocument";

	       	 EndIf;

		Header = Query.Execute().Select();
	Header.Next();
	    
	LinesSelectionInventory = Header.Inventory.Select();
	
	If Header.DocumentDate < Date('20110101') Then
		DocumentNo = SmallBusinessServer.GetNumberForPrinting(Header.Number, Header.Prefix);
	Else
		DocumentNo = ObjectPrefixationClientServer.GetNumberForPrinting(Header.Number, True, True);
	EndIf;
	
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////TITLE////Start///////////////////////////////
/////////////////////////////////////////////////////////////////////////////
	
	TemplateArea = Template.GetArea("Title");
	TemplateArea.Parameters.HeaderText = "Bon de consum nr. "
											+ DocumentNo
											+ " din "
											+ Format(Header.DocumentDate, "L = ro; DLF=DD");
											
	SpreadsheetDocument.Put(TemplateArea);
	
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////TITLE////End//////////////////////////////
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
///////////////////////////////WAREHOUSE////Start////////////////////////////
/////////////////////////////////////////////////////////////////////////////

	TemplateArea = Template.GetArea("Warehouse");
	TemplateArea.Parameters.WarehousePresentation = Header.WarehousePresentation;
	
	SpreadsheetDocument.Put(TemplateArea);
	
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////WAREHOUSE////End////////////////////////////
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////CELL////Start///////////////////////////
/////////////////////////////////////////////////////////////////////////////

	If Constants.FunctionalOptionWarehouseManagementByLocations.Get() Then
		
	TemplateArea = Template.GetArea("Cell");
	TemplateArea.Parameters.CellPresentation = Header.CellPresentation;
	
	SpreadsheetDocument.Put(TemplateArea);
		
	EndIf;
	
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////CELL////End///////////////////////////
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
///////////////////////////////PRINTING TIME////Start////////////////////////
/////////////////////////////////////////////////////////////////////////////

	TemplateArea = Template.GetArea("PrintingTime");
	TemplateArea.Parameters.PrintingTime = "Data si ora printarii: "
										 	+ CurrentDate()
											+ ", Utilizator: "
											+ Users.CurrentUser();
	SpreadsheetDocument.Put(TemplateArea);
	
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////PRINTING TIME////End//////////////////////////
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
///////////////////////////////TABLE HEADER////Start/////////////////////////
/////////////////////////////////////////////////////////////////////////////

	TemplateArea = Template.GetArea("TableHeader");
	
	SpreadsheetDocument.Put(TemplateArea);
	
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////TABLE HEADER////End///////////////////////////
/////////////////////////////////////////////////////////////////////////////
	
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////STRING////Start///////////////////////////////
/////////////////////////////////////////////////////////////////////////////
	TemplateArea = Template.GetArea("String");
	
	While LinesSelectionInventory.Next() Do

		If Not LinesSelectionInventory.NomenclatureType = Enums.NomenclatureTypes.InventoryItem Then
			Continue;
		EndIf;	
			
	TemplateArea.Parameters.Fill(LinesSelectionInventory);
	TemplateArea.Parameters.InventoryItem = SmallBusinessServer.GetNomenclaturePresentationForPrinting(LinesSelectionInventory.InventoryItem, 
																LinesSelectionInventory.Characteristic, LinesSelectionInventory.SKU);
								
	SpreadsheetDocument.Put(TemplateArea);
						
	EndDo;

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////STRING////End//////////////////////////////
/////////////////////////////////////////////////////////////////////////////
	
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////TOTAL////Start//////////////////////////////
/////////////////////////////////////////////////////////////////////////////

	TemplateArea = Template.GetArea("Total");
	
	SpreadsheetDocument.Put(TemplateArea);
	
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////TOTAL////End//////////////////////////////
/////////////////////////////////////////////////////////////////////////////	

	PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstRowNumber, PrintObjects, CurrentDocument);
	EndDo;		
	SpreadsheetDocument.FitToPage = True;

	Return SpreadsheetDocument;

EndFunction 
