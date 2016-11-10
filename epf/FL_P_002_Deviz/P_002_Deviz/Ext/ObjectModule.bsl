///////////////////////////////////////////////////
//
// Preparation external print form
//
/////////////////////////////////////////////////// 
Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	RegistrationParametrs.Insert("Type", "PrintForm"); 
	
	DestinationArray = New Array();
	DestinationArray.Add("Document.CustomerOrder");
	//DestinationArray.Add("Document.InvoiceForPayment");

	RegistrationParametrs.Insert("Presentation", DestinationArray);
	
	// Parameters for registration ExtProc in Application
	//RegistrationParametrs.Insert("Description", "Formele de listare la doc. Comanda de lucru");
	RegistrationParametrs.Insert("Description", "Formele de listare la doc. Comanda Deviz");
	RegistrationParametrs.Insert("Version", "4.1"); 	// "1.0"
	RegistrationParametrs.Insert("SafeMode", False); 	// Variants: True, False / Варианты: Истина, Ложь 
	RegistrationParametrs.Insert("Information", "Formele de listare la doc. Comanda Deviz");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
				"Comanda Deviz",						// what we will see under button PRINT
				"ComandaDeviz",   							    // Name of Template 
				"CallOfServerMethod",  					// "CallOfServerMethod" = for MXL / "CallOfClientMethod" = for WORD !!! Использование.  Варианты: "ОткрытиеФормы", "ВызовКлиентскогоМетода", "ВызовСерверногоМетода"   
				False,									// Показывать оповещение. Варианты Истина, Ложь / Variants: True, False
				"MXLPrint");           					// "MXLPrint" = for MXL / "" = for WORD !!! Модификатор 
	
	AddCommand(CommandTable,
				"Deviz de reparatie",						// what we will see under button PRINT
				"DevizDeReparatie",   							    // Name of Template 
				"CallOfServerMethod",  					// "CallOfServerMethod" = for MXL / "CallOfClientMethod" = for WORD !!! Использование.  Варианты: "ОткрытиеФормы", "ВызовКлиентскогоМетода", "ВызовСерверногоМетода"   
				False,									// Показывать оповещение. Варианты Истина, Ложь / Variants: True, False
				"MXLPrint");           					// "MXLPrint" = for MXL / "" = for WORD !!! Модификато?":gc45	
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

/////////////////////////////////////////////////////
//
// Preparing of Print Form 
//
/////////////////////////////////////////////////////
Procedure Print(ObjectArray, PrintFormsCollection, PrintObjects, OutputParametrs)  Export 
	
	Try
		TemplateName = PrintFormsCollection[0].DesignName;
	Except
		Message(NStr("en = 'Template name is empty!'; 
					 |ro = 'Numele șablonului este gol!'; 
					 |ru = 'Template name is empty!'"));
		Return;
	EndTry;
	
	PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			TemplateName,  												// Template Name
			TemplateName,   											// Template Synonim
			CreatePrintForm(ObjectArray, PrintObjects, TemplateName)  	// Function for Execution (in this Module) - исполняющая функция (в этом же модуле)
	);
	
EndProcedure

/////////////////////////////////////////////////////
//
// Preparing of Print Form 
//
/////////////////////////////////////////////////////
Function CreatePrintForm(ObjectsArray, PrintObjects, TemplateName)	

	Var Errors;
		
	// Получение макета и создание на его основании табличного документа, который будет выведен на печать
	// Get Template and creating  "on base" the Table Document for printing 
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_CustomerOrder";  // PrintParameters_ + Name_of_Document
	
	// ЭтотОбъект - объект обработки, где расположен Template
	// ThisObject - the Object of procedure where Template is placed
	//DesignName	= ThisObject.GetTemplate(TemplateName);
	

/////////////////////////////////////////////////////
//

	FirstDocument = True;
	
	For Each CurrentDocument In ObjectsArray Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		FirstRowNumber = SpreadsheetDocument.TableHeight + 1;
		
		Query = New Query;
		Query.SetParameter("CurrentDocument", CurrentDocument);
		Query.Text = 
		"SELECT
		|	CustomerOrder.Ref AS Ref,
		|	CustomerOrder.Number AS Number,
		|	CustomerOrder.Date AS DocumentDate,
		|	CustomerOrder.PCShop_BaseDocument.Number AS VST,
		|	CustomerOrder.Start,
		|	CustomerOrder.Finish,
		|	CustomerOrder.Entity AS Entity,
		|	CustomerOrder.Counterparty AS Counterparty,
		|	CustomerOrder.AmountIncludesVAT AS AmountIncludesVAT,
		|	CustomerOrder.DocumentCurrency AS DocumentCurrency,
		|	CustomerOrder.Entity.Prefix AS Prefix,
		|	CustomerOrder.Inventory.(
		|		LineNumber AS LineNumber,
		|		CASE
		|			WHEN (CAST(CustomerOrder.Inventory.Nomenclature.DescriptionFull AS STRING(1000))) = """"
		|				THEN CustomerOrder.Inventory.Nomenclature.Description
		|			ELSE CAST(CustomerOrder.Inventory.Nomenclature.DescriptionFull AS STRING(1000))
		|		END AS Product,
		|		Nomenclature.SKU AS SKU,
		|		UnitOfMeasure.Description AS UnitOfMeasure,
		|		Quantity AS Quantity,
		|		Price AS Price,
		|		Amount AS Amount,
		|		VATAmount AS VATAmount,
		|		TotalAmount AS TotalAmount,
		|		Characteristic,
		|		Content AS Content,
		|		DiscountMarkupRate,
		|		CASE
		|			WHEN CustomerOrder.Inventory.DiscountMarkupRate <> 0
		|				THEN 1
		|			ELSE 0
		|		END AS IsDiscount
		|	),
		|	CustomerOrder.ConsumerMaterials.(
		|		LineNumber AS LineNumber,
		|		CASE
		|			WHEN (CAST(CustomerOrder.ConsumerMaterials.Nomenclature.DescriptionFull AS STRING(1000))) = """"
		|				THEN CustomerOrder.ConsumerMaterials.Nomenclature.Description
		|			ELSE CAST(CustomerOrder.ConsumerMaterials.Nomenclature.DescriptionFull AS STRING(1000))
		|		END AS Product,
		|		Nomenclature.SKU AS SKU,
		|		UnitOfMeasure.Description AS UnitOfMeasure,
		|		Quantity AS Quantity,
		|		Characteristic
		|	),
		|	CustomerOrder.Author AS User
		|FROM
		|	Document.CustomerOrder AS CustomerOrder
		|WHERE
		|	CustomerOrder.Ref = &CurrentDocument";
		
		Header = Query.Execute().Select();
		Header.Next();

		Query = New Query;
		Query.SetParameter("CurrentDocument", CurrentDocument);
		Query.SetParameter("ToDate", Header.DocumentDate);
		Query.Text = 
		"SELECT
		|	CustomerOrderWorks.LineNumber 																AS LineNumber,
		|	CASE
		|		WHEN (CAST(CustomerOrderWorks.Nomenclature.DescriptionFull AS STRING(1000))) = """"
		|			THEN CustomerOrderWorks.Nomenclature.Description
		|		ELSE CAST(CustomerOrderWorks.Nomenclature.DescriptionFull AS STRING(1000))
		|	END 																						AS Product,
		|	CustomerOrderWorks.Nomenclature.SKU 														AS SKU,
		|	CustomerOrderWorks.Nomenclature.UnitOfMeasure.Description 									AS UnitOfMeasure,
		|	CustomerOrderWorks.Quantity 																AS Quantity,
		|	CustomerOrderWorks.Quantity * CustomerOrderWorks.Multiplicity * CustomerOrderWorks.Factor 	AS CountRepetitionFactor,
		|	CustomerOrderWorks.Price 																	AS Price,
		|	CustomerOrderWorks.Amount 																	AS Amount,
		|	CustomerOrderWorks.VATAmount 																AS VATAmount,
		|	ISNULL(CustomerOrderWorks.TotalAmount, 0) 													AS TotalAmount,
		|	CustomerOrderWorks.Characteristic 															AS Characteristic,
		|	CustomerOrderWorks.Content 																	AS Content,
		|	CustomerOrderWorks.DiscountMarkupRate 														AS DiscountMarkupRate,
		|	CASE
		|		WHEN CustomerOrderWorks.DiscountMarkupRate <> 0
		|			THEN 1
		|		ELSE 0
		|	END 																						AS IsDiscount,
		|	IndividualsNameAndSurnameSliceLast.Surname,
		|	IndividualsNameAndSurnameSliceLast.Name,
		|	IndividualsNameAndSurnameSliceLast.Patronymic,
		|	CustomerOrderAssignees.Employee.Ind 														AS Ind,
		|	CustomerOrderWorks.LinkKey 																	AS LinkKey
		|FROM
		|	Document.CustomerOrder.Jobs 																AS CustomerOrderWorks
		|		LEFT JOIN Document.CustomerOrder.Assignees AS CustomerOrderAssignees
		|			LEFT JOIN InformationRegister.IndividualsNameAndSurname.SliceLast(&ToDate, ) 		AS IndividualsNameAndSurnameSliceLast
		|				ON CustomerOrderAssignees.Employee.Ind = IndividualsNameAndSurnameSliceLast.Ind
		|			ON CustomerOrderWorks.LinkKey = CustomerOrderAssignees.LinkKey
		|			AND (CustomerOrderAssignees.Ref = &CurrentDocument)
		|WHERE
		|	CustomerOrderWorks.Ref = &CurrentDocument
		|TOTALS
		|	MAX(Product),
		|	MAX(SKU),
		|	MAX(UnitOfMeasure),
		|	MAX(Quantity),
		|	MAX(CountRepetitionFactor),
		|	MAX(Price),
		|	MAX(Amount),
		|	MAX(VATAmount),
		|	MAX(TotalAmount),
		|	MAX(Characteristic),
		|	MAX(Content),
		|	MAX(DiscountMarkupRate),
		|	MAX(IsDiscount)
		|BY
		|	LinkKey";
		
		
		
		QueryResultWork					= Query.Execute();
		RowsSelectionWork				= QueryResultWork.Select(QueryResultIteration.ByGroups, "LinkKey");
		RowsSelectionProducts			= Header.Inventory.Select();
		RowsOfCustomerMaterialsSelection= Header.ConsumerMaterials.Select();
		
		SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_PF_MXL_OrderCustomerWorkOrder";
		
		//Template = PrintManagement.GetTemplate("Document.CustomerOrder.PF_MXL_WorkOrder");
		Template = ThisObject.GetTemplate(TemplateName);
	
		InfoAboutEntity			= SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Entity, Header.DocumentDate, ,);
		InfoAboutCounterparty 	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Counterparty, Header.DocumentDate, ,);
		
		If Header.DocumentDate < Date('20110101') Then
			DocumentNo = SmallBusinessServer.GetNumberForPrinting(Header.Number, Header.Prefix);
		Else
			DocumentNo = ObjectPrefixationClientServer.GetNumberForPrinting(Header.Number, True, True);
		EndIf;		

		TemplateArea = Template.GetArea("Header");
		TemplateArea.Parameters.Fill(Header);
		//TemplateArea.Parameters.VendorPresentation = SmallBusinessServer.EntitiesLongDescription(InfoAboutEntity, "FullDescr,TIN,CIO,LegalAddress,PhoneNumbers,");
		TemplateArea.Parameters.VendorPresentation = ?(IsBlankString(InfoAboutEntity.CorrespondentText), 
														InfoAboutEntity.FullDescr, 
														InfoAboutEntity.CorrespondentText);
		
		TemplateArea.Parameters.ORC 			= InfoAboutEntity.TIN;
		TemplateArea.Parameters.CUI 			= InfoAboutEntity.CIO;
		TemplateArea.Parameters.Adresa 			= InfoAboutEntity.LegalAddress;
		//TemplateArea.Parameters.VendorBankBIN 	= InfoAboutEntity.BIN;
		If ValueIsFilled(InfoAboutEntity.Bank) Then
			TemplateArea.Parameters.Banca	= InfoAboutEntity.Bank.Description;
		EndIf; 
		TemplateArea.Parameters.Cont 			= InfoAboutEntity.AccountNo;
		//TemplateArea.Parameters.VendorBankAccountPresentation = InfoAboutEntity.CorrAccount;
		//SpreadsheetDocument.Put(TemplateArea);
		
		/////////////////////////////////////////////////////
		//TemplateArea = Template.GetArea("Customer");
		//TemplateArea.Parameters.RecipientPresentation = SmallBusinessServer.EntitiesLongDescription(InfoAboutCounterparty, "FullDescr,TIN,CIO,LegalAddress,PhoneNumbers,");
		TemplateArea.Parameters.RecipientPresentation = ?(IsBlankString(InfoAboutCounterparty.CorrespondentText), 
														InfoAboutCounterparty.FullDescr, 
														InfoAboutCounterparty.CorrespondentText);
		
		TemplateArea.Parameters.ORCC 				= InfoAboutCounterparty.TIN;
		TemplateArea.Parameters.CUIC 				= InfoAboutCounterparty.CIO;
		TemplateArea.Parameters.AdresaC 			= InfoAboutCounterparty.LegalAddress;
		//TemplateArea.Parameters.RecipientBankBIN 	= InfoAboutCounterparty.BIN;
		If ValueIsFilled(InfoAboutCounterparty.Bank) Then
			TemplateArea.Parameters.BancaC	= InfoAboutCounterparty.Bank.Description;
		EndIf; 
		TemplateArea.Parameters.ContC 				= InfoAboutCounterparty.AccountNo;		
		TemplateArea.Parameters.Date                = Header.DocumentDate;
		
		//TemplateArea.Parameters.RecipientBankAccountPresentation = InfoAboutCounterparty.CorrAccount;
		//SpreadsheetDocument.Put(TemplateArea);
		
		/////////////////////////////////////////////////////
		//TemplateArea = Template.GetArea("Terms");
		FillPropertyValues(TemplateArea.Parameters, Header);
		SpreadsheetDocument.Put(TemplateArea);
		
		WorkAmount		= 0;
		AmountVATWork	= 0;
		Amount			= 0;
		VATAmount		= 0;
		TotalAmount		= 0;
		LineNumberS		= 0;
		
		
		///////////////////////////////////////////////////////
		//AreDiscounts = Header.Inventory.Unload().Total("IsDiscount") <> 0;
		//
		//If AreDiscounts Then
		//	/////////////////////////////////////////////////////
		//	TemplateArea = Template.GetArea("TableWithDiscountHeader");
		//	SpreadsheetDocument.Put(TemplateArea);
		//	
		//	/////////////////////////////////////////////////////
		//	TemplateArea = Template.GetArea("RowWithDiscount");
		//Else
		//	/////////////////////////////////////////////////////
		//	//TemplateArea = Template.GetArea("TableHeader");
		//	//SpreadsheetDocument.Put(TemplateArea);
		//	//
		//	/////////////////////////////////////////////////////
		//	TemplateArea = Template.GetArea("JobRow");
		//EndIf;
		//	
		//AreDiscounts = QueryResultWork.Unload().Total("IsDiscount") <> 0;
		//
		//If AreDiscounts Then
		//	/////////////////////////////////////////////////////
		//	TemplateArea = Template.GetArea("TableWithDiscountHeader");
		//	SpreadsheetDocument.Put(TemplateArea);
		//	
		//	/////////////////////////////////////////////////////
		//	TemplateArea = Template.GetArea("RowWithDiscount");
		//Else
		//	/////////////////////////////////////////////////////
		//	TemplateArea = Template.GetArea("TableHeader");
		//	SpreadsheetDocument.Put(TemplateArea);
		//	
		//	/////////////////////////////////////////////////////
		//	TemplateArea = Template.GetArea("JobRow");
		//	////////////////////////////
		//	TemplateArea = Template.GetArea("TotalProducts");
		//EndIf;
		///////////////////////////////////////////////////////
			
			
		///////////////////////////////////////////////////////
		TemplateArea = Template.GetArea("TableHeader");
		SpreadsheetDocument.Put(TemplateArea);
		
		///////////////////////////////////////////////////////
		TemplateArea = Template.GetArea("ProductJobRow");
		
		
		/////////////////////////////////////////////////////
		// PRODUCTS start
		//
		If Header.Inventory.Unload().Count() > 0 Then
			
			AmountProducts		= 0;
			AmountVATProducts	= 0;
			
			While RowsSelectionProducts.Next() Do
				TemplateArea.Parameters.Fill(RowsSelectionProducts);
				
				If ValueIsFilled(RowsSelectionProducts.Content) Then
					TemplateArea.Parameters.Product = RowsSelectionProducts.Content;
				Else
					TemplateArea.Parameters.Product = SmallBusinessServer.GetNomenclaturePresentationForPrinting(RowsSelectionProducts.Product +
																							(" - ") 										   +
																							RowsSelectionProducts.SKU, 
																							RowsSelectionProducts.Characteristic, 
																							RowsSelectionProducts.SKU);
				EndIf;
				
				TemplateArea.Parameters.VATn = ?(RowsSelectionProducts.VATAmount = 0, 0, RowsSelectionProducts.VATAmount);
				
				SpreadsheetDocument.Put(TemplateArea);
				
				AmountProducts	 = AmountProducts	+ RowsSelectionProducts.Amount;
				AmountVATProducts= AmountVATProducts+ RowsSelectionProducts.VATAmount;
				Amount			 = Amount			+ RowsSelectionProducts.Amount;
				VATAmount		 = VATAmount		+ RowsSelectionProducts.VATAmount;
				TotalAmount 	 = TotalAmount		+ RowsSelectionProducts.TotalAmount;
				LineNumberS		 = LineNumberS 		+ 1;
				
			EndDo;
			//  PRODUCTS end
			/////////////////////////////////////////////////////
		EndIf; 
		//  PRODUCTS end
		/////////////////////////////////////////////////////
		
		
		
		/////////////////////////////////////////////////////
		// WORKS start
		//
		While RowsSelectionWork.Next() Do

			TemplateArea.Parameters.Fill(RowsSelectionWork);
			
			LineNumberS							= LineNumberS + 1;
			TemplateArea.Parameters.LineNumber 	= LineNumberS;
			
			If ValueIsFilled(RowsSelectionWork.Content) Then
				TemplateArea.Parameters.Product = RowsSelectionWork.Content;
			Else
				TemplateArea.Parameters.Product = SmallBusinessServer.GetNomenclaturePresentationForPrinting(RowsSelectionWork.Product, 
																	RowsSelectionWork.Characteristic, RowsSelectionWork.SKU);
			EndIf;
			
			Selection = RowsSelectionWork.Select();
			StringArtist = "";
			While Selection.Next() Do
				PresentationEmployee= SmallBusinessServer.GetSurnameNamePatronymic(Selection.Surname, Selection.Name, Selection.Patronymic);
				StringArtist 		= StringArtist + 
									  ?(StringArtist = "", "", ", ") + 
									  ?(ValueIsFilled(PresentationEmployee), 
									  			PresentationEmployee, 
												Selection.Ind);
				/////////////////////////////////////////////////////
				// CE INSEAMNA ???
				//
				//Message(StringArtist);
				//
				/////////////////////////////////////////////////////
				
				//TemplateArea.Parameters.Assignees = StringArtist;
				

			EndDo;
	
			TemplateArea.Parameters.VATn = ?(RowsSelectionWork.VATAmount = 0, 0, RowsSelectionWork.VATAmount);
			
			SpreadsheetDocument.Put(TemplateArea);
			
			Amount			= Amount		+ RowsSelectionWork.Amount;
			VATAmount		= VATAmount		+ RowsSelectionWork.VATAmount;
			TotalAmount		= TotalAmount	+ RowsSelectionWork.TotalAmount;
			WorkAmount		= WorkAmount	+ RowsSelectionWork.Amount;
			AmountVATWork	= AmountVATWork	+ RowsSelectionWork.VATAmount;
			
		EndDo;
		//
		// WORKS end
		/////////////////////////////////////////////////////
		
		
		////////////// Query for CNP  //////START
		
		//
		//Query		= New Query;
		//Query.Text	= 
		//"SELECT
		//|	UserEmployees.Employee,
		//|	UserEmployees.User
		//|FROM
		//|	InformationRegister.UserEmployees AS UserEmployees
		//|WHERE
		//|	UserEmployees.User = &Author";
		//
		////  }}QUERY_BUILDER_WITH_RESULT_PROCESSING
		//
		//Query.SetParameter("Author", Selection.Author);
		//
		//Result		= Query.Execute();
		//SelectionD	= Result.Choose();
		//
		//While SelectionD.Next() Do
		//	Try
		//		
		//		TemplateArea.CNP =	SelectionD.Employee.Ind.PersonalCode;
		//		//Footer.Parameters["CNPU"]	= SelectionD.Employee.Ind.PersonalCode;
		//	Except
		//	
		//	EndTry;
		//	
		//EndDo;
		
 //   	 ////////Query for CNP/////////// END
 //   	 
 //   	Query		= New Query;
 //   	Query.Text	= 
 //   	"SELECT
 //   	|	UserEmployees.Employee,
 //   	|	UserEmployees.User
 //   	|FROM
 //   	|	InformationRegister.UserEmployees AS UserEmployees
 //   	|WHERE
 //   	|	UserEmployees.User = &Author"; 
 //   	
 //   	 Query.SetParameter("User", Header.User);
 //   	 
 //   	 Result		= Query.Execute();
 //   	 HeaderD 	= Result.Choose();
 //   	 
 //   	While HeaderD.Next() Do
 //   		Try
 //   			
 //   			TemplateArea.CNP = HeaderD.Employee.Ind.PersonalCode;
 //   		Except
 //   		
 //   		EndTry;
 //   		
 //   	EndDo;
 //
 //////////////////////////////////
 //////////////////////////////////
 
 // 			 i = TemplateArea.Parameters.LineNumber;
 //   			Spreadsheet.Put(Header.Inventory, HeaderInventory.Level());

 ////
 //   For i=i +1 To 10 Do       // Adelin Serb  08.02.2015 40->10
 //   		TemplateArea.Parameters.LineNumber		    = i;
 //   		TemplateArea.Parameters.Product				= Undefined;
 //   		TemplateArea.Parameters.UnitOfMeasure   	= Undefined;
 //   		TemplateArea.Parameters.Quantity			= Undefined;
 //   		TemplateArea.Parameters.Price				= Undefined;
 //   		TemplateArea.Parameters.Amount				= Undefined;

 //   					
 //   		Try
 //   			TemplateArea.Parameters.VATN			= Undefined;
 //   		Except
 //   			
 //   		EndTry;
 //   		
 //   		Spreadsheet.Put(Header.Inventory, HeaderInventory.Level());

 //   	EndDo;
 //   	
		
											
		//////////////////////////
		
	TemplateArea = Template.GetArea("Table");
		
	SpreadsheetDocument.Put(TemplateArea);
		
		//////////////////////////
    TemplateArea = Template.GetArea("Total");
	
	TemplateArea.Parameters.Fill(Header);
	
	SpreadsheetDocument.Put(TemplateArea);
				
	TemplateArea = Template.GetArea("TotalToPay");
		
		TemplateArea.Parameters.TotalAmount = Amount;	
			
		If VATAmount = 0 Then
						TemplateArea.Parameters.TotalVAT = "0";
		Else
		TemplateArea.Parameters.TotalVAT = 	VATAmount;
		EndIf; 
				
		TemplateArea.Parameters.TotalToPayText = NStr("en = 'Total de plata(col5+col6):'; ro = 'Total de plata(col5+col6)'; ru = 'Total de plata(col5+col6)'");
		
		TemplateArea.Parameters.Fill(New Structure("TotalToPay", SmallBusinessServer.AmountsFormat(TotalAmount)));
		
		If TemplateName = "ComandaDeviz" Then
				
		TemplateArea.Parameters.VendorPresentation	  = SmallBusinessServer.EntitiesLongDescription(InfoAboutEntity, 
																									"FullDescr,TIN,CIO,LegalAddress,PhoneNumbers,");
		TemplateArea.Parameters.VendorPresentation	  = SmallBusinessServer.EntitiesLongDescription(InfoAboutEntity, "FullDescr,");
		TemplateArea.Parameters.CUI 	= InfoAboutEntity.CIO;
		TemplateArea.Parameters.ORC		= InfoAboutEntity.TIN;
		TemplateArea.Parameters.Adresa	= InfoAboutEntity.LegalAddress;
		TemplateArea.Parameters.Banca	= InfoAboutEntity.Bank;
		TemplateArea.Parameters.Cont	= InfoAboutEntity.AccountNo;
	
        EndIf;
		
		AmountToBeWrittenInWords = TotalAmount;
		TemplateArea.Parameters.TotalRow =  NStr("en = 'Total titles '; ro = 'Total rânduri '; ru = 'Total rânduri '") + 
											String(LineNumberS) + 
											NStr("en = ', on amount '; ro = ', in total '; ru = ', in total '") + 
											SmallBusinessServer.AmountsFormat(AmountToBeWrittenInWords, Header.DocumentCurrency);
		
		TemplateArea.Parameters.AmountInWords = WorkWithExchangeRates.GenerateAmountInWords(AmountToBeWrittenInWords, Header.DocumentCurrency);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		EndDo;

		
		
		
		//
		///////////////////////////////////////////////////////
		//TemplateArea = Template.GetArea("AmountInWords");
		//AmountToBeWrittenInWords = TotalAmount;
		////===============================
		////©# (Begin)	AlekS [2015-07-19]
		////TemplateArea.Parameters.TotalRow = "Total titles "
		////										+ String(Quantity)
		////										+ ", on amount "
		////										+ SmallBusinessServer.AmountsFormat(AmountToBeWrittenInWords, Header.DocumentCurrency);
		//TemplateArea.Parameters.TotalRow = 	NStr("en = 'Total titles '; ro = 'Total rânduri '; ru = 'Всего позиций '") + 
		//									String(LineNumberS) + 
		//									NStr("en = ', on amount '; ro = ', in total '; ru = ', на сумму '") + 
		//									SmallBusinessServer.AmountsFormat(AmountToBeWrittenInWords, 
		//																	Header.DocumentCurrency);
		////©# (End)		AlekS [2015-07-19]
		////===============================
		//
		//TemplateArea.Parameters.AmountInWords = WorkWithExchangeRates.GenerateAmountInWords(AmountToBeWrittenInWords, Header.DocumentCurrency);
		//SpreadsheetDocument.Put(TemplateArea);
		//
		///////////////////////////////////////////////////////
		//TemplateArea = Template.GetArea("Signatures");
		//SpreadsheetDocument.Put(TemplateArea);
		//
		//PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, 
		//									 FirstRowNumber, 
		//									 PrintObjects, 
		//									 Header.Ref);

//
/////////////////////////////////////////////////////
	
	SpreadsheetDocument.BackgroundPicture = New Picture(GetTemplate("SiglaWatermark"), True);  //  Transparent = True

	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction   //  CreatePrintForm(ObjectArray, PrintObjects, DesignName)

/////////////////////////////////////////////////////
//
// Preparing of Print Form 
//
/////////////////////////////////////////////////////
Function CreatePrintFormAdl(ObjectsArray, PrintObjects, TemplateName)	

	Var Errors;
	
	// Получение макета и создание на его основании табличного документа, который будет выведен на печать
	// Get Template and creating  "on base" the Table Document for printing 
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_CustomerOrder";  // PrintParameters_ + Name_of_Document
	
	// ЭтотОбъект - объект обработки где расположен Template
	// ThisObject - the Object of procedure where Template is placed
	DesignName	= ThisObject.GetTemplate(TemplateName);
	
	Query = New Query();
	
	//////////////////////////////////////////////////////////
	// этот Запрос возвращал ВСЕ проведенные документы CustomerOrder, а нам-то нужен только ОДИН   (AlekS)
	//////////////////////////////////////////////////////////
	//Query.Text = 
	//"SELECT
	//|	CustomerOrderJobs.Ref,
	//|	CustomerOrderJobs.LineNumber,
	//|	CustomerOrderJobs.JobKind,
	//|	CustomerOrderJobs.Nomenclature AS InventoryItem,
	//|	CustomerOrderJobs.NomenclatureTypeService AS TypeService,
	//|	CustomerOrderJobs.Characteristic,
	//|	CustomerOrderJobs.Specification,
	//|	CustomerOrderJobs.Quantity,
	//|	CustomerOrderJobs.Price,
	//|	CustomerOrderJobs.Amount,
	//|	CustomerOrderJobs.DiscountMarkupRate,
	//|	CustomerOrderJobs.VATRate,
	//|	CustomerOrderJobs.VATAmount,
	//|	CustomerOrderJobs.TotalAmount,
	//|	CustomerOrderJobs.Content,
	//|	CustomerOrderJobs.LinkKey,
	//|	CustomerOrderJobs.Multiplicity,
	//|	CustomerOrderJobs.Factor,
	//|	CustomerOrder.Inventory.(
	//|		Ref,
	//|		LineNumber,
	//|		Nomenclature AS InventoryItem2,
	//|		NomenclatureTypeInventory,
	//|		Characteristic,
	//|		Batch,
	//|		Quantity,
	//|		Reserve,
	//|		ReserveShipment,
	//|		UnitOfMeasure,
	//|		Price,
	//|		DiscountMarkupRate,
	//|		Amount,
	//|		VATRate,
	//|		VATAmount,
	//|		TotalAmount,
	//|		ShippingDate,
	//|		Specification,
	//|		Content
	//|	),
	//|	CustomerOrder.Entity,
	//|	CustomerOrder.Counterparty,
	//|	CustomerOrder.Date AS DocumentDate,
	//|	CustomerOrder.Counterparty.BankAccountByDefault,
	//|	CustomerOrder.Counterparty.TIN,
	//|	CustomerOrder.Counterparty.CIO,
	//|	CustomerOrder.Entity.BankAccountByDefault AS BankAccount,
	//|	CustomerOrder.Entity.CIO,
	//|	CustomerOrder.Entity.TIN,
	//|	CustomerOrder.Number,
	//|	CustomerOrder.DocumentCurrency,
	//|	CustomerOrder.Author AS User,
	//|	CustomerOrder.PCShop_BaseDocument.Number AS VST
	//|FROM
	//|	Document.CustomerOrder.Jobs AS CustomerOrderJobs
	//|		LEFT JOIN Document.CustomerOrder AS CustomerOrder
	//|		ON CustomerOrderJobs.Ref = CustomerOrder.Ref";
	//////////////////////////////////////////////////////////
	
	Query.Text = 
	"SELECT
	|	CustomerOrderWorks.LineNumber AS LineNumber,
	|	CASE
	|		WHEN (CAST(CustomerOrderWorks.Nomenclature.DescriptionFull AS STRING(1000))) = """"
	|			THEN CustomerOrderWorks.Nomenclature.Description
	|		ELSE CAST(CustomerOrderWorks.Nomenclature.DescriptionFull AS STRING(1000))
	|	END AS Product,
	|	CustomerOrderWorks.Nomenclature.SKU AS SKU,
	|	CustomerOrderWorks.Nomenclature.UnitOfMeasure.Description AS UnitOfMeasure,
	|	CustomerOrderWorks.Quantity AS Quantity,
	|	CustomerOrderWorks.Quantity * CustomerOrderWorks.Multiplicity * CustomerOrderWorks.Factor AS CountRepetitionFactor,
	|	CustomerOrderWorks.Price AS Price,
	|	CustomerOrderWorks.Amount AS Amount,
	|	CustomerOrderWorks.VATAmount AS VATAmount,
	|	ISNULL(CustomerOrderWorks.TotalAmount, 0) AS TotalAmount,
	|	CustomerOrderWorks.Characteristic AS Characteristic,
	|	CustomerOrderWorks.Content AS Content,
	|	CustomerOrderWorks.DiscountMarkupRate AS DiscountMarkupRate,
	|	CASE
	|		WHEN CustomerOrderWorks.DiscountMarkupRate <> 0
	|			THEN 1
	|		ELSE 0
	|	END AS IsDiscount,
	|	IndividualsNameAndSurnameSliceLast.Surname,
	|	IndividualsNameAndSurnameSliceLast.Name,
	|	IndividualsNameAndSurnameSliceLast.Patronymic,
	|	CustomerOrderAssignees.Employee.Ind AS Ind,
	|	CustomerOrderWorks.LinkKey AS LinkKey
	|FROM
	|	Document.CustomerOrder.Jobs AS CustomerOrderWorks
	|		LEFT JOIN Document.CustomerOrder.Assignees AS CustomerOrderAssignees
	|			LEFT JOIN InformationRegister.IndividualsNameAndSurname.SliceLast(&ToDate, ) AS IndividualsNameAndSurnameSliceLast
	|				ON CustomerOrderAssignees.Employee.Ind = IndividualsNameAndSurnameSliceLast.Ind
	|			ON CustomerOrderWorks.LinkKey = CustomerOrderAssignees.LinkKey
	|			AND (CustomerOrderAssignees.Ref = &CurrentDocument)
	|WHERE
	|	CustomerOrderWorks.Ref = &CurrentDocument
	|TOTALS
	|	MAX(Product),
	|	MAX(SKU),
	|	MAX(UnitOfMeasure),
	|	MAX(Quantity),
	|	MAX(CountRepetitionFactor),
	|	MAX(Price),
	|	MAX(Amount),
	|	MAX(VATAmount),
	|	MAX(TotalAmount),
	|	MAX(Characteristic),
	|	MAX(Content),
	|	MAX(DiscountMarkupRate),
	|	MAX(IsDiscount)
	|BY
	|	LinkKey";

	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Header = Query.Execute().Select();
	
	FirstDocument = True;
	
	// While Header.Next() Do
	For Each CurrentDocument In ObjectsArray Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument			= False;
		FirstRowNumber			= SpreadsheetDocument.TableHeight + 1;
		
		LinesSelectionInventory = Header.Inventory.Select();
				
		SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_" + DesignName + "_" + DesignName;
		
		Template				= ThisObject.GetTemplate(TemplateName);
		
		InfoAboutEntity			= SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Entity, 
																		Header.DocumentDate, ,Header.BankAccount);
		InfoAboutCounterparty	= SmallBusinessServer.InfoAboutLegalEntityIndividual(Header.Counterparty, 
																		Header.DocumentDate, ,);
																		
		/////////////////////////////////////////////////////
		TemplateArea = Template.GetArea("Header");
		TemplateArea.Parameters.Fill(Header);

		If Header.DocumentDate < Date('20110101') Then
			DocumentNo = SmallBusinessServer.GetNumberForPrinting(Header.Number, Header.Prefix);
		Else
			DocumentNo = ObjectPrefixationClientServer.GetNumberForPrinting(Header.Number, True, True);
		EndIf;		

		TemplateArea.Parameters.VST    = Header.VST;
		
	  	TemplateArea.Parameters.VendorPresentation	  = 
										  SmallBusinessServer.EntitiesLongDescription(InfoAboutEntity, 
																	"FullDescr,TIN,CIO,LegalAddress,PhoneNumbers,");
		TemplateArea.Parameters.VendorPresentation	  = 
										  SmallBusinessServer.EntitiesLongDescription(InfoAboutEntity, "FullDescr,");
		TemplateArea.Parameters.CUI 	= InfoAboutEntity.CIO;
		TemplateArea.Parameters.ORC		= InfoAboutEntity.TIN;
		TemplateArea.Parameters.Adresa	= InfoAboutEntity.LegalAddress;
		TemplateArea.Parameters.Banca	= InfoAboutEntity.Bank;
		TemplateArea.Parameters.Cont	= InfoAboutEntity.AccountNo;
		
		TemplateArea.Parameters.RecipientPresentation = 
										  SmallBusinessServer.EntitiesLongDescription(InfoAboutCounterparty, 
																	"FullDescr,TIN,CIO,LegalAddress,PhoneNumbers,");
		TemplateArea.Parameters.RecipientPresentation = 
										  SmallBusinessServer.EntitiesLongDescription(InfoAboutCounterparty, 
										  							"FullDescr,");
		TemplateArea.Parameters.CUIC	= InfoAboutCounterparty.CIO;
		TemplateArea.Parameters.ORCC	= InfoAboutCounterparty.TIN;
		TemplateArea.Parameters.AdresaC	= InfoAboutCounterparty.LegalAddress;
		TemplateArea.Parameters.BancaC	= InfoAboutCounterparty.Bank;
		TemplateArea.Parameters.ContC	= InfoAboutCounterparty.AccountNo;
		
		//
		//TemplateArea.Parameters.Number  = DocumentNo;
		TemplateArea.Parameters.Date    = Header.DocumentDate;

		SpreadsheetDocument.Put(TemplateArea);
		
		/////////////////////////////////////////////////////
		TemplateArea = Template.GetArea("Title");
												
		TemplateArea.Parameters.HeaderText = NStr("en = 'Invoice for payment # '; ro = 'Factura proformă Nr. '; ru = 'Factura proformă Nr. '") + 
											 DocumentNo + 
											 NStr("en = ' from '; ro = ' din data '; ru = ' din data '") + 
											 Format(Header.DocumentDate, "DLF=DD");

		/////////////////////////////////////////////////////
		TemplateArea= Template.GetArea("String");	
		Amount		= 0;
		VATAmount	= 0;
		TotalAmount	= 0;
		Quantity	= 0;
			
		While LinesSelectionInventory.Next() Do
				
			Quantity = Quantity + 1;
			TemplateArea.Parameters.Fill(LinesSelectionInventory);
			TemplateArea.Parameters.LineNumber = Quantity;
			
			If ValueIsFilled(LinesSelectionInventory.Content) Then
			//	TemplateArea.Parameters.InventoryItem = LinesSelectionInventory.Content;
			//Else
				TemplateArea.Parameters.Product = SmallBusinessServer.GetNomenclaturePresentationForPrinting(
																	LinesSelectionInventory.Product, 
																	LinesSelectionInventory.Characteristic);
																	//,
														//LinesSelectionInventory.SKU);
			EndIf;													
		EndDo;	

		TemplateArea.Parameters.VATN	= LinesSelectionInventory.VATAmount;

	    SpreadsheetDocument.Put(TemplateArea);
		
		Amount		= Amount		+ LinesSelectionInventory.Amount;
		VATAmount	= VATAmount		+ LinesSelectionInventory.VATAmount;
		TotalAmount	= TotalAmount	+ LinesSelectionInventory.TotalAmount;

		/////////////////////////////////////////////////////
		TemplateArea = Template.GetArea("Total");
		TemplateArea.Parameters.TotalAmount = SmallBusinessServer.AmountsFormat(Amount);
		TemplateArea.Parameters.Fill(Header);

		TemplateArea.Parameters.TotalVAT = SmallBusinessServer.AmountsFormat(VATAmount);

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
		
		
				
			TemplateArea = Template.GetArea("TotalToPay");
			TemplateArea.Parameters.TotalToPayText = NStr("en = 'Total de plata(col5+col6):'; ro = 'Total de plata(col5+col6)'; ru = 'Total de plata(col5+col6)'");
			TemplateArea.Parameters.Fill(New Structure("TotalToPay", SmallBusinessServer.AmountsFormat(TotalAmount)));
					
				
		TemplateArea.Parameters.VendorPresentation	  = SmallBusinessServer.EntitiesLongDescription(InfoAboutEntity, 
																									"FullDescr,TIN,CIO,LegalAddress,PhoneNumbers,");
		TemplateArea.Parameters.VendorPresentation	  = SmallBusinessServer.EntitiesLongDescription(InfoAboutEntity, "FullDescr,");
		TemplateArea.Parameters.CUI 	= InfoAboutEntity.CIO;
		TemplateArea.Parameters.ORC		= InfoAboutEntity.TIN;
		TemplateArea.Parameters.Adresa	= InfoAboutEntity.LegalAddress;
		TemplateArea.Parameters.Banca	= InfoAboutEntity.Bank;
		TemplateArea.Parameters.Cont	= InfoAboutEntity.AccountNo;
	

		
		AmountToBeWrittenInWords = TotalAmount;
		TemplateArea.Parameters.TotalRow =  NStr("en = 'Total titles '; ro = 'Total rânduri '; ru = 'Total rânduri '") + 
											String(Quantity) + 
											NStr("en = ', on amount '; ro = ', in total '; ru = ', in total '") + 
											SmallBusinessServer.AmountsFormat(AmountToBeWrittenInWords, Header.DocumentCurrency);
		
		TemplateArea.Parameters.AmountInWords = WorkWithExchangeRates.GenerateAmountInWords(AmountToBeWrittenInWords, Header.DocumentCurrency);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		
		
		
		
		TemplateArea = Template.GetArea("AccountFooter");
		
		Heads = SmallBusinessServer.OrganizationalUnitsResponsiblePersons(Header.Entity, Header.DocumentDate);
		
		//TemplateArea.Parameters.HeadFullName = Heads.HeadFullName;
		//TemplateArea.Parameters.AccountantFullName   = Heads.ChiefAccountantNameAndSurname;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstRowNumber, PrintObjects, Header.Ref);
		
	EndDo;
	
	CommonUseClientServer.ShowErrorsToUser(Errors);
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction   //  CreatePrintFormAdelin(ObjectArray, PrintObjects, DesignName)


