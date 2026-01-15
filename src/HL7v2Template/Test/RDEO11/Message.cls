Class HL7v2Template.Test.RDEO11.Message Extends HL7v2Template.Test.RDEO11.Template
{

Property MsgControlId As %String;

Property PatientId As %String;

Property LastName As %String;

Property FirstName As %String;

Property LastNameKana As %String;

Property FirstNameKana As %String;

Property DOB As %Date;

Property Gender As %String;

Property Address As HL7v2Template.Test.RDEO11.Address;

Property PhoneHome As %String;

Property PhoneWork As %String;

Property PatientUpdateTime As %TimeStamp;

Property AttendingDoctor As HL7v2Template.Test.RDEO11.Doctor;

Property MedicationOrders As list Of HL7v2Template.Test.RDEO11.Order;

XData Template [ MimeType = application/json ]
{
[
"MSH|^~\\&|HIS123|SEND|GW|RCV|#(..MsgTime)#||RDE^O11^RDE_O11|#(..MsgControlId)#|P|2.5||||||~ISO IR87||ISO2022-1994|SS-MIX2_1.20^SS-MIX2^1.2.392.200250.2.1.100.1.2.120^ISO",
"PID|0001||#(..PatientId)#^^^^PI||#(..LastName)#^#(..FirstName)#^^^^^L^I~#(..LastNameKana)#^#(..FirstNameKana)#^^^^^L^P||#(..DOB)#|#(..Gender)#|||#(..Address)#||^PRN^PH^^^^^^^^^#(..PhoneHome)#|^WPN^PH^^^^^^^^^#(..PhoneWork)#|||||||||||||||||||#(..PatientUpdateTime)#",
"PV1|0001|O|01^^^^^C||||#(..AttendingDoctor)#|||01",
"ORC|#(..MedicationOrders)#"
]
}

}
