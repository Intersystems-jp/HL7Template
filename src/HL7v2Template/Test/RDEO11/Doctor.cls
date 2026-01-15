Class HL7v2Template.Test.RDEO11.Doctor Extends HL7v2Template.DT.DataType
{

Parameter HL7DataType = "XCN";

Parameter Template = "#(..Id)#^#(..FamilyName)#^#(..GivenName)#^^^^^#(..AssigningAuthority)#^^^#(..NameTypeCode)#";

Property Id As %String;

Property FamilyName As %String;

Property GivenName As %String;

Property AssigningAuthority As %String;

Property NameTypeCode As %String;

}
