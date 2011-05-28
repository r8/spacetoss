{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
Unit r8sqLst;

interface

Uses
  r8alst,
  r8str,
  objects,
  r8objs;

Type

  TSqList = object(TArealist)
    Constructor Init;
    Destructor Done;virtual;

    Procedure Read;virtual;
  end;

  PSqList = ^TSqList;

implementation

Constructor TSqList.Init;
begin
  inherited Init;
end;

Destructor TSqList.Done;
begin
  inherited Done;
end;

Procedure TSqList.Read;
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

      If Pos('.....',sTemp)=0 then continue;

      sTemp:=strTrimL(sTemp,[#32]);
      if sTemp='' then continue;

      Name:=strParser(sTemp,1,[#32]);
      Desc:=strParser(sTemp,2,['"']);

      TempArea:=New(PEArealistitem,Init(Name,Desc));

      ListAreas^.Insert(TempArea);
    end;

  Close(T);
end;

end.