==============================================================================
MIGRATION GUIDE V3: GO TO DELPHI (MICRO-TASK ARCHITECTURE)
TARGET: DELPHI 12/13 (Athens+)
STRATEGY: ATOMIC MICRO-TASKS FOR MAXIMAL RELIABILITY
==============================================================================

1. PRE-REQUISITES (HUMAN CONTEXT)
------------------------------------------------------------------------------

Subfolder Compatibility\Golang\version 0.06 contains Delphi unit `unit_GoLang_Compatibility_version_006.pas` it contains `TGoChannel<T>`, `TGoWaitGroup`, and `TGoContext` for golang compatibility, use this unit when these golang features are needed.

2. THE MICRO-TASK LIST
------------------------------------------------------------------------------
Do not ask the AI to "Convert the file." Ask it to perform one Micro-Task
at a time. Copy the output of one task to your IDE before starting the next.

MICRO-TASK 1: DEPENDENCY MAPPING
"Analyze the 'import' section of the Go file. Output ONLY the Delphi 'uses'
clause. Map 'fmt' to 'System.SysUtils', 'net/http' to 'System.Net.HttpClient',
and add 'GoCompat' to the list. Do not write any other code."

MICRO-TASK 2: CONSTANT & TYPE DISCOVERY
"Scan the Go file for 'const' definitions and 'type' aliases (e.g., type MyInt int).
Output a Delphi 'const' section and a 'type' section for simple aliases only.
Ignore structs and interfaces for now."

MICRO-TASK 3: STRUCT TO CLASS SKELETONS
"Find all 'type struct' definitions. Output them as Delphi 'class' definitions.
Only declare the fields (variables) inside the class 'public' section.
Do not add methods or properties yet.
Example:
  type TMyStruct = class
  public
    Field1: Integer;
  end;"

MICRO-TASK 4: MULTI-RETURN RECORD GENERATION
"Identify every Go function that returns more than one value (e.g., (int, error)).
For each one, create a Delphi 'record' type named 'TResult_<FunctionName>'.
Fields should match the Go return types.
Example:
  type TResult_Calc = record
    Val: Integer;
    Err: string;
  end;"

MICRO-TASK 5: INTERFACE DEFINITION
"Find all 'type interface' definitions. Convert them to Delphi interfaces.
1. Add a GUID ['{...}'] to every interface.
2. Ensure method signatures use the 'TResult_' records created in Task 4
   if they had multiple returns in Go."

MICRO-TASK 6: METHOD HEADERS (INTERFACE SECTION)
"Now generate the complete Delphi 'interface' section for the classes defined
in Task 3. 
1. Add the method headers (procedures/functions) that correspond to Go receivers.
2. If a Go method returns multiple values, use the TResult_ record as the result.
3. If a Go method returns nothing, use 'procedure'.
Output ONLY the interface section code."

MICRO-TASK 7: CONSTRUCTOR GENERATION
"Create the 'implementation' section. Write a 'Create' constructor for every
Class defined in Task 3.
1. If the Go struct had map fields, initialize them as TDictionary.
2. If the Go struct had slice fields, initialize them if necessary.
3. If the Go struct had channel fields, initialize them as TGoChannel.Create."

MICRO-TASK 8: IMPLEMENTATION - PURE FUNCTIONS
"Convert ONLY the standalone helper functions (those that do not belong to a struct).
Use Delphi 13 inline variables.
If the function returns a TResult_ record, assign fields like:
  Result.Val := 10;
  Result.Err := '';"

MICRO-TASK 9: IMPLEMENTATION - METHODS & CONCURRENCY
"Convert the methods attached to the Classes.
1. Replace 'go func()' with 'TTask.Run(procedure begin ... end);'.
2. Replace 'chan <- x' with 'FChannel.Send(x)'.
3. Replace '<- chan' with 'FChannel.Receive(out var)'.
4. Use 'Self.Field' to access struct fields."

MICRO-TASK 10: DEFER & CLEANUP
"Review the code from Task 8 and 9.
1. Identify where 'defer' was used in Go.
2. Wrap those specific blocks in 'try..finally'.
3. Put the deferred action in the 'finally' block.
4. Output the corrected implementations for those specific methods."

------------------------------------------------------------------------------
3. HOW TO EXECUTE
------------------------------------------------------------------------------
Read the *.go file. Consult the mappings. If no mapping is there for filename follows fully qualified delphi unit name rules. Save converted delphi code to the *.pas or *.dpr file, Validate the output, save it, and move to the next Micro-Task.
