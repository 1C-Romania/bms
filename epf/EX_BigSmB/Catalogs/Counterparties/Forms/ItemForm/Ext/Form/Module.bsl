&AtClient
Procedure BSB_BeforeWrite(Cancel, WriteParameters)
	
	If Not Modified Then
		Return;
	EndIf;
	
	QuantityEqualCounterparties = QuantityEqualCounterparties(Object.TIN, Object.CIO, Object.Ref);
	If QuantityEqualCounterparties <> 0 Then
		If QuantityEqualCounterparties = 1 Then
			TextCounterparties = НСтр("ru = 'один контрагент';en='one counterparty';ro='un contraparte'");
		ElsIf QuantityEqualCounterparties < 5 Then
			TextCounterparties = String(QuantityEqualCounterparties) 
				+ " " + НСтр("ru = 'контрагента';en='counterparties';ro='contrapartidele'");
		Else
			TextCounterparties = String(QuantityEqualCounterparties) 
				+ " " + НСтр("ru = 'контрагентов';en='counterparties';ro='contrapartidele'");
		EndIf;
		TextQuestion = StringFunctionsClientServer.PlaceParametersIntoString(
			NStr("ru='С таким TIN и CIO уже есть %1. Записать?';
			|en='You have %1 with such TIN and CIO. Save?';
			|ro=''"),
			TextCounterparties);
		Answer = DoQueryBox(TextQuestion, QuestionDialogMode.YesNo);
		If Answer = DialogReturnCode.No Then
			Cancel = True;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function QuantityEqualCounterparties(Val TIN, Val CIO, val Ref)
	
	If IsBlankString(TIN) And IsBlankString(CIO) Then
		Return 0;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("CIO", CIO);
	Query.SetParameter("TIN", TIN);
	Query.SetParameter("Ref", Ref);
	Query.Text =
	"SELECT
	|	COUNT(Counterparties.Ref) AS QuantityEqualCounterparties
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.CIO = &CIO
	|	AND Counterparties.TIN = &TIN
	|	AND Counterparties.Ref <> &Ref
	|	AND NOT Counterparties.IsFolder";
	ResultQuery = Query.Execute();
	If ResultQuery.IsEmpty() Then
		Return 0;
	Else
		Selection = ResultQuery.Select();
		Selection.Next();
		Return Selection.QuantityEqualCounterparties;
	EndIf;
	
EndFunction