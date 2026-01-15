Class HL7v2Template.Test.RDEO11.Order Extends HL7v2Template.Test.RDEO11.Template
{

Property OrderControl As %String;

Property PlacerOrderNumber As %String;

Property PlacerGroupNumber As %String;

Property TransactionTime As %TimeStamp;

Property EnteredBy As HL7v2Template.Test.RDEO11.Doctor;

Property OrderingProvider As HL7v2Template.Test.RDEO11.Doctor;

Property OrderControlCodeReason As HL7v2Template.Test.CodeSet;

Property OrderType As HL7v2Template.Test.CodeSet;

Property DispenseGiveCode As HL7v2Template.Test.CodeSet.Medicine;

Property GiveAmountMinimum As %String;

Property GiveUnits As HL7v2Template.Test.CodeSet.Units;

Property DispenseAmount As %String;

Property DispenseUnits As HL7v2Template.Test.CodeSet.Units;

Property PrescriptionNumber As %String;

Property TotalDailyDose As HL7v2Template.DT.CQ;

Property SpecialDispensingInstructions As list Of HL7v2Template.Test.CodeSet;

Property SetId As %String;

Property RepeatPattern As HL7v2Template.Test.RDEO11.RepeatPattern;

Property Duration As HL7v2Template.Test.RDEO11.Duration;

Property StartDateTime As %TimeStamp;

Property Route As HL7v2Template.Test.RDEO11.Route;

XData Template [ MimeType = application/json ]
{
[
"ORC|#(..OrderControl)#|#(..PlacerOrderNumber)#||#(..PlacerGroupNumber)#|||||#(..TransactionTime)#|#(..EnteredBy)#||#(..OrderingProvider)#|10^^^^^C||||#(..OrderControlCodeReason)#|VMDOCX01^^99XY2||||||||||#(..OrderType)#",
"RXE||#(..DispenseGiveCode)#|#(..GiveAmountMinimum)#||#(..GiveUnits)#|||||#(..DispenseAmount)#|#(..DispenseUnits)#||||#(..PrescriptionNumber)#||||#(..TotalDailyDose)#||#(..SpecialDispensingInstructions)#",
"TQ1|#(..SetId)#||#(..RepeatPattern)#|||#(..Duration)#|#(..StartDateTime)#",
"RXR|#(..Route)#"
]
}

}
