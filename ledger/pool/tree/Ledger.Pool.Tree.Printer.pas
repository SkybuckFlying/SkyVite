unit Ledger.Pool.Tree.Printer;

interface

uses
  SysUtils, Classes,
  System.Text,
  Ledger.Pool.Tree.Branch; // For IBranch

type
  TTreePrinter = class
  private
    procedure PrintBranch(Branch: IBranch; Builder: TStringBuilder; Indent: string);
  public
    function Print(Root: IBranch): string;
  end;

implementation

{ TTreePrinter }

function TTreePrinter.Print(Root: IBranch): string;
var
  sb: TStringBuilder;
begin
  sb := TStringBuilder.Create;
  try
    if Root <> nil then
    begin
      PrintBranch(Root, sb, '');
    end;
    Result := sb.ToString;
  finally
    sb.Free;
  end;
end;

procedure TTreePrinter.PrintBranch(Branch: IBranch; Builder: TStringBuilder; Indent: string);
var
  child: IBranch;
  tx: ITransaction;
begin
  // Print current branch info
  tx := Branch.GetTransaction;
  Builder.Append(Indent);
  if tx <> nil then
    Builder.AppendLine(tx.Hash.ToString)
  else
    Builder.AppendLine('[nil]');

  // Recursively print children
  for child in Branch.GetChildren do
  begin
    PrintBranch(child, Builder, Indent + '  ');
  end;
end;

end.
