unit GlobalConst;

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

const

  AppName = 'Open FlappyBird';

  WndW = 288;
  WndH = 512;
  ColorDepth = 32;

  Burung_W = 34;
  Burung_H = 24;

  def_dist = 180; //default distance

  // maksimum rotasi yg mungkin
  up_rotasi = -30;
  dw_rotasi = 90;

  grav_turun = 0.025;
  grav_naik  = 0.25;
  max_gnaik  = 1.5;
  x_miring   = up_rotasi / -max_gnaik;

  tbl_pipa = 52;
  maks_pipa = 320;
  intv_pipa = 200;
  horz_pipa_awal = WndW + 200;
  horz_pipa_awal2 = horz_pipa_awal + intv_pipa;
  min_celah = 105;
  max_celah = 120;
  rng_celah = max_celah - min_celah;
  min_ppipa = 30;

  fpx_skor = 230;
  fpy_skor = 235;
  fpy_hskr = 276;

implementation

end.
