Class HL7v2Template.DT.MSG Extends HL7v2Template.DT.DataType
{

ClassMethod ConvertFromHL7(datatype As %String, HL7value As %String) As %DataType
{
	if datatype="%Library.String" {
		quit $piece(HL7value,"^",3)
	}
	quit HL7value
}

/// 指定したデータをHL7の形式に変換
ClassMethod ConvertToHL7(datatype As %String, value As %String) As %DataType
{
	quit value
}

}
