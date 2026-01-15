Class HL7v2Template.DT.CE Extends HL7v2Template.DT.DataType
{

/// HL7データタイプの指定
Parameter HL7DataType = "CE";

Parameter Template = "#(..Code)#^#(..Text)#^#(..System)#";

Property Code As %String;

Property Text As %String;

Property System As %String;

/// 指定したデータタイプへの変換
ClassMethod ConvertFromHL7(datatype As %String, HL7value As %String) As %DataType
{
	if datatype="%Library.String" {
		quit $piece(HL7value,"^",1)
	}
	quit HL7value
}

/// 指定したデータをHL7の形式に変換
ClassMethod ConvertToHL7(datatype As %String, value As %String) As %DataType
{
	quit value
}

}
