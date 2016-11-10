
Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	RegistrationParametrs.Insert("Type", "PrintForm"); 
	DestinationArray = New Array();
	DestinationArray.Add("Document.PettyCashExpense");
	RegistrationParametrs.Insert("Presentation", DestinationArray);
	RegistrationParametrs.Insert("Description", "Forma de listare - Dispoziție de plată");
	RegistrationParametrs.Insert("Version", "1.1"); 
	RegistrationParametrs.Insert("SafeMode", False); 
	RegistrationParametrs.Insert("Information", "Forma de listare - Dispoziție de plată");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
	"Dispoziție de plată",						
	"DispozitieDePlata",   					 	     
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
	Message("en = 'Template name is empty!'; ro = 'Numele șablonului este necompletat!'; ru = 'Numele șablonului este necompletat'");
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
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_PettyCashExpense";
	DesignName	= ThisObject.GetTemplate(TemplateName);
	
	FirstDocument = True;
	
	For Each CurrentDocument In ObjectsArray Do
	
	If Not FirstDocument Then
		SpreadsheetDocument.PutHorizontalPageBreak();
	EndIf;
		FirstDocument = False;
		
		FirstRowNumber = SpreadsheetDocument.TableHeight + 1;
		
		Query = New Query();
		Query.SetParameter("CurrentDocument", CurrentDocument);
		
		Query.Text =
		   "SELECT
		   |	PettyCashExpense.Ref,
		   |	PettyCashExpense.DataVersion,
		   |	PettyCashExpense.Number,
		   |	PettyCashExpense.Date,
		   |	PettyCashExpense.Author,
		   |	PettyCashExpense.CashCurrency,
		   |	PettyCashExpense.TaxKind,
		   |	PettyCashExpense.TransactionType,
		   |	PettyCashExpense.Document,
		   |	PettyCashExpense.DocumentBasis,
		   |	PettyCashExpense.GoodsOrder,
		   |	PettyCashExpense.PettyCash,
		   |	PettyCashExpense.Comment,
		   |	PettyCashExpense.Counterparty,
		   |	PettyCashExpense.Correspondence,
		   |	PettyCashExpense.BusinessActivity,
		   |	PettyCashExpense.Entity,
		   |	PettyCashExpense.Basis,
		   |	PettyCashExpense.RegistrationPeriod,
		   |	PettyCashExpense.ByDocument,
		   |	PettyCashExpense.AdvanceHolder,
		   |	PettyCashExpense.Department,
		   |	PettyCashExpense.Application,
		   |	PettyCashExpense.Article,
		   |	PettyCashExpense.DocumentAmount,
		   |	PettyCashExpense.TaxationVAT,
		   |	PettyCashExpense.CashRegister,
		   |	PettyCashExpense.RetailReceiptNo,
		   |	PettyCashExpense.PaymentDetails.(
		   |		Ref,
		   |		LineNumber,
		   |		Contract,
		   |		AdvanceFlag,
		   |		Document,
		   |		SettlementsAmount,
		   |		ExchangeRate,
		   |		Multiplicity,
		   |		PaymentAmount,
		   |		VATRate,
		   |		VATAmount,
		   |		GoodsOrder,
		   |		InvoiceForPayment,
		   |		PlanningDocument
		   |	),
		   |	PettyCashExpense.SalaryPay.(
		   |		Ref,
		   |		LineNumber,
		   |		Statement,
		   |		PaymentAmount,
		   |		PlanningDocument
		   |	)
		   |FROM
		   |	Document.PettyCashExpense AS PettyCashExpense";
			
	ResultsArray = Query.ExecuteBatch();
	Header = ResultsArray[0].Select();
	Header.Next();
		
		
//////////////////////////////////////////////////////////////////////////////
///////////////////////////////CAPTION////Start////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
	TemplateArea = DesignName.GetArea("Caption");
		
	TemplateArea.Parameters.Fill(Header);

	SpreadsheetDocument.Put(TemplateArea);
//////////////////////////////////////////////////////////////////////////////
///////////////////////////////CAPTION//////End////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
		
//////////////////////////////////////////////////////////////////////////////
///////////////////////////////HEADER////Start////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
	TemplateArea = DesignName.GetArea("Header");
		 
	TemplateArea.Parameters.Fill(Header);
	
	TemplateArea.Parameters.AmountInWords = SmallBusinessServer.FormatPaymentDocumentAmountInWords(
																						Header.DocumentAmount,
																							Header.CashCurrency,
																							False
																							)+"i";
	SpreadsheetDocument.Put(TemplateArea);
	
//////////////////////////////////////////////////////////////////////////////
/////////////////////////////////HEADER//////End//////////////////////////////
//////////////////////////////////////////////////////////////////////////////
			

	PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstRowNumber, PrintObjects, CurrentDocument);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;

	Return SpreadsheetDocument;

EndFunction 
