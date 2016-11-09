/////////////////////////////////// 
// Preparation external print form
Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	RegistrationParametrs.Insert("Type", "PrintForm"); 
	
	DestinationArray = New Array();
	DestinationArray.Add("Document.FixedAssetSale");
	DestinationArray.Add("Document.FixedAssetSale");

	RegistrationParametrs.Insert("Presentation", DestinationArray);
	
	// Parameters for registration ExtProc in Application
	RegistrationParametrs.Insert("Description", "Forma de listare la doc. Vanzare MF");
	RegistrationParametrs.Insert("Version", "1.1"); 	// "1.0"
	RegistrationParametrs.Insert("SafeMode", False); 	// Variants: True, False / Варианты: Истина, Ложь 
	RegistrationParametrs.Insert("Information", "Forma de listare la doc. Vanzare MF");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
	"Factura fiscala de vânzare",						// what we will see under button PRINT
	"FacturaFiscalaDeVânzareMF",   						// Name of Template 
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
	Spreadsheet.PrintParametersKey = "PrintParameters_FixedAssetSale";  // PrintParameters_ + Name_of_Document
	
	// ЭтотОбъект - объект обработки где расположен Template
	// ThisObject - the Object of procedure where Template is placed
	Template	= ThisObject.GetTemplate(TemplateName);
	Query		= New Query;
	//|	FixedAssetSale.Counterparty,
	//|	FixedAssetSale.Date,
	//|	FixedAssetSale.Number,
	////|	FixedAssetSale.Driver,
	//|	FixedAssetSale.Entity,
	////|	FixedAssetSale.NumberIE,
	////|	FixedAssetSale.SeriesIE,
	//|	FixedAssetSale.Author,
	//|	FixedAssetSale.Contract,
	//|	FixedAssetSale.Counterparty.Code,
	////|	FixedAssetSale.Responsible,
	//|	FixedAssetSale.Counterparty.ContactPerson,
	////|	FixedAssetSale.Readdressing,
	//|	FixedAssetSale.DocumentCurrency AS Currency,
	////|	FixedAssetSale.GoodsOrder,
	//|	FixedAssetSale.FixedAssets.(
	//|		LineNumber,
	//|		FixedAsset,
	////|		Characteristic,
	////|		Quantity,
	////|		UnitOfMeasure,
	//|		Cost,
	////|		DiscountMarkupRate,
	//|		Amount,
	//|		VATAmount,
	//|		TotalAmount,
	//|		VATRate,
	////|		CASE
	////|			WHEN FixedAssetSale.FixedAssets.Description <> """"
	//|				THEN FixedAssetSale.FixedAssets.Description + """" + (CAST(FixedAssetSale.FixedAssets AS STRING(65))) + """" + CASE
	//|						WHEN (CAST(FixedAssetSale.FixedAssets.FixedAsset.DescriptionFull AS STRING(1000))) = """"
	//|							THEN FixedAssetSale.FixedAssets.FixedAsset.Description
	//|						ELSE CAST(FixedAssetSale.FixedAssets.FixedAsset.DescriptionFull AS STRING(1000))
	//|					END
	//|			ELSE """" + (CAST(FixedAssetSale.FixedAssets AS STRING(65))) + """" + CASE
	//|					WHEN (CAST(FixedAssetSale.FixedAssets.FixedAsset.DescriptionFull AS STRING(1000))) = """"
	//|						THEN FixedAssetSale.FixedAssets.FixedAsset.Description
	//|					ELSE CAST(FixedAssetSale.FixedAssets.FixedAsset.DescriptionFull AS STRING(1000))
	//|				END
	//|		END AS Item
	//|	),
	//|	PurchaseOrder.Ref,
	//|	PurchaseOrder.PaymentCalendar.(
	//|		PayDate
	//|	),
	//|	FixedAssetSale.Entity.TIN AS INN,
	//|	FixedAssetSale.Entity.CIO AS KPP,
	//|	FixedAssetSale.Entity.BankAccountByDefault.Bank AS Bank,
	//|	FixedAssetSale.Entity.BankAccountByDefault.AccountNo AS Bankaccount,
	//|	FixedAssetSale.Entity.Capital AS Capital,
	//|	FixedAssetSale.Counterparty.TIN AS INNC,
	//|	FixedAssetSale.Counterparty.CIO AS KPPC,
	//|	FixedAssetSale.Counterparty.BankAccountByDefault.Bank AS BankC,
	//|	FixedAssetSale.Counterparty.BankAccountByDefault.AccountNo AS BankaccountC,
	//|	ActualAddress.Country AS CountryCAct,
	//|	LegAddress.Country AS CountryCLeg,
	//|	FixedAssetSale.hiDocumentVATAmount AS DocumentVATAmount,
	//|	FixedAssetSale.hiDocumentAmountWithoutVAT AS DAmountWithoutVAT
	////|FROM
	//|	Document.FixedAssetSale AS FixedAssetSale
	//|		LEFT JOIN Document.PurchaseOrder AS PurchaseOrder
	//|		ON FixedAssetSale.GoodsOrder = PurchaseOrder.Ref
	//|		LEFT JOIN (SELECT
	//|			CounterpartiesContactInformation.Country AS Country,
	//|			CounterpartiesContactInformation.Ref AS Ref
	//|		FROM
	//|			Catalog.Counterparties.ContactInformation AS CounterpartiesContactInformation
	//|		WHERE
	//|			CounterpartiesContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.CounterpartyRealAddress)) AS ActualAddress
	//|		ON FixedAssetSale.Counterparty = ActualAddress.Ref
	//|		LEFT JOIN (SELECT
	//|			CounterpartiesContactInformation.Country AS Country,
	//|			CounterpartiesContactInformation.Ref AS Ref
	//|		FROM
	//|			Catalog.Counterparties.ContactInformation AS CounterpartiesContactInformation
	//|		WHERE
	//|			CounterpartiesContactInformation.Kind = VALUE(Catalog.ContactInformationKinds.CounterpartyLegalAddress)) AS LegAddress
	//|		ON FixedAssetSale.Counterparty = LegAddress.Ref
	//|WHERE
	//|	FixedAssetSale.Ref IN(&Ref)";
	  	Query.Text	=

	   "SELECT
	   |	FixedAssetSale.Ref,
	   |	FixedAssetSale.DataVersion,
	   |	FixedAssetSale.DeletionMark,
	   |	FixedAssetSale.Number,
	   |	FixedAssetSale.Date AS Date,
	   |	FixedAssetSale.Posted,
	   |	FixedAssetSale.Entity,
	   |	FixedAssetSale.Comment,
	   |	FixedAssetSale.Counterparty,
	   |	FixedAssetSale.Contract,
	   |	FixedAssetSale.DocumentCurrency,
	   |	FixedAssetSale.TaxationVAT,
	   |	FixedAssetSale.AmountIncludesVAT,
	   |	FixedAssetSale.IncludeVATInCost,
	   |	FixedAssetSale.ExchangeRate AS Currency,
	   |	FixedAssetSale.Multiplicity,
	   |	FixedAssetSale.DocumentAmount AS DTotalAmount,
	   |	FixedAssetSale.Author,
	   |	FixedAssetSale.FixedAssets.(
	   |		Ref,
	   |		LineNumber,
	   |		FixedAsset AS Item,
	   |		Cost,
	   |		DepreciatedCost,
	   |		Amortization,
	   |		MonthlyAmortization,
	   |		Amount AS Amount,
	   |		VATRate,
	   |		VATAmount AS VATAmount,
	   |		TotalAmount AS TotalAmount
	   |	),
	   |	FixedAssetSale.Prepayment.(
	   |		Ref,
	   |		LineNumber,
	   |		Document,
	   |		SettlementsAmount,
	   |		ExchangeRate,
	   |		Multiplicity,
	   |		PaymentAmount
	   |	),
	   |	FixedAssetSale.Counterparty.ContactPerson AS ContactPerson
	   |FROM
	   |	Document.FixedAssetSale AS FixedAssetSale";
	
		
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
		
		SelectionFixedAssets	= Selection.FixedAssets.Choose();
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
		//If TemplateName <> "FacturaFiscalaDeVinzare" Then 
		//Header.Parameters["ContactPerson"]  = Selection.ContactPerson;
		//Header.Parameters["ClientCode"]  = Selection.Counterparty.Code;
		//Header.Parameters["Number"]  = Selection.Number;
		//EndIf;
	      ///Adelin Serb 10.02.2015 EndIf
		  
		 ///Adelin Serb 11.02.2015 
		//If ValueIsFilled(Selection.GoodsOrder) Then 		
		//	Header.Parameters["NrComanda"] =  Selection.GoodsOrder.Number     /// I removed /+ " / " + Selection.GoodsOrder.hiCMD;
		//   ///Adelin Serb 11.02.2015
		//EndIf;
		
		//	 
		//If TemplateName <> "FacturaFiscalaDeVinzare" And ValueIsFilled(Selection.GoodsOrder)   Then 
		////	Header.Parameters["ShippingDate"] =  Format(Selection.GoodsOrder.ShippingDate,"DF=""dd.MM.yyyy""");
		//EndIf;  
			// If TemplateName <> "FacturaFiscalaDeVinzare" And ValueIsFilled(Selection.Responsible)   Then 
			//Header.Parameters ["Responsible"] =     Selection.Responsible;
			
/////de pus Selection///////Header.Parameters ["PhoneAgent"]   =    Selection.Author;
/////de pus Selection//////Header.Parameters ["EmailAgent"]   =    Selection.Author;
		// Else
		//	 If TemplateName <> "FacturaFiscalaDeVinzare" Then 
		//Header.Parameters ["Responsible"]  =    Selection.Author;
		//	//Header.Parameters ["PhoneNumber"]   =    Selection.Author.PhoneNumber;
		//	//Header.Parameters ["EmailAgent"]   =  Selection.Author1.ContactInformation.EMail_Address;
		// EndIF;
		// EndIf;
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

		//If ValueIsFilled(Selection.NumberIE) Then
		//	Header.Parameters["NumberIE"] = Selection.NumberIE;
		//Else
		//	Header.Parameters["NumberIE"] = right(SmallBusinessServer.GetNumberForPrinting(Selection.Number, Selection.Entity.Prefix), 
		//	                                strlen(SmallBusinessServer.GetNumberForPrinting(Selection.Number, Selection.Entity.Prefix))-4);
		//EndIf;
										
		Header.Parameters["Date"]				= Format(Selection.Date,"DF=""dd.MM.yyyy""");

		// AlekS  2014-09-10	
		
		While SelectionFixedAssets.Next() Do 
			Try
				Header.Parameters["VATRate"] = SelectionFixedAssets.VATRate;
			Except
			
			EndTry;
			
		EndDo;
		
		Spreadsheet.Put(Header, Selection.Level());
		
//////////////////////////////////////////////////////////AreaInventoryHeader////////////////////////////////////////////////
////////////////////////////////////////////////////////////////START////////////////////////////////////////////////////////
				
		Spreadsheet.Put(AreaInventoryHeader);
//////////////////////////////////////////////////////////AreaInventoryHeader////////////////////////////////////////////////
////////////////////////////////////////////////////////////////END//////////////////////////////////////////////////////////
				
/////////////////////////////////////////////////////////////AreaInventory///////////////////////////////////////////////////
///////////////////////////////////////////////////////////////START/////////////////////////////////////////////////////////
		
		AreaInventory.Parameters.Fill(Selection);
		
		SelectionFixedAssets			= Selection.FixedAssets.Choose();
		//SelectionPaymentCalendar	= Selection.PaymentCalendar.Choose();
		TotalAmount					= 0;
		TotalVAT					= 0;
		Amount                      = 0;
		While SelectionFixedAssets.Next() Do
			AreaInventory.Parameters["LineNumber"]		= SelectionFixedAssets.LineNumber;
			AreaInventory.Parameters["Item"]			= SelectionFixedAssets.Item;
			Quantity=1;
			
			AreaInventory.Parameters["UnitOfMeasure"]	= "buc";
			AreaInventory.Parameters["Quantity"]		= Quantity;
			
	//AreaInventory.Parameters["Amount"]    = Selection.Amount;
	//AreaInventory.Parameters["VATAmount"] = Selection.VATAmount;
	//AreaInventory.Parameters["Price"]     = Price;
				
			i = SelectionFixedAssets.LineNumber;
			Spreadsheet.Put(AreaInventory, SelectionFixedAssets.Level());
	EndDo;
		
	For i=i +1 To 35 Do      
		AreaInventory.Parameters["LineNumber"]		= i;
		AreaInventory.Parameters["Item"]			= Undefined;
		AreaInventory.Parameters["UnitOfMeasure"]	= Undefined;
		AreaInventory.Parameters["Quantity"]		= Undefined;
		AreaInventory.Parameters["Price"]			= Undefined;
		AreaInventory.Parameters["Amount"]			= Undefined;
		AreaInventory.Parameters["VATAmount"]		= Undefined;		
				
		Spreadsheet.Put(AreaInventory, SelectionFixedAssets.Level());
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
		//
		//Footer.Parameters.Fill(SelectionPaymentCalendar);
		//Footer.Parameters.Fill(Selection);
		////Footer.Parameters["TotalTVA"] = Round(TotalVAT, 2);
		////Footer.Parameters["TotalCuTVA"] = Round(TotalAmount,2);
		////Footer.Parameters["TotalFaraTVA"] = Round(TotalAmount - TotalVAT,2);
		//
		//Try
		//	Footer.Parameters["TotalTVA"]			= Format(Selection.DocumentVATAmount*Rate,				"NFD=2");
		Footer.Parameters["TotalCuTVA"]			= Format(Selection.DTotalAmount*Rate,"NFD=2");
		//Except
		//
		//EndTry;
		//
		//Footer.Parameters["TotalFaraTVA"]		= Format(Selection.DAmountWithoutVAT*Rate,			"NFD=2");

//		Footer.Parameters["Driver"]				= Selection.Driver;
//		If TemplateName <> "Invoice" Then
//			Footer.Parameters["CI"]					= Selection.Driver.IDCard;
//			Footer.Parameters["MijlocDeTransport"]	= Selection.Readdressing;
//		EndIf;
//		Footer.Parameters["Date"]				= Selection.Date;
//		///Adelin Serb 10.02.2015 If
//		
//		If TemplateName  <>  "FacturaFiscalaDeVinzare" And  CommaPosition > 0 Then
//		Footer.Parameters["Company"] = left(CounterpartyName, CommaPosition-1);
//	     EndIf;
//		  //  I removed   ///  Else ///   Footer.Parameters["Company"] = 		CounterpartyName;

//		If TemplateName  <>  "FacturaFiscalaDeVinzare" Then
//		Footer.Parameters ["KPPC"]			    = Selection.Counterparty.CIO;
////in asteptare//Footer.Parameters ["CountryCAct"]       = Selection.Counterparty.ActualAddress.Country;                      
//		 EndIf;
//		///Adelin Serb 10.02.2015 EndIf
//		
//         If TemplateName <> "FacturaFiscalaDeVinzare" Then 
//         Footer.Parameters["ContactPerson"]  = Selection.Counterparty.ContactPerson;
//		 EndIf; 
//		 
//		Try
//			Footer.Parameters["CNP"]				= Selection.Driver.PersonalCode;
////			Footer.Parameters["User"]				= Selection.Author;
////			
//			Footer.Parameters["DataLimita"] = Format(Selection.Date + (Selection.Contract.CustomerPaymentTerm * 86400), "DF=""dd.MM.yyyy""");
//		Except
//		
//		EndTry;
//		
		 //  ///Adelin Serb 11.02.2015
		 //If TemplateName <> "FacturaFiscalaDeVinzare" Then
		 //Footer.Parameters["AddressCAct"]		= SmallBusinessServer.EntitiesLongDescription(InfoAboutVendorC, "ActualAddress,");
		 //EndIf ;
		 /////Adelin Serb 11.02.2015
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

	Return "" + Header.FixedAsset + ", " + Header.Characteristic;	
EndFunction // CreateStringProduct(Header)