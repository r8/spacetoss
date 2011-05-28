{
 MadMed Stuff
 (c) by Sergey Storchay (2:462/117@fidonet), 2001.
}
Unit r8med;

{$IFDEF RELEASE}
 {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
 {$ASMMODE intel}
{$ENDIF}

interface

Uses
  objects;

const
  medMsgOpus    = $0000;
  medMsgSquish  = $0001;
  medMsgJam     = $0002;
  medMsgHudson  = $0003;

  medNetMail    = $0010;
  medEchoMail   = $0020;
  medGroupMail  = $0040;
  medLocalMail  = $0000;

  medCollapsed  = $0080;
  medTwitFolder = $0100;
  medAddIntl    = $0200;
  medAddDomain  = $0400;
  medAddOrigin  = $0800;
  medRandOrigin = $1000;
  medShowTwits  = $2000;
  medNoSentmail = $4000;

type

  TMedAddress = record
    Zone   : integer;
    Net    : integer;
    Node   : integer;
    Point  : integer;
  end;

  TFolderHeader = record
    Size            : integer;
    Flags           : integer;
    LevelIndex      : integer;
    NameLen         : integer;
    AreaLen         : integer;
    PathLen         : integer;
    OrigLen         : integer;
    TplLen          : integer;
    DefaultAddress  : TMedAddress;
    DefaultAttrs    : longint;
    HudsonBoard     : integer;
    Reserved        : array[0..25] of byte;
    ThirdPartyFlags : integer;
  end;

  TMedFolderList = object(TObject)
    FileName : PString;

    Constructor Init(const AFileName:string);
    Destructor  Done; virtual;
  end;
  PMedFolderList = ^TMedFolderList;

implementation

Constructor TMedFolderList.Init(const AFileName:string);
begin
  inherited Init;

  FileName:=NewStr(AFileName);
end;

Destructor  TMedFolderList.Done;
begin
  DisposeStr(FileName);

  inherited Done;
end;

end.