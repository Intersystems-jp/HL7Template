Class HL7v2Template.DT.CodeSet Extends HL7v2Template.DT.DataType [ Abstract ]
{

Parameter HL7DataType = "CE";

Parameter Template = "#(..Code)#^#(..Text)#^#(..System)#";

Property Code As %String;

Property Text As %String;

Property System As %String;

}
