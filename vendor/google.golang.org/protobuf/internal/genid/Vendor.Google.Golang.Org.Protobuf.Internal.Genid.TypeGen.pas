unit Vendor.Google.Golang.Org.Protobuf.Internal.Genid.TypeGen;

{$MODE DELPHIUNICODE}

interface

uses
	Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.Proto;

const
	File_google_protobuf_type_proto = 'google/protobuf/type.proto';

// Full and short names for google.protobuf.Syntax.
const
	Syntax_enum_fullname = 'google.protobuf.Syntax';
	Syntax_enum_name = 'Syntax';

// Names for google.protobuf.Type.
const
	Type_message_name : TName = 'Type';
	Type_message_fullname : TFullName = 'google.protobuf.Type';

// Field names for google.protobuf.Type.
const
	Type_Name_field_name : TName = 'name';
	Type_Fields_field_name : TName = 'fields';
	Type_Oneofs_field_name : TName = 'oneofs';
	Type_Options_field_name : TName = 'options';
	Type_SourceContext_field_name : TName = 'source_context';
	Type_Syntax_field_name : TName = 'syntax';

	Type_Name_field_fullname : TFullName = 'google.protobuf.Type.name';
	Type_Fields_field_fullname : TFullName = 'google.protobuf.Type.fields';
	Type_Oneofs_field_fullname : TFullName = 'google.protobuf.Type.oneofs';
	Type_Options_field_fullname : TFullName = 'google.protobuf.Type.options';
	Type_SourceContext_field_fullname : TFullName = 'google.protobuf.Type.source_context';
	Type_Syntax_field_fullname : TFullName = 'google.protobuf.Type.syntax';

// Field numbers for google.protobuf.Type.
const
	Type_Name_field_number : TFieldNumber = 1;
	Type_Fields_field_number : TFieldNumber = 2;
	Type_Oneofs_field_number : TFieldNumber = 3;
	Type_Options_field_number : TFieldNumber = 4;
	Type_SourceContext_field_number : TFieldNumber = 5;
	Type_Syntax_field_number : TFieldNumber = 6;

// Names for google.protobuf.Field.
const
	Field_message_name : TName = 'Field';
	Field_message_fullname : TFullName = 'google.protobuf.Field';

// Field names for google.protobuf.Field.
const
	Field_Kind_field_name : TName = 'kind';
	Field_Cardinality_field_name : TName = 'cardinality';
	Field_Number_field_name : TName = 'number';
	Field_Name_field_name : TName = 'name';
	Field_TypeUrl_field_name : TName = 'type_url';
	Field_OneofIndex_field_name : TName = 'oneof_index';
	Field_Packed_field_name : TName = 'packed';
	Field_Options_field_name : TName = 'options';
	Field_JsonName_field_name : TName = 'json_name';
	Field_DefaultValue_field_name : TName = 'default_value';

	Field_Kind_field_fullname : TFullName = 'google.protobuf.Field.kind';
	Field_Cardinality_field_fullname : TFullName = 'google.protobuf.Field.cardinality';
	Field_Number_field_fullname : TFullName = 'google.protobuf.Field.number';
	Field_Name_field_fullname : TFullName = 'google.protobuf.Field.name';
	Field_TypeUrl_field_fullname : TFullName = 'google.protobuf.Field.type_url';
	Field_OneofIndex_field_fullname : TFullName = 'google.protobuf.Field.oneof_index';
	Field_Packed_field_fullname : TFullName = 'google.protobuf.Field.packed';
	Field_Options_field_fullname : TFullName = 'google.protobuf.Field.options';
	Field_JsonName_field_fullname : TFullName = 'google.protobuf.Field.json_name';
	Field_DefaultValue_field_fullname : TFullName = 'google.protobuf.Field.default_value';

// Field numbers for google.protobuf.Field.
const
	Field_Kind_field_number : TFieldNumber = 1;
	Field_Cardinality_field_number : TFieldNumber = 2;
	Field_Number_field_number : TFieldNumber = 3;
	Field_Name_field_number : TFieldNumber = 4;
	Field_TypeUrl_field_number : TFieldNumber = 6;
	Field_OneofIndex_field_number : TFieldNumber = 7;
	Field_Packed_field_number : TFieldNumber = 8;
	Field_Options_field_number : TFieldNumber = 9;
	Field_JsonName_field_number : TFieldNumber = 10;
	Field_DefaultValue_field_number : TFieldNumber = 11;

// Full and short names for google.protobuf.Field.Kind.
const
	Field_Kind_enum_fullname = 'google.protobuf.Field.Kind';
	Field_Kind_enum_name = 'Kind';

// Full and short names for google.protobuf.Field.Cardinality.
const
	Field_Cardinality_enum_fullname = 'google.protobuf.Field.Cardinality';
	Field_Cardinality_enum_name = 'Cardinality';

// Names for google.protobuf.Enum.
const
	Enum_message_name : TName = 'Enum';
	Enum_message_fullname : TFullName = 'google.protobuf.Enum';

// Field names for google.protobuf.Enum.
const
	Enum_Name_field_name : TName = 'name';
	Enum_Enumvalue_field_name : TName = 'enumvalue';
	Enum_Options_field_name : TName = 'options';
	Enum_SourceContext_field_name : TName = 'source_context';
	Enum_Syntax_field_name : TName = 'syntax';

	Enum_Name_field_fullname : TFullName = 'google.protobuf.Enum.name';
	Enum_Enumvalue_field_fullname : TFullName = 'google.protobuf.Enum.enumvalue';
	Enum_Options_field_fullname : TFullName = 'google.protobuf.Enum.options';
	Enum_SourceContext_field_fullname : TFullName = 'google.protobuf.Enum.source_context';
	Enum_Syntax_field_fullname : TFullName = 'google.protobuf.Enum.syntax';

// Field numbers for google.protobuf.Enum.
const
	Enum_Name_field_number : TFieldNumber = 1;
	Enum_Enumvalue_field_number : TFieldNumber = 2;
	Enum_Options_field_number : TFieldNumber = 3;
	Enum_SourceContext_field_number : TFieldNumber = 4;
	Enum_Syntax_field_number : TFieldNumber = 5;

// Names for google.protobuf.EnumValue.
const
	EnumValue_message_name : TName = 'EnumValue';
	EnumValue_message_fullname : TFullName = 'google.protobuf.EnumValue';

// Field names for google.protobuf.EnumValue.
const
	EnumValue_Name_field_name : TName = 'name';
	EnumValue_Number_field_name : TName = 'number';
	EnumValue_Options_field_name : TName = 'options';

	EnumValue_Name_field_fullname : TFullName = 'google.protobuf.EnumValue.name';
	EnumValue_Number_field_fullname : TFullName = 'google.protobuf.EnumValue.number';
	EnumValue_Options_field_fullname : TFullName = 'google.protobuf.EnumValue.options';

// Field numbers for google.protobuf.EnumValue.
const
	EnumValue_Name_field_number : TFieldNumber = 1;
	EnumValue_Number_field_number : TFieldNumber = 2;
	EnumValue_Options_field_number : TFieldNumber = 3;

// Names for google.protobuf.Option.
const
	Option_message_name : TName = 'Option';
	Option_message_fullname : TFullName = 'google.protobuf.Option';

// Field names for google.protobuf.Option.
const
	Option_Name_field_name : TName = 'name';
	Option_Value_field_name : TName = 'value';

	Option_Name_field_fullname : TFullName = 'google.protobuf.Option.name';
	Option_Value_field_fullname : TFullName = 'google.protobuf.Option.value';

// Field numbers for google.protobuf.Option.
const
	Option_Name_field_number : TFieldNumber = 1;
	Option_Value_field_number : TFieldNumber = 2;

implementation

end.
