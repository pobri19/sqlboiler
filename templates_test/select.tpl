{{- $tableNameSingular := .Table.Name | singular | titleCase -}}
{{- $dbName := singular .Table.Name -}}
{{- $tableNamePlural := .Table.Name | plural | titleCase -}}
{{- $varNamePlural := .Table.Name | plural | camelCase -}}
{{- $varNameSingular := .Table.Name | singular | camelCase -}}
func Test{{$tableNamePlural}}Select(t *testing.T) {
  // Only run this test if there are ample cols to test on
  if len({{$varNameSingular}}AutoIncrementColumns) == 0 {
    return
  }

  var err error

  x := &struct{
  {{- $colNames := .Table.Columns | filterColumnsByAutoIncrement true | columnNames }}
  {{ $colTypes := .Table.Columns | filterColumnsByAutoIncrement true | columnTypes }}
  {{range $index, $element := $colNames}}
    {{$element | titleCase}} {{index $colTypes $index}}
  {{end}}
  }{}

  item := {{$tableNameSingular}}{}

  blacklistCols := boil.SetMerge({{$varNameSingular}}AutoIncrementColumns, {{$varNameSingular}}PrimaryKeyColumns)
  if err = boil.RandomizeStruct(&item, {{$varNameSingular}}DBTypes, false, blacklistCols...); err != nil {
    t.Errorf("Unable to randomize {{$tableNameSingular}} struct: %s", err)
  }

  if err = item.Insert(); err != nil {
    t.Errorf("Unable to insert item {{$tableNameSingular}}:\n%#v\nErr: %s", item, err)
  }

  err = {{$tableNamePlural}}(qm.Select({{$varNameSingular}}AutoIncrementColumns...), qm.Where(`{{whereClause .Table.PKey.Columns 1}}`, {{.Table.PKey.Columns | stringMap .StringFuncs.titleCase | prefixStringSlice "item." | join ", "}})).Bind(x)
  if err != nil {
    t.Errorf("Unable to select insert results with bind: %s", err)
  }

  {{range $index, $element := $colNames }}
  {{$e := titleCase $element}}
  if item.{{$e}} != x.{{$e}} || x.{{$e}} == {{index $colTypes $index}}(0) {
    t.Errorf("Expected item.{{$e}} to match x.{{$e}}, but got: %v, %v", item.{{$e}}, x.{{$e}})
  }
  {{end}}

  {{$varNamePlural}}DeleteAllRows(t)
}