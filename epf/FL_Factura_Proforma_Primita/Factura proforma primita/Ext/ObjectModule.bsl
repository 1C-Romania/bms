///////////////////////////////////////////////////
//
// Preparation external print form
//
/////////////////////////////////////////////////// 
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
	DestinationArray.Add("Document.PurchaseInvoiceForPayment");
	//DestinationArray.Add("Document.PurchaseInvoiceForPayment");

	RegistrationParametrs.Insert("Presentation", DestinationArray);
	
	// Parameters for registration ExtProc in Application
	RegistrationParametrs.Insert("Description", "Forma de listare la doc. Factură proformă primită");
	RegistrationParametrs.Insert("Version", "1.0"); 	// "1.0"
	RegistrationParametrs.Insert("SafeMode", False); 	// Variants: True, False / Варианты: Истина, Ложь 
	RegistrationParametrs.Insert("Information", "Forma de listare la doc. Factură proformă primită");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
	"Factura Proforma Romania",						    // what we will see under button PRINT
	"FacturaProformaEmisa",   							// Name of Template 
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
			TemplateName,  												// Template Name
			TemplateName,   											// Template Synonim
			CreatePrintForm(ObjectArray, PrintObjects, TemplateName)  	// Function for Execution (in this Module) - исполняющая функция (в этом же модуле)
	);
	
EndProcedure

Function CreatePrintForm(ObjectsArray, PrintObjects, TemplateName)	

	Var Errors;
	
	// Получение макета и создание на его основании табличного документа, который будет выведен на печать
	// Get Template and creating  "on base" the Table Document for printing 
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_PurchasePurchaseInvoiceForPayment";  // PrintParameters_ + Name_of_Document
	
	// ЭтотОбъект - объект обработки где расположен Template
	// ThisObject - the Object of procedure where Template is placed
	DesignName	= ThisObject.GetTemplate(TemplateName);
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	PurchaseInvoiceForPayment.Ref AS Ref,
	|	PurchaseInvoiceForPayment.AmountIncludesVAT AS AmountIncludesVAT,
	|	PurchaseInvoiceForPayment.DocumentCurrency AS DocumentCurrency,
	|	PurchaseInvoiceForPayment.Date AS DocumentDate,
	|	PurchaseInvoiceForPayment.Number AS Number,
	|	PurchaseInvoiceForPayment.BankAccount AS BankAccount,
	|	PurchaseInvoiceForPayment.Counterparty AS Counterparty,
	|	PurchaseInvoiceForPayment.Entity AS Entity,
	|	PurchaseInvoiceForPayment.Entity.Prefix AS Prefix,
	|	PurchaseInvoiceForPayment.Inventory.(
	|		CASE
	|			WHEN (CAST(PurchaseInvoiceForPayment.Inventory.Nomenclature.DescriptionFull AS STRING(1000))) = """"
	|				THEN PurchaseInvoiceForPayment.Inventory.Nomenclature.Description
	|			ELSE CAST(PurchaseInvoiceForPayment.Inventory.Nomenclature.DescriptionFull AS STRING(1000))
	|		END AS InventoryItem,
	|		Nomenclature.SKU AS SKU,
	|		UnitOfMeasure AS UnitOfMeasure,
	|		Price AS Price,
	|		Amount AS Amount,
	|		VATAmount AS VATAmount,
	|		TotalAmount AS TotalAmount,
	|		Quantity AS Quantity,
	|		Characteristic,
	|		Content,
	////|		DiscountMarkupRate,
	//|		CASE
	//|			WHEN PurchaseInvoiceForPayment.Inventory.DiscountMarkupRate <> 0
	//|				THEN 1
	//|			ELSE 0
	//|		END AS IsDiscount,
	|		LineNumber AS LineNumber
	|	),
	|	PurchaseInvoiceForPayment.PaymentCalendar.(
	|		PaymentPercentage,
	|		AmountOfPayment,
	|		PayVATAmount
	|	)
	|FROM
	|	Document.PurchaseInvoiceForPayment AS PurchaseInvoiceForPayment
	|WHERE
	|	PurchaseInvoiceForPayment.Ref IN(&ObjectsArray)
	|
	|ORDER  BY
	|	Ref,
	|	LineNumber";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Header = Query.Execute().Select();
	
	FirstDocument = True;
	
	While Header.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument			= False;
		FirstRowNumber			= SpreadsheetDocument.TableHeight + 1;
		
		LinesSelectionInventory = Header.Inventory.Select();
		PrepaymentTable 		= Header.PaymentCalendar.Unload(); 
				
		SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_" + DesignName + "_" + DesignName;
		
		//Template = PrintManagement.GetTemplate("Document.PurchaseInvoiceForPayment.PF_MXL_" + DesignName);
		Template				= ThisObject.GetTemplate(TemplateName);
		
		InfoAboutEntity			= SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Entity, Header.DocumentDate, ,Header.BankAccount);
		InfoAboutCounterparty	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Counterparty, Header.DocumentDate, ,);
		
		//
		If Template.Areas.Find("TitleWithLogo") <> Undefined
			AND Template.Areas.Find("TitleWithoutLogo") <> Undefined Then
			
			If ValueIsFilled(Header.Entity.LogoFile) Then
				
				TemplateArea = Template.GetArea("TitleWithLogo");
				
				PictureData  = AttachedFiles.GetFileBinaryData(Header.Entity.LogoFile);
				If ValueIsFilled(PictureData) Then
					TemplateArea.Drawings.Logo.Picture = New Picture(PictureData);
				EndIf;
				
			Else // 
				TemplateArea = Template.GetArea("TitleWithoutLogo");
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
		Else
			MessageText = NStr("en='ATTENTION! Perhaps the user template is used. Staff mechanism for the accounts printing may work incorrectly.';
							   |ro='ATENȚIE! Poate se folosește șablonul de utilizator. Mecanism de personal pentru tipărirea conturile pot lucra în mod incorect.';
							   |ru='ВНИМАНИЕ! Возможно используется пользовательский макет. Штатный механизм печати счетов может работать некоректно.'");
			CommonUseClientServer.AddUserError(Errors, , MessageText);
		EndIf;
		
		TemplateArea = Template.GetArea("InvoiceHeader");
		
		If ValueIsFilled(InfoAboutEntity.Bank) Then
			TemplateArea.Parameters.RecipientBankPresentation = InfoAboutEntity.Bank.Description + " " + InfoAboutEntity.Bank.City;
		EndIf; 
		TemplateArea.Parameters.TIN					= InfoAboutEntity.TIN;
		TemplateArea.Parameters.CIO					= InfoAboutEntity.CIO;
		TemplateArea.Parameters.VendorPresentation	= ?(IsBlankString(InfoAboutEntity.CorrespondentText), 
														InfoAboutEntity.FullDescr, 
														InfoAboutEntity.CorrespondentText);
		TemplateArea.Parameters.RecipientBankBIN	= InfoAboutEntity.BIN;
		
		TemplateArea.Parameters.RecipientBankAccountPresentation = InfoAboutEntity.CorrAccount;
		TemplateArea.Parameters.RecipientAccountPresentation	 = InfoAboutEntity.AccountNo;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		If Header.DocumentDate < Date('20110101') Then
			DocumentNo = SmallBusinessServer.GetNumberForPrinting(Header.Number, Header.Prefix);
		Else
			DocumentNo = ObjectPrefixationClientServer.GetNumberForPrinting(Header.Number, True, True);
		EndIf;		
		
		TemplateArea = Template.GetArea("Title");
		//TemplateArea.Parameters.HeaderText = "Invoice for payment # "
		//										+ DocumentNo
		//										+ " from "
		//										+ Format(Header.DocumentDate, "L = en; DLF=DD");
												
		TemplateArea.Parameters.HeaderText = NStr("en = 'Invoice for payment # '; ro = 'Factura proformă Nr. '; ru = 'Factura proformă Nr. '") + 
											 DocumentNo + 
											 NStr("en = ' from '; ro = ' din data '; ru = ' din data '") + 
											 Format(Header.DocumentDate, "DLF=DD");
												
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Vendor");
		//TemplateArea.Parameters.VendorPresentation	  = SmallBusinessServer.EntitiesLongDescription(InfoAboutEntity, 
		//																							"FullDescr,TIN,CIO,LegalAddress,PhoneNumbers,");
		TemplateArea.Parameters.VendorPresentation	  = SmallBusinessServer.EntitiesLongDescription(InfoAboutEntity, "FullDescr,");
		TemplateArea.Parameters.CUI 	= InfoAboutEntity.CIO;
		TemplateArea.Parameters.ORC		= InfoAboutEntity.TIN;
		TemplateArea.Parameters.Adresa	= InfoAboutEntity.LegalAddress;
		TemplateArea.Parameters.Banca	= InfoAboutEntity.Bank;
		TemplateArea.Parameters.Cont	= InfoAboutEntity.AccountNo;
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Customer");
		//TemplateArea.Parameters.RecipientPresentation = SmallBusinessServer.EntitiesLongDescription(InfoAboutCounterparty, 
		//																							"FullDescr,TIN,CIO,LegalAddress,PhoneNumbers,");
		TemplateArea.Parameters.RecipientPresentation = SmallBusinessServer.EntitiesLongDescription(InfoAboutCounterparty, "FullDescr,");
		TemplateArea.Parameters.CUI		= InfoAboutCounterparty.CIO;
		TemplateArea.Parameters.ORC		= InfoAboutCounterparty.TIN;
		TemplateArea.Parameters.Adresa	= InfoAboutCounterparty.LegalAddress;
		TemplateArea.Parameters.Banca	= InfoAboutCounterparty.Bank;
		TemplateArea.Parameters.Cont	= InfoAboutCounterparty.AccountNo;
		SpreadsheetDocument.Put(TemplateArea);

		//AreDiscounts = Header.Inventory.Unload().Total("IsDiscount") <> 0;
		//
		//If AreDiscounts Then
		//	
		//	TemplateArea = Template.GetArea("TableWithDiscountHeader");
		//	SpreadsheetDocument.Put(TemplateArea);
		//	TemplateArea = Template.GetArea("RowWithDiscount");
		//	
		//Else
			
			TemplateArea = Template.GetArea("TableHeader");
			SpreadsheetDocument.Put(TemplateArea);
			TemplateArea = Template.GetArea("String");
			
		//EndIf;
		
		Amount		= 0;
		VATAmount	= 0;
		TotalAmount	= 0;
		Quantity	= 0;

		While LinesSelectionInventory.Next() Do
			
			Quantity = Quantity + 1;
			TemplateArea.Parameters.Fill(LinesSelectionInventory);
			TemplateArea.Parameters.LineNumber = Quantity;
			
			If ValueIsFilled(LinesSelectionInventory.Content) Then
				TemplateArea.Parameters.InventoryItem = LinesSelectionInventory.Content;
			Else
				TemplateArea.Parameters.InventoryItem = SmallBusinessServer.GetNomenclaturePresentationForPrinting(
																	LinesSelectionInventory.InventoryItem, 
																	LinesSelectionInventory.Characteristic,
																	LinesSelectionInventory.SKU);
			EndIf;
						
			//If AreDiscounts Then
			//	If LinesSelectionInventory.DiscountMarkupRate = 100 Then
			//		Discount 									  = LinesSelectionInventory.Price * LinesSelectionInventory.Quantity;
			//		TemplateArea.Parameters.Discount         	  = Discount;
			//		TemplateArea.Parameters.AmountWithoutDiscount = Discount;
			//	ElsIf LinesSelectionInventory.DiscountMarkupRate = 0 Then
			//		TemplateArea.Parameters.Discount         	  = 0;
			//		TemplateArea.Parameters.AmountWithoutDiscount = LinesSelectionInventory.Amount;
			//	Else
			//		Discount = LinesSelectionInventory.Amount * LinesSelectionInventory.DiscountMarkupRate / (100 - LinesSelectionInventory.DiscountMarkupRate);
			//		TemplateArea.Parameters.Discount         	  = Discount;
			//		TemplateArea.Parameters.AmountWithoutDiscount = LinesSelectionInventory.Amount + Discount;
			//	EndIf;
			//EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
			Amount		= Amount		+ LinesSelectionInventory.Amount;
			VATAmount	= VATAmount		+ LinesSelectionInventory.VATAmount;
			TotalAmount	= TotalAmount	+ LinesSelectionInventory.TotalAmount;
			
		EndDo;
		
		TemplateArea = Template.GetArea("Total");
		TemplateArea.Parameters.TotalAmount = SmallBusinessServer.AmountsFormat(Amount);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("TotalVAT");
		If VATAmount = 0 Then
			
			//TemplateArea.Parameters.VAT = "Without tax (VAT)";
			TemplateArea.Parameters.VAT = NStr("en = 'Without tax (VAT)'; ro = 'fara TVA'; ru = 'fara TVA'");
			TemplateArea.Parameters.TotalVAT = "-";
			
		Else
			
			//TemplateArea.Parameters.VAT = ?(Header.AmountIncludesVAT, "Including VAT:", "VAT Amount:");
			TemplateArea.Parameters.VAT = ?(Header.AmountIncludesVAT, 
											NStr("en = 'Including VAT:'; ro = 'Inclusive TVA:'; ru = 'Inclusive TVA:'"), 
											NStr("en = 'VAT Amount:'; ro = 'Valoarea TVA:'; ru = 'Valoarea TVA:'"));
			TemplateArea.Parameters.TotalVAT = SmallBusinessServer.AmountsFormat(VATAmount);
			
		EndIf; 
		
		///////////////////////////////////////////////////////////
		//
		//  NU TREBUIE SA STERGETI !!!  SE POATE - MAI TREBUIE IN VIITOR !!!
		//
		///////////////////////////////////////////////////////////
		//If DesignName = "InvoiceForPartialPay" Then
		//	
		//	If VATAmount = 0 Then
		//		TemplateArea.Parameters.VATToPay = NStr("en = 'Without tax (VAT)'; ro = 'fara TVA'; ru = 'fara TVA'");
		//		TemplateArea.Parameters.TotalVATToPay = "-";
		//	Else
		//		TemplateArea.Parameters.VATToPay = ?(Header.AmountIncludesVAT, 
		//											 NStr("en = 'In volume among the VAT Payments:'"), 
		//											 NStr("en = 'Amount VAT Payments:'");
		//		If PrepaymentTable.Total("PaymentPercentage") > 0 Then
		//			TemplateArea.Parameters.TotalVATToPay = SmallBusinessServer.AmountsFormat(PrepaymentTable.Total("PayVATAmount"));
		//		Else
		//			TemplateArea.Parameters.TotalVATToPay = "-";
		//		EndIf;
		//	EndIf; 
		//	
		//	If PrepaymentTable.Total("PaymentPercentage") > 0 Then
		//		TemplateArea.Parameters.TotalToPay = SmallBusinessServer.AmountsFormat(PrepaymentTable.Total("AmountOfPayment"));
		//		TemplateArea.Parameters.PaymentPercentage = PrepaymentTable.Total("PaymentPercentage");
		//	Else
		//		TemplateArea.Parameters.TotalToPay = "-";
		//		TemplateArea.Parameters.PaymentPercentage = "-";
		//	EndIf;
		//	
		//EndIf;
		///////////////////////////////////////////////////////////
		
		SpreadsheetDocument.Put(TemplateArea);
		
		If Template.Areas.Find("TotalToPay") = Undefined Then
			
			MessageText = NStr("en='ATTENTION! Template area is not found ""Total for payment"". Perhaps, user template is used';
							   |ro='ATENȚIE! Zona șablon nu este găsit ""Total de plata"". Poate că, șablon de utilizator este folosit';
							   |ru='ВНИМАНИЕ! Не обнаружена область макета ""Итог к оплате"". Возможно используется пользовательский макет.'");
			CommonUseClientServer.AddUserError(Errors, , MessageText);
			
		Else
			
			TemplateArea = Template.GetArea("TotalToPay");
			TemplateArea.Parameters.TotalToPayText = NStr("en = 'Total to pay:'; ro = 'Total de plata:'; ru = 'Total de plata:'");
			TemplateArea.Parameters.Fill(New Structure("TotalToPay", SmallBusinessServer.AmountsFormat(TotalAmount)));
			SpreadsheetDocument.Put(TemplateArea);
			
		EndIf;
		
		TemplateArea = Template.GetArea("AmountInWords");
		AmountToBeWrittenInWords = TotalAmount;
		TemplateArea.Parameters.TotalRow =  NStr("en = 'Total titles '; ro = 'Total marfuri '; ru = 'Total marfuri '") + 
											String(Quantity) + 
											NStr("en = ', on amount '; ro = ', in total '; ru = ', in total '") + 
											SmallBusinessServer.AmountsFormat(AmountToBeWrittenInWords, Header.DocumentCurrency);
		
		TemplateArea.Parameters.AmountInWords = WorkWithExchangeRates.GenerateAmountInWords(AmountToBeWrittenInWords, Header.DocumentCurrency);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("AccountFooter");
		
		Heads = SmallBusinessServer.OrganizationalUnitsResponsiblePersons(Header.Entity, Header.DocumentDate);
		
		TemplateArea.Parameters.HeadFullName = Heads.HeadFullName;
		TemplateArea.Parameters.AccountantFullName   = Heads.ChiefAccountantNameAndSurname;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstRowNumber, PrintObjects, Header.Ref);
		
	EndDo;
	
	CommonUseClientServer.ShowErrorsToUser(Errors);
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction   //  CreatePrintForm(ObjectArray, PrintObjects, DesignName)

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