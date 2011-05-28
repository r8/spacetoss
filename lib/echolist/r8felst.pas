{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
Unit r8FeLst;

interface

Uses
  r8alst,
  r8str,
  objects,
  r8objs;

Type

  TFeList = object(TArealist)
    Constructor Init;
    Destructor Done;virtual;

    Procedure Read;virtual;
  end;

  PFeList = ^TFeList;

implementation

Constructor TFeList.Init;
begin
  inherited Init;
end;

Destructor TFeList.Done;
begin
  inherited Done;
end;

Procedure TFeList.Read;
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

      If (sTemp[1]<>' ') and (sTemp[1]<>'*') then continue;
      If Copy(sTemp,1,10)='          ' then continue;

      sTemp:=strTrimL(sTemp,[#32,'*']);
      if sTemp='' then continue;

      strSplitWords(sTemp,Name,Desc);
      Desc:=strTrimB(Desc,[#32,'.']);

      TempArea:=New(PEArealistitem,Init(Name,Desc));

      ListAreas^.Insert(TempArea);
    end;

  Close(T);
end;

end.