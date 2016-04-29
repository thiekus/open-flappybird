unit GameGlobal;

(*==============================================================================

  Open FlappyBird - Clone by Faris Khowarizmi
  Copyright © Khayalan Software 2014.
  Copyright © initial developer of FlappyBird - for it's graphics and sfx.

  email: thekill96@gmail.com
  website: http://www.khayalan.web.id

  This code available under GNU General Public License (GPL) version 2
  See COPYING file that shipped with this application

==============================================================================*)

interface

uses
  SysUtils, GlobalConst, GlobalTypes, AppUtils,
  // ZenGL units
  zgl_main, zgl_screen, zgl_window, zgl_timers, zgl_keyboard, zgl_mouse, zgl_textures,
  zgl_textures_png, zgl_font, zgl_text, zgl_primitives_2d, zgl_sprite_2d, zgl_File,
  zgl_Memory, zgl_utils, zgl_sound, zgl_sound_wav, zgl_sound_ogg, zgl_collision_2d,
  zgl_math_2d, zgl_log;

procedure GameInit;
procedure GameDraw;
procedure GameUpdate(dt: Double);
procedure GameExit;

var

  skor, hskor: integer;
  IsHskor: boolean;
  ofbscr: File;

  // texture dlm game
  BgLatar: array[0..2] of zglPTexture;
  Medals: array[0..3] of zglPTexture;
  TxTanah: zglPTexture;
  TxTitle: zglPTexture;
  TxCopyr: zglPTexture;
  TxReady: zglPTexture;
  TxGameo: zglPTexture;
  ScrNew: zglPTexture;
  ScrHint: zglPTexture;
  ScrOver: zglPTexture;
  TblPlay: zglPTexture;
  PipaAtas: zglPTexture;
  PipaBawah: zglPTexture;
  Burungs: TListBurung;

  bg_skr: integer;
  Pipas: array[0..1] of TPipa;
  pipa_mxt: integer;
  pipenum: integer;

  fnt_fb : zglPFont;
  fnt_fbs: zglPFont;

  TickCnt: Int64;
  tc_rd, tc_nd: Int64;

  // Sound Effect a.k.a SFX
  sfx_die: zglPSound;
  sfx_hit: zglPSound;
  sfx_point: zglPSound;
  sfx_swooshing: zglPSound;
  sfx_wing: zglPSound;

  // Untuk tanah
  tnh_iw, tnh_ih: integer;
  tnh_mtw, tnh_jln: integer;
  tnh_pmk: integer;

  // Untuk burung
  brg_jgt: integer;  // efek pengaruh gerak burung, min = -3; max = 3
  brg_jga: boolean;  // kalo true, goncangan burung ke atas, & sebaliknya
  brg_idx: integer;  // warna burung yg dipilih
  brg_syp: integer;  // posisi sayap 0-2 (3 bentuk)
  brg_dist: single;  // ketinggian burung saat ini
  brg_grav: single;  // gravitasi burung
  brg_mjmp: single;  // kemampuan loncat berkali-kali
  brg_naik: boolean; // kalo true, berarti gravitasi burung naik
  brg_xmod: integer; // posisi x burung
  brg_colb: integer; // posisi maksimum burung tabrakan dimana burung mencapai tanah
  brg_mati: boolean; // burung udah wafat

  // look & feel
  alphav: byte; // value alpha
  alpham: boolean; // status kalo alpha value lagi dimodif

  // status handler
  mulai    : boolean; // kalo true, game udah dimulai atau udah main
  siapmain : boolean; // kalo true, status lagi "Get Ready"
  gameover : boolean; // permainan berakhir :D
  siapmenu : boolean; // jeda antara matinya burung dengan pemunculan menu
  restmenu : boolean; // true, menu akhir ditampilkan

implementation

//==============================================================================

procedure TickGenerator;
begin
  TickCnt:= TickCnt + 1;
end;

procedure TulisSkor(skor: integer);
var
  skfile: TScoreFile;
  chk: Cardinal;
begin
  chk:= 0;
  CalcCRC32(@skor, 4, chk);
  skfile.Skor:= skor;
  skfile.Checksum:= chk;
  {$I-}
  Rewrite(ofbscr, 1);
  BlockWrite(ofbscr, skfile, SizeOf(TScoreFile));
  log_add(Format('Write high score data: score %d CRC32 0x%s', [skor, IntToHex(chk, 8)]));
  {$I+}
end;

function BacaSkor: integer;
var
  skfile: TScoreFile;
  sk: integer;
  chk: Cardinal;
begin
  {$I-}
  Reset(ofbscr, 1);
  BlockRead(ofbscr, skfile, SizeOf(TScoreFile));
  log_add(Format('Read high score data: score %d CRC32 0x%s', [skfile.Skor, IntToHex(skfile.Checksum, 8)]));
  {$I+}
  sk:= skfile.Skor;
  chk:= 0;
  CalcCRC32(@sk, 4, chk);
  if chk = skfile.Checksum then
    Result:= skfile.Skor
  else
    Result:= 0;
end;

procedure BuatUlangPipa(idx: integer; ulang: boolean);

  function PipaRect(X, Y, W, H: Single): zglTRect;
  begin
    Result:= BuatRect(X, Y, W, H);
    log_add(Format('Pipe: rect x=%f; y=%f; w=%f; h=%f', [X, Y, W, H]));
  end;

var
  nexp: integer;
begin

  Inc(pipenum);
  log_add(Format('Pipe: Setting for pipe no %d', [pipenum]));
  if ulang then
    log_add('Pipe: ReCreate')
  else
    log_add('Pipe: Create');
  Randomize;
  Pipas[idx].CelahPipa:= Random(rng_celah)+min_celah;
  log_add(Format('Pipe: GapSize=%d', [Pipas[idx].CelahPipa]));
  Randomize;
  Pipas[idx].PanjangPipaAtas:= Random(pipa_mxt-Pipas[idx].CelahPipa)+min_ppipa;
  log_add(Format('Pipe: TopSize=%d', [Pipas[idx].PanjangPipaAtas]));

  if idx = 0 then
    nexp:= 1
  else
    nexp:= 0;
  if ulang then
    Pipas[idx].PosisiHorz:= Pipas[nexp].PosisiHorz + intv_pipa
  else
    begin
    if idx = 0 then
      Pipas[idx].PosisiHorz:= horz_pipa_awal
    else
      Pipas[idx].PosisiHorz:= horz_pipa_awal2;
  end;

  log_add('Pipe: Create new top pipe');
  Pipas[idx].ColAtas:= PipaRect(Pipas[idx].PosisiHorz, -(maks_pipa - Pipas[idx].PanjangPipaAtas), tbl_pipa, maks_pipa);
  log_add('Pipe: Create new bottom pipe');
  Pipas[idx].ColBawah:= PipaRect(Pipas[idx].PosisiHorz, (Pipas[idx].PanjangPipaAtas + Pipas[idx].CelahPipa), tbl_pipa, maks_pipa);
  log_add('Pipe: Create new pipe gap');
  Pipas[idx].ColInside:= PipaRect(Pipas[idx].PosisiHorz, Pipas[idx].PanjangPipaAtas, tbl_pipa, Pipas[idx].CelahPipa);
  Pipas[idx].Dilewati:= FALSE;

  log_add(Format('Pipe: End of pipe no %d', [pipenum]));

end;

procedure EfekJalanTanah;
var
  i: integer;
begin

  if not gameover then
    begin

    Inc(tnh_jln);
    if tnh_jln > tnh_mtw then
      tnh_jln:= 0;

    if mulai then
      for i:= 0 to 1 do
        begin
        Dec(Pipas[i].PosisiHorz);
        Pipas[i].ColAtas.X:= Pipas[i].ColAtas.X - 1;
        Pipas[i].ColAtas.W:= Pipas[i].ColAtas.W - 1;
        Pipas[i].ColBawah.X:= Pipas[i].ColBawah.X - 1;
        Pipas[i].ColBawah.W:= Pipas[i].ColBawah.W - 1;
        Pipas[i].ColInside.X:= Pipas[i].ColInside.X - 1;
        Pipas[i].ColInside.W:= Pipas[i].ColInside.W - 1;
        if Pipas[i].PosisiHorz < -tbl_pipa then
          BuatUlangPipa(i, TRUE);
      end;

  end;

end;

procedure EfekJalanBurung;
begin

  if not gameover then
    begin

    if brg_jga then
      begin
      Dec(brg_jgt);
      if brg_jgt <= -3 then
        brg_jga:= FALSE;
    end
    else
      begin
      Inc(brg_jgt);
      if brg_jgt >= 3 then
        brg_jga:= TRUE;
    end;

    brg_syp:= (brg_jgt div 2) + 1;

  end;

end;

procedure GravitasiBurung;
begin

  if (mulai) then
    begin
    brg_grav:= brg_grav+grav_turun; // gravitasi turun
    if (brg_naik) and (not gameover) then
      begin
      brg_grav:= brg_grav-grav_naik;
      if brg_grav < -max_gnaik then
        begin
        brg_mjmp:= brg_mjmp-max_gnaik;
        brg_naik:= FALSE;
      end;
    end;
    if tnh_pmk > brg_dist+Burung_H then
      brg_dist:= brg_dist+brg_grav
    else
    if not(brg_mati) and (gameover) then
      begin
      snd_Play(sfx_die);
      brg_mati:= TRUE;
    end;
  end;

end;

procedure PosisiBurung(var tinggi, rotasi: single);
var
  trot: single;
begin

  if mulai then
    begin
    tinggi:= brg_dist;
    trot:= brg_grav * x_miring;
    if trot < dw_rotasi then
      rotasi:= trot
    else
      rotasi:= dw_rotasi;
  end
  else
    begin
    tinggi:= def_dist+brg_jgt;
    rotasi:= 0;
  end;

end;

procedure ModifyAlpha;
begin

  if alpham then
    begin
    Inc(alphav);
    if alphav >= 255 then
      alpham:= FALSE;
  end;

end;

procedure AcakGaya;
begin
  log_add('Style: Randomize style');
  Randomize;
  bg_skr:= Random(3);
  log_add(Format('Style: Background index %d', [bg_skr]));
  Randomize;
  brg_idx:= Random(3);
  log_add(Format('Style: Bird index %d', [brg_idx]));
end;

procedure BagianAwal;
begin

  log_add('Creating new game...');
  skor:= 0;
  IsHskor:= FALSE;

  alphav:= 0;
  alpham:= TRUE;
  brg_mati:= FALSE;
  brg_naik:= FALSE;
  brg_dist:= def_dist;
  brg_grav:= 0;
  brg_mjmp:= 0;

  pipenum:= 0;
  BuatUlangPipa(0, FALSE);
  BuatUlangPipa(1, FALSE);

  mulai:= FALSE;
  siapmain:= FALSE;
  gameover:= FALSE;
  restmenu:= FALSE;

  AcakGaya;
  log_add('New game creation end!');

end;

//=== Inisialisasi game ========================================================

procedure GameInit;
var
  DirApp, scrfile: string;
begin

  DirApp:= PChar(zgl_Get(DIRECTORY_APPLICATION));
  scrfile:= DirApp+'ofbscr.dat';
  AssignFile(ofbscr, scrfile);
  log_add(Format('Assign score data: %s', [scrfile]));
  if FileExists(scrfile) then
    Reset(ofbscr)
  else
    Rewrite(ofbscr);

  // Inisialisasi sound system
  snd_Init();

  TickCnt:= 0;
  timer_Add(@TickGenerator, 1);

  // buka file zip
  file_OpenArchive(DirApp+'assets.zip');
  // load tekstur latar dan tulisan
  BgLatar[0]:= tex_LoadFromFile('assets/gfx/bg_siang.png');
  BgLatar[1]:= tex_LoadFromFile('assets/gfx/bg_sore.png');
  BgLatar[2]:= tex_LoadFromFile('assets/gfx/bg_malam.png');
  TxTanah:= tex_LoadFromFile('assets/gfx/tanah.png');
  TxTitle:= tex_LoadFromFile('assets/gfx/title.png');
  TxCopyr:= tex_LoadFromFile('assets/gfx/cpyrght.png');
  TxReady:= tex_LoadFromFile('assets/gfx/ready.png');
  TxGameo:= tex_LoadFromFile('assets/gfx/gameover.png');
  ScrNew:= tex_LoadFromFile('assets/gfx/nskor.png');
  ScrHint:= tex_LoadFromFile('assets/gfx/tap_scr.png');
  ScrOver:= tex_LoadFromFile('assets/gfx/scform.png');
  TblPlay:= tex_LoadFromFile('assets/gfx/tbl_play.png');
  PipaAtas:= tex_LoadFromFile('assets/gfx/pipa_ijo_atas.png');
  PipaBawah:= tex_LoadFromFile('assets/gfx/pipa_ijo_bawah.png');
  Medals[0]:= tex_LoadFromFile('assets/gfx/med_bronze.png');
  Medals[1]:= tex_LoadFromFile('assets/gfx/med_silver.png');
  Medals[2]:= tex_LoadFromFile('assets/gfx/med_gold.png');
  Medals[3]:= tex_LoadFromFile('assets/gfx/med_platinum.png');
  // load tekstur untuk burungnya
  Burungs[0][0]:= tex_LoadFromFile('assets/gfx/b_kuning_0.png');
  Burungs[0][1]:= tex_LoadFromFile('assets/gfx/b_kuning_1.png');
  Burungs[0][2]:= tex_LoadFromFile('assets/gfx/b_kuning_2.png');
  Burungs[1][0]:= tex_LoadFromFile('assets/gfx/b_biru_0.png');
  Burungs[1][1]:= tex_LoadFromFile('assets/gfx/b_biru_1.png');
  Burungs[1][2]:= tex_LoadFromFile('assets/gfx/b_biru_2.png');
  Burungs[2][0]:= tex_LoadFromFile('assets/gfx/b_merah_0.png');
  Burungs[2][1]:= tex_LoadFromFile('assets/gfx/b_merah_1.png');
  Burungs[2][2]:= tex_LoadFromFile('assets/gfx/b_merah_2.png');
  // load sound effect (sfx)
  sfx_die:= snd_LoadFromFile('assets/sfx/sfx_die.ogg');
  sfx_hit:= snd_LoadFromFile('assets/sfx/sfx_hit.ogg');
  sfx_point:= snd_LoadFromFile('assets/sfx/sfx_point.ogg');
  sfx_swooshing:= snd_LoadFromFile('assets/sfx/sfx_swooshing.ogg');
  sfx_wing:= snd_LoadFromFile('assets/sfx/sfx_wing.ogg');
  // load font
  fnt_fbs:= font_LoadFromFile('assets/fonts/FBStyle-14pt.zfi');
  fnt_fb:= font_LoadFromFile('assets/fonts/FBStyle-36pt.zfi');

  // jangan lupa tutup arsip
  file_CloseArchive();

  tnh_iw:= TxTanah^.Width;
  tnh_ih:= TxTanah^.Height;
  tnh_mtw:= tnh_iw-WndW;
  tnh_jln:= 0;
  tnh_pmk:= WndH-tnh_ih;

  pipa_mxt:= WndH - (tnh_ih+min_ppipa*2);

  brg_xmod:= (WndW-Burung_W) div 4;
  brg_jgt:= 0;
  brg_jga:= FALSE;
  brg_colb:= WndH-(tnh_ih+Burung_H);

  timer_Add(@EfekJalanTanah, 8); // tiap 8 milidetik tekstur tanah maju 1 pixel
  timer_Add(@EfekJalanBurung, 45); // efek goyangan burung...
  timer_Add(@GravitasiBurung, 5); // timer perubahan gravitasi
  timer_Add(@ModifyAlpha, 5);

  log_add('Initialization finish!');
  BagianAwal;

end;

//=== Penggambaran utama =======================================================

procedure GameDraw;
var
  b_dist, b_rot: single;
  fcx: integer;
  sks: string;
  x: integer;
  sk, sh: single;
begin

  PosisiBurung(b_dist, b_rot);

  // penggambaran latar
  ssprite2d_Draw(BgLatar[bg_skr], 0, 0, WndW, WndH, 0, alphav);
  // penggambaran pipa
  if mulai then
    for x:= 0 to 1 do
      begin
      ssprite2d_Draw(PipaAtas, Pipas[x].PosisiHorz, Pipas[x].ColAtas.Y, tbl_pipa, maks_pipa, 0);
      ssprite2d_Draw(PipaBawah, Pipas[x].PosisiHorz, Pipas[x].ColBawah.Y, tbl_pipa, maks_pipa, 0);
    end;
  // penggambaran tanah
  ssprite2d_Draw(TxTanah, -tnh_jln, WndH-tnh_ih, tnh_iw, tnh_ih, 0, alphav);
  // penggambaran burung
  ssprite2d_Draw(Burungs[brg_idx][brg_syp], brg_xmod, b_dist, Burung_W, Burung_H, b_rot, alphav);

  if not mulai then
    begin
    if siapmain then
      ssprite2d_Draw(TxReady, (WndW-186) div 2, 96, 186, 48, 0, alphav)
    else
      begin
      ssprite2d_Draw(TxTitle, (WndW-178) div 2, 48, 178, 64, 0, alphav);
      ssprite2d_Draw(TxCopyr, (WndW-180) div 2, WndH-60, 180, 30, 0, alphav);
      ssprite2d_Draw(ScrHint, (WndW-113) div 2, 180, 113, 98, 0, alphav);
    end;
  end
  else
  if brg_mati then
    begin
    ssprite2d_Draw(TxGameo, (WndW-193) div 2, 96, 193, 46, 0, alphav);
  end;
  if (siapmain) or (mulai) then
    begin
    sks:= IntToStr(skor);
    fcx:= Round((WndW-text_GetWidth(fnt_fb, sks)) / 2);
    text_DrawEx(fnt_fb, fcx+3, 19, 1, 0, sks, $FF, $000000);
    text_Draw(fnt_fb, fcx, 16, sks);
  end;

  if (restmenu) then
    begin

    ssprite2d_Draw(ScrOver, (WndW-228) div 2, (WndH-116) div 2, 228, 116, 0, alphav);
    if skor >= 300 then
      ssprite2d_Draw(Medals[3], 58, 240, 44, 44, 0)
    else
    if skor >= 100 then
      ssprite2d_Draw(Medals[2], 58, 240, 44, 44, 0)
    else
    if skor >= 50 then
      ssprite2d_Draw(Medals[1], 58, 240, 44, 44, 0)
    else
    if skor >= 10 then
      ssprite2d_Draw(Medals[0], 58, 240, 44, 44, 0);

    if IsHSkor then
      ssprite2d_Draw(ScrNew, 58, 240, 32, 14, 0);

    sk:= text_GetWidth(fnt_fbs, sks);
    text_Draw(fnt_fbs, fpx_skor-sk, fpy_skor, sks);

    sks:= IntToStr(hskor);
    sh:= text_GetWidth(fnt_fbs, sks);
    text_Draw(fnt_fbs, fpx_skor-sh, fpy_hskr, sks);

    ssprite2d_Draw(TblPlay, (WndW-104) div 2, 320, 104, 58, 0);

  end;

end;

//=== Update status game =======================================================

procedure GameUpdate(dt: Double);
var
  brg_rc: zglTRect;
  tbl_rc: zglTRect;
  x: integer;
begin

  if not gameover then
    begin

    // deteksi tabrakan
    if mulai then
      begin
      brg_rc:= BuatRect(brg_xmod, brg_dist, Burung_W-2, Burung_H-2);
      if (tnh_pmk <= brg_dist+Burung_H) or
         DeteksiTabrakan(Pipas[0].ColAtas, brg_rc) or
         DeteksiTabrakan(Pipas[0].ColBawah, brg_rc) or
         DeteksiTabrakan(Pipas[1].ColAtas, brg_rc) or
         DeteksiTabrakan(Pipas[1].ColBawah, brg_rc) then
        begin
        gameover:= TRUE;
        log_add(Format('End with score %d', [skor]));
        hskor:= BacaSkor;
        if skor > hskor then
          begin
          TulisSkor(skor);
          IsHSkor:= TRUE;
          hskor:= skor;
        end;
        snd_Play(sfx_hit);
      end
      else
      for x:= 0 to 1 do
        if DeteksiCelah(Pipas[x].ColInside, brg_rc) and not(Pipas[x].Dilewati) then
          begin
          Pipas[x].Dilewati:= TRUE;
          Inc(skor);
          log_add(Format('Enter pipe gap no %d', [skor]));
          snd_Play(sfx_point);
        end;
    end;

    if mouse_Click(0) or key_Press(K_SPACE) then // mouse klik kiri atau spasi
      begin
      if (mulai) then
        begin
        brg_naik:= TRUE; // burung dinaikan
        brg_mjmp:= brg_mjmp+max_gnaik;
        GravitasiBurung;
        snd_Play(sfx_wing);
      end
      else
      if (not siapmain) then
        begin
        tc_rd:= Int64(TickCnt);
        brg_dist:= def_dist+brg_jgt;
        siapmain:= TRUE;
        snd_Play(sfx_swooshing);
      end;

    end;

    if (siapmain) and (not mulai) then
      begin
      if TickCnt-tc_rd >= 3000 then
        begin
        siapmain:= FALSE;
        mulai:= TRUE;
        snd_Play(sfx_swooshing);
      end;
    end;

    if (not mulai) and (not siapmain) then
      begin
      if key_Press(K_LEFT) then
        begin
        Dec(brg_idx);
        if brg_idx < 0 then
          brg_idx:= 2;
      end
      else
      if key_Press(K_RIGHT) then
        begin
        Inc(brg_idx);
        if brg_idx > 2 then
          brg_idx:= 0;
      end
      else
      if key_Press(K_UP) then
        begin
        Inc(bg_skr);
        if bg_skr > 2 then
          bg_skr:= 0;
      end
      else
      if key_Press(K_DOWN) then
        begin
        Dec(bg_skr);
        if bg_skr < 0 then
          bg_skr:= 2;
      end;
    end;

  end

  else
    begin
    if restmenu then
      begin
      tbl_rc.X := (WndW-104) div 2;
      tbl_rc.Y := 320;
      tbl_rc.W := 104;
      tbl_rc.H := 58;
      if (mouse_Click(0)) and (col2d_PointInRect(mouse_X, mouse_Y, tbl_rc)) then
        BagianAwal;
    end
    else
    if brg_mati then
      begin
      if siapmenu then
        begin
        if TickCnt-tc_nd >= 2000 then
          begin
          restmenu:= TRUE;
          siapmenu:= FALSE;
          snd_Play(sfx_swooshing);
        end;
      end
      else
        begin
        tc_nd:= TickCnt;
        siapmenu:= TRUE;
      end;
    end;

  end;

  if key_Press(K_ESCAPE) then
    zgl_Exit()
  else
  if key_Press(K_BACKSPACE) then
    BagianAwal;

  mouse_ClearState();
  key_ClearState();

end;

//==== Kalau game di exit ======================================================

procedure GameExit;
begin

  CloseFile(ofbscr);
  log_add('Close score data');

end;

end.
