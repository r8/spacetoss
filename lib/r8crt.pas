{$IFDEF RELEASE}
  {$A+,B-,D-,E-,F+,G+,I-,L-,N+,Q-,R-,S-,X+,Y-}
{$ENDIF}
{$IFDEF FPC}
  {SMARTLINK ON}
{$ENDIF}
{$IFDEF FPC}
  {$ASMMODE intel}
{$ENDIF}

{$IFDEF MSDOS}
  {$DEFINE DOS}
{$ENDIF}
{$IFDEF DPMI}
  {$DEFINE DOS}
{$ENDIF}


Unit r8Crt;

interface
Uses Crt;

Const
  curThin    = $0707;           {Тонкий курсор}
  curSquare  = $0307;           {Квадратный курсор}
  curBar     = $000D;           {Прямоугольный курсор}
  curNormal  = $0607;           {Обыкновенный курсор}

{$IFDEF DOS}
Type
  VRecord = record
              VChar : char;
         VAttr : byte;
            End;
  VMemType = array[1..25,1..80] of VRecord;

Var
  TextMem    : VMemType absolute $B800:0000;
{$ENDIF}

Procedure crtShowCursor;
Procedure crtHideCursor;
Procedure crtSetCursor(CursorType: Word);

Procedure crtWriteCh(x,y: byte;Ch: char);
Procedure crtWriteStr(x,y,fg,bg:byte;S: string);
Procedure crtWriteParagraph(fg,bg:byte;S:string);

Procedure crtUnregistered;
Procedure crtUnregisteredP;

implementation

{$IFDEF DOS}
Procedure crtShowCursor; assembler;
asm
  mov ax, $0100
  mov cx, $0506;
  int $10
end;
{$ELSE}
Procedure crtShowCursor;
begin
end;
{$ENDIF}

{$IFDEF DOS}
Procedure crtHideCursor; assembler;
asm
  mov ax, $0100
  mov cx, $2607;
  int $10
end;
{$ELSE}
Procedure crtHideCursor;
begin
end;
{$ENDIF}

Procedure crtSetCursor(CursorType: Word); assembler;
asm
  mov ax, $0100
  mov cx, CursorType
  int $10
end;

{$IFDEF DOS}
Procedure crtWriteCh(x,y: byte;Ch: char);
begin
  TextMem[Y,X].VChar :=Ch;
  TextMem[Y,X].VAttr :=TextAttr;
end;
{$ELSE}
Procedure crtWriteCh(x,y: byte;Ch: char);
Begin
{$IFNDEF OS2}
  DirectVideo:=True;
{$ENDIF}
  GotoXY(X,Y);
  Write(Ch);
End;
{$ENDIF}

{$IFNDEF X}
Procedure crtWriteStr(x,y,fg,bg:byte;S: string);
Var
  Tel : byte;
  Bak : byte;
Begin
  Bak :=TextAttr;
  TextColor(Fg);
  TextBackGround(Bg);
  For Tel :=1 to length(s) do crtWriteCh(x-1+tel,y,S[Tel]);
  TextAttr :=Bak;
End;
{$ELSE}
Procedure crtWriteStr(x,y,fg,bg:byte;S: string);
Var
  Bak : byte;
Begin
  Bak :=TextAttr;
  TextColor(Fg);
  TextBackGround(Bg);
{$IFNDEF OS2}
  DirectVideo:=True;
{$ENDIF}
  GotoXY(X,Y);
  Write(S);
  TextAttr :=Bak;
End;
{$ENDIF}

Procedure crtWriteParagraph(fg,bg:byte;S:string);
begin
 TextColor(fg);
 TextBackGround(bg);
 Write(#254);
 Write(#32+S);
end;

Procedure crtUnregisteredP;
begin
  Write(#7);
  crtWriteParagraph(3,0,'Unregistered version.');
  WriteLn;
  Delay(5000);
end;

Procedure crtUnregistered;
begin
  Write(#7);
  WriteLn('Unregistered version.');
  WriteLn;
  Delay(5000);
end;

end.