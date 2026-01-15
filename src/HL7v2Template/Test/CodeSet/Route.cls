Class HL7v2Template.Test.CodeSet.Route Extends (%Persistent, HL7v2Template.DT.CodeSet)
{

Index CodeIndex On Code [ IdKey, Unique ];

Storage Default
{
<Data name="RouteDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Text</Value>
</Value>
<Value name="3">
<Value>System</Value>
</Value>
</Data>
<DataLocation>^HL7v2Template.Test.C9F11.RouteD</DataLocation>
<DefaultData>RouteDefaultData</DefaultData>
<IdLocation>^HL7v2Template.Test.C9F11.RouteD</IdLocation>
<IndexLocation>^HL7v2Template.Test.C9F11.RouteI</IndexLocation>
<StreamLocation>^HL7v2Template.Test.C9F11.RouteS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
