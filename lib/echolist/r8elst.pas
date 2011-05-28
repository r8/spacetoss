{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
Unit r8elst;

interface

Uses
  r8alst,
  r8str,
  objects,
  r8objs;

Type

  TEchoList = object(TArealist)
    Constructor Init;
    Destructor Done;virtual;

    Procedure Read;virtual;
  end;

  PEcholist = ^TEcholist;

implementation

Constructor TEcholist.Init;
begin
  inherited Init;
end;

Destructor TEcholist.Done;
begin
  inherited Done;
end;

Procedure TEchoList.Read;
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

      sTemp:=strTrimL(sTemp,[#32]);
      if sTemp='' then continue;

      Name:='';
      Desc:='';

      strSplitWords(sTemp,Name,Desc);
      Desc:=strTrimB(Desc,[#32]);

      TempArea:=New(PEArealistitem,Init(Name,Desc));
      ListAreas^.Insert(TempArea);
    end;

  Close(T);
end;

end.
