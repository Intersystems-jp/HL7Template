Class HL7v2Template.Test.RDEO11.Duration Extends HL7v2Template.DT.DataType
{

Parameter HL7DataType = "CQ";

Parameter Template = "#(..Quantity)#^#(..Units)#";

Property Quantity As %String;

Property Units As %String;

}
