#Region FormEvents

&AtClient
Procedure BSB_CounterpartyDebtOnClick(Item, StandardProcessing)
	StandardProcessing = False;
	OpenReport();
EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Procedure BSB_CreateInvoiceForPayment(Command)
	BSB_CreateDocument("InvoiceForPayment");
EndProcedure

&AtClient
Procedure BSB_CreateCustomerOrder(Command)
	BSB_CreateDocument("CustomerOrder");
EndProcedure

&AtClient
Procedure BSB_CreateInvoice(Command)
	BSB_CreateDocument("Invoice");
EndProcedure

&AtClient
Procedure BSB_CreatePurchaseOrder(Command)
	BSB_CreateDocument("PurchaseOrder");
EndProcedure

&AtClient
Procedure BSB_CreatePurchaseInvoiceReceived(Command)
	BSB_CreateDocument("PurchaseInvoiceReceived");
EndProcedure

#EndRegion

#Region ListEvents

&AtClient
Procedure BSB_ListOnActivateRow(Item)
	SetEventHandlersExecution(False);
	AttachIdleHandler("Handle_BSBIncreasedRowsList", 0.2, True);
EndProcedure

#EndRegion

#Region InternalProceduresFunctions

&AtClient
Procedure BSB_CreateDocument(DocumentName)
	
	CurrentDataOfList = ThisForm.Items.List.CurrentData;
	
	If CurrentDataOfList = Undefined Then
		Return;
	EndIf;
	
	FillingValues = New Structure;
	FillingValues.Insert("Counterparty", CurrentDataOfList.Ref);
	
	FormNameDocument = "Document." + DocumentName + ".ObjectForm";
	ParametersStructure = New Structure("FillingValues", FillingValues);
	OpenForm(FormNameDocument, ParametersStructure, ThisForm, UniqueKey);
	
EndProcedure

&AtClient
Procedure Handle_BSBIncreasedRowsList()
	InfPanelParameters = New Structure("CIAttribute, Counterparty, ContactPerson, MutualSettlements", "Ref");
	SmallBusinessClient.InfoPanelProcessListRowActivation(ThisForm, InfPanelParameters);
EndProcedure

&AtClient
Procedure OpenReport()
	
	CurrentDataOfList = ThisForm.Items.List.CurrentData;
	
	If CurrentDataOfList = Undefined Then
		Return;
	EndIf;
	
	FilterStructure = New Structure("Counterparty", CurrentDataOfList.Ref);
	ReportParametres = New Structure;
	ReportParametres.Insert("GenerateOnOpen", True);
	ReportParametres.Insert("Filter", FilterStructure);
	OpenForm("Отчет.MutualSettlementsBriefly.ФормаОбъекта", ReportParametres, ThisForm);
	
EndProcedure

#EndRegion