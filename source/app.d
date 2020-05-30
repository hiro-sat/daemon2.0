// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.string;
import std.file;
import std.conv;
import std.random;
import std.array;
import std.datetime.systime : SysTime, Clock;
import core.stdc.stdlib : exit;
import core.stdc.stdarg;    // ... : 可変個引数関数

// dub
import derelict.sdl2.sdl;
import mofile;

// mysource 
import lib_sdl;
import lib_screen;
import lib_readline;
import lib_json;
import cTextarea;
import def;

import castle;
import dungeon;

import cParty;
import cMember;
import cMap;
import cItem;
import cItemDef;

import cBattleTurn;
import cMonsterParty;
import cMonsterTeam;
import cMonster;
import cMonsterDef;

void main(string[] args)
{


    /* debugmode = true; */
    debugmodeOffFlg = true;

    // 初期設定
    if( ! initialize )
        return ;

    // SDLオブジェクト作成（SDL初期設定）
    // 80x23
    gsdl = new MySDL;
    scr = gsdl.InitScreen;
    scr.cls;
    readline = new ReadLine( gsdl , scr );
    readline_spell = new ReadLine( gsdl , scr );

    // タイトル表示
    title;

    // メインルーチン
    while( true )
    {

        if( ! castle_main )
            break;

        // return で戻った直後に保存すると layer=0 になる。
        if( party.layer == 0 )
            continue;

        if( ! dungeon_main )
            break;

    }

    // 終了処理
    appExit;

    return;

}

/**
 終了処理 - x ボタン閉じる場合も
 */
void appExit()
{
    exit( 0 );
}

/**
 appSave - 全体セーブ
 */
void appSave()
{
    saveBoltac();
    saveMarks();
    saveCharacter();
    saveMap();
    return;
}


/**
  ====== title ========================================================
  */
void title()
{
    int x , y;
    bool waitflg = true;
    string txt2;

    void titlePrint( int wait , string txt )
    {
        
        txt2 = txt;

        foreach( i , s ; txt )
        {
            if( ! waitflg )
            {
                mvprintw( y , x , txt2 );
                return;
            }
        
            mvprintw( y , x++ , s );
            scr.disp;
            if( waitflg || wait > -1 )
                if( getChar( wait ) != 0 )
                    waitflg = false;

            txt2 = txt[ i + 1 .. $ ];
        }
        return;
    }
    

    x = 32 ; 
    y = 8 ;
    titlePrint( 75 , "d a e m o n  2.0");

    if( waitflg )
        getChar( 1500 ); // timeout付き

    x = 30 ; 
    y = 13 ;
    titlePrint( 0 , "yet another WIZ-LIKE");

    x = 30 ; 
    y = 15 ;
    titlePrint( 0 , "--- press any key ---");

    getChar;
    scr.cls;

    return;

}

/**
  ====== ending ========================================================
  */
void ending()
{
    int i, j;
    win_msg.textout( "\n       *** Congratulations! ***" );
    getChar();
    win_msg.textout( "\n\n" );
    win_msg.textout( "君たちはShelton氏の豪華な屋敷でのディナーに\n" );
    win_msg.textout( "招かれた。Sheltonホテルの一流シェフによって\n" );
    win_msg.textout( "作られた、見目麗しい料理の数々がテーブルに\n" );
    win_msg.textout( "並んでいた。\n" );
    getChar();
    win_msg.textout( "\n「ほう、これが例の魔物が持っていたという\n" );
    win_msg.textout( "  日記かね」\n" );
    win_msg.textout( "君たちが迷宮の主を倒した証拠として持ってきた\n" );
    win_msg.textout( "日記にShelton氏は興味を示したようだ。\n" );
    getChar();
    win_msg.textout( "\n「これを調べれば奴が何者であったかがわかる\n" );
    win_msg.textout( "  だろう。しかし何はともあれ、君たちには\n" );
    win_msg.textout( "  『おめでとう!』を言わせてもらおう!」\n" );
    getChar();
    win_msg.textout( "\nその夜、君たちは思う存分豪華な食事を堪能\n" );
    win_msg.textout( "した。そして約束どおり、60万ゴールドの賞金を\n" );
    win_msg.textout( "受け取った。\n" );
    for ( i = 0; i < party.num; i++ )
    {
        party.mem[ i ].gold += 600000 / party.num;
  
        if ( party.mem[ i ].doesHeHave( 171 ) )
        {
            for ( j = 0; j < MAXCARRY; j++ )
                if ( ( party.mem[ i ].item[ j ].itemNo ) == 171 )
                    party.mem[ i ].item[ j ].release;
        }
    }
    win_msg.textout( "\n*** game is over.\n" );
    win_msg.textout( "    push any key to continue.\n" );
    getChar();

    return;
}


/*--------------------
   setFontSize - フォントサイズ設定
    para : 1 : small , 2 : big
   --------------------*/
void setFontSize( long para )
{

    if( para == 1 )
    {
        FONTSIZE        = S_FONTSIZE;
        FONT_WIDTH      = S_FONT_WIDTH;
        FONT_HEIGHT     = S_FONT_HEIGHT;
        FONT_J_WIDTH    = S_FONT_J_WIDTH;
        FONT_J_HEIGHT   = S_FONT_J_HEIGHT;
        FONT_X_MARGINE  = S_FONT_X_MARGINE;
        FONT_Y_MARGINE  = S_FONT_Y_MARGINE;
    }
    else if( para == 2 )
    {
        FONTSIZE        = L_FONTSIZE;
        FONT_WIDTH      = L_FONT_WIDTH;
        FONT_HEIGHT     = L_FONT_HEIGHT;
        FONT_J_WIDTH    = L_FONT_J_WIDTH;
        FONT_J_HEIGHT   = L_FONT_J_HEIGHT;
        FONT_X_MARGINE  = L_FONT_X_MARGINE;
        FONT_Y_MARGINE  = L_FONT_Y_MARGINE;
    }
    else
    {
        FONTSIZE        = L_FONTSIZE;
        FONT_WIDTH      = L_FONT_WIDTH;
        FONT_HEIGHT     = L_FONT_HEIGHT;
        FONT_J_WIDTH    = L_FONT_J_WIDTH;
        FONT_J_HEIGHT   = L_FONT_J_HEIGHT;
        FONT_X_MARGINE  = L_FONT_X_MARGINE;
        FONT_Y_MARGINE  = L_FONT_Y_MARGINE;
    }

    WINDOW_WIDTH = ( FONT_WIDTH + FONT_X_MARGINE ) * TEXT_WIDTH
                  + WINDOW_TOP_MARGINE + WINDOW_BOTTOM_MARGINE 
                  + WINDOW_LEFT_MARGINE + WINDOW_RIGHT_MARGINE ;
    WINDOW_HEIGHT = ( FONT_HEIGHT + FONT_Y_MARGINE ) * TEXT_HEIGHT
                  + WINDOW_TOP_MARGINE + WINDOW_BOTTOM_MARGINE 
                  + WINDOW_LEFT_MARGINE + WINDOW_RIGHT_MARGINE ;

    return;

}

/*--------------------
   initialize - 初期設定
   --------------------*/
private bool initialize()
{

    // json 確認
    Json json = new Json( JSONFILE );

    // 画面サイズ設定
    setFontSize( json[ "size" ].integer );

    // 言語ファイル
    // ※ MoFile を設定しない場合は文字列がそのまま出力される。
    string locale;
    locale = json[ "language" ].str;

    writeln(  formatText( LANGUAGEFILE , locale ) );

    if( locale != "" )
    {
        if( exists( formatText( LANGUAGEFILE , locale ) ) )
            moFile = MoFile( formatText( LANGUAGEFILE , locale ) );
    }

    
    setRndSeed;

    // データ保存フォルダ確認
    if( ! exists( DATA_FOLDER ) )
        mkdir( DATA_FOLDER );

    if ( ! readItem )
    {
        printf("\ncannot read item file\n");
        return false;
    }
    if ( ! readMagic )
    {
        printf("\ncannot read magic file\n");
        return false;
    }

    if( ! readMapAll )
    {
        printf("\ncannot read map file\n");
        return false;
    }

    if ( ! readMonster )
    {
        printf("\ncannot read monster file\n");
        return false;
    }

    if ( ! readBoltac )
    {
        printf("\ncannot read shop file.");
        return false;
    }

    readMarks();

    if ( ! readCharacter )
    {
        printf("\ncannot read character file.");
        return false;
    }

    party = new Party;

    monParty = new MonsterParty;
    for( int i = 0; i < monTeam.length ; i++ ) monTeam[ i ] = new MonsterTeam;
    for( int i = 0; i < monster.length ; i++ ) monster[ i ] = new Monster;


    top_turn = new BattleTurn;
    end_turn = new BattleTurn;
    for( int i = 0 ; i < turn.length ; i ++ )
        turn[ i ] = new BattleTurn;


    TRAP_NAME[ TRAP.NO         ] = _( "no trap" );
    TRAP_NAME[ TRAP.POISON     ] = _( "poison needle" );
    TRAP_NAME[ TRAP.GASBOMB    ] = _( "gas bomb" );
    TRAP_NAME[ TRAP.CROSSBOW   ] = _( "crossbow bolt" );
    TRAP_NAME[ TRAP.EXPLODING  ] = _( "exploding box" );
    TRAP_NAME[ TRAP.STUNNER    ] = _( "stunner" );
    TRAP_NAME[ TRAP.TELEPORT   ] = _( "teleporter" );
    TRAP_NAME[ TRAP.MAGBLASTER ] = _( "mage blaster" );
    TRAP_NAME[ TRAP.PRIBLASTER ] = _( "priest blaster" );
    TRAP_NAME[ TRAP.ALARM      ] = _( "alarm" );

    win_msg = new Textarea( TXTW_X_SIZ , TXTW_Y_SIZ );
    win_msg.setDispPos( TXTW_X_TOP , TXTW_Y_TOP );

    win_status = new Textarea( STSW_X_SIZ , STSW_Y_SIZ );
    win_status.setDispPos( STSW_X_TOP , STSW_Y_TOP );

    return true;
}


/*--------------------
   readItem - アイテムファイル読み込み
   --------------------*/
private bool readItem()
{

    int id;

    auto fin  = File( ITEMFILE ,"r");
    foreach ( line; fin.byLine )
    {
        auto data = split( line.chop , "\t" );

        id = to!int( data[ 0 ] );

        if ( id == 9999)
            break;

        item_data[ id ] = new ItemDef( data );

    }
    
    return true;
}

/*--------------------
   reaaMagic - 魔法ファイル読み込み
   --------------------*/
private bool readMagic()
{
    auto fin  = File( MAGICFILE ,"r");
    foreach (line; fin.byLine)
    {
        int i;
        auto data = split( line.chop , "\t" );

        i = 0;

        if ( data.length == 0 )
            continue;

        if ( data[ i ] == "ffff")
            break;

        magicdef* mgc;
        mgc      = & magic_data[ to!int( data[ i++ ] , 16 ) ];
        mgc.name = to!string( data[ i++ ] );
        mgc.camp = to!byte( data[ i++ ] );
        mgc.batl = to!byte( data[ i++ ] );
        mgc.type = to!byte( data[ i++ ] );
        mgc.attr = to!byte( data[ i++ ] );
        mgc.min  = cast(short) to!int( data[ i++ ] );
        mgc.add  = cast(short) to!int( data[ i++ ] );
    }
    
    return true;
}


/*--------------------
   readMapAll - マップ情報読み込み
   --------------------*/
private bool readMapAll()
{

    int layer = 1;
    Map m;
    while( exists( formatText( ORGMAPFILE , fill0( layer , 2 ) ) ) )
    {
        dungeonMap.length ++;
        dungeonMap.back = new Map( layer ); // インスタンス作成のみ
        if( ! dungeonMap.back.initialize )  // 初期化はこちらですべて行う
            return false;
        layer ++;
    }
    MAXLAYER = layer;

    return true;
}


/**--------------------
   saveMap - マップ情報書き込み（フロア別）
   --------------------*/
public bool saveMap()
{

    foreach( d ; dungeonMap )
        d.saveMap;

    return true;
}



/*--------------------
   readMonster - モンスターファイル読み込み
   --------------------*/
private bool readMonster()
{

    int id;

    auto fin  = File( MONSTERFILE ,"r");
    foreach (line; fin.byLine)
    {
        auto data = split( line , "\t" );

        id = to!int( data[ 0 ] );

        if ( id == 9999 )
            break;

        monster_data[ id ] = new MonsterDef( data );

    }

    return true;
}


/*--------------------
   readBoltac - 商店ファイル読み込み
   --------------------*/
private bool readBoltac()
{

    int i;
    for ( i = 0 ; i < MAXITEM ; i++ )
        shopitem[ i ] = 0;

    if( ! exists( SHOPFILE ) )
    {
        // initialize
        printf("initializing... shoplist\n");
        for ( i = 1 ; i <= 10 ; i++ )
            shopitem[ i ] = 9999 ;
        for ( i = 13 ; i <= 19 ; i++ )
            shopitem[ i ] = 9999 ;
        shopitem[ 39 ] = 1 ; // plate+1
        shopitem[ 77 ] = 9999; // gloves of copper
        return true;
    }

    auto fin  = File( SHOPFILE ,"r");
    foreach ( line ; fin.byLine)
    {
        if( line == "9999" )
            break;
        auto data = split( line , " " );
        shopitem[ to!int( data[ 0 ] ) ] = to!int( data[ 1 ] ) ;
    }

    return true;
}


/**--------------------
   saveBoltac - 商店ファイル書き込み
   --------------------*/
public bool saveBoltac()
{

    auto fout = File( SHOPFILE, "w" );

    for ( int i = 0  ; i < shopitem.length ; i++ )
        if ( shopitem[ i ] !=0 )
            fout.writef( "%d %d\n" , i , shopitem[ i ] );

    fout.writef( "9999" );

    return true;
}


/*--------------------
   readMarks - モンスターマークファイル読み込み
   --------------------*/
private bool readMarks()
{

    int i;
    for ( i = 0 ; i < MAXMONSTER ; i++ )
        monstermarks[ i ] = 0;

    if( ! exists( MARKSFILE ) )
    {
        printf("\ncannot read marks file\n");
        return false;
    }

    auto fin  = File( MARKSFILE ,"r");
    foreach ( line ; fin.byLine)
    {
        if( line == "9999999" )
            break;
        auto data = split( line , " " );
        monstermarks[ to!int( data[ 0 ] ) ] = to!int( data[ 1 ] ) ;
    }

    return true;
}


/**--------------------
   saveMarks - モンスターマークファイル書き込み
   --------------------*/
public int saveMarks()
{

    auto fout = File( MARKSFILE, "w" );

    for ( int i = 0  ; i < monstermarks.length ; i++ )
        if ( monstermarks[ i ] !=0 )
            fout.writef( "%d %d\n" , i , monstermarks[ i ] );

    fout.writef( "9999999" );

    return true;
}


/*--------------------
   readCharacter - キャラクタファイル読み込み
   --------------------*/
private bool readCharacter()
{

    if( ! exists( MEMBERFILE ) )
    {
        writef("\nInitialie ... %s\n" , MEMBERFILE );
        initCharactor;
        return true;
    }

    int no = 0;
    auto fin  = File( MEMBERFILE ,"r");
    foreach ( line ; fin.byLine)
        member[ no++ ] = new Member( to!string( line ) );

    Member mb;

    for( int i = 0 ; i < MAXMEMBER ; i++ )
    {
        mb = member[ i ];

        if( mb.outflag != 3 )
            continue;

        // DEAD -> ASHED
        if( mb.status == STS.DEAD && get_rand( 19 ) == 0 )
        {
            mb.status = STS.DEAD;
        }
        // ASHED -> LOST
        else if( mb.status == STS.ASHED && get_rand( 19 ) == 0 )
        {
            mb.status = STS.LOST;  // no meaning, though.
            mb.name = "";
        }


        // item lost
        if (( mb.status == STS.DEAD || mb.status == STS.ASHED ) && get_rand( 9 ) == 0 )
        {
            for ( int j = 0 ; j < 8 ; j++ )
            {
                  if (mb.item[ 7 - j ].isNothing )
                  {
                      mb.item[ 7 - j ].setNull ;
                      break;
                  }
              }
        }
    }

    return true;
}


/**--------------------
   saveCharacter - キャラクタファイル書き込み
   --------------------*/
public bool saveCharacter()
{

    /* chr file */
    auto fout = File( MEMBERFILE , "w" );

    foreach ( Member mem ; member )
        mem.save( fout );

    return true;
}

/*--------------------
   initCharactor - キャラクタファイル初期化
   --------------------*/
private void initCharactor()
{
    int i;
    for ( i = 0 ; i < MAXMEMBER ; i++)
        member[ i ] = new Member();

    i = 14;
  
    member[i].name    = "zucchini";
    member[i].gold    = 27;
    /* member[i].gold    = 2700000; */
    member[i].hp      = 6;
    member[i].maxhp   = 6;
    member[i].age     = 16;
    member[i].day     = 0;
    member[i].item[0].setItem = 0x8001; // long_sword
    member[i].item[1].setItem = 0x800e; // chain_mail
    member[i].item[2].setItem = 0x8009; // large_shield
    member[i].item[3].setItem = 0x8011; // helm
    member[i].race    = RACE.HUMAN;
    member[i].Class   = CLS.FIG;
    member[i].Align   = ALIGN.GOOD;
    member[i].str[0]  = 13;
    member[i].iq[0]   = 8;
    member[i].pie[0]  = 5;
    member[i].vit[0]  = 14;
    member[i].agi[0]  = 8;
    member[i].luk[0]  = 9;
    member[i].cha[0]  = 11;
    i++;
  
    member[i].name    = "cucumber";
    member[i].gold    = 23;
    member[i].hp      = 12;
    member[i].maxhp   = 12;
    member[i].age     = 17;
    member[i].day     = 0;
    member[i].item[0].setItem = 0x8001; // long_sword
    member[i].item[1].setItem = 0x800e; // chain_mail
    member[i].item[2].setItem = 0x8009; // large_shield
    member[i].item[3].setItem = 0x8011; // helm
    member[i].race    = RACE.DWARF;
    member[i].Class   = CLS.FIG;
    member[i].Align   = ALIGN.NEWT;
    member[i].str[0]  = 18;
    member[i].iq[0]   = 7;
    member[i].pie[0]  = 10;
    member[i].vit[0]  = 18;
    member[i].agi[0]  = 13;
    member[i].luk[0]  = 10;
    member[i].cha[0]  = 1;
    i++;
  
    member[i].name    = "pumpkin";
    member[i].gold    = 23;
    member[i].hp      = 10;
    member[i].maxhp   = 10;
    member[i].age     = 16;
    member[i].day     = 0;
    member[i].item[0].setItem = 0x8001; // long_sword
    member[i].item[1].setItem = 0x800e; // chain_mail
    member[i].item[2].setItem = 0x8009; // large_shield
    member[i].item[3].setItem = 0x8011; // helm
    member[i].race    = RACE.GNOME;
    member[i].Class   = CLS.FIG;
    member[i].Align   = ALIGN.GOOD;
    member[i].str[0]  = 16;
    member[i].iq[0]   = 7;
    member[i].pie[0]  = 10;
    member[i].vit[0]  = 16;
    member[i].agi[0]  = 10;
    member[i].luk[0]  = 7;
    member[i].cha[0]  = 14;
    i++;
  
    member[i].name   = "avocado";
    member[i].gold   = 23;
    member[i].hp     = 4;
    member[i].maxhp  = 4;
    member[i].age    = 19;
    member[i].day    = 0;
    member[i].race   = RACE.HOBBIT;
    member[i].Class  = CLS.THI;
    member[i].Align  = ALIGN.NEWT;
    member[i].str[0] = 5;
    member[i].iq[0]  = 7;
    member[i].pie[0] = 7;
    member[i].vit[0] = 8;
    member[i].agi[0] = 18;
    member[i].luk[0] = 18;
    member[i].cha[0] = 15;

    /* member[i].exp = 1000000; */

    i++;
  
    member[i].name        = "celery";
    member[i].gold        = 23;
    member[i].hp          = 4;
    member[i].maxhp       = 4;
    member[i].age         = 14;
    member[i].day         = 0;
    member[i].pspl_know[0] = cast(byte)( 0xc0 );
    member[i].pspl_max[0]  = cast(byte)( 0x3 );
    member[i].pspl_pt [0]  = cast(byte)( 0x3 );
    member[i].race        = RACE.ELF;
    member[i].Class       = CLS.PRI;
    member[i].Align       = ALIGN.GOOD;
    member[i].str[0]      = 7;
    member[i].iq[0]       = 10;
    member[i].pie[0]      = 18;
    member[i].vit[0]      = 9;
    member[i].agi[0]      = 9;
    member[i].luk[0]      = 7;
    member[i].cha[0]      = 12;
    i++;
  
    member[i].name        = "tomato";
    member[i].gold        = 23;
    member[i].hp          = 4;
    member[i].maxhp       = 4;
    member[i].age         = 17;
    member[i].day         = 0;
    member[i].mspl_know[0] = cast(byte)( 0xc0 );
    member[i].mspl_max[0]  = cast(byte)( 0x2 );
    member[i].mspl_pt [0]  = cast(byte)( 0x2 );
    member[i].race        = RACE.ELF;
    member[i].Class       = CLS.MAG;
    member[i].Align       = ALIGN.GOOD;
    member[i].str[0]      = 7;
    member[i].iq[0]       = 18;
    member[i].pie[0]      = 10;
    member[i].vit[0]      = 8;
    member[i].gold    = 27;
    member[i].agi[0]      = 9;
    member[i].luk[0]      = 8;
    member[i].cha[0]      = 17;
}


/* get radom value 0-maxl(include maxl) */
int get_rand( int maxl )
{
    return uniform( 0 , maxl + 1 , rnd );
}
void setRndSeed()
{
    SysTime currentTime = Clock.currTime();

    string seed;
    foreach( char c ; to!string( currentTime ) )
        if( c >= '0' && c <= '9' )
            seed ~= c;

    ulong seed1 , seed2;
    seed1 = to!ulong( seed[ 0 .. seed.length / 2 ] ) / 10;
    seed2 = to!ulong( seed[ seed.length / 2 .. seed.length ] ) / 10;

    assert( seed1 + seed2 < int.max , "setRndSeed Error." );

    uint  seed0;
    seed0 = to!uint( seed1 + seed2 );

    rnd = Random( seed0 );

    return;
}



/*====== header ============================================*/
/**
  header_disp - partyステータス、場所を表示
  */
void header_disp( HSTS sts , bool rewrite = true )
{

    now_mode = sts;

    rewriteOff;

    mvprintw( 0, 0, "                                                       " );
    if( ! debugmode )
        mvprintw( 0, 0, "[daemon2.0] " );
    else
        mvprintw( 0, 0, " ** DeBuG **" );

    if ( party.layer > 0 && party.isMapper  )
    { // mapper ON?
        intDispD( party.layer , 2);
        printw("F(");
        intDispD(party.x, 2);
        printw(",");
        intDispD(party.y, 2);
        printw(")");
    }
    else
    {
        printw("          ");
    //    printw("??F(??,??)");
    }
    if ( sts == HSTS.DUNGEON || sts == HSTS.CAMP || sts == HSTS.BATTLE )
    {
        if ( party.isFloat )
            printw(" f"); // float
        else
            printw("  ");

        if ( party.isLight )
            printw("l"); // light
        else
            printw(" ");

        if ( party.isIdentify )
            printw("i"); // identify
        else
            printw(" ");
        
        if ( party.ac < 0 )
            printw("p");
        else
            printw(" ");

        if ( party.isScope )
            printw("s"); // scope
        else
            printw(" ");

    }


    switch( sts )
    {
        case HSTS.DUNGEON:
            mvprintw(0, 31, _( "- dungeon -              [push '?' key for help]" ));
            break;
        case HSTS.BATTLE:
            mvprintw(0, 31, _( "- battle -               [push '?' key for help]" ));
            break;
        case HSTS.CAMP:
            mvprintw(0, 31, _( "- camp mode -         [#:inspect,?:help,z:leave]" ));
            break;
        case HSTS.CASTLE:
            mvprintw(0, 23, _( "- castle -       [g:bar,s:hotel,t:temple,a:shop,e:leave]" ));
            break;
        case HSTS.EOT:
            mvprintw(0, 23, _( "- edge of town -   [c:astle,t:raining,d:angeon,r:estart]" ));
            break;
        case HSTS.BAR:
            mvprintw(0, 23, _( "- ginger's forest bar -      for your quality time      " ));
            break;
        case HSTS.INN:
            mvprintw(0, 23, _( "- yankee flipper hotel -      satisfaction guaranteed!  " ));
            break;
        case HSTS.TEMPLE:
            mvprintw(0, 23, _( "- temple of dice -       you can always count on us.    " ));
            break;
        case HSTS.SHOP:
            mvprintw(0, 23, _( "- albertsan's mart -      we love to see you smile.     " ));
            break;
        case HSTS.TRAINING:
            mvprintw(0, 23, _( "- training ground -   wanna get a job? you'll find one! " ));
            break;
        default:
            assert( 0 );
    }

    if( rewrite )
        rewriteOn;

    return;
}


/*====== scroll window ===========================================*/
/*--------------------
   scrClear - 表示初期化
   --------------------*/
void scrClear()
{
    int x, y;
    string spc;
    
    for( x = 0 ; x < TEXT_WIDTH ; x++ )
        spc ~= " ";

    rewriteOff;
    for( y = 0 ; y < SCRW_Y_SIZ ; y++ )
        /* mvprintw( y + SCRW_Y_TOP , x + SCRW_X_TOP , spc ); */
        mvprintw( y + SCRW_Y_TOP , 0 , spc );
    rewriteOn;

    return;
}


/*====== sub routines =====================================*/

/** mvprintw - char表示 */
void mvprintw( int nY , int nX , char ch ) 
{
    mvprintw( nY, nX , to!string( ch ) );
}
/** mvprintw - int表示 */
void mvprintw( int nY , int nX , int i ) 
{
    mvprintw( nY, nX , to!string( i ) );
}
/** mvprintw - string表示 */
void mvprintw( int nY , int nX , string text )
{
    scr.print( nX , nY , text );
    if( rewrite_flg )
        scr.disp;
    return;
}

/** mvprintw  */
void printw( string text )
{
    scr.print( text );
    if( rewrite_flg )
        scr.disp;
    return;
}


/** intDisp - 数字をテキスト表示  */
void intDisp( long num )
{
    scr.print( to!string( num ) );
    if( rewrite_flg )
        scr.disp;
    return;
}

/** intDisp - 数字をテキスト表示(桁数を揃える)  */
void intDispD(long num, int digit)
{
    string text = "                       " ~ to!string( num );
    scr.print( text[ text.length - digit .. text.length ] );
    if( rewrite_flg )
        scr.disp;
    return;
}

/** intFormat - 数字をテキスト整形(桁数を揃える)  */
string intFormat(long num, int digit)
{
    string text = "                       " ~ to!string( num );
    return text[ text.length - digit .. text.length ];
}
/** mvIntDispD - 数字をテキスト表示(桁数を揃える)  */
void mvIntDispD( int y , int x , long num, int digit )
{
    scr.locate( x , y );
    intDispD( num , digit );
    return;
}

/**-------------------- 
   fill - 文字列長をそろえる（左詰め）
   --------------------*/
string fillL( T )( T value , int size )
{
    string word = to!string( value );
    string spc;
    for( int i ; word.length + i < size ; i++ )
        spc ~= " ";
    word ~= spc;
    return word[ 0 .. size ];
}

/**-------------------- 
   fillR - 文字列長をそろえる（右詰め）
   --------------------*/
string fillR( T )( T value , int size )
{
    string word = to!string( value );

    if( size > word.length )
    {
        string spc;
        for( int i = 0 ; word.length + i < size ; i++ )
            spc ~= " ";
        word = spc ~ word;
    }
    return word[ size - word.length .. $ ];
}

/**-------------------- 
   fill0 - 0埋め
   --------------------*/
string fill0( int value , int size )
{
    string word = to!string( value );
    assert( word.length <= size );

    string zero;
    for( int i ; word.length + i < size ; i++ )
        zero ~= "0";

    word = zero ~ word;
    return word[ 0 .. size ];

}

/**-------------------- 
   leftB - 文字数分だけ抽出（全角2バイト扱い）
   --------------------*/
string leftB( string word , int size , bool fill = true )
{
    
    int s = 0;
    string ret;

    for( int i = 0 ; i < word.length ; i++ )
    {
        if( ( word[ i ] & 0x80 ) == 0 )
        {   // 半角
            ret ~= word[ i ];
            s++;
            if( s == size )
                break;
        }
        else
        {   // 全角`
            if( s + 2 > size )
                break;
            ret ~= word[ i++ ];
            ret ~= word[ i++ ];
            ret ~= word[ i ];
            s += 2;
        }
    }

    if( fill )
        while( s < size )
        {
            ret ~= " ";
            s++;
        }

    return ret;

}


/** -------------------- 
   setColor - 文字色設定`
   --------------------*/
void setColor( int cl )
{
    scr.setColor( cl );
    text_color = cl;
    return;
}

/** -------------------- 
   getColor - 文字色取得
   --------------------*/
int getColor()
{
    return text_color;
}


/**-------------------- 
   getChar - 一文字入力
   --------------------*/
char getChar( int timeout = -1 )
{
    bool quit;
    char ret = gsdl.inkey( timeout , quit );

    if( quit )
        appExit;
    
    return ret;
}

/**-------------------- 
   answerYN - y or n を入力
   --------------------*/
char answerYN()
{

    char c;

    while ( true )
    {
        c = getChar();
        if ( c == 'y' || c == 'n' )
            break;
    }
    win_msg.textout( c );
    win_msg.textout( '\n' );
    
    return c;
}

/*-------------------- 
   tline_input - 文字列入力
   size_max : 入力文字列 全角2バイト換算
   --------------------*/
string tline_input( int size_max )
{

    bool quit;
    string ret = readline.input( size_max , quit );

    writef( "app.d : %s" , ret );

    if( quit )
        appExit;
    
    return ret;
}

/*-------------------- 
   tline_input - 文字列入力
   size_max : 入力文字列 全角2バイト換算
   --------------------*/
string tline_input( int size_max, int y, int x )
{

    bool quit;
    string ret = readline.input( size_max , y , x , quit );

    if( quit )
        appExit;
    
    return ret;
}

/*-------------------- 
   tline_input_spell - 文字列入力
   size_max : 入力文字列 全角2バイト換算
   --------------------*/
string tline_input_spell( Member mem , int size_max, int y, int x )
{

    bool quit;
    if( now_mode == HSTS.CAMP )
        readline_spell.setHotKey( "r" , true , false , &mem.dispSpellsInCamp );
    else if( now_mode == HSTS.BATTLE )
        readline_spell.setHotKey( "r" , true , false , &mem.dispSpellsInBattle );
    else
        readline_spell.setHotKey( "r" , true , false , null );

    string ret = readline_spell.input( size_max , y , x , quit );

    if( quit )
        appExit;
    
    return ret;
}



/*-------------------- 
   isHankaku - 半角文字かどうか
   --------------------*/
bool isHankaku( char c )
{
    return ( ( c & 0x80 ) == 0 );
}

/*-------------------- 
   formatText - 出力文字列を整形
   ... : 可変引数 ※string , int , char , long , byte
   usage : formatText( "%1 is the ultimate %2." , 42 , "answer" ) );
           ret : 42 is the ultimate answer.
           formatText( "This is %1%%" , 42 );
           ret : This is 42%
           ※ args は9まで。%10になると、%1 がヒットしてしまう。
   --------------------*/
/* string formatText( string fmt , ... ) */
string formatText( T... )( string fmt , T args )
{

    string keyword;
    foreach( i, type ; args )
    {
        keyword = to!string( type );
        fmt = fmt.replace( "%" ~ to!string( i + 1 ) , keyword );
    }

    return fmt.replace( "%%" , "%" );
}

