//////////////////////////////////////////////////////////////////////////// 
//
// Preparation external print form
//
//
//	RegistrationParametrs.Insert("Type", "PrintForm"); 
// 	Варианты берутся из перечисления AdditionalReportAndDataProcessorKinds: 
// 	Variants are from ENUM 			 AdditionalReportAndDataProcessorKinds:
//		- "ДополнительнаяОбработка"		= "AdditionalDataProcessor"
//		- "ДополнительныйОтчет"			= "AdditionalReport"
//		- "ЗаполнениеОбъекта"			= "ObjectFilling"
//		- "Отчет"						= "Report"
//		- "ПечатнаяФорма"				= "PrintForm"
//		- "СозданиеСвязанныхОбъектов"	= "CreatingOfLinkedObjects"
//
//////////////////////////////////////////////////////////////////////////// 
Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	RegistrationParametrs.Insert("Type", "PrintForm");		//  see comment above
	
	DestinationArray = New Array();
	DestinationArray.Add("Document.PettyCashReceipt");
	//DestinationArray.Add("Document.InventoryExpense");

	RegistrationParametrs.Insert("Presentation", DestinationArray);
	
	// Parameters for registration ExtProc in Application
	RegistrationParametrs.Insert("Description", "Forma de listare Chitanta");
	RegistrationParametrs.Insert("Version", "1.1"); 	// "1.0"
	RegistrationParametrs.Insert("SafeMode", False); 	// Variants: True, False / Варианты: Истина, Ложь 
	RegistrationParametrs.Insert("Information", "Forma de listare Chitanta");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
	"Chitanta",						    				// what we will see under button PRINT
	"Chitanta",   										// Name of Template 
	"CallOfServerMethod",  								// "CallOfServerMethod" = for MXL / "CallOfClientMethod" = for WORD !!! Использование.  Варианты: "ОткрытиеФормы", "ВызовКлиентскогоМетода", "ВызовСерверногоМетода"   
	False,												// Показывать оповещение. Варианты Истина, Ложь / Variants: True, False
	"MXLPrint");           								// "MXLPrint" = for MXL / "" = for WORD !!! Модификатор 
	
	RegistrationParametrs.Insert("Commands", CommandTable);
	
	Return RegistrationParametrs;
	
EndFunction		// ExternalDataProcessorInfo() 

/////////////////////////////////// 
//
/////////////////////////////////// 
Function GetCommandTable()
	
	Commands = New ValueTable;
	Commands.Columns.Add("Presentation",	New TypeDescription("String"));
	Commands.Columns.Add("ID",				New TypeDescription("String"));
	Commands.Columns.Add("Use",				New TypeDescription("String"));
	Commands.Columns.Add("ShowNotification",New TypeDescription("Boolean"));
	Commands.Columns.Add("Modifier",		New TypeDescription("String"));
	
	Return Commands;
	
EndFunction		// GetCommandTable()


/////////////////////////////////// 
//
// Add Command to Document 
//
/////////////////////////////////// 
Procedure AddCommand(CommandTable, Presentation, ID, Use, ShowNotification = False, Modifier = "")
	
	NewCommand					= CommandTable.Add();
	NewCommand.Presentation 	= Presentation;
	NewCommand.ID				= ID;
	NewCommand.Use				= Use;
	NewCommand.ShowNotification	= ShowNotification;
	NewCommand.Modifier			= Modifier;
	
EndProcedure		//  AddCommand()

/////////////////////////////////// 
//
// Preparing of Print Form 
//
/////////////////////////////////// 
Procedure Print(ObjectArray, PrintFormsCollection, PrintObjects, OutputParametrs)  Export 
	
	Try
		TemplateName = PrintFormsCollection[0].DesignName;
	Except
		Message("TemplateName is empty");
		Return;
	EndTry;
	
	PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			TemplateName,  												// Template Name
			TemplateName,   											// Template Synonim
			CreatePrintForm(ObjectArray, PrintObjects, TemplateName)  	// Function for Execution (in this Module) - исполняющая функция (в этом же модуле)
														 );
	
EndProcedure		//  Print()

/////////////////////////////////// 
//
// Creating Print Form 
//
/////////////////////////////////// 
Function CreatePrintForm(ObjectsArray, PrintObjects, TemplateName)	

	// Получение макета и создание на его основании табличного документа, который будет выведен на печать
	// Get Template and creating  "on base" the Table Document for printing 
	Spreadsheet						= New SpreadsheetDocument;
	Spreadsheet.PrintParametersKey 	= "PrintParameters_PettyCashReceipt";  // PrintParameters_ + Name_of_Document
	Template	 					= ThisObject.GetTemplate(TemplateName);

	// ЭтотОбъект - объект обработки где расположен Template
	// ThisObject - the Object of procedure where Template is placed
		
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
	|	PettyCashReceipt.Counterparty.TIN AS ONRC,
	|	PettyCashReceipt.Counterparty.CIO AS CUI,
	|	PettyCashReceipt.CashCurrency AS CashCurrency,
	|	PRESENTATION(PettyCashReceipt.CashCurrency) AS CurrencyPresentation,
	|	PettyCashReceipt.AcceptedFrom AS AcceptedFrom,
	|	PettyCashReceipt.Basis AS Basis,
	//|	PettyCashReceipt.DocumentBasis AS DocumentBasis,
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
	|	PettyCashReceipt.DocumentBasis.Number AS BasisNumber,
	|	PettyCashReceipt.DocumentBasis.Date AS BasisDate
	|FROM
	|	Document.PettyCashReceipt AS PettyCashReceipt
	|WHERE
	|	PettyCashReceipt.Ref IN(&CurrentDocument)";
	//|	PettyCashReceipt.Ref = &CurrentDocument";
	
	Selection = Query.Execute().Select();
		
	FirstDocument = True;
		
	LineNumber = 1;
	While Selection.Next() Do                                                                                        

		TemplateArea = Template.GetArea("Header");
	    TemplateArea.Parameters.Fill(Selection);

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
		
				//TemplateArea.Parameters.TipChitanta   		= "CHITANTA";
		TemplateArea.Parameters.DocumentNo   		= Selection.Number;
		
		TemplateArea.Parameters.DocumentDate		= Format(Selection.DocumentDateRAW, "DF=dd/MM/yyyy");
		
		InfoAboutVendor   							= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Entity, 
																							Selection.DocumentDateRAW, ,);
		InfoAboutCustomer 							= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Customer, 
																							Selection.DocumentDateRAW, ,);
		
		TemplateArea.Parameters.VendorAddress		= InfoAboutVendor.LegalAddress;
		//TemplateArea.Parameters.FurnizorBanca		= InfoAboutVendor.Bank;
		//TemplateArea.Parameters.FurnizorContDecont	= InfoAboutVendor.AccountNo;

		TemplateArea.Parameters.CustomerAddress		= InfoAboutCustomer.LegalAddress;
		//TemplateArea.Parameters.ClientBanca			= InfoAboutCustomer.Bank;
		//TemplateArea.Parameters.ClientContDecont	= InfoAboutCustomer.AccountNo;
		
		
			    		
		
		

		//TemplateArea.Parameters.LineNumber    		= LineNumber;
		
		PaymentAmount 								= Format(Selection.DocumentAmount, "ND=15; NFD=2") + 
											    	  ?(Currency, " " + TrimAll(Selection.CashCurrency), "");
		//PaymentsAmounts 							= SmallBusinessServer.AmountsFormat(Selection.DocumentAmount, Selection.CashCurrency);
		//Message(PaymentAmount);
		//Message(PaymentsAmounts);
													  
		//TemplateArea.Parameters.PaymentAmount		= PaymentAmount;
		


		
		//TemplateArea.Parameters.Amount 				= PaymentAmount + " " + Selection.CashCurrency;
		TemplateArea.Parameters.Amount 				= SmallBusinessServer.AmountsFormat(Selection.DocumentAmount, Selection.CashCurrency);
		TemplateArea.Parameters.AmountInWords 		= SmallBusinessServer.FormatPaymentDocumentAmountInWords(
																							Selection.DocumentAmount,
																							Selection.CashCurrency,
																							False
																							);
		
		Heads = SmallBusinessServer.OrganizationalUnitsResponsiblePersons(Selection.Entity, 
																		  Selection.DocumentDateRAW);
		
		//TemplateArea.Parameters.ChiefAccountantNameAndSurname	= Heads.ChiefAccountantNameAndSurname;
		TemplateArea.Parameters.CashierNameAndSurname			= Heads.CashierNameAndSurname;
		
		  Spreadsheet.Put(TemplateArea);
		  Spreadsheet.Put(TemplateArea);
		 		

		PrintManagement.SetDocumentPrintArea(Spreadsheet, FirstRowNumber, PrintObjects, Selection.Ref);

	EndDo;
	
	Spreadsheet.FitToPage = True;
	
	Return Spreadsheet;

EndFunction		//  CreatePrintForm()
