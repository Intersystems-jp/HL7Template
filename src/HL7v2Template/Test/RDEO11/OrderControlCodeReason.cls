Class HL7v2Template.Test.RDEO11.OrderControlCodeReason Extends HL7v2Template.DT.DataType
{

Parameter HL7DataType = "CE";

Parameter Template = "#(..Code)#^#(..Text)#^#(..System)#";

Property Code As %String;

Property Text As %String;

Property System As %String;

}
