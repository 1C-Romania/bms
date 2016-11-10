////////////INFO PRINT FORMS



Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	RegistrationParametrs.Insert("Type", "PrintForm");
	
	DastinationArray = New Array();
	DastinationArray.Add("Document.PCShop_ReceptieInService");
	
	
	
	RegistrationParametrs.Insert("Presentation", DastinationArray);
	
	RegistrationParametrs.Insert("Description", "Print Forms Service");
	RegistrationParametrs.Insert("Version", "2.1");
	RegistrationParametrs.Insert("SafeMode", False); 
	RegistrationParametrs.Insert("Information", "Print Forms Service");
	
	CommandTable = GetCommandTable();
		
	//  Adelin Serb 04.03.2015
	AddCommand(CommandTable,
	"Bon de predare catre client",
	"BonPredareCatreClientReception",
	"CallOfServerMethod",    
	False,
	"MXLPrint");
	
	 AddCommand(CommandTable,
	"Bon de predare catre laborator",
	"BonDePredareCatreLaboratorReception",
	"CallOfServerMethod",    
	False,
	"MXLPrint");	
	
	RegistrationParametrs.Insert("Commands", CommandTable);
	
	Return RegistrationParametrs;
	
EndFunction

Function GetCommandTable()
	
	Commands = New ValueTable;
	Commands.Columns.Add("Presentation", New TypeDescription("String"));
	Commands.Columns.Add("ID", New TypeDescription("String"));
	Commands.Columns.Add("Use", New TypeDescription("String"));
	Commands.Columns.Add("ShowNotification", New TypeDescription("Boolean"));
	Commands.Columns.Add("Modifier", New TypeDescription("String"));
	
	Return Commands;
	
EndFunction

Procedure AddCommand(CommandTable, Presentation, ID, Use, ShowNotification = False, Modifier = "")
	
	NewCommand = CommandTable.Add();
	NewCommand.Presentation = Presentation;
	NewCommand.ID = ID;
	NewCommand.Use = Use;
	NewCommand.ShowNotification = ShowNotification;
	NewCommand.Modifier = Modifier;
	
EndProcedure


////CREATE PRINT FORMS

Function CreatePrintForm(ObjectArray, PrintObjects, TemplateName)	

		
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_PCShop_ReceptieInService";
	//Template = ThisObject.GetTemplate("BonDePredareCatreLaboratorReception");
	
	//////// I need a "switch"  here ///////   
	
	//SpreadsheetDocument = New SpreadsheetDocument;
	//SpreadsheetDocument.PrintParametersKey = "PrintParameters_PCShop_ReceptieInService";
	//Template = ThisObject.GetTemplate("BonPredareCatreClientReception");
	
////////Selection	
	Template = ThisObject.GetTemplate(TemplateName);
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PCShop_ReceptieInService.Date AS Date,
	|	PCShop_ReceptieInService.Number AS VST,
	|	hiBarcodesOfService.Barcode,
	|	PCShop_ReceptieInService.Counterparty,
	|	PCShop_ReceptieInService.Email,
	|	PCShop_ReceptieInService.PhoneNumber,
	|	PCShop_ReceptieInService.Nomenclature,
	|	PCShop_ReceptieInService.Characteristic,
	|	PCShop_ReceptieInService.SeriesNumber,
	|	PCShop_ReceptieInService.IMEINumber,
	|	PCShop_ReceptieInService.Accessories,
	|	PCShop_ReceptieInService.Warranty,
	|	PCShop_ReceptieInService.AWB,
	|	PCShop_ReceptieInService.DocumentAmount,
	|	PCShop_ReceptieInService.BringByHimself,
	|	PCShop_ReceptieInService.Description,
	|	PCShop_ReceptieInService.AccessoriesList.(
	|		Ref,
	|		LineNumber,
	|		Nomenclature AS ListaAccesorii,
	|		Characteristic
	|	),
	|	PCShop_ReceptieInService.DeffectsList.(
	|		Ref,
	|		LineNumber,
	|		Deffect
	|	),
	|	PCShop_ReceptieInService.Description AS ReclaimDeffect,
	|	PCShop_ReceptieInService.Comments.(
	|		Ref,
	|		LineNumber,
	|		Date,
	|		User,
	|		Comment,
	|		Workplace
	|	),
	|	PCShop_ReceptieInService.ContactWithLiquid,
	|	PCShop_ReceptieInService.SignsOfWear,
	|	PCShop_ReceptieInService.Shock,
	|	PCShop_ReceptieInService.UsedAccessories,
	|	PCShop_ReceptieInService.Misapplication,
	|	PCShop_ReceptieInService.Tampering,
	|	PCShop_ReceptieInService.TamperingDescription,
	|	PCShop_ReceptieInService.Ref,
	|	PCShop_ReceptieInService.Address AS Adresa,
	|	PCShop_ReceptieInService.DetailsProduct AS Detalii,
	|	PCShop_ReceptieInService.GoodsForRepair.(
	|		Nomenclature.DescriptionFull AS Products,
	|		Price AS PriceN
	|	),
	|	PCShop_ReceptieInService.ServicesForRepair.(
	|		Nomenclature.DescriptionFull AS Services,
	|		Price AS PriceS
	|	)
	|FROM
	|	Document.PCShop_ReceptieInService AS PCShop_ReceptieInService
	|		LEFT JOIN InformationRegister.hiBarcodesOfService AS hiBarcodesOfService
	|		ON (hiBarcodesOfService.Recorder = PCShop_ReceptieInService.Ref)
	|WHERE
	|	PCShop_ReceptieInService.Ref IN(&Ref)";
	
	Query.SetParameter("Ref", ObjectArray);
	FirstDocument = False;
	
	Result = Query.Execute();
	Prototype = DataProcessors.PrintLabelsAndTags.GetTemplate("Prototype");
	
	CountNumberOfMillimetersInPixel = Prototype.Drawings.Square100Pixels.Height / 100;
	
	TemplateArea = Template.ПолучитьОбласть("Header");
	
	SpreadsheetDocument.Очистить();
	Header = Result.Select();
	While  Header.Next() Do
		If FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		Endif;	
		FirstDocument = False;
		// + HVOYA 2015/05/05 Darya   
		//BarcodeValue = Header.Barcode;
		BarcodeValue = Header.VST;
		// - HVOYA 2015/05/05 Darya   
		For Each Draw In TemplateArea.Drawings Do

			If Left(Draw.Name,7) = GetParameterNameBarcode() Then

				//BarcodeValue = Header.Barcode;
				If ValueIsFilled(BarcodeValue) Then
					BarcodeParameters = New Structure;
					BarcodeParameters.Insert("Width", Draw.Width / CountNumberOfMillimetersInPixel);
					BarcodeParameters.Insert("Height", Draw.Height / CountNumberOfMillimetersInPixel);
					BarcodeParameters.Insert("Barcode", BarcodeValue);
					BarcodeParameters.Insert("CodeType", 99);
					BarcodeParameters.Insert("ShowText", True);
					BarcodeParameters.Insert("SizeOfFont", 12);
					Draw.Picture = CallingServerEquipmentManager.GetBarcodePicture(BarcodeParameters);
				EndIf;
				
			EndIf;
		EndDo;
		// + HVOYA 2015/05/05 Darya  
		Attributes = Header.Ref.Metadata().Attributes;
		StareProdusString = ?(Header.Warranty, Attributes.Warranty.Synonym, ?(Header.ContactWithLiquid, Attributes.ContactWithLiquid.Synonym + ", ", "") 
							+ "" + ?(Header.SignsOfWear, Attributes.SignsOfWear.Synonym + ", ", "") + "" + ?(Header.Shock, Attributes.Shock.Synonym + ", ", "") 
							+ "" + ?(Header.UsedAccessories, Attributes.UsedAccessories.Synonym + ", ", "") + " " + ?(Header.Misapplication, Attributes.Misapplication.Synonym + ", ", "")
							+ "" + ?(Header.Tampering, Attributes.Tampering.Synonym + ", ", "") + "" + ?(Header.TamperingDescription <> "", Attributes.TamperingDescription.Synonym + ", ", ""));
							
		//// - HVOYA 2015/05/05 Darya   
		TemplateArea.Parameters.Fill(Header);                                                                                                               
		TemplateArea.Parameters.Date 			= Format(Header.Date, "DLF = DD" );
		TemplateArea.Parameters.Product			= CreateStringProduct(Header);
		TemplateArea.Parameters.StareProdus     = StareProdusString;//?(Header.Warranty, "Garantie", ?(NOT Header.BringByHimself, Header.AWB, Header.DocumentAmount));  
		Desc = Header.Description;
		// + HVOYA 2015/05/05 Darya 
		DescAccesorii = "";
		Desc = "";
		For Each Row In Header.AccessoriesList.Unload() Do
			
			DescAccesorii = DescAccesorii + ", " + Row.ListaAccesorii;
		EndDo;
		TemplateArea.Parameters.ListaAccesorii = Right(DescAccesorii, StrLen(DescAccesorii)-2);
		// - HVOYA 2015/05/05 Darya   
		
		For Each Row In Header.DeffectsList.Unload() Do
			
			Desc = Desc +  Row.Deffect + ", " ;     //  + Row.Deffect.Code
		EndDo;
		
		TemplateArea.Parameters.DeffectReclamat	= Right(Desc, StrLen(Desc)-2);
		SpreadsheetDocument.Put(TemplateArea);
		
		//TemplateArea.Parameters.Accessories = AccessoriesList.Nomenclature;

	EndDo;
	
	Return SpreadsheetDocument;
		
EndFunction

Function GetParameterNameBarcode()
	
	Return "Barcode";
	
EndFunction // 

Function CreateStringClient(Header)

	Return "" + Header.Counterparty + ", " + Header.PhoneNumber + ", " + Header.Email;

EndFunction // CreateStringClient()

Function CreateStringProduct(Header)

	Return "" + Header.Nomenclature + ", " + Header.Characteristic;	
EndFunction // CreateStringProduct(Header)()


Procedure Print(ObjectArray, PrintFormsCollection, PrintObjects, OutputParametrs)  Export 
	
	//PrintManagement.OutputSpreadsheetDocumentToCollection(
	//PrintFormsCollection,
	//"BonDePredareCatreLaboratorReception",  
	//"Bon de predare catre laborator",
	//CreatePrintForm(ObjectArray, PrintObjects)       //bon laborator
	//);
	
	////////Adelin Serb 06.03.2015
	 
	//PrintManagement.OutputSpreadsheetDocumentToCollection(
	//PrintFormsCollection,
	//"BonPredareCatreClientReception",  
	//"Bon de predare catre client",
	//CreatePrintForm(ObjectArray, PrintObjects)        //bon client

	//);
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

	




