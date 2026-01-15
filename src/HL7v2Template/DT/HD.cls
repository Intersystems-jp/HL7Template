Class HL7v2Template.DT.HD Extends HL7v2Template.DT.DataType
{

/// HL7データタイプの指定
Parameter HL7DataType = "HD";

/// 指定したデータタイプへの変換
ClassMethod ConvertFromHL7(datatype As %String, HL7value As %String) As %DataType
{
	quit HL7value
}

/// 指定したデータをHL7の形式に変換
ClassMethod ConvertToHL7(datatype As %String, value As %String) As %DataType
{
	quit value
}

}
