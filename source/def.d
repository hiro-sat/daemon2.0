// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.file;
import std.random;
import std.datetime;

// my source
import lib_sdl;
import lib_screen;
import lib_readline;

import cParty;
import cMember;
import cMap;
import cItemDef;

import cMonsterParty;
import cMonsterTeam;
import cMonster;
import cMonsterDef;
import cBattleTurn;


// debug
bool debugmode = false;
bool debugmodeOffFlg = false;


// SDLオブジェクト
MySDL    gsdl;
Screen   scr;
ReadLine readline;

bool rewrite_flg = true;
void rewriteOff(){ rewrite_flg = false; }
void rewriteOn()
{
    rewrite_flg = true;
    scr.disp;
    return;
}

//upredictableSeedによって実行するごとに異なる乱数列を生成できる
/* auto rnd = Random(unpredictableSeed); */         // error ?
Random rnd;

// 実行時ExePath;
string gExePath;

// データ保存用パス
string DATA_FOLDER = "data";

// フォントファイル名
/* string FONTNAME = "resources/mplus-1mn-regular.ttf"; */
string FONTNAME = "resources/mplus-2m-regular.ttf";

// 画面サイズ設定
enum S_FONTSIZE = 16;
enum S_FONT_WIDTH = 8;
enum S_FONT_HEIGHT = 23;
enum S_FONT_J_WIDTH = 16;
enum S_FONT_J_HEIGHT = 23;
enum S_FONT_X_MARGINE = 1;
enum S_FONT_Y_MARGINE = -4;
enum L_FONTSIZE = 24;
enum L_FONT_WIDTH = 12;
enum L_FONT_HEIGHT = 35;
enum L_FONT_J_WIDTH = 24;
enum L_FONT_J_HEIGHT = 35;
enum L_FONT_X_MARGINE = 1;
enum L_FONT_Y_MARGINE = -4;

int FONTSIZE;
int FONT_WIDTH;
int FONT_HEIGHT;
int FONT_J_WIDTH;
int FONT_J_HEIGHT;
int FONT_X_MARGINE;
int FONT_Y_MARGINE;



enum TEXT_WIDTH = 80;
enum TEXT_HEIGHT = 23;

enum WINDOW_TOP_MARGINE = 2;
enum WINDOW_BOTTOM_MARGINE = 4;
enum WINDOW_LEFT_MARGINE = 6;
enum WINDOW_RIGHT_MARGINE = 2;

/* enum WINDOW_WIDTH = ( FONT_WIDTH + FONT_X_MARGINE ) * TEXT_WIDTH */
/*                   + WINDOW_TOP_MARGINE + WINDOW_BOTTOM_MARGINE  */
/*                   + WINDOW_LEFT_MARGINE + WINDOW_RIGHT_MARGINE ; */
/* enum WINDOW_HEIGHT = ( FONT_HEIGHT + FONT_Y_MARGINE ) * TEXT_HEIGHT */
/*                   + WINDOW_TOP_MARGINE + WINDOW_BOTTOM_MARGINE  */
/*                   + WINDOW_LEFT_MARGINE + WINDOW_RIGHT_MARGINE ; */
int WINDOW_WIDTH;
int WINDOW_HEIGHT;


/* display */
enum WIN_X_SIZ  = 78;
enum WIN_Y_SIZ  = SCRW_Y_SIZ + CHRW_Y_SIZ + 2;
enum SCRW_X_TOP = 1;
enum SCRW_Y_TOP = 1;
enum SCRW_X_SIZ = 30;
enum SCRW_Y_SIZ = 15;
enum TXTW_X_TOP = SCRW_X_TOP + SCRW_X_SIZ + 2;
enum TXTW_Y_TOP = SCRW_X_TOP + 1;
enum TXTW_X_SIZ = WIN_X_SIZ - TXTW_X_TOP - 1;
enum TXTW_Y_SIZ = SCRW_Y_SIZ - 2;
enum CHRW_X_SIZ = WIN_X_SIZ;
enum CHRW_Y_SIZ = 7;
enum CHRW_X_TOP = 0;
enum CHRW_Y_TOP = SCRW_Y_TOP + SCRW_Y_SIZ;

/* for text window */
int text_curx, text_cury;
int text_color = CL.NORMAL;
int text_top;
string[ TXTW_Y_SIZ ] text_win_buffer;
int   [ TXTW_Y_SIZ ] text_win_buffer_size;
int   [ TXTW_Y_SIZ ] text_win_buffer_color;

/* text color */
enum CL
{
    NORMAL      = 7,
    NORMAL_DARK = 15,
    MENU        = 3,
    KIND        = 2,
    BONUS       = 2,
    ENCOUNT     = 4,
    TREASURE    = 6,
    MONSTER     = 5,
    TRAP        = 5,
    TRAP_FAIL   = 4
}


/* etc */
enum MAXITEM    = 200;
enum MAXMAGIC   = 100;
enum MAXLAYER   = 10;
enum MAXMONSTER = 150;
enum MAXTRAP    = 9;
enum MAXMEMBER  = 20;
enum MAXCARRY   = 8;
enum AC_UP_SLEEP  = 5; // AC up when sleep, paralized, ...
enum AC_UP_PARRY  = 2; // AC up when player parry
enum S_LIGHT_COUNT  = 100;
enum L_LIGHT_COUNT  = 999;
enum S_SCOPE_COUNT  = 1;
enum L_SCOPE_COUNT  = 20;
//----------------------------------------
// マップ情報
//----------------------------------------
enum MAP_MAX_X = 80;
enum MAP_MAX_Y = 40;
string ORGMAPFILE = "resources/orgmap.";
string MAPFILE = "data/map.";

Map[ MAXLAYER ] dungeonMap;

enum MAP_CL
{
    PARTY    = 2,
    DARKZONE = 1,
    NUL      = 15,
    WALL     = 7,
    WALL2    = 3,
    DOOR     = 2,
    STAIRS   = 5,
    LIGHT    = 6
}



//----------------------------------------
// アイテム情報
//----------------------------------------
string ITEMFILE = "resources/item";
ItemDef[ MAXITEM ] item_data;

//----------------------------------------
// 商店情報
//----------------------------------------
string SHOPFILE = "data/boltac";
int[ MAXITEM ] boltacitem;

//----------------------------------------
// 魔法情報
//----------------------------------------
string MAGICFILE = "resources/magic";
magicdef[ MAXMAGIC ]  magic_data;
struct magicdef {
    string name;
    byte camp; /* 0:can't,1:no target,2:sel mem */
    byte batl; /* 0:can't,1:no target,2:sel mem,3:sel mon */
    byte type; /* 0:etc,1:atk(1),2:atk(gr),3:atk(all),4:HP(1) */
               /* 6:ac+(1),7:ac+(gr),8:ac+(all),9:ac-(1),10,HP(all) */
               /* 11:latumofis, 12:dialko, 13:madi, 14:maporfic */
    byte attr; /* 0:no,1:fire,2:ice,3:small fire,4:undead only */
    short min;
    short add;
}


//----------------------------------------
// モンスター情報
//----------------------------------------
string MONSTERFILE = "resources/monster";

MonsterDef[ MAXMONSTER ]  monster_data;
MonsterParty      monParty;
MonsterTeam[ 4 ]  monTeam;
Monster[ 4 * 9 ]  monster; /* max 4team*9 */
int get_exp;

//----------------------------------------
// モンスターマーク情報
//----------------------------------------
string MARKSFILE = "data/marks";
int[ MAXMONSTER ] monstermarks;

//----------------------------------------
// パーティー情報
//----------------------------------------
Party party;

//----------------------------------------
// プレイヤー情報
//----------------------------------------
string MEMBERFILE = "data/player";
Member[ MAXMEMBER ]  member;
enum MAX_MEMBER_NAME = 20;
enum OUT_F
{
    BAR     = 0,
    CASTLE  = 1,
    DUNGEON = 3
}


//----------------------------------------
// for battle
//----------------------------------------

BattleTurn top_turn, end_turn;
BattleTurn[ 9 * 4 + 6 ] turn;


/*====== CONSTANTS ==============================================*/

/* status */
enum STS
{
    OK       = 0,
    SLEEP    = 1,
    AFRAID   = 2,
    PARALY   = 3,
    STONED   = 4,
    DEAD     = 5,
    ASHED    = 6,
    LOST     = 7 
    /* POISONED = 0x80  /* flag(MSB) */ 
}


/* race */
enum RACE
{
    HUMAN  = 0,
    ELF    = 1,
    DWARF  = 2,
    GNOME  = 3,
    HOBBIT = 4
}

/* class */
enum CLS
{
    FIG = 0,
    THI = 1,
    PRI = 2,
    MAG = 3,
    BIS = 4,
    SAM = 5,
    LOR = 6,
    NIN = 7
}

/* align */
enum ALIGN
{
    GOOD = 0,
    EVIL = 1,
    NEWT = 2
}

/* item kind */
enum ITM_KIND
{
    WEAPON = 0,
    ARMOR  = 1,
    SHIELD = 2,
    HELM   = 3,
    GLOVES = 4,
    ITEM   = 5
}

/* item atack effect */
enum ITM_ATKEF
{
    CRITICAL = 0x80,
    STONE    = 0x40,
    SLEEP    = 0x20,

    HUMAN  = 0x10,
    ANIMAL = 0x8,
    DRAGON = 0x4,
    DEMON  = 0x2,
    INSECT = 0x1
}

/* item deffence effect */
enum ITM_DEFEF
{
    CRITICAL = 0x80,
    STONE    = 0x40,
    PARALIZE = 0x20,
    SLEEP    = 0x10,
    POISON   = 0x8,
    FIRE     = 0x4,
    ICE      = 0x2,
    DRAIN    = 0x1
}


/* range */
enum RANGE
{
    NOT   = 0,
    SHORT = 1,
    LONG  = 2
}

/* action */
enum ACT
{
    FIGHT  = 0,
    PARRY  = 1,
    SPELL  = 2,
    USE    = 3,
    RUN    = 4,
    DISPEL = 5
}

/* attack effect */
enum ATKEF
{
    POISON   = 0x80,
    STONE    = 0x40,
    PARALY   = 0x20,
    SLEEP    = 0x10,
    CRITICAL = 0x8
}

/* defend effect */
enum DEFEF
{
    FIRE  = 0x4,
    COLD  = 0x2,
    SLEEP = 0x1,
    LONG  = 0x80
}

/* magic type */
enum MAG
{
    ATKONE  = 1,    /* attack one monster */
    ATKGRP  = 2,    /* attack group */
    ATKALL  = 3,    /* attack all */
    HEALONE = 4,    /* heal one player */
    ACONE   = 6,    /* increase one monster's AC */
    ACGRP   = 7,    /* increase one monster group's AC */
    ACALL   = 8,    /* increase all monsters' AC */
    ACPONE  = 9,    /* decrease one player's AC */
    HEALALL = 10,   /* heal all */
    CUREPOI = 11,   /* latumofis */
    CUREPAR = 12,   /* dialko */
    MADI    = 13,   /* madi */
    MAPOR   = 14,   /* maporfic */
    KATINO  = 15,   /* katino(gr) */
    MANIFO  = 16,   /* manifo(gr) */
    ACPGR   = 17,   /* decrease player group's AC */
    KANI    = 18,   // kanito(gr)
    MAKANI  = 19,   // makanito(all)
    DI      = 20,   // di
    KADOR   = 21,   // katorto
    BADI    = 22,   // badi(one)
    LABADI  = 23,   // labadi(one)
    LITO    = 24,   // litofeit
    LATUMA  = 25,   // latumapic
    MONTI   = 26,   // montino(gr)
    MAPPER  = 27,   // dumapic
    MILWA   = 28,   // milwa
    LOMILWA = 29,   // lomilwa
    MALOR   = 30,   // malor(xoowgn)
    LOKTO   = 31   // loktofeit(vxvxpow)
}


// header info status 
enum HSTS
{
    DUNGEON  = 0,
    BATTLE   = 1,
    CAMP     = 2,
    CASTLE   = 3,
    EOT      = 4,
    BAR      = 5,
    INN      = 6,
    TEMPLE   = 7,
    SHOP     = 8,
    TRAINING = 9
}

// encount treasure
enum TRE
{
    GOLD     = 0,
    TREASURE = 1,
    ALARM    = 2
}

// battle result
enum BATTLE_RESULT
{
    WON  = 1,
    RAN  = 2,
    LOST = 3
}

// Monster type
enum MON_TYPE
{
    ETC   = 0,  // other type(friendly ratio=50%)
    FIG   = 1,  // fighter(friendly ratio=10%)
    MAG   = 2,  // mage(friendly ratio=5%)
    PRI   = 3,  // priest(friendly ratio=15%)
    THI   = 4,  // thief(friendly ratio=3%)
    SHUM  = 5,  // small humanoid(friendly ratio=30%)
    DRA   = 6,  // dragon(friendly ratio=25%)
    ANML  = 7,  // animal
    UND   = 8,  // undead
    FAIRY = 9,  // fairy
    MAGIC = 10, // magic
    INS   = 11, // insect
    GIA   = 12, // giant
    DEM   = 13, // demon
    GOD   = 14  // god
}


// Monster status
enum MON_STS
{
    OK       = 0,
    SLEEP    = 1,
    PARALIZE = 2,
    STONED   = 3
}

/* monster action */
enum MON_ACT
{
    RUN      = 1,    /* run away */
    HLP      = 2,    /* help */
    BRT      = 3,    /* breath */
    ATK_ATK  = 0x10, /* attack no effect */
    ATK_SLS  = 0x11, /* slash no effect */
    ATK_TCH  = 0x12, /* touch no effect */
    ATK_BIT  = 0x13, /* bite no effect */

    // with effect
    WITH_EFEECT_ST = 0x20,
    ATK_ATKE = 0x20, /* attack with effect */
    ATK_SLSE = 0x21, /* slash with effect */
    ATK_TCHE = 0x22, /* touch with effect */
    ATK_BITE = 0x23, /* bite with effect */
    WITH_EFEECT_ED = 0x30,
}


/* magic type */
enum MAG_TYPE
{
    ATKONE  = 1  ,   /* attack one monster */
    ATKGRP  = 2  ,   /* attack group */
    ATKALL  = 3  ,   /* attack all */
    HEALONE = 4  ,   /* heal one player */
    ACONE   = 6  ,   /* increase one monster's AC */
    ACGRP   = 7  ,   /* increase one monster group's AC */
    ACALL   = 8  ,   /* increase all monsters' AC */
    ACPONE  = 9  ,   /* decrease one player's AC */
    HEALALL = 10 ,   /* heal all */
    CUREPOI = 11 ,   /* latumofis */
    CUREPAR = 12 ,   /* dialko */
    MADI    = 13 ,   /* madi */
    MAPOR   = 14 ,   /* maporfic */
    KATINO  = 15 ,   /* katino(gr) */
    MANIFO  = 16 ,   /* manifo(gr) */
    ACPGR   = 17 ,   /* decrease player group's AC */
    KANI    = 18 ,   // kanito(gr)
    MAKANI  = 19 ,   // makanito(all)
    DI      = 20 ,   // di
    KADOR   = 21 ,   // katorto
    BADI    = 22 ,   // badi(one)
    LABADI  = 23 ,   // labadi(one)
    LITO    = 24 ,   // litofeit
    LATUMA  = 25 ,   // latumapic
    MONTI   = 26 ,   // montino(gr)
    MAPPER  = 27 ,   // dumapic
    MILWA   = 28 ,   // milwa
    LOMILWA = 29 ,   // lomilwa
    MALOR   = 30 ,   // malor(xoowgn)
    LOKTO   = 31     // loktofeit(vxvxpow)
}

/* trap name */
enum TRAP
{
    NO         = 0,
    POISON     = 1,
    GASBOMB    = 2,
    CROSSBOW   = 3,
    EXPLODING  = 4,
    STUNNER    = 5,
    TELEPORT   = 6,
    MAGBLASTER = 7,
    PRIBLASTER = 8,
    ALARM      = 9
}
string[ MAXTRAP + 1 ] TRAP_NAME;

