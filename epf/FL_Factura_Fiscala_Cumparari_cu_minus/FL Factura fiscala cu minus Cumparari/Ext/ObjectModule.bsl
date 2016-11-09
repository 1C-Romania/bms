
Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	RegistrationParametrs.Insert("Type", "PrintForm"); 
	
	DestinationArray = New Array();
	DestinationArray.Add("Document.InventoryReceipt");

	RegistrationParametrs.Insert("Presentation", DestinationArray);
	
	RegistrationParametrs.Insert("Description", "Forma de listare Factura fiscala(minus)");
	RegistrationParametrs.Insert("Version", "2.2"); 
	RegistrationParametrs.Insert("SafeMode", False);
	RegistrationParametrs.Insert("Information", "Forma de listare Factura fiscala(minus)");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
	"Factura fiscala",						   
	"FacturaFiscalaMinus",   				 
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
	
//"SELECT
//	|	InventoryReceipt.Counterparty AS Company,
//	|	InventoryReceipt.Date,
//	|	InventoryReceipt.Number,
//	|	InventoryReceipt.DocumentBasis,
//	|	InventoryReceipt.Entity,
//	|	InventoryReceipt.DateOfIncomingDocument,
//	|	InventoryReceipt.IncomingDocumentNo,
//	|	InventoryReceipt.Responsible,
//	|	InventoryReceipt.ExchangeRate,
//	|	InventoryReceipt.DocumentCurrency,
//	|	InventoryReceipt.Inventory.(
//	|		LineNumber AS LineNumber,
//	|		Nomenclature,
//	|		UnitOfMeasure,
//	|		Quantity,
//	|		VATAmount,
//	|		TotalAmount AS AmountTotal,
//	|		Price,
//	|		Amount,
//	|		ExpenseAmount
//	|	),
//	|	InventoryReceipt.hiDocumentAmountWithoutVAT AS TotalFaraTVA,
//	|	InventoryReceipt.hiDocumentVATAmount AS TotalTVA,
//	|	InventoryReceipt.DocumentAmount AS Total,
//	|	InventoryReceipt.AmountIncludesVAT AS SumaIncludeTva
//	|FROM
//	|	Document.InventoryReceipt AS InventoryReceipt
//	|WHERE
//	|	InventoryReceipt.Ref IN(&Ref)
//	|
//	|ORDER BY
//	|	LineNumber";
//	
	
	
	
	"SELECT
	|	InventoryReceipt.Counterparty AS Company,
	|	InventoryReceipt.Date,
	|	InventoryReceipt.Number,
	|	InventoryReceipt.DocumentBasis,
	|	InventoryReceipt.Entity,
	|	InventoryReceipt.DateOfIncomingDocument,
	|	InventoryReceipt.IncomingDocumentNo,
	|	InventoryReceipt.Responsible,
	|	InventoryReceipt.Inventory.(
	|		LineNumber AS LineNumber,
	|		Nomenclature,
	|		UnitOfMeasure,
	|		Quantity,
	|		Quantity AS Suma,
	|		VATAmount,
	|		TotalAmount AS AmountTotal,
	|		Price,
	|		Amount AS AmountWhitoutTVA
	|	),
	|	InventoryReceipt.ExchangeRate,
	|	InventoryReceipt.DocumentCurrency,
	|	InventoryReceipt.Entity.TIN AS NrOrcE,
	|	InventoryReceipt.Entity.BankAccountByDefault.AccountNo AS BankAccountE,
	|	InventoryReceipt.Entity.BankAccountByDefault.Bank AS BankE,
	|	InventoryReceipt.Entity.Capital AS Capital,
	|	InventoryReceipt.Counterparty.TIN AS NrOrcC,
	|	InventoryReceipt.Counterparty.BankAccountByDefault.AccountNo AS BankAccountC,
	|	InventoryReceipt.Counterparty.BankAccountByDefault.Bank AS BankC,
	|	InventoryReceipt.hiDocumentVATAmount AS SDTotalTVA,
	|	InventoryReceipt.hiDocumentAmountWithoutVAT AS SDFaraTVA,
	|	InventoryReceipt.DocumentAmount AS SDTotal,
	|	InventoryReceipt.TransactionType AS TipTranzactie,
	|	InventoryReceipt.Author,
	|	InventoryReceipt.DocumentBasis.Driver AS Driver,
	|	InventoryReceipt.DocumentBasis.Readdressing AS Readdressing,
	|	InventoryReceipt.DocumentBasis.Driver.IDCard AS DriverIDCard,
	|	InventoryReceipt.DocumentBasis.Driver.PersonalCode AS DriverPersonalCode,
	|	TransactionTypesInventoryReceipt.Ref AS RefTip,
	|	TransactionTypesInventoryReceipt.Order AS OrderTip,
	|	InventoryReceipt.Posted AS PostedA
	|FROM
	|	Document.InventoryReceipt AS InventoryReceipt
	|		LEFT JOIN Enum.TransactionTypesInventoryReceipt AS TransactionTypesInventoryReceipt
	|		ON InventoryReceipt.TransactionType = TransactionTypesInventoryReceipt.Ref
	|WHERE
	|	InventoryReceipt.Ref IN(&Ref)
	|
	|ORDER BY
	|	LineNumber";
	
	
	
	Query.Parameters.Insert("Ref", Ref);
	Selection = Query.Execute().Choose();

		AreaCaption	 		= Template.GetArea("Caption");
		Header 				= Template.GetArea("Header");
		AreaInventoryHeader = Template.GetArea("InventoryHeader");
		AreaInventory 		= Template.GetArea("Inventory");
		Footer 				= Template.GetArea("Footer");
	Spreadsheet.Clear();

	InsertPageBreak = False;
	While Selection.Next() Do
	If InsertPageBreak Then
		Spreadsheet.PutHorizontalPageBreak();
	EndIf;
		DocRate = WorkWithExchangeRates.GetCurrencyRate(Selection.DocumentCurrency, BegOfDay(Selection.Date)); 
		NatRate = WorkWithExchangeRates.GetCurrencyRate(Constants.NationalCurrency.get(), BegOfDay(Selection.Date));
	Try
		ERate = DocRate.ExchangeRate / NatRate.ExchangeRate;
	Except
		Message("Cursul valutar nu este actualizat!");
		Rate = 1;
	EndTry;
	Spreadsheet.Put(AreaCaption);
	
	Header.Parameters.Fill(Selection);
		////////////////////////Header/////////////////////////////
	InfoAboutVendor  = SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Entity, Selection.Date, ,);
	InfoAboutVendorC = SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Company, Selection.Date, ,);
		
	Header.Parameters["CFE"] 		= Selection.Entity.CIO;
	Header.Parameters["CFC"] 		= Selection.Company.CIO;
	Header.Parameters["AdresaE"]	= SmallBusinessServer.EntitiesLongDescription(InfoAboutVendor, "LegalAddress,");
	Header.Parameters["AdresaC"] 	= SmallBusinessServer.EntitiesLongDescription(InfoAboutVendorC, "LegalAddress,");
	Header.Parameters["Number"] 	= Selection.Number;
	Header.Parameters["Date"]		= Selection.Date;
	Header.Parameters["ERate"]		= ERate;

	
	Spreadsheet.Put(Header, Selection.Level());
		
		////////////////////////Header/////////////////////////////

//		Header1.Parameters["DocumentBasis"] = Selection.DocumentBasis;
//				Header1.Parameters["Company"]		= Selection.Company;
//		Header1.Parameters["DocNumber"] 	= Selection.IncomingDocumentNo;
//		Header1.Parameters["DocDate"] 		= Selection.DateOfIncomingDocument;
//		ERate = Selection.ExchangeRate;
//		Header1.Parameters["ERate"]= ERate;	
//		Spreadsheet.Put(Header1);

///////////////////////////////AreaInventoryHeader/////////////////////////////////////
	Spreadsheet.Put(AreaInventoryHeader);
///////////////////////////////AreaInventoryHeader/////////////////////////////////////
	

	
///////////////////////////////AreaInventory/////////////////////////////////////
///////////////////////////////AreaInventory/////////////////////////////////////
AreaInventory.Parameters.Fill(Selection);
SelectionInventory = Selection.Inventory.Choose();
While SelectionInventory.Next() Do
	
	
	AreaInventory.Parameters["LineNumber"]	    =SelectionInventory.LineNumber;
	AreaInventory.Parameters["Nomenclature"]	=SelectionInventory.Nomenclature;
	AreaInventory.Parameters["Price"]	      	=Format(Round(SelectionInventory.Price*ERate,2),"NFD=2");
	AreaInventory.Parameters["UnitOfMeasure"]	=SelectionInventory.UnitOfMeasure;
	AreaInventory.Parameters["Quantity"]		=SelectionInventory.Quantity;				
	
Try
	AreaInventory.Parameters["VATAmount"]		=Format(Round("-"+SelectionInventory.VATAmount*ERate,2),"NFD=2");
Except
			
EndTry;
	AreaInventory.Parameters["Amount"]	  		=Format(Round("-"+SelectionInventory.AmountWhitoutTVA*ERate,2),"NFD=2");
			
	i = SelectionInventory.LineNumber;
Spreadsheet.Put(AreaInventory, SelectionInventory.Level());
EndDo;
	
	

	For i=i +1 To 35 Do 
				
	AreaInventory.Parameters["LineNumber"]				= i;
	AreaInventory.Parameters["Nomenclature"]			= Undefined;
	AreaInventory.Parameters["Price"]	     			= Undefined;
	AreaInventory.Parameters["Amount"]	      			= Undefined;
	AreaInventory.Parameters["Quantity"]	   			= Undefined;
	AreaInventory.Parameters["UnitOfMeasure"]	      	= Undefined;
Try
	AreaInventory.Parameters["VATAmount"]		= Undefined;
Except
			
EndTry;

	Spreadsheet.Put(AreaInventory, SelectionInventory.Level());
EndDo;
	

///////////////////////////////AreaInventoryHeader/////////////////////////////////////
///////////////////////////////AreaInventoryHeader/////////////////////////////////////	


//////////////////////Footer
	Footer.Parameters["SDTotalTVA"]  =Format(Round("-"+Selection.SDTotalTVA*ERate,2),"NFD=2");
	Footer.Parameters["SDFaraTVA"]   =Format(Round("-"+Selection.SDFaraTVA*ERate,2),"NFD=2");
	Footer.Parameters["SDTotal"]     =Format(Round("-"+Selection.SDTotal*ERate,2),"NFD=2");
	
	Query		= New Query;
		Query.Text	= 
		"SELECT
		|	UserEmployees.Employee,
		|	UserEmployees.User
		|FROM
		|	InformationRegister.UserEmployees AS UserEmployees
		|WHERE
		|	UserEmployees.User = &Author";
		
		Query.SetParameter("Author", Selection.Author);
		
		Result		= Query.Execute();
		SelectionD	= Result.Choose();
		
		While SelectionD.Next() Do
			Try
				Footer.Parameters["CNPU"]	= SelectionD.Employee.Ind.PersonalCode;
				Footer.Parameters["CIU"]	= SelectionD.Employee.Ind.IDCard;
				Footer.Parameters["User"]				= Selection.Author;	
			Except
			
			EndTry;
	Footer.Parameters["CNP"]				= Selection.DriverPersonalCode;
	Footer.Parameters["Driver"]				= Selection.Driver;
	Footer.Parameters["CI"]					= Selection.DriverIDCard;
	Footer.Parameters["MijlocDeTransport"]	= Selection.Readdressing;
	Footer.Parameters["Date"]				= Selection.Date;
EndDo;
		
	
		

	Spreadsheet.Put(Footer);

//////////////////////Footer

	InsertPageBreak = True;
	
EndDo; 
Message ("Atenție! Această imprimare este specifică doar pentru documentele cu tipul operațiunii ""Returnare de la cumpărător""");
If Selection.PostedA = False Then Spreadsheet.BackgroundPicture = New Picture(GetTemplate("Template"), True);
EndIf;

Return Spreadsheet;                              

EndFunction 
