
Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	RegistrationParametrs.Insert("Type", "PrintForm"); 
	
	DestinationArray = New Array();
	DestinationArray.Add("Document.InventoryReceipt");

	RegistrationParametrs.Insert("Presentation", DestinationArray);
	
	RegistrationParametrs.Insert("Description", "Forma de listare la doc. Cumparari marfuri si servicii-NIR");
	RegistrationParametrs.Insert("Version", "2.0"); 
	RegistrationParametrs.Insert("SafeMode", False);
	RegistrationParametrs.Insert("Information", "Forma de listare la doc. Cumparari marfuri si servicii-NIR");
	
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

Procedure Print(ObjectArray, PrintFormsCollection, PrintObjects, OutputParametrs)  Export 
	
	Try
		TemplateName = PrintFormsCollection[0].DesignName;
	Except
		Message("en = 'TemplateName is empty!'; ro = 'TemplateName este goala!'; ru = 'TemplateName este goala!'");
		Return;
	EndTry;
	
	PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			TemplateName,  												
			TemplateName,   											
			CreatePrintForm(ObjectArray, PrintObjects, TemplateName));
	
EndProcedure

Function CreatePrintForm(Ref, PrintObjects, TemplateName)		
	
	Var Errors;
	
	Spreadsheet = New SpreadsheetDocument;
	Spreadsheet.PrintParametersKey = "PrintParameters_InventoryReceipt";

	Template = ThisObject.GetTemplate(TemplateName);
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	InventoryReceipt.Counterparty AS Company,
	|	InventoryReceipt.Date,
	|	InventoryReceipt.Number,
	|	InventoryReceipt.DocumentBasis,
	|	InventoryReceipt.Entity,
	|	InventoryReceipt.DateOfIncomingDocument,
	|	InventoryReceipt.IncomingDocumentNo,
	|	InventoryReceipt.Responsible,
	|	InventoryReceipt.ExchangeRate,
	|	InventoryReceipt.DocumentCurrency,
	|	InventoryReceipt.Inventory.(
	|		LineNumber AS LineNumber,
	|		Nomenclature,
	|		UnitOfMeasure,
	|		Quantity,
	|		VATAmount,
	|		TotalAmount AS AmountTotal,
	|		Price,
	|		Amount,
	|		ExpenseAmount
	|	),
	|	InventoryReceipt.hiDocumentAmountWithoutVAT AS TotalFaraTVA,
	|	InventoryReceipt.hiDocumentVATAmount AS TotalTVA,
	|	InventoryReceipt.DocumentAmount AS Total,
	|	InventoryReceipt.AmountIncludesVAT AS SumaIncludeTva
	|FROM
	|	Document.InventoryReceipt AS InventoryReceipt
	|WHERE
	|	InventoryReceipt.Ref IN(&Ref)
	|
	|ORDER BY
	|	LineNumber";
	
	Query.Parameters.Insert("Ref", Ref);
	Selection = Query.Execute().Choose();
    Tab= Query.Execute().Unload();
		AreaCaption	 		= Template.GetArea("Caption");
		Header 				= Template.GetArea("Header");
		Header1 			= Template.GetArea("Header1");
		AreaInventoryHeader = Template.GetArea("InventoryHeader");
		AreaInventory 		= Template.GetArea("Inventory");
		Footer 				= Template.GetArea("Footer");
		Totals 				= Template.GetArea("Totals");
		Gestionari			= Template.GetArea("Gestionari");
	Spreadsheet.Clear();

	InsertPageBreak = False;
	Cheltuieli  = 0;
	Total       = 0;
	While Selection.Next() Do
	If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
	EndIf;
		DocRate = WorkWithExchangeRates.GetCurrencyRate(Selection.DocumentCurrency, BegOfDay(Selection.Date)); 
		NatRate = WorkWithExchangeRates.GetCurrencyRate(Constants.NationalCurrency.get(), BegOfDay(Selection.Date));
	Try
			Rate = DocRate.ExchangeRate / NatRate.ExchangeRate;
	Except
			Message("Cursul valutar nu este actualizat!");
			Rate = 1;
	EndTry;
		

		Spreadsheet.Put(AreaCaption);
		InfoAboutVendor  = SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Entity, Selection.Date, ,);
		InfoAboutVendorC = SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Company, Selection.Date, ,);
		
		Header.Parameters["CFE"] 		= Selection.Entity.CIO;
		Header.Parameters["CFC"] 		= Selection.Company.CIO;
		Header.Parameters["AdresaE"]	= SmallBusinessServer.EntitiesLongDescription(InfoAboutVendor, "LegalAddress,");
		Header.Parameters["AdresaC"] 	= SmallBusinessServer.EntitiesLongDescription(InfoAboutVendorC, "LegalAddress,");
		
		Header.Parameters.Fill(Selection);
		Spreadsheet.Put(Header, Selection.Level());
		Header1.Parameters["DocumentBasis"] = Selection.DocumentBasis;
		Header1.Parameters["Number"] 		= Selection.Number;
		Header1.Parameters["Date"]			= Selection.Date;
		Header1.Parameters["Company"]		= Selection.Company;
		Header1.Parameters["DocNumber"] 	= Selection.IncomingDocumentNo;
		Header1.Parameters["DocDate"] 		= Selection.DateOfIncomingDocument;
		ERate = Selection.ExchangeRate;
		Header1.Parameters["ERate"]= ERate;
		
		Spreadsheet.Put(Header1);
		Spreadsheet.Put(AreaInventoryHeader);
		//SelectionExpenses = Selection.Expenses.Choose();
		//While SelectionExpenses.Next() Do
			Cheltuieli = Cheltuieli + 100;//SelectionExpenses.TotalAmount
			VAT = 20;//SelectionExpenses.VATRate;
		//EndDo;	
		
		SelectionInventory = Selection.Inventory.Choose();
	While SelectionInventory.Next() Do
		Expense = SelectionInventory.ExpenseAmount / (1 + ?(VAT <> Undefined, 20 / 100, 0)); // VAT.Rate
		AreaInventory.Parameters.Fill(SelectionInventory);
		AreaInventory.Parameters["Price"]	= SelectionInventory.Price*ERate;
		AreaInventory.Parameters["TVA"]		= SelectionInventory.VATAmount*ERate;
			
		SUMAFARATVA	=	(SelectionInventory.Amount+ SelectionInventory.ExpenseAmount);	
		
	If  Selection.SumaIncludeTva = False Then 
		AreaInventory.Parameters["SumafaraTVA"]	=(SelectionInventory.Amount+ SelectionInventory.ExpenseAmount)*ERate;
			
	Else
		AreaInventory.Parameters["SumafaraTVA"]	=(SUMAFARATVA-SelectionInventory.VATAmount)*ERate;
	EndIf;
	
			AreaInventory.Parameters["SumaCuTVA"]	=(SelectionInventory.AmountTotal + SelectionInventory.ExpenseAmount)*ERate;
			
			AreaInventory.Parameters["Expenses"]= SelectionInventory.ExpenseAmount*ERate;
			AreaInventory.Parameters["Unitar"]  =(SelectionInventory.Price + 
													SelectionInventory.ExpenseAmount)*ERate;
			Spreadsheet.Put(AreaInventory, SelectionInventory.Level());
			
		//Total								=  Total + ( SelectionInventory.AmountTotal) + SelectionInventory.ExpenseAmount;
	EndDo;
		//Totals.Parameters["Total"] = Total*ERate;

		Totals.Parameters["TotalFaraTVA"] 	= Selection.TotalFaraTVA *ERate;
		Totals.Parameters["TotalTVA"] 		= Selection.TotalTVA*ERate;
		Totals.Parameters["Total"] 			= Selection.Total*ERate;
   

		Spreadsheet.Put(Totals);
		
		Gestionari.Parameters.Fill(Selection);
		Spreadsheet.Put(Gestionari);
		Footer.Parameters.Fill(Selection);
		Spreadsheet.Put(Footer);
		InsertPageBreak = True;
	EndDo;
	
	Return Spreadsheet;

EndFunction 
