Class HL7v2Template.Test.RDEO11.Address Extends HL7v2Template.DT.DataType
{

Parameter HL7DataType = "XAD";

Parameter Template = "^^^^#(..PostalCode)#^JPN^H^#(..Text)#";

Property Text As %String;

Property PostalCode As %String;

}
