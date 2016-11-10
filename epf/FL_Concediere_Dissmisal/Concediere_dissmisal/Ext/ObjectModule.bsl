
Function ExternalDataProcessorInfo() Export
	
	RegistrationParametrs = New Structure;
	RegistrationParametrs.Insert("Type", "PrintForm");	
	
	DestinationArray = New Array();
	DestinationArray.Add("Document.Dismissal");

	RegistrationParametrs.Insert("Presentation", DestinationArray);
	
	RegistrationParametrs.Insert("Description", "Forma de listare Concediere-Dismissal");
	RegistrationParametrs.Insert("Version", "1.0"); 
	RegistrationParametrs.Insert("SafeMode", False); 	 
	RegistrationParametrs.Insert("Information", "Forma de listare Concediere-Dismissal");
	
	CommandTable = GetCommandTable();
	
	AddCommand(CommandTable,
	"Concediere",						    				
	"Concediere",   										 
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
	Spreadsheet.PrintParametersKey 	= "PrintParameters_Dismissal";
	Template	 					= ThisObject.GetTemplate(TemplateName);
	
	Query = New Query();
	Query.SetParameter("CurrentDocument", ObjectsArray);
	
	Query.Text =
	"SELECT
	|	Dismissal.Author,
	|	Dismissal.Comment,
	|	Dismissal.Date,
	|	Dismissal.Entity,
	|	Dismissal.Number,
	|	Dismissal.Employees.(
	|		LineNumber,
	|		Employee,
	|		Period,
	|		DismissalBasis
	|	),
	|	Dismissal.Ref
	|FROM
	|	Document.Dismissal AS Dismissal";
	
	Selection = Query.Execute().Select();	
	
	FirstDocument = True;
	
	FirstRowNumber = Spreadsheet.TableHeight + 1;

    LineNumber = 1;
	While Selection.Next() Do


	AreaCaption = Template.GetArea("Caption");
	Header = Template.GetArea("Header");
	Text= Template.GetArea("Text");
	
	Footer = Template.GetArea("Footer");
	Spreadsheet.Clear();	
	InsertPageBreak = False;

	Query = New Query;
	Query.Text = 
		"SELECT
		|	Employees.Position,
		|	Employees.Employee,
		|	Employees.Entity
		|FROM
		|	InformationRegister.Employees AS Employees
		|WHERE
		|	Employees.Employee = &Author";

	Query.SetParameter("Author", Selection.Author);

	Result = Query.Execute();

	SelectionDetailRecords = Result.Choose();

	
	 EndDo;
	While Selection.Next() Do
		SelectionEmployees = Selection.Employees.Choose();
		
		 While SelectionEmployees.Next() do 
			
         Text.Parameters["DismissalBasis"] = SelectionEmployees.DismissalBasis;
		 Text.Parameters["Employee"] = SelectionEmployees.Employee ;
	 EndDo;
           
		While SelectionDetailRecords.Next() Do
		Text.Parameters["functia"] = SelectionDetailRecords.Position ;
	EndDo;
	     	 
	 
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;

		Spreadsheet.Put(AreaCaption);

		Header.Parameters.Fill(Selection);
		Spreadsheet.Put(Header, Selection.Level());

		
		//SelectionText = Selection.Text.Choose();
		//While SelectionText.Next() Do
			//AreaText.Parameters.Fill(SelectionEmployees);
			Text.Parameters  .Fill(Selection);
			Spreadsheet.Put(Text, Selection.Level());
		//EndDo;

		Footer.Parameters.Fill(Selection);
		Spreadsheet.Put(Footer);

		InsertPageBreak = True;
		
	PrintManagement.SetDocumentPrintArea(Spreadsheet, FirstRowNumber, PrintObjects, Selection.Ref);
	EndDo;
	

	Spreadsheet.FitToPage = True;
	
	Return Spreadsheet;

EndFunction
