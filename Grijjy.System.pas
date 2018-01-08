unit Grijjy.System;

{$INCLUDE 'Grijjy.inc'}

interface

type
  { Abstract base class for classes that can implement interfaces, but are not
    reference counted (unless on ARC systems of course). If you want your class
    to be reference counted, derive from TInterfacedObject instead. }
  TgoNonRefCountedObject = class abstract(TObject)
  {$REGION 'Internal Declarations'}
  protected
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  {$ENDREGION 'Internal Declarations'}
  end;

implementation

{ TgoNonRefCountedObject }

function TgoNonRefCountedObject.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TgoNonRefCountedObject._AddRef: Integer;
begin
  Result := -1;
end;

function TgoNonRefCountedObject._Release: Integer;
begin
  Result := -1;
end;

end.
