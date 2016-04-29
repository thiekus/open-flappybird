program OpenFBird;

(*==============================================================================

  Open FlappyBird - Clone by Faris Khowarizmi
  Copyright © Khayalan Software 2014.
  Copyright © initial developer of FlappyBird - for it's graphics and sfx.

  email: thekill96@gmail.com
  website: http://www.khayalan.web.id

  This code available under GNU General Public License (GPL) version 2
  See COPYING file that shipped with this application

==============================================================================*)

{$IFDEF FPC}
// delphi compability mode
{$MODE DELPHI}
{$ENDIF}
{$IFDEF MSWINDOWS}
// use delphi resource
{$R *.RES}
{$ENDIF}

uses
  SysUtils,
  zgl_main,
  zgl_screen,
  zgl_window,
  zgl_timers,
  GameGlobal in 'GameGlobal.pas',
  GlobalConst in 'GlobalConst.pas',
  GlobalTypes in 'GlobalTypes.pas',
  AppUtils in 'AppUtils.pas';

//==============================================================================

procedure CounterTimer;
begin
  wnd_SetCaption(AnsiToUTF8(Format('%s [%d]', [AppName, zgl_Get(RENDER_FPS)])));
end;

//==============================================================================

procedure BacaParameter;
var
  i: integer;
  par: string;
begin
  zgl_Disable(APP_USE_LOG);
  scr_SetVSync(TRUE);
  zgl_Enable(SND_CAN_PLAY);
  if ParamCount > 0 then
    for i:= 1 to ParamCount do
      begin
      par:= ParamStr(i);
      if par = '-log' then
        zgl_Enable(APP_USE_LOG)
      else
      if par = '-nvs' then
        scr_SetVSync(FALSE)
      else
      if par = '-nos' then
        zgl_Disable(SND_CAN_PLAY);
    end;
end;

begin

  // tambah timer fps
  timer_Add(@CounterTimer, 1000);

  zgl_Reg(SYS_LOAD, @GameInit);
  zgl_Reg(SYS_DRAW, @GameDraw);
  zgl_Reg(SYS_UPDATE, @GameUpdate);
  zgl_Reg(SYS_EXIT, @GameExit);

  wnd_SetCaption(AppName);
  wnd_ShowCursor(TRUE);
  scr_SetOptions(WndW, WndH, REFRESH_MAXIMUM, FALSE, TRUE);

  BacaParameter;
  zgl_Init();

end.
