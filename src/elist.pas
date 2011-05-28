{
 Echolist loader for SpaceToss.
 (c) by Sergey Storchay (2:462/117@fidonet), 2002.
}
Unit EList;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  r8alst,
  r8elst,
  lng,

  r8sqlst,
  r8felst,
  r8bcl,
  r8xofl,

  r8objs;

Type

  TArealistRec = record
    Path : string;
    ListType : longint;
    List : PAreaList;
  end;

Procedure ReadEcholist(var EchoList:TArealistRec;const Parent:string);

implementation

Uses
  global;


Procedure ReadEcholist(var EchoList:TArealistRec;const Parent:string);
begin
  If EchoList.ListType=ltNone then exit;

  Case EchoList.ListType of
    ltEchoList : EchoList.List:=New(PEchoList,Init);
    ltBCL      : EchoList.List:=New(PBCL,Init);
    ltFastecho : EchoList.List:=New(PFeList,Init);
    ltSquish   : EchoList.List:=New(PSqList,Init);
    ltXOfcEList: EchoList.List:=New(PxOfcEList,Init);
   end;

  EchoList.List^.SetFilename(EchoList.Path);
  EchoList.List^.Read;

  If EchoList.List^.Status<>alstOk then
    begin
      EchoList.ListType:=ltNone;
      objDispose(EchoList.List);

      LngFile^.AddVar(Parent);
      LngFile^.AddVar(EchoList.Path);
      LogFile^.SendStr(LngFile^.GetString(LongInt(lngCantOpenArealist)),'!');
    end;
end;

begin
end.
