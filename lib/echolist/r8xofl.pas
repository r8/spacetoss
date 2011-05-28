{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
Unit r8xofl;

interface

Uses
  r8alst,
  r8str,
  objects,
  r8objs;

Type

  TxOfcEList = object(TArealist)
    Constructor Init;
    Destructor Done;virtual;

    Procedure Read;virtual;
  end;

  PxOfcEList = ^TxOfcEList;

implementation

Constructor TxOfcEList.Init;
begin
  inherited Init;
end;

Destructor TxOfcEList.Done;
begin
  inherited Done;
end;

Procedure TxOfcEList.Read;
Var
 T:text;
 sTemp:string;
 TempArea : PEArealistitem;
 Name, Desc : string;
begin
  Assign(T,FileName^);
{$I-}
  Reset(T);
{$I+}

  If IOResult<>0 then
    begin
      Status:=alstCantOpenFile;
      exit;
    end;

  While not eof(T) do
    begin
      ReadLn(T,sTemp);
      sTemp:=strTrimB(sTemp,[#32,',']);

      If sTemp='' then continue;
      If sTemp[1]=';' then continue;

      Name:=strUpper(strParser(sTemp,1,[',']));
      Desc:=strParser(sTemp,2,[',']);

      TempArea:=New(PEArealistitem,Init(Name,Desc));

      ListAreas^.Insert(TempArea);
    end;

  Close(T);
end;

end.