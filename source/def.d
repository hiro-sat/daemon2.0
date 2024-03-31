// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.file;
import std.random;
import std.datetime;

// dub
import mofile;

// my source
import lib_sdl;
import lib_screen;
import lib_readline;

import ctextarea;

import ccastle;
import cedgeoftown;
import cdungeon;
import cbattle;

import cparty;
import cmember;
import cmap;
import citem_def;
import cmagic_def;

import cmonster_party;
import cmonster_team;
import cmonster;
import cmonster_def;
import cmonster_encount;
import cbattleturnmanager;

// json設定ファイル
string JSONFILE = "resources/daemon.json";
const AUTOSAVE = "autosave";
const INPUT_TRAPNAME = "inputtrapname";
bool autosave       = false;
bool inputTrapName  = false;

// 言語ファイル
string LANGUAGEFILE = "resources/%1.mo";

// gettext
alias gettext _;
alias ngettext N_;
MoFile moFile;
string gettext( string s  ) { return moFile.gettext( s ); }
string ngettext( string s1 , string s2 , int i ) 
                        { return moFile.ngettext( s1 , s2 , i ); }

//----------------------------------------
// scene
//----------------------------------------
Castle sceneCastle;
Dungeon sceneDungeon;
EdgeOfTown sceneEdgeOfTown;
Battle sceneBattle;




// debug
bool debugmode = false;
bool debugmodeOffFlg = false;


// SDLオブジェクト
MySDL    gsdl;
Screen   scr;
ReadLine readline;
ReadLine readline_spell;

enum FPS=60;

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
enum XS_FONTSIZE = 16 / 2;
enum XS_FONT_WIDTH = 8 / 2;
enum XS_FONT_HEIGHT = 15;
enum XS_FONT_J_WIDTH = 16 / 2;
enum XS_FONT_J_HEIGHT = 15;
enum XS_FONT_X_MARGINE = 1;
enum XS_FONT_Y_MARGINE = -4;
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

enum SCRW_X_SIZ = 79;
enum SCRW_Y_SIZ = 15;
enum SCR_X_MARGIN = 15;
enum SCR_Y_MARGIN = 5;

enum TXTW_X_TOP = 33;
enum TXTW_Y_TOP = 2;
enum TXTW_X_SIZ = 44;
enum TXTW_Y_SIZ = 13;

enum STSW_X_TOP = 1;
enum STSW_Y_TOP = 1;
enum STSW_X_SIZ = 31;
enum STSW_Y_SIZ = 15;

enum CHRW_X_SIZ = WIN_X_SIZ;
enum CHRW_Y_SIZ = 7;
enum CHRW_X_TOP = 0;
enum CHRW_Y_TOP = SCRW_Y_TOP + SCRW_Y_SIZ;

enum MAPMSG_X_SIZ = 30;
enum MAPMSG_Y_SIZ = 1;
enum MAPMSG_X_MARGIN = 3;
enum MAPMSG_Y_MARGIN = 3;

enum EVENT_X_SIZ = 44;
enum EVENT_Y_SIZ = 6;
enum EVENT_X_MARGIN = 1;
enum EVENT_Y_MARGIN = 1;

/* textarea */
Textarea txtMessage;
Textarea txtStatus;
int text_color;




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
    TRAP_FAIL   = 4,
    CANT_SPELL  = 15,
    GOLD        = 6,
    EQUIP_OK    = 7,
    EQUIP_NG    = 15,
}


/* etc */
enum MAXITEM    = 200;
enum MAXMAGIC   = 100;
enum MAXMONSTER = 150;
enum MAXTRAP    = 9;
enum MAXMEMBER  = 25;   // a-y
enum MAXCARRY   = 8;
enum AC_UP_SLEEP  = 5; // AC up when sleep, paralized, ...
enum AC_UP_PARRY  = 2; // AC up when player parry
enum S_LIGHT_COUNT  = 30;
enum L_LIGHT_COUNT  = 25;    // x Level
enum MAX_LIGHT_COUNT  = 800;
enum S_SCOPE_COUNT  = 25;    // x Level
/* enum L_SCOPE_COUNT  = 30; */
enum MAX_SCOPE_COUNT  = 800;
enum CORPSE_X_RANGE = 5;
enum CORPSE_Y_RANGE = 2;

enum ENCOUNT_RATE             = 95;  // 1/95
enum ENCOUNT_RATE_STOP        = 64;  // 1/xx    立ち止まっているとき
enum ENCOUNT_RATE_DOOR        = 10;  // 1/xx    ドアくぐる
enum ENCOUNT_RATE_CORNER      = 25;  // 1/xx    曲がり角
enum ENCOUNT_RATE_DARKZONE    = 128;  // 1/xx   ダークゾーン
//----------------------------------------
// マップ情報
//----------------------------------------
int    MAXLAYER;    // readMapAll で設定。orgmap.xx がある数で設定される。
string ORGMAPFILE = "resources/mapdata/orgmap.%1";
string ORGMAPJSON = "resources/mapdata/orgmap.%1.json";
string MAPFILE = "data/map.%1";

Map[] dungeonMap;

enum MAP_CL
{
    PARTY    = 2,
    DARKZONE = 21,
    NUL      = 20,
    WALL     = 3,
    WALL2    = 7,
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
int[ MAXITEM ] shopitem;

//----------------------------------------
// 魔法情報
//----------------------------------------
string MAGICFILE = "resources/magic";
/* magicdef[ MAXMAGIC ]  magic_data; */
MagicDef[ string ]  magic_all;
MagicDef[ string ]  magic_mag;
MagicDef[ string ]  magic_prt;

string SPELL_INSPECT = "inspct";
enum TYPE_MAGIC
{
    mage = 0,
    priest = 1
}
enum TYPE_MAGIC_CAMPMODE
{
    cant = 0,
    notarget = 1,
    player = 2,
}
enum TYPE_MAGIC_BATTLEMODE
{
    cant = 0,
    notarget = 1,
    player = 2,
    monster = 3,
}

enum TYPE_MAGIC_ATTRIBUTE
{
    no = 0,
    fire = 1,
    ice = 2,
    smallfire = 3,
    undead = 4
}




//----------------------------------------
// モンスター情報
//----------------------------------------
string MONSTERFILE = "resources/monster";

MonsterDef[ MAXMONSTER ]  monster_data;
MonsterParty      monParty;
enum MAX_MONSTER_TEAM   = 4;
enum MAX_MONSTER_MEMBER = 9;
/* MonsterTeam[ 4 ]  monTeam; */
/* Monster[ 4 * 9 ]  monster; /* max 4team*9 */ 

string MONSTER_SPELL_METHOD = "monsterCastSpell";   // traits で使いたいけどエラー

MonsterEncountTable[ string ]   encountTable;
string ENC_TBL_SP = "s";
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
enum MAX_MEMBER_NAME = 15;
enum OUT_F
{
    BAR     = 0,
    CASTLE  = 1,
    DUNGEON = 3
}


//----------------------------------------
// for battle
//----------------------------------------
BattleTurnManager battleManager;
bool messageNoWait = false;
enum MESSAGE_NO_WAIT = 30;

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
    LOST     = 7,
    NIL      = 8 
    /* POISONED = 0x80  /* flag(MSB) */ 
}

enum STS_CL
{
    OK       = 7,   // WHITE
    SLEEP    = 1,   // BLUE
    AFRAID   = 30,   // BLUE     0,73.132
    PARALY   = 31,   // yellow   189,186,0
    STONED   = 32,   // GLAY     139,136,136
    /* DEAD     = 4,   // RED */
    DEAD     = 33,   // DARK RED
    ASHED    = 34,  // GLAY     83,83,83
    LOST     = 35,  // GLAY     50,50,50
    NIL      = 36,  // GLAY     30,30,30
    POISONED = 5    // PURPLE
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
    fight  = 0,
    parry  = 1,
    spell  = 2,
    use    = 3,
    run    = 4,
    dispel = 5,
    magic  = 6
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
HSTS now_mode;

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
    WON   = 1,
    RAN   = 2,
    LOST  = 3,
    LEAVE = 4
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
	MGC      = 4,    /* magic */
    ATK_ATK  = 10, /* attack no effect */
    ATK_SLS  = 11, /* slash no effect */
    ATK_TCH  = 12, /* touch no effect */
    ATK_BIT  = 13, /* bite no effect */

    // with effect
    WITH_EFEECT_ST = 20,
    ATK_ATKE = 20, /* attack with effect */
    ATK_SLSE = 21, /* slash with effect */
    ATK_TCHE = 22, /* touch with effect */
    ATK_BITE = 23, /* bite with effect */
    WITH_EFEECT_ED = 30,
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
    DETXIFY = 11 ,   /* latumofis */
    CURE    = 12 ,   /* dialko */
    BLESS   = 13 ,   /* madi */
    GUARD   = 14 ,   /* maporfic */
    SLEEP   = 15 ,   /* katino(gr) */
    BIND    = 16 ,   /* manifo(gr) */
    ACPGR   = 17 ,   /* decrease player group's AC */
    SUFCATN = 18 ,   // kanito(gr)
    VACUITY = 19 ,   // makanito(all)
    BREATHE = 20 ,   // di
    Bless   = 21 ,   //katorto
    NOKESSN = 22 ,   // badi(one)
    DYNG    = 23 ,   // labadi(one)
    FLOATN  = 24 ,   // litofeit
    RCGNIZE = 25 ,   // latumapic
    SILENC  = 26 ,   // montino(gr)
    MAPPER  = 27 ,   // dumapic
    FLASH   = 28 ,   // milwa
    LIGHT   = 29 ,   // lomilwa
    TELEPT  = 30 ,   // malor(xoowgn)
    RETURN  = 31     // loktofeit(vxvxpow)
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
enum MAX_TRAP_NAME = 14;    // priest blaster

