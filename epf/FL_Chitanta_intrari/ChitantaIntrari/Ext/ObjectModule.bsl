
Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	RegistrationParametrs.Insert("Type", "PrintForm");			
	DestinationArray = New Array();
	DestinationArray.Add("Document.PettyCashReceipt");
	
	RegistrationParametrs.Insert("Presentation", DestinationArray);
	
	RegistrationParametrs.Insert("Description", "Forma de listare Chitanta - Intrare în casierie");
	RegistrationParametrs.Insert("Version", "1.3");
	RegistrationParametrs.Insert("SafeMode", False); 
	RegistrationParametrs.Insert("Information", "Forma de listare Chitanta - Intrare în casierie");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
	"Chitanta(intrare)",						    				
	"Chitanta_Intrare",   										
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
	
	NewCommand					= CommandTable.Add();
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
		Message("TemplateName is empty");
		Return;
	EndTry;
	
	PrintManagement.OutputSpreadsheetDocumentToCollection(
		PrintFormsCollection,
		TemplateName,  												
		TemplateName,   											
		CreatePrintForm(ObjectArray, PrintObjects, TemplateName));
	
EndProcedure

Function CreatePrintForm(ObjectsArray, PrintObjects, TemplateName)	

	Spreadsheet						= New SpreadsheetDocument;
	Spreadsheet.PrintParametersKey 	= "PrintParameters_PettyCashReceipt";
	Template	 					= ThisObject.GetTemplate(TemplateName);
	
	Query = New Query();
	Query.SetParameter("CurrentDocument", ObjectsArray);
	
	Query.Text = 
	"SELECT
	|	PettyCashReceipt.Ref AS Ref,
	|	PettyCashReceipt.Number AS Number,
	|	PettyCashReceipt.Date AS DocumentDateRAW,
	|	PettyCashReceipt.Entity AS Entity,
	|	PettyCashReceipt.Entity.Prefix AS Prefix,
	|	PettyCashReceipt.Entity.TIN AS ONRCVendor,
	|	PettyCashReceipt.Entity.CIO AS KPPVendor,
	|	PettyCashReceipt.Entity.DescriptionFull AS Vendor,
	|	PettyCashReceipt.PettyCash.GLAccount.Code AS DebitCode,
	|	PettyCashReceipt.Counterparty AS Customer,
	|	PettyCashReceipt.Counterparty.TIN AS ONRCCustomer,
	|	PettyCashReceipt.Counterparty.CIO AS KPPCustomer,
	|	PettyCashReceipt.CashCurrency AS CashCurrency,
	|	PRESENTATION(PettyCashReceipt.CashCurrency) AS CurrencyPresentation,
	|	PettyCashReceipt.AcceptedFrom AS AcceptedFrom,
	|	PettyCashReceipt.Basis AS Basis,
	|	PettyCashReceipt.DocumentBasis AS DocumentBasis,
	|	PettyCashReceipt.Application AS Application,
	|	PettyCashReceipt.DocumentAmount AS DocumentAmount,
	|	CASE
	|		WHEN PettyCashReceipt.TransactionType = VALUE(Enum.TransactionTypesCashReceipt.Other)
	|				OR PettyCashReceipt.TransactionType = VALUE(Enum.TransactionTypesCashReceipt.CurrencyPurchase)
	|			THEN PettyCashReceipt.Correspondence.Code
	|		ELSE CASE
	|				WHEN PettyCashReceipt.TransactionType = VALUE(Enum.TransactionTypesCashReceipt.FromAdvanceHolder)
	|					THEN PettyCashReceipt.AdvanceHolder.AdvanceHoldersGLAccount.Code
	|				ELSE CASE
	|						WHEN PettyCashReceipt.TransactionType = VALUE(Enum.TransactionTypesCashReceipt.FromCustomer)
	|							THEN PettyCashReceipt.Counterparty.CustomerAdvancesGLAccount.Code
	|						ELSE CASE
	|								WHEN PettyCashReceipt.TransactionType = VALUE(Enum.TransactionTypesCashReceipt.FromVendor)
	|									THEN PettyCashReceipt.Counterparty.AccountsWithVendorsGLAccount.Code
	|								ELSE UNDEFINED
	|							END
	|					END
	|			END
	|	END AS BalancedAccount,
	|	CASE
	|		WHEN PettyCashReceipt.TransactionType = VALUE(Enum.TransactionTypesCashReceipt.FromCustomer)
	|			THEN PettyCashReceipt.Counterparty.CustomerAdvancesGLAccount.Code
	|		ELSE CASE
	|				WHEN PettyCashReceipt.TransactionType = VALUE(Enum.TransactionTypesCashReceipt.FromVendor)
	|					THEN PettyCashReceipt.Counterparty.VendorsAdvancesGLAccount.Code
	|				ELSE UNDEFINED
	|			END
	|	END AS CorAccountOfAdvances,
	|	PettyCashReceipt.DocumentBasis.Number AS DocumentBNumber,
	|	PettyCashReceipt.DocumentBasis.Date AS DocumentBDate,
	|	PettyCashReceipt.Basis AS Reprezentand
	|FROM
	|	Document.PettyCashReceipt AS PettyCashReceipt
	|WHERE
	|	PettyCashReceipt.Ref IN(&CurrentDocument)";
	
	Selection = Query.Execute().Select();
		
	FirstDocument = True;
		
	LineNumber = 1;
	While Selection.Next() Do
///////////////////////////////////////////////////////////////////////////
/////////////////////////////////HEADER/////Start//////////////////////////
///////////////////////////////////////////////////////////////////////////

TemplateArea = Template.GetArea("Header");
	
	If Not FirstDocument Then
		Spreadsheet.PutHorizontalPageBreak();
	EndIf;
		
		FirstDocument  = False;
		
		FirstRowNumber = Spreadsheet.TableHeight + 1;
		
		Currency = Selection.CashCurrency <> Constants.NationalCurrency.Get();
		
	If Selection.DocumentDateRAW < Date('20110101') Then
		DocumentNo = SmallBusinessServer.GetNumberForPrinting(Selection.Number, Selection.Prefix);
	Else
		DocumentNo = ObjectPrefixationClientServer.GetNumberForPrinting(Selection.Number, True, True);
	EndIf;		
		
	TemplateArea.Parameters.Fill(Selection);
	TemplateArea.Parameters.TipChitanta   		= "CHITANȚĂ";
	TemplateArea.Parameters.DocumentNo   		= DocumentNo;
		
	TemplateArea.Parameters.DocumentDate		= Format(Selection.DocumentDateRAW, "DF=dd/MM/yyyy");
		
		InfoAboutVendor   						= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Entity, 
																							Selection.DocumentDateRAW, ,);
		InfoAboutCustomer 						= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Customer, 
																							Selection.DocumentDateRAW, ,);
	TemplateArea.Parameters.VendorAddress		= InfoAboutVendor.LegalAddress;
	TemplateArea.Parameters.FurnizorBanca		= InfoAboutVendor.Bank;
	TemplateArea.Parameters.FurnizorContDecont	= InfoAboutVendor.AccountNo;
	TemplateArea.Parameters.CustomerAddress		= InfoAboutCustomer.LegalAddress;
	TemplateArea.Parameters.ClientBanca			= InfoAboutCustomer.Bank;
	TemplateArea.Parameters.ClientContDecont	= InfoAboutCustomer.AccountNo;
		
Spreadsheet.Put(TemplateArea);

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////HEADER/////End//////////////////////////
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
/////////////////////////////////STRING/////Start//////////////////////////
///////////////////////////////////////////////////////////////////////////

		
TemplateArea = Template.GetArea("String");
	TemplateArea.Parameters.Fill(Selection);
	TemplateArea.Parameters.LineNumber    		= LineNumber;
		PaymentAmount 							= Format(Selection.DocumentAmount, "ND=15; NFD=2") + 
											    	  ?(Currency, " " + TrimAll(Selection.CashCurrency), "");
	TemplateArea.Parameters.PaymentAmount		= PaymentAmount;
	If ValueIsFilled(Selection.DocumentBasis)   Then  
	TemplateArea.Parameters.DocumentBasis   = " Factura fiscală " + Selection.DocumentBNumber+ " din " +Selection.DocumentBDate ;
	Else 
		TemplateArea.Parameters.DocumentBasis   = "Avans";
	EndIf;	
Spreadsheet.Put(TemplateArea);	
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////STRING/////End//////////////////////////
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
/////////////////////////////////FOOTER/////Start//////////////////////////
///////////////////////////////////////////////////////////////////////////

TemplateArea = Template.GetArea("Footer");

	TemplateArea.Parameters.Fill(Selection);
	TemplateArea.Parameters.Amount 				= SmallBusinessServer.AmountsFormat(Selection.DocumentAmount, Selection.CashCurrency);
	TemplateArea.Parameters.AmountInWords 		= SmallBusinessServer.FormatPaymentDocumentAmountInWords(
																							Selection.DocumentAmount,
																							Selection.CashCurrency,
																							False
																							)+"i";
		Heads = SmallBusinessServer.OrganizationalUnitsResponsiblePersons(Selection.Entity, 
																		  Selection.DocumentDateRAW);
		TemplateArea.Parameters.CashierNameAndSurname	= Heads.CashierNameAndSurname;
		
Spreadsheet.Put(TemplateArea);	

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////FOOTER/////End//////////////////////////
///////////////////////////////////////////////////////////////////////////

//////////////////////////Two Per Page/////Start///////////////////////////
/////////////////////////////////HEADER/////Start//////////////////////////
///////////////////////////////////////////////////////////////////////////

TemplateArea = Template.GetArea("Header");
	
		Currency = Selection.CashCurrency <> Constants.NationalCurrency.Get();
		
	If Selection.DocumentDateRAW < Date('20110101') Then
		DocumentNo = SmallBusinessServer.GetNumberForPrinting(Selection.Number, Selection.Prefix);
	Else
		DocumentNo = ObjectPrefixationClientServer.GetNumberForPrinting(Selection.Number, True, True);
	EndIf;		
		
	TemplateArea.Parameters.Fill(Selection);
	TemplateArea.Parameters.TipChitanta   		= "CHITANȚĂ";
	TemplateArea.Parameters.DocumentNo   		= DocumentNo;
		
	TemplateArea.Parameters.DocumentDate		= Format(Selection.DocumentDateRAW, "DF=dd/MM/yyyy");
		
		InfoAboutVendor   						= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Entity, 
																							Selection.DocumentDateRAW, ,);
		InfoAboutCustomer 						= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Customer, 
																							Selection.DocumentDateRAW, ,);
	TemplateArea.Parameters.VendorAddress		= InfoAboutVendor.LegalAddress;
	TemplateArea.Parameters.FurnizorBanca		= InfoAboutVendor.Bank;
	TemplateArea.Parameters.FurnizorContDecont	= InfoAboutVendor.AccountNo;
	TemplateArea.Parameters.CustomerAddress		= InfoAboutCustomer.LegalAddress;
	TemplateArea.Parameters.ClientBanca			= InfoAboutCustomer.Bank;
	TemplateArea.Parameters.ClientContDecont	= InfoAboutCustomer.AccountNo;
		
Spreadsheet.Put(TemplateArea);

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////HEADER/////End//////////////////////////
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
/////////////////////////////////STRING/////Start//////////////////////////
///////////////////////////////////////////////////////////////////////////

		
TemplateArea = Template.GetArea("String");
	TemplateArea.Parameters.Fill(Selection);
	TemplateArea.Parameters.LineNumber    		= LineNumber;
		PaymentAmount 							= Format(Selection.DocumentAmount, "ND=15; NFD=2") + 
											    	  ?(Currency, " " + TrimAll(Selection.CashCurrency), "");
	TemplateArea.Parameters.PaymentAmount		= PaymentAmount;
	If ValueIsFilled(Selection.DocumentBasis)   Then  
	TemplateArea.Parameters.DocumentBasis   = " Factura fiscală " + Selection.DocumentBNumber+ " din " +Selection.DocumentBDate ;
	Else 
		TemplateArea.Parameters.DocumentBasis   = "Avans";
	EndIf;	

	//If ValueIsFilled(Selection.DocumentBasis)   Then  
	//	TemplateArea.Parameters.DocumentBasis   = Selection.DocumentBasis;
	//Else 
	//	TemplateArea.Parameters.DocumentBasis   = "Avans";
	//EndIf;	
Spreadsheet.Put(TemplateArea);	
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////STRING/////End//////////////////////////
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
/////////////////////////////////FOOTER/////Start//////////////////////////
///////////////////////////////////////////////////////////////////////////

TemplateArea = Template.GetArea("Footer");

	TemplateArea.Parameters.Fill(Selection);
	TemplateArea.Parameters.Amount 			= SmallBusinessServer.AmountsFormat(Selection.DocumentAmount, Selection.CashCurrency);
	TemplateArea.Parameters.AmountInWords 	= SmallBusinessServer.FormatPaymentDocumentAmountInWords(
																							Selection.DocumentAmount,
																							Selection.CashCurrency,
																							False
																							)+"i";
		Heads = SmallBusinessServer.OrganizationalUnitsResponsiblePersons(Selection.Entity, 
																		  Selection.DocumentDateRAW);
		TemplateArea.Parameters.CashierNameAndSurname	= Heads.CashierNameAndSurname;
		
Spreadsheet.Put(TemplateArea);	

////////////////////////////Two Per Page/////End///////////////////////////
///////////////////////////////////HEADER/////End//////////////////////////
///////////////////////////////////////////////////////////////////////////
				
		PrintManagement.SetDocumentPrintArea(Spreadsheet, FirstRowNumber, PrintObjects, Selection.Ref);

	EndDo;
	
	Spreadsheet.FitToPage = True;
	
	Return Spreadsheet;

EndFunction	
