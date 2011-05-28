{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
Unit r8outcmn;

interface

Uses
  r8objs,
  r8str,
  r8ftn,
  objects;

Type
  TOutFileCollection = object(TCollection)
    Procedure FreeItem(item:pointer);virtual;
  end;

  POutFileCollection = ^TOutAddressCollection;

  TOutAddress = object(TObject)
    Address : TAddress;
    Files : POutFileCollection;

    Constructor Init;
    Destructor Done;virtual;
    Function FindFile(S:string):longint;
 end;

 POutAddress = ^TOutAddress;

  TOutAddressCollection = object(TCollection)
    Procedure FreeItem(item:pointer);virtual;
  end;

  POutAddressCollection = ^TOutAddressCollection;


{様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様}

  TOutFile = object(TObject)
    Name : PString;
    Flavour : word;
    Addresses : POutAddressCollection;

    Constructor Init;
    Destructor Done;virtual;
  end;

 POutFile = ^TOutFile;

{様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様}

implementation

{様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様}


Constructor TOutAddress.Init;
begin
  inherited init;

  Files:=New(POutFileCollection,Init($10,$10));
end;

Destructor TOutAddress.Done;
begin
  Files^.DeleteAll;
  objDispose(Files);

  inherited Done;
end;

Function TOutAddress.FindFile(S:string):longint;
var
  i:longint;
  TempFile : POutFile;
begin
  FindFile:=-1;

  S:=strUpper(S);

  For i:=0 to Files^.Count-1 do
    begin
      TempFile:=Files^.At(i);
      If TempFile^.Name^=S then
        begin
          FindFile:=i;
          exit;
        end;
    end;
end;

{様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様}

Constructor TOutFile.Init;
begin
   inherited Init;

   Addresses:=New(POutAddressCollection,Init($10,$10));
end;

Destructor TOutFile.Done;
begin
  DisposeStr(Name);
  Addresses^.DeleteAll;
  objDispose(Addresses);

  inherited Done;
end;

{様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様}

Procedure TOutAddressCollection.FreeItem(item:pointer);
Begin
  If Item<>nil then objDispose(POutAddress(Item));
End;

Procedure TOutFileCollection.FreeItem(item:pointer);
Begin
  If Item<>nil then objDispose(POutFile(Item));
End;

end.
