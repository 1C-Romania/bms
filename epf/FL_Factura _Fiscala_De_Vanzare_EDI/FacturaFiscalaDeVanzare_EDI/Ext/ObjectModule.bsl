/////////////////////////////////// 
// Preparation external print form
//
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
	RegistrationParametrs.Insert("Description", "Factura fiscala de vanzare cu EDI (la doc. Vinzare Bunuri)");
	RegistrationParametrs.Insert("Version", "1.0"); 	// "1.0"
	RegistrationParametrs.Insert("SafeMode", False); 	// Variants: True, False / Варианты: Истина, Ложь 
	RegistrationParametrs.Insert("Information", "Factura fiscala de vanzare cu EDI (la doc.Vinzare Bunuri)");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
	"Factura fiscala de vânzare cu EDI",				// what we will see under button PRINT
	"FacturaFiscalaDeVinzare",   						// Name of Template 
	"CallOfServerMethod",  								// "CallOfServerMethod" = for MXL / "CallOfClientMethod" = for WORD !!! Использование.  Варианты: "ОткрытиеФормы", "ВызовКлиентскогоМетода", "ВызовСерверногоМетода"   
	False,												// Показывать оповещение. Варианты Истина, Ложь / Variants: True, False
	"MXLPrint");           								// "MXLPrint" = for MXL / "" = for WORD !!! Модификатор 
	
	RegistrationParametrs.Insert("Commands", CommandTable);
	
	Return RegistrationParametrs;
	
EndFunction

/////////////////////////////////// 
//
Function GetCommandTable()
	
	Commands = New ValueTable;
	Commands.Columns.Add("Presentation",	New TypeDescription("String"));
	Commands.Columns.Add("ID",				New TypeDescription("String"));
	Commands.Columns.Add("Use",				New TypeDescription("String"));
	Commands.Columns.Add("ShowNotification",New TypeDescription("Boolean"));
	Commands.Columns.Add("Modifier",		New TypeDescription("String"));
	
	Return Commands;
	
EndFunction

/////////////////////////////////// 
//
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
//
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

/////////////////////////////////// 
//
Function CreatePrintForm(ObjectArray, PrintObjects, TemplateName)	
	
	// Получение макета и создание на его основании табличного документа, который будет выведен на печать
	// Get Template and creating  "on base" the Table Document for printing 
	Spreadsheet = New SpreadsheetDocument;
	Spreadsheet.PrintParametersKey = "PrintParameters_InventoryExpense";  // PrintParameters_ + Name_of_Document
	
	// ЭтотОбъект - объект обработки где расположен Template
	// ThisObject - the Object of procedure where Template is placed
	Template	= ThisObject.GetTemplate(TemplateName);
	Query		= New Query;
	Query.Text	=
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
	|	InventoryExpense.Counterparty.Code,
	|	InventoryExpense.Responsible,
	|	InventoryExpense.Counterparty.ContactPerson,
	|	InventoryExpense.Readdressing,
	|	InventoryExpense.DocumentCurrency AS Currency,
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
	|		CASE
	|			WHEN InventoryExpense.Inventory.Characteristic.Description <> """"
	|				THEN InventoryExpense.Inventory.Characteristic.Description + """" + (CAST(InventoryExpense.Inventory.Content AS STRING(65))) + """" + CASE
	|						WHEN (CAST(InventoryExpense.Inventory.Nomenclature.DescriptionFull AS STRING(1000))) = """"
	|							THEN InventoryExpense.Inventory.Nomenclature.Description
	|						ELSE CAST(InventoryExpense.Inventory.Nomenclature.DescriptionFull AS STRING(1000))
	|					END
	|			ELSE """" + (CAST(InventoryExpense.Inventory.Content AS STRING(65))) + """" + CASE
	|					WHEN (CAST(InventoryExpense.Inventory.Nomenclature.DescriptionFull AS STRING(1000))) = """"
	|						THEN InventoryExpense.Inventory.Nomenclature.Description
	|					ELSE CAST(InventoryExpense.Inventory.Nomenclature.DescriptionFull AS STRING(1000))
	|				END
	|		END AS Item
	|	),
	|	PurchaseOrder.Ref,
	|	PurchaseOrder.PaymentCalendar.(
	|		PayDate
	|	),
	|	InventoryExpense.Entity.TIN AS INN,
	|	InventoryExpense.Entity.CIO AS KPP,
	|	InventoryExpense.Entity.BankAccountByDefault.Bank AS Bank,
	|	InventoryExpense.Entity.BankAccountByDefault.AccountNo AS Bankaccount,
	|	InventoryExpense.Entity.Capital AS Capital,
	|	InventoryExpense.Counterparty.TIN AS INNC,
	|	InventoryExpense.Counterparty.CIO AS KPPC,
	|	InventoryExpense.Counterparty.BankAccountByDefault.Bank AS BankC,
	|	InventoryExpense.Counterparty.BankAccountByDefault.AccountNo AS BankaccountC,
		// + HVOYA 2015/12/07 Darya   
	|	InventoryExpense.hiDeliveryAddress.Address AS DeliveryAddress,
		// - HVOYA 2015/12/07 Darya   
	|	ActualAddress.Country AS CountryCAct,
	|	LegAddress.Country AS CountryCLeg
	|FROM
	|	Document.InventoryExpense AS InventoryExpense
	|		LEFT JOIN Document.PurchaseOrder AS PurchaseOrder
	|		ON InventoryExpense.GoodsOrder = PurchaseOrder.Ref
	|		LEFT JOIN (SELECT
	|			CounterpartiesContactInformation.Country AS Country,
	|			CounterpartiesContactInformation.Ref AS Ref
	|		FROM
	|			Catalog.Counterparties.ContactInformation AS CounterpartiesContactInformation
	|		WHERE
	|			CounterpartiesContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.CounterpartyRealAddress)) AS ActualAddress
	|		ON InventoryExpense.Counterparty = ActualAddress.Ref
	|		LEFT JOIN (SELECT
	|			CounterpartiesContactInformation.Country AS Country,
	|			CounterpartiesContactInformation.Ref AS Ref
	|		FROM
	|			Catalog.Counterparties.ContactInformation AS CounterpartiesContactInformation
	|		WHERE
	|			CounterpartiesContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.CounterpartyLegalAddress)) AS LegAddress
	|		ON InventoryExpense.Counterparty = LegAddress.Ref
	|WHERE
	|	InventoryExpense.Ref IN(&Ref)";
	
	
	Query.Parameters.Insert("Ref", ObjectArray);
	Selection			= Query.Execute().Choose();
	
	AreaCaption			= Template.GetArea("Caption");
	Header				= Template.GetArea("Header");
	AreaInventoryHeader = Template.GetArea("InventoryHeader");
	AreaInventory		= Template.GetArea("Line");
	Footer				= Template.GetArea("Footer");
	Spreadsheet.Clear();
	
	InsertPageBreak = False;
	While Selection.Next() Do
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;
		DocRate = WorkWithExchangeRates.GetCurrencyRate(Selection.Currency, BegOfDay(Selection.Date)); 
		NatRate = WorkWithExchangeRates.GetCurrencyRate(Constants.NationalCurrency.get(), BegOfDay(Selection.Date));
		Try
			Rate = DocRate.ExchangeRate / NatRate.ExchangeRate;
		Except
			Message("Cursul valutar nu este actualizat!");
			Rate = 1;
		EndTry;
		
		SelectionInventory	= Selection.Inventory.Choose();
		Spreadsheet.Put(AreaCaption);
		InfoAboutVendor  	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Entity, Selection.Date, ,);
		InfoAboutVendorC  	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Counterparty, Selection.Date, ,);
		Header.Parameters.Fill(Selection);
		
		Try
			Header.Parameters["CurrencyRate"]	= Rate;
		Except
			
		EndTry;
		
		Header.Parameters["Address"]		= SmallBusinessServer.EntitiesLongDescription(InfoAboutVendor, "LegalAddress,");
		Header.Parameters["AddressC"]		= SmallBusinessServer.EntitiesLongDescription(InfoAboutVendorC, "LegalAddress,");
		///Adelin Serb 10.02.2015 If selection
		If TemplateName <> "FacturaFiscalaDeVinzare" Then 
			Header.Parameters["ContactPerson"]  = Selection.Counterparty.ContactPerson;
			Header.Parameters["ClientCode"]  = Selection.Counterparty.Code;
			Header.Parameters["Number"]  = Selection.Number;
		EndIf;
		///Adelin Serb 10.02.2015 EndIf
		
		///Adelin Serb 11.02.2015 
		If ValueIsFilled(Selection.GoodsOrder) Then 		
			Header.Parameters["NrComanda"] =  Selection.GoodsOrder.Number     /// I removed /+ " / " + Selection.GoodsOrder.hiCMD;
			///Adelin Serb 11.02.2015
		EndIf;
		
		///Adelin Serb 11.02.2015   all
		
		If TemplateName <> "FacturaFiscalaDeVinzare" And ValueIsFilled(Selection.GoodsOrder)   Then 
			Header.Parameters["ShippingDate"] =  Format(Selection.GoodsOrder.ShippingDate,"DF=""dd.MM.yyyy""");
		EndIf;  
		If TemplateName <> "FacturaFiscalaDeVinzare" And ValueIsFilled(Selection.Responsible)   Then 
			Header.Parameters ["Responsible"] =     Selection.Responsible;
			
			/////de pus Selection///////Header.Parameters ["PhoneAgent"]   =    Selection.Author;
			/////de pus Selection//////Header.Parameters ["EmailAgent"]   =    Selection.Author;
		Else
			If TemplateName <> "FacturaFiscalaDeVinzare" Then 
				Header.Parameters ["Responsible"]  =    Selection.Author;
				//Header.Parameters ["PhoneNumber"]   =    Selection.Author.PhoneNumber;
				//Header.Parameters ["EmailAgent"]   =  Selection.Author1.ContactInformation.EMail_Address;
			EndIF;
		EndIf;
		///Adelin Serb 11.02.2015  all
		InfoAboutEntity			= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Entity, Selection.Date, ,);
		InfoAboutCounterparty	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Selection.Counterparty, Selection.Date, ,);
		
		CounterpartyName	= SmallBusinessServer.EntitiesLongDescription(InfoAboutCounterparty, "FullDescr, ActualAddress");
		CommaPosition		= find(CounterpartyName, ",");
		If CommaPosition > 0 Then
			Header.Parameters["Company"] = left(CounterpartyName, CommaPosition-1);
		Else
			Header.Parameters["Company"] = 		CounterpartyName;
		EndIf;
		
		If ValueIsFilled(Selection.NumberIE) Then
			Header.Parameters["NumberIE"] = Selection.NumberIE;
		Else
			Header.Parameters["NumberIE"] = right(SmallBusinessServer.GetNumberForPrinting(Selection.Number, Selection.Entity.Prefix), 
			strlen(SmallBusinessServer.GetNumberForPrinting(Selection.Number, Selection.Entity.Prefix))-4);
		EndIf;
		
		Header.Parameters["Date"]				= Format(Selection.Date,"DF=""dd.MM.yyyy""");
		
		// AlekS  2014-09-10	
		
		While SelectionInventory.Next() Do 
			Try
				Header.Parameters["VATRate"] = SelectionInventory.VATRate;
			Except
				
			EndTry;
			
		EndDo;
		// + HVOYA 2015/12/07 Darya   
		If Constants.hiUseEDI.Get() Then
			Header.Parameters.DeliveryAddressTitle = "Delivery Address";
			Header.Parameters.DeliveryAddress = Selection.DeliveryAddress;
		EndIf;
		// - HVOYA 2015/12/07 Darya   
		
		Spreadsheet.Put(Header, Selection.Level());
		Spreadsheet.Put(AreaInventoryHeader);
		SelectionInventory			= Selection.Inventory.Choose();
		SelectionPaymentCalendar	= Selection.PaymentCalendar.Choose();
		TotalAmount					= 0;
		TotalVAT					= 0;
		While SelectionInventory.Next() Do
			///Adelin Serb 10.02.2015 If
			// + HVOYA 2015/12/08 Darya   
			ConterpartyNomenclatureCode	= ConterpartyNomenclatureCode(SelectionInventory.Nomenclature, 
			SelectionInventory.Characteristic, Selection.Counterparty);
			
			//Message(ConterpartyNomenclatureCode);
			
			// - HVOYA 2015/12/08 Darya   
			
			AreaInventory.Parameters["LineNumber"]		= SelectionInventory.LineNumber;
																					    // ATTENTION - PARTNER's CODE !!!
			AreaInventory.Parameters["Item"]			= SelectionInventory.Item + " " + ConterpartyNomenclatureCode;
			
			If TemplateName = "FacturaFiscalaDeVinzare" Then
				AreaInventory.Parameters["UnitOfMeasure"]	= SelectionInventory.UnitOfMeasure;
			Else
				//  ???
			EndIf;
			///Adelin Serb 10.02.2015 EndIf
			AreaInventory.Parameters["Quantity"]		= SelectionInventory.Quantity;
			///Adelin Serb 09.02.2015 If
			
			If TemplateName <>  "FacturaFiscalaDeVinzare"  Then
				AreaInventory.Parameters["VATRate"]	   		= SelectionInventory.VATRate;
			EndIf ;
			///Adelin Serb 09.02.2015 EndIf
			Price	  = Format(Round(SelectionInventory.Price * Rate,2),					"NFD=2");
			Amount	  = Format(Round(Price		* SelectionInventory.Quantity,2),			"NFD=2");
			VATAmount = Format(Round((Amount	* SelectionInventory.VATRate.Rate)/100,2),	"NFD=2");
			
			AreaInventory.Parameters["Price"]	  = Price;
			AreaInventory.Parameters["Amount"]    = Amount;
			
			Try
				//// ///Adelin Serb 10.02.2015 If
				If TemplateName =  "FacturaFiscalaDeVinzare" Then
					AreaInventory.Parameters["VATAmount"] = VATAmount;
				EndIf;
				///Adelin Serb 10.02.2015 EndIf
				
			Except
				//   ???				
			EndTry;
			
			TotalAmount = TotalAmount	+ Amount;
			TotalVAT 	= TotalVAT		+ VATAmount;
			i = SelectionInventory.LineNumber;
			Spreadsheet.Put(AreaInventory, SelectionInventory.Level());
		EndDo;
		
		For i=i +1 To 40 Do       // Adelin Serb  08.02.2015 40->10
			AreaInventory.Parameters["LineNumber"]		= i;
			AreaInventory.Parameters["Item"]			= Undefined;
			If TemplateName =  "FacturaFiscalaDeVinzare" Then
				AreaInventory.Parameters["UnitOfMeasure"]	= Undefined;
			Endif;
			AreaInventory.Parameters["Quantity"]		= Undefined;
			AreaInventory.Parameters["Price"]			= Undefined;
			AreaInventory.Parameters["Amount"]			= Undefined;
			
			If TemplateName <>  "FacturaFiscalaDeVinzare" Then
				AreaInventory.Parameters["VATRate"]			= Undefined;
			EndIf;
			
			Try
				AreaInventory.Parameters["VATAmount"]		= Undefined;
			Except
				
			EndTry;
			
			Spreadsheet.Put(AreaInventory, SelectionInventory.Level());
		EndDo;
		
		//{{QUERY_BUILDER_WITH_RESULT_PROCESSING
		// This fragment was built by the wizard.
		// Warning! All manually made changes will be lost next time you use the wizard.
		
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
			Except
				
			EndTry;
			
		EndDo;
		
		//  }}QUERY_BUILDER_WITH_RESULT_PROCESSING
		
		Footer.Parameters.Fill(SelectionPaymentCalendar);
		Footer.Parameters.Fill(Selection);
		//Footer.Parameters["TotalTVA"] = Round(TotalVAT, 2);
		//Footer.Parameters["TotalCuTVA"] = Round(TotalAmount,2);
		//Footer.Parameters["TotalFaraTVA"] = Round(TotalAmount - TotalVAT,2);
		
		Try
			Footer.Parameters["TotalTVA"]			= Format(TotalVAT,				"NFD=2");
			Footer.Parameters["TotalCuTVA"]			= Format(TotalVAT + TotalAmount,"NFD=2");
		Except
			
		EndTry;
		
		Footer.Parameters["TotalFaraTVA"]		= Format(TotalAmount,			"NFD=2");
		
		Footer.Parameters["Driver"]				= Selection.Driver;
		If TemplateName <> "Invoice" Then
			Footer.Parameters["CI"]					= Selection.Driver.IDCard;
			Footer.Parameters["MijlocDeTransport"]	= Selection.Readdressing;
		EndIf;
		Footer.Parameters["Date"]				= Selection.Date;
		///Adelin Serb 10.02.2015 If
		
		If TemplateName  <>  "FacturaFiscalaDeVinzare" And  CommaPosition > 0 Then
			Footer.Parameters["Company"] = left(CounterpartyName, CommaPosition - 1);
		EndIf;
		//  I removed   ///  Else ///   Footer.Parameters["Company"] = 		CounterpartyName;
		
		If TemplateName  <>  "FacturaFiscalaDeVinzare" Then
			Footer.Parameters ["KPPC"]			    = Selection.Counterparty.CIO;
			//in asteptare//Footer.Parameters ["CountryCAct"]       = Selection.Counterparty.ActualAddress.Country;                      
		EndIf;
		///Adelin Serb 10.02.2015 EndIf
		
		If TemplateName <> "FacturaFiscalaDeVinzare" Then 
			Footer.Parameters["ContactPerson"]  = Selection.Counterparty.ContactPerson;
		EndIf; 
		
		Try
			Footer.Parameters["CNP"]		= Selection.Driver.PersonalCode;
			Footer.Parameters["User"]		= Selection.Author;
			Footer.Parameters["DataLimita"]	= Format(Selection.Date + (Selection.Contract.CustomerPaymentTerm * 86400), 
														"DF=""dd.MM.yyyy""");
		Except
			
		EndTry;
		
		///Adelin Serb 11.02.2015
		If TemplateName <> "FacturaFiscalaDeVinzare" Then
			Footer.Parameters["AddressCAct"]		= SmallBusinessServer.EntitiesLongDescription(InfoAboutVendorC, "ActualAddress,");
		EndIf ;
		///Adelin Serb 11.02.2015
		Spreadsheet.Put(Footer);
		InsertPageBreak = True;
	EndDo;
	
	Return Spreadsheet;
	
EndFunction

/////////////////////////////////// 
// ... 
Function GetParameterNameBarcode()
	
	Return "Barcode";
	
EndFunction // GetParameterNameBarcode()

/////////////////////////////////// 
// ... 
Function CreateStringClient(Header)
	
	Return "" + Header.Counterparty + ", " + Header.PhoneNumber + ", " + Header.Email;
	
EndFunction // CreateStringClient()

/////////////////////////////////// 
// ... 
Function CreateStringProduct(Header)
	
	Return "" + Header.Nomenclature + ", " + Header.Characteristic;	
EndFunction // CreateStringProduct(Header)

/////////////////////////////////////////////////
//
// + HVOYA 2015/12/07 Darya   
//
Function ConterpartyNomenclatureCode(Nomenclature, Characteristic, Counterparty)
	
	//{{QUERY_BUILDER_WITH_RESULT_PROCESSING
	// Данный фрагмент построен конструктором.
	// При повторном использовании конструктора, внесенные вручную изменения будут утеряны!!!
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	NomenclatureBarcodes.Barcode
	|FROM
	|	InformationRegister.NomenclatureBarcodes AS NomenclatureBarcodes
	|WHERE
	|	NomenclatureBarcodes.Nomenclature = &Nomenclature
	|	AND NomenclatureBarcodes.Characteristic = &Characteristic
	|	AND NomenclatureBarcodes.Counterparty = &Counterparty";
	
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Nomenclature", Nomenclature);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	If SelectionDetailRecords.Next() Then
		Return SelectionDetailRecords.Barcode;
	EndIf;	
	
EndFunction // ConterpartyNomenclatureCode()
// - HVOYA 2015/12/07 Darya   
//////////////////////////////////////
