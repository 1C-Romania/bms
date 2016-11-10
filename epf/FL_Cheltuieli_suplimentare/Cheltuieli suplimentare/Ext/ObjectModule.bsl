
Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	RegistrationParametrs.Insert("Type", "PrintForm");			
	DestinationArray = New Array();
	DestinationArray.Add("Document.AdditionalExpenses");
	
	RegistrationParametrs.Insert("Presentation", DestinationArray);
	
	RegistrationParametrs.Insert("Description", "Forma de listare Cheltuieli suplimentare");
	RegistrationParametrs.Insert("Version", "1.1");
	RegistrationParametrs.Insert("SafeMode", False); 
	RegistrationParametrs.Insert("Information", "Forma de listare Cheltuieli suplimentare");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
	"Cheltuieli suplimentare",						    				
	"Cheltuieli",   										
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
Var Errors;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PrintParameters_AdditionalExpenses";  	
	
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
	|	AdditionalExpenses.Counterparty,
	|	AdditionalExpenses.Entity,
	|	AdditionalExpenses.Responsible,
	|	AdditionalExpenses.Ref,
	|	AdditionalExpenses.DateOfIncomingDocument,
	|	AdditionalExpenses.Expenses.(
	|		LineNumber,
	|		Nomenclature,
	|		Quantity,
	|		UnitOfMeasure,
	|		Price,
	|		Amount,
	|		VATAmount,
	|		TotalAmount
	|	)
	|FROM
	|	Document.AdditionalExpenses AS AdditionalExpenses";
	
	
	  	ResultsArray = Query.ExecuteBatch();
		
		Selection = ResultsArray[0].Select();
		Selection.Next();
//////////////////////////////////////////////////////////////////////////////
///////////////////////////////CAPTION////Start///////////////////////////////
//////////////////////////////////////////////////////////////////////////////
	TemplateArea = DesignName.GetArea("Caption");

	TemplateArea.Parameters.Fill(Selection);

	SumaTotal = 0;
	TotalTVA = 0;
		
	SpreadsheetDocument.Put(TemplateArea);
		
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////CAPTION////End////////////////////////////////
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
///////////////////////////////HEADER////Start///////////////////////////////
/////////////////////////////////////////////////////////////////////////////
	TemplateArea = DesignName.GetArea("Header");
	
	TemplateArea.Parameters.Fill(Selection);
	
	SpreadsheetDocument.Put(TemplateArea);
	
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////HEADER////End///////////////////////////////
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////EXPENSES////End/////////////////////////////
/////////////////////////////////////////////////////////////////////////////

	TemplateArea = DesignName.GetArea("Expenses");
	
	TemplateArea.Parameters.Fill(Selection);
	
	SelectionExpenses = Selection.Expenses.Select();
	While SelectionExpenses.Next() Do
		TemplateArea.Parameters["Price"] 		  = ( SelectionExpenses.TotalAmount - SelectionExpenses.VATAmount )
												  / SelectionExpenses.Quantity;
		TemplateArea.Parameters["Amount"]      	  = ( SelectionExpenses.TotalAmount - SelectionExpenses.VATAmount );
		TemplateArea.Parameters["AmountWithVAT"]  = SelectionExpenses.TotalAmount;
		TemplateArea.Parameters["Item"] 		  = SelectionExpenses.Nomenclature;
		TemplateArea.Parameters["LineNumber"]     = SelectionExpenses.LineNumber;
		TemplateArea.Parameters["UnitOfMeasure"]  = SelectionExpenses.UnitOfMeasure;
		TemplateArea.Parameters["Quantity"]       = SelectionExpenses.Quantity;
		SumaTotal  = SumaTotal + SelectionExpenses.TotalAmount;
		TotalTVA   = TotalTVA  + SelectionExpenses.VATAmount;
	
	SpreadsheetDocument.Put(TemplateArea, SelectionExpenses.Level());
	 EndDo;
/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////EXPENSES////End/////////////////////////////
/////////////////////////////////////////////////////////////////////////////	

/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////TOTALS////Start///////////////////////////
/////////////////////////////////////////////////////////////////////////////
		
	TemplateArea = DesignName.GetArea("Totals");
	
		TemplateArea.Parameters["Total"] = SumaTotal;
		TemplateArea.Parameters["TotalVAT"] = TotalTVA;
		
	TemplateArea.Parameters.Fill(Selection);
	
	SpreadsheetDocument.Put(TemplateArea);
		
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////TOTALS////End/////////////////////////////
/////////////////////////////////////////////////////////////////////////////
	
/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////FOOTER///Start////////////////////////////
/////////////////////////////////////////////////////////////////////////////	

	TemplateArea = DesignName.GetArea("Footer");
	
	TemplateArea.Parameters.Fill(Selection);
		
		SumaLei  = INT(SumaTotal);
		SumaBani = (SumaTotal - SumaLei) * 100;
		
		If StrLen(String(SumaBani))    = 0 Then 
			SumaBani = "00";
		ElsIf StrLen(String(SumaBani)) = 1 Then
			SumaBani = "0" + SumaBani;
		EndIf;	
		
		SumaLei = StrReplace(NumberInWords(SumaLei, "L=ro_RO", ", , , , , , 0"), " ", "");
		SumaLei = StrReplace(SumaLei, "zero", "");
		TemplateArea.Parameters["SumaInLitere"] = SumaLei + " lei " + SumaBani + " bani";
		TemplateArea.Parameters["Responsabil"]  = Selection.Responsible;
		
	SpreadsheetDocument.Put(TemplateArea);

/////////////////////////////////////////////////////////////////////////////
///////////////////////////////////FOOTER////End/////////////////////////////
/////////////////////////////////////////////////////////////////////////////	
	
	
	PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, FirstRowNumber, PrintObjects, CurrentDocument);
	
	SpreadsheetDocument.FitToPage = True;
	EndDo;

	Return SpreadsheetDocument;
	
EndFunction	
