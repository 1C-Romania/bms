/////////////////////////////////// 
// Preparation external print form
Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	// Варианты берутся из перечисления AdditionalReportAndDataProcessorKinds: 
	// Variants are from list AdditionalReportAndDataProcessorKinds:
	//		- "ДополнительнаяОбработка"		= ""
	//		- "ДополнительныйОтчет"			= ""
	//		- "ЗаполнениеОбъекта"			= ""
	//		- "Отчет"						= ""
	//		- "ПечатнаяФорма"				= "PrintForm"
	//		- "СозданиеСвязанныхОбъектов"	= ""
	RegistrationParametrs.Insert("Type", "PrintForm"); 
	
	DestinationArray = New Array();
	DestinationArray.Add("Document.InventoryExpense");
	DestinationArray.Add("Document.InventoryExpense");

	RegistrationParametrs.Insert("Presentation", DestinationArray);
	
	// Parameters for registration ExtProc in Application
	RegistrationParametrs.Insert("Description", "Forma de listare la doc. Vinzare Bunuri-Avans");
	RegistrationParametrs.Insert("Version", "0.1"); 	// "1.0"
	RegistrationParametrs.Insert("SafeMode", False); 	// Variants: True, False / Варианты: Истина, Ложь 
	RegistrationParametrs.Insert("Information", "Forma de listare la doc. Vinzare Bunuri-Avans");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
	"Factura fiscala de avans",						    // what we will see under button PRINT
	"FacturaFiscalaDeVinzareAV",   						// Name of Template 
	"CallOfServerMethod",  								// "CallOfServerMethod" = for MXL / "CallOfClientMethod" = for WORD !!! Использование.  Варианты: "ОткрытиеФормы", "ВызовКлиентскогоМетода", "ВызовСерверногоМетода"   
	False,												// Показывать оповещение. Варианты Истина, Ложь / Variants: True, False
	"MXLPrint");           								// "MXLPrint" = for MXL / "" = for WORD !!! Модификатор 
	
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

/////////////////////////////////// 
// Preparing of Print Form 
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
	
EndProcedure

Function CreatePrintForm(ObjectArray, PrintObjects, TemplateName)	

	// Получение макета и создание на его основании табличного документа, который будет выведен на печать
	// Get Template and creating  "on base" the Table Document for printing 
	Spreadsheet = New SpreadsheetDocument;
	Spreadsheet.PrintParametersKey = "PrintParameters_InventoryExpense";  // PrintParameters_ + Name_of_Document
	
	// ЭтотОбъект - объект обработки где расположен Template
	// ThisObject - the Object of procedure where Template is placed
	Template	= ThisObject.GetTemplate(TemplateName);
	Query = New Query;
	Query.Text =
	"SELECT
	|	InventoryExpense.Counterparty,
	|	InventoryExpense.Date,
	|	InventoryExpense.Number,
	|	InventoryExpense.Driver,
	|	InventoryExpense.Entity,
	|	InventoryExpense.NumberIE,
	|	InventoryExpense.SeriesIE,
	|	InventoryExpense.Author,
	|	InventoryExpense.Contract,
	|	InventoryExpense.Readdressing,
	|	InventoryExpense.DocumentCurrency,
	|	InventoryExpense.GoodsOrder,
	|	InventoryExpense.Inventory.(
	|		LineNumber,
	|		Nomenclature,
	|		Characteristic,
	|		Quantity,
	|		UnitOfMeasure,
	|		Price,
	|		Amount,
	|		VATAmount,
	|		TotalAmount,
	|		VATRate,
	//===============================
	//©# (Begin) Fedorenco A. [09.10.2014] 2feb9cb1-4e35-11e4-81d2-c86000e2ac82	
	|		CASE
	|			WHEN InventoryExpense.Inventory.Characteristic.Description <> """"
	|				THEN InventoryExpense.Inventory.Characteristic.Description + "" / "" + (CAST(InventoryExpense.Inventory.Content AS STRING(65))) + "" / "" + CASE
	|						WHEN (CAST(InventoryExpense.Inventory.Nomenclature.DescriptionFull AS STRING(1000))) = """"
	|							THEN InventoryExpense.Inventory.Nomenclature.Description
	|						ELSE CAST(InventoryExpense.Inventory.Nomenclature.DescriptionFull AS STRING(1000))
	|					END
	|			ELSE (CAST(InventoryExpense.Inventory.Content AS STRING(65)))  + CASE
	|					WHEN (CAST(InventoryExpense.Inventory.Nomenclature.DescriptionFull AS STRING(1000))) = """"
	|						THEN InventoryExpense.Inventory.Nomenclature.Description
	|					ELSE CAST(InventoryExpense.Inventory.Nomenclature.DescriptionFull AS STRING(1000))
	|				END
	|		END AS Item
	|	),
	//©# (End) Fedorenco A. [09.10.2014] 2feb9cb1-4e35-11e4-81d2-c86000e2ac82
	//===============================
	//===============================
	//©# (Begin) ArNi [18.09.2016]
	|	InventoryExpense.TransactionType,
	|	InventoryExpense.AmountIncludesVAT,
	|	InventoryExpense.AdvanceAmount,
	|	InventoryExpense.AdvanceVATAmount,
	|	InventoryExpense.CustomerAdvance.(
	|		Document,
	|		-Amount AS Amount,
	|		-VATAmount AS VATAmount),
	//©# (End) ArNi
	//===============================
	|	PurchaseOrder.Ref,
	|	PurchaseOrder.PaymentCalendar.(
	|		PayDate
	|	)
	|FROM
	|	Document.InventoryExpense AS InventoryExpense
	|		LEFT JOIN Document.PurchaseOrder AS PurchaseOrder
	|		ON InventoryExpense.GoodsOrder = PurchaseOrder.Ref
	|WHERE
	|	InventoryExpense.Ref IN(&Ref)";
	
	Query.Parameters.Insert("Ref", ObjectArray);
	Selection = Query.Execute().Choose();
	
	AreaCaption = Template.GetArea("Caption");
	Header = Template.GetArea("Header");
	AreaInventoryHeader = Template.GetArea("InventoryHeader");
	AreaInventory = Template.GetArea("Line");
	Footer = Template.GetArea("Footer");
	Spreadsheet.Clear();
	
	InsertPageBreak = False;
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
		
		SelectionInventory = Selection.Inventory.Choose();
		Spreadsheet.Put(AreaCaption);
		InfoAboutVendor  	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Entity, Selection.Date, ,);
		InfoAboutVendorC  	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Counterparty, Selection.Date, ,);
		Header.Parameters.Fill(Selection);
		Header.Parameters["Currency"] = Selection.DocumentCurrency;
		Header.Parameters["CurrencyRate"] = Rate;
		Header.Parameters["Capital"] = Selection.Entity.Capital;
		Header.Parameters["INN"] = Selection.Entity.TIN;
		Header.Parameters["INNC"] = Selection.Counterparty.TIN;
		Header.Parameters["KPP"] = Selection.Entity.CIO;
		Header.Parameters["KPPC"] = Selection.Counterparty.CIO;
		Header.Parameters["Bankaccount"] =  Selection.Entity.BankAccountByDefault.AccountNo;
		Header.Parameters["BankaccountC"] =  Selection.Counterparty.BankAccountByDefault.AccountNo;
		Header.Parameters["Bank"] =  Selection.Entity.BankAccountByDefault.Bank;
		Header.Parameters["BankC"] =  Selection.Counterparty.BankAccountByDefault.Bank;
		Header.Parameters["Address"] =  SmallBusinessServer.EntitiesLongDescription(InfoAboutVendor, "LegalAddress,");
		Header.Parameters["AddressC"] = SmallBusinessServer.EntitiesLongDescription(InfoAboutVendorC, "LegalAddress,");
		
		//===============================
		//©# (Begin) Fedorenco A. [10.10.2014] 2feb9cb1-4e35-11e4-81d2-c86000e2ac82
		If ValueIsFilled(Selection.GoodsOrder)  Then 
			Header.Parameters["NrComanda"] =  Selection.GoodsOrder.Number + " / " + Selection.GoodsOrder.hiCMD;
		EndIf;
		//©# (End) Fedorenco A. [10.10.2014] 2feb9cb1-4e35-11e4-81d2-c86000e2ac82
		//===============================
		// AlekS  2014-09-10	
		InfoAboutEntity = SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Entity, Selection.Date, ,);
		InfoAboutCounterparty = SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Counterparty, Selection.Date, ,);
		
		
		//===============================
		//©# (Begin) Fedorenco A. [13.11.2014] 2feb9cb1-4e35-11e4-81d2-c86000e2ac82
		
		If find(SmallBusinessServer.EntitiesLongDescription(InfoAboutCounterparty, "FullDescr,ActualAddress"), ",") >0 Then
			
			Header.Parameters["Company"] = left(SmallBusinessServer.EntitiesLongDescription(InfoAboutCounterparty, "FullDescr,ActualAddress"), find(SmallBusinessServer.EntitiesLongDescription(InfoAboutCounterparty, "FullDescr,ActualAddress"), ",")-1);
		Else
			Header.Parameters["Company"] = SmallBusinessServer.EntitiesLongDescription(InfoAboutCounterparty, "FullDescr,ActualAddress");
			
		EndIf;
		//©# (End) Fedorenco A. [13.11.2014] 2feb9cb1-4e35-11e4-81d2-c86000e2ac82
		//===============================

		// AlekS  2014-09-10	
		If ValueIsFilled(Selection.NumberIE) Then
			Header.Parameters["NumberIE"] = Selection.NumberIE;
			//		Header.Parameters["SeriesIE"] = Selection.SeriesIE;
		Else
		// AlekS  2014-12-18	
			//  Header.Parameters["NumberIE"]=right(SmallBusinessServer.GetNumberForPrinting(Selection.Number, Selection.Entity.Prefix), strlen(SmallBusinessServer.GetNumberForPrinting(Selection.Number, Selection.Entity.Prefix))-5);
			Header.Parameters["NumberIE"]=right(SmallBusinessServer.GetNumberForPrinting(Selection.Number, Selection.Entity.Prefix), strlen(SmallBusinessServer.GetNumberForPrinting(Selection.Number, Selection.Entity.Prefix))-4);
		// AlekS  2014-12-18	
			//		Header.Parameters["SeriesIE"]=Selection.Prefix;
			//		Header.Parameters["NumberIE"]=SmallBusinessServer.GetNumberForPrinting(Selection.Number, Selection.Prefix);
		EndIf;
		// AlekS  2014-09-10	
		
		While SelectionInventory.Next() Do 
			Header.Parameters["VATRate"] = SelectionInventory.VATRate;
		EndDo;
		Spreadsheet.Put(Header, Selection.Level());
		Spreadsheet.Put(AreaInventoryHeader);
		SelectionInventory = Selection.Inventory.Choose();
		SelectionPaymentCalendar = Selection.PaymentCalendar.Choose();
		TotalAmount = 0;
		TotalVAT = 0;
		//===============================
		//©# (Begin) ArNi [18.09.2016]
		i = 0;
		//©# (End) ArNi
		//===============================
		While SelectionInventory.Next() Do
			AreaInventory.Parameters["LineNumber"] = SelectionInventory.LineNumber;
			//===============================
			//©# (Begin) Fedorenco A. [09.10.2014] 2feb9cb1-4e35-11e4-81d2-c86000e2ac82
			//AreaInventory.Parameters["Item"] = String(SelectionInventory.Nomenclature) + "/" + String(SelectionInventory.Characteristic);
			AreaInventory.Parameters["Item"] =SelectionInventory.Item;
			//©# (End) Fedorenco A. [09.10.2014] 2feb9cb1-4e35-11e4-81d2-c86000e2ac82
			//===============================
			AreaInventory.Parameters["UnitOfMeasure"] = SelectionInventory.UnitOfMeasure;
			AreaInventory.Parameters["Quantity"] = SelectionInventory.Quantity;
			
			//===============================
			//©# (Begin) Fedorenco A. [12.11.2014] 
			//AreaInventory.Parameters["Price"] =  ((SelectionInventory.TotalAmount - SelectionInventory.VATAmount) / SelectionInventory.Quantity) * Rate ;
			//AreaInventory.Parameters["Amount"] = (SelectionInventory.TotalAmount - SelectionInventory.VATAmount) * Rate;
			//AreaInventory.Parameters["VATAmount"] = SelectionInventory.VATAmount * Rate;
			//Price  	  = Round(((SelectionInventory.TotalAmount - SelectionInventory.VATAmount) / SelectionInventory.Quantity) * Rate,2);
			//Amount 	  = Round((SelectionInventory.TotalAmount - SelectionInventory.VATAmount) * Rate,2);
			Price	  = Format(Round(SelectionInventory.Price * Rate,2),"NFD=2");
			Amount	  = Format(Round(Price * SelectionInventory.Quantity,2),"NFD=2");
			VATAmount = Format(Round((Amount * SelectionInventory.VATRate.Rate)/100,2),"NFD=2");
			AreaInventory.Parameters["Price"]	  = Price;
			AreaInventory.Parameters["Amount"]    = Amount;
			AreaInventory.Parameters["VATAmount"] = VATAmount;
			//©# (End) Fedorenco A. [12.11.2014] 
			//===============================
			
			//TotalAmount = TotalAmount + SelectionInventory.TotalAmount * Rate;
			//TotalVAT = TotalVAT + SelectionInventory.VATAmount * Rate;
			TotalAmount = TotalAmount + Amount;
			TotalVAT 	= TotalVAT + VATAmount;
			i = SelectionInventory.LineNumber;
			Spreadsheet.Put(AreaInventory, SelectionInventory.Level());
		EndDo;
		//===============================
		//©# (Begin) ArNi [18.09.2016]
		If Selection.TransactionType = Enums.TransactionTypesSalesInvoice.AdvanceFromCustomer Then
			i = i + 1;
			AreaInventory.Parameters["LineNumber"]    = i;
			AreaInventory.Parameters["Item"]          = NStr("en='Advance';ru='Аванс';ro = 'Avans'");
			AreaInventory.Parameters["UnitOfMeasure"] = "";
			AreaInventory.Parameters["Quantity"]      = "1";
			AreaInventory.Parameters["Price"]         = "";
			
			AdvanceAmount = Selection.AdvanceAmount - ?(Selection.AmountIncludesVAT, Selection.AdvanceVATAmount, 0);
			AreaInventory.Parameters["Amount"]        = AdvanceAmount;
			AreaInventory.Parameters["VATAmount"]     = Selection.AdvanceVATAmount;
			
			TotalAmount = TotalAmount + AdvanceAmount;
			TotalVAT 	= TotalVAT + Selection.AdvanceVATAmount;
			Spreadsheet.Put(AreaInventory, Selection.Level());
		EndIf;
		SelectionAdvance = Selection.CustomerAdvance.Choose();
		While SelectionAdvance.Next() Do
			i = i + 1;
			AreaInventory.Parameters["LineNumber"]    = i;
			TextItem = StringFunctionsClientServer.PlaceParametersIntoString(
				NStr("en='Credit advance in the document %1 from %2';ru='Закрытие аванса по документу %1 %2';ro = 'Regularizare avans de factura %1 %2'"),
				SmallBusinessServer.GetNumberForPrinting(SelectionAdvance.Document.Number, Selection.Entity.Prefix),
				Format(SelectionAdvance.Document.Date, "DLF=D"));
			AreaInventory.Parameters["Item"]          = TextItem;
			AreaInventory.Parameters["UnitOfMeasure"] = "";
			AreaInventory.Parameters["Quantity"]      = "1";
			AreaInventory.Parameters["Price"]         = "";
			AreaInventory.Parameters["Amount"]        = SelectionAdvance.Amount;
			AreaInventory.Parameters["VATAmount"]     = SelectionAdvance.VATAmount;
			TotalAmount = TotalAmount + SelectionAdvance.Amount;
			TotalVAT 	= TotalVAT + SelectionAdvance.VATAmount;
			Spreadsheet.Put(AreaInventory, SelectionAdvance.Level());
		EndDo;
		//©# (End) ArNi
		//===============================
		//===============================
		//©# (Begin) Fedorenco A. [13.11.2014] 
		If Not SelectionInventory.Next() Then
			//©# (Begin) AlekS [2014-11-17]
			// я не понял - зачем была вставлена эта проверка?
			// она сбивает нумерацию в таблице FF - закоментирую!
			// i = 0;
			//©# (End)   AlekS [2014-11-17]
		EndIf;
		//©# (End) Fedorenco A. [13.11.2014] 
		//===============================
		
		For i=i +1 To 40 Do
			AreaInventory.Parameters["LineNumber"] = i;
			AreaInventory.Parameters["Item"] = Undefined;
			AreaInventory.Parameters["UnitOfMeasure"] = Undefined;
			AreaInventory.Parameters["Quantity"] = Undefined;
			AreaInventory.Parameters["Price"] =  Undefined;
			AreaInventory.Parameters["Amount"] = Undefined;
			AreaInventory.Parameters["VATAmount"] = Undefined;
			Spreadsheet.Put(AreaInventory, SelectionInventory.Level());
		EndDo;
		
		
		//{{QUERY_BUILDER_WITH_RESULT_PROCESSING
		// This fragment was built by the wizard.
		// Warning! All manually made changes will be lost next time you use the wizard.
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	UserEmployees.Employee,
		|	UserEmployees.User
		|FROM
		|	InformationRegister.UserEmployees AS UserEmployees
		|WHERE
		|	UserEmployees.User = &Author";
		
		Query.SetParameter("Author", Selection.Author);
		
		Result = Query.Execute();
		
		SelectionD = Result.Choose();
		
		While SelectionD.Next() Do
			Footer.Parameters["CNPU"] = SelectionD.Employee.Ind.PersonalCode;
			Footer.Parameters["CIU"] = SelectionD.Employee.Ind.IDCard;
		EndDo;
		
		//}}QUERY_BUILDER_WITH_RESULT_PROCESSING
		
		
		
		Footer.Parameters.Fill(SelectionPaymentCalendar);
		//Footer.Parameters["TotalTVA"] = Round(TotalVAT, 2);
		//Footer.Parameters["TotalCuTVA"] = Round(TotalAmount,2);
		//Footer.Parameters["TotalFaraTVA"] = Round(TotalAmount - TotalVAT,2);
		
		//Footer.Parameters["TotalTVA"] = Format(TotalVAT,"NFD=2");
		
		
		Footer.Parameters["TotalTVA"] = Format(TotalVAT,"NFD=2");
		
		Footer.Parameters["TotalCuTVA"] = Format(TotalVAT + TotalAmount,"NFD=2");
		Footer.Parameters["TotalFaraTVA"] = Format(TotalAmount,"NFD=2");

		Footer.Parameters["Driver"] = Selection.Driver;
		Footer.Parameters["CNP"] = Selection.Driver.PersonalCode;
		Footer.Parameters["CI"]  = Selection.Driver.IDCard;
		Footer.Parameters["MijlocDeTransport"] = Selection.Readdressing;
		Footer.Parameters["Date"] = Selection.Date;
		Footer.Parameters["User"] = Selection.Author;
		
		Footer.Parameters["DataLimita"] = Format( Selection.Date + (Selection.Contract.CustomerPaymentTerm * 86400), "DF=""dd.MM.yyyy""");
		
		Spreadsheet.Put(Footer);
		InsertPageBreak = True;
	EndDo;
	
	//{{QUERY_BUILDER_WITH_RESULT_PROCESSING
	// This fragment was built by the wizard.
	// Warning! All manually made changes will be lost next time you use the wizard.

	

	//}}QUERY_BUILDER_WITH_RESULT_PROCESSING

	//}}
//PrintRo_End

	
	
	
	Return Spreadsheet;

EndFunction
