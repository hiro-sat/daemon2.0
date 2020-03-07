// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.string : format , split , chop ;
import std.file;
import std.conv;
import std.random;
import std.datetime.systime : SysTime, Clock;
import core.stdc.stdlib : exit;

// derelict SDL
import derelict.sdl2.sdl;

// mysource 
import lib_sdl;
import lib_screen;
import lib_readline;
import def;
import spell;

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

    setFontSize( args );

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


    // メインルーチン
    while( true )
    {

        if( ! castle_main )
            break;

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
  ====== ending ========================================================
  */
void ending()
{
    int i, j;
    textout( "\n       *** Congratulations! ***" );
    getChar();
    textout( "\n\n" );
    textout( "君たちはShelton氏の豪華な屋敷でのディナーに\n" );
    textout( "招かれた。Sheltonホテルの一流シェフによって\n" );
    textout( "作られた、見目麗しい料理の数々がテーブルに\n" );
    textout( "並んでいた。\n" );
    getChar();
    textout( "\n「ほう、これが例の魔物が持っていたという\n" );
    textout( "  日記かね」\n" );
    textout( "君たちが迷宮の主を倒した証拠として持ってきた\n" );
    textout( "日記にShelton氏は興味を示したようだ。\n" );
    getChar();
    textout( "\n「これを調べれば奴が何者であったかがわかる\n" );
    textout( "  だろう。しかし何はともあれ、君たちには\n" );
    textout( "  『おめでとう!』を言わせてもらおう!」\n" );
    getChar();
    textout( "\nその夜、君たちは思う存分豪華な食事を堪能\n" );
    textout( "した。そして約束どおり、60万ゴールドの賞金を\n" );
    textout( "受け取った。\n" );
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
    textout( "\n*** game is over.\n" );
    textout( "    push any key to continue.\n" );
    getChar();

    return;
}


/*--------------------
   setFontSize - フォントサイズ設定
   --------------------*/
void setFontSize( string[] args )
{
    int para;
    para = 0;
    if( args.length > 1 )
        switch( args[ 1 ] )
        {
            case "1":
                para = 1;
                break;
            case "2":
                para = 2;
                break;
            default:
                para = 0;
        }

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


    TRAP_NAME[ TRAP.NO         ] = "no trap";
    TRAP_NAME[ TRAP.POISON     ] = "poison needle";
    TRAP_NAME[ TRAP.GASBOMB    ] = "gas bomb";
    TRAP_NAME[ TRAP.CROSSBOW   ] = "crossbow bolt";
    TRAP_NAME[ TRAP.EXPLODING  ] = "exploding box";
    TRAP_NAME[ TRAP.STUNNER    ] = "stunner";
    TRAP_NAME[ TRAP.TELEPORT   ] = "teleporter";
    TRAP_NAME[ TRAP.MAGBLASTER ] = "mage blaster";
    TRAP_NAME[ TRAP.PRIBLASTER ] = "priest blaster";
    TRAP_NAME[ TRAP.ALARM      ] = "alarm";

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

    for (int layer = 0 ; layer < 8 ; layer ++)
    {
        dungeonMap[ layer ] = new Map( layer ); // インスタンス作成のみ
        if( ! dungeonMap[ layer ].initialize )  // 初期化はこちらですべて行う
            return false;
    }

    return true;
}


/**--------------------
   saveMap - マップ情報書き込み（フロア別）
   --------------------*/
public bool saveMap()
{

    for ( int layer = 0 ; layer <= 7; layer ++)
        dungeonMap[ layer ].saveMap;

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
        boltacitem[ i ] = 0;

    if( ! exists( SHOPFILE ) )
    {
        // initialize
        printf("initializing... shoplist\n");
        for ( i = 1 ; i <= 10 ; i++ )
            boltacitem[ i ] = 9999 ;
        for ( i = 13 ; i <= 19 ; i++ )
            boltacitem[ i ] = 9999 ;
        boltacitem[ 39 ] = 1 ; // plate+1
        boltacitem[ 77 ] = 9999; // gloves of copper
        return true;
    }

    auto fin  = File( SHOPFILE ,"r");
    foreach ( line ; fin.byLine)
    {
        if( line == "9999" )
            break;
        auto data = split( line , " " );
        boltacitem[ to!int( data[ 0 ] ) ] = to!int( data[ 1 ] ) ;
    }

    return true;
}


/**--------------------
   saveBoltac - 商店ファイル書き込み
   --------------------*/
public bool saveBoltac()
{

    auto fout = File( SHOPFILE, "w" );
    /* fout.writeln("Hello World!"); */

    for ( int i = 0  ; i < boltacitem.length ; i++ )
        if ( boltacitem[ i ] !=0 )
            fout.writef( "%d %d\n" , i , boltacitem[ i ] );

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
    /* member[i].gold    = 27; */
    member[i].gold    = 2700000;
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

    member[i].exp = 1000000;

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

    uint seed1 , seed2;
    seed1 = to!uint( seed[ 0 .. seed.length / 2 ] );
    seed2 = to!uint( seed[ seed.length / 2 .. seed.length ] );


    rnd = Random( seed1 + seed2 );

    return;
}



/*====== header ============================================*/
/**
  header_disp - partyステータス、場所を表示
  */
void header_disp( HSTS sts , bool rewrite = true )
{

    rewriteOff;

    mvprintw( 0, 0, "                                                       " );
    if( ! debugmode )
        mvprintw( 0, 0, " - Daemon - " );
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

        if ( party.isShine )
            printw("s"); // shine
        else
            printw(" ");

        if ( party.isIdentify )
            printw("i"); // identify
        else
            printw(" ");
        
        if ( party.ac < 0 )
            printw("p ");
        else
            printw("  ");
    }

    switch( sts )
    {
        case HSTS.DUNGEON:
            mvprintw(0, 31, "- dungeon -              [push '?' key for help]");
            break;
        case HSTS.BATTLE:
            mvprintw(0, 31, "- battle -               [push '?' key for help]");
            break;
        case HSTS.CAMP:
            mvprintw(0, 31, "- camp mode -         [#:inspect,h:help,z:leave]");
            break;
        case HSTS.CASTLE:
            mvprintw(0, 23, "- castle -      [g:bar,s:hotel,t:temple,a:shop,e:leave]");
            break;
        case HSTS.EOT:
            mvprintw(0, 23, "- eot -   [c:astle,q:uit game,t:raining,m:aze,r:estart]");
            break;
        case HSTS.BAR:
            mvprintw(0, 23, "- ginger's forest bar -     for your quality time      ");
            break;
        case HSTS.INN:
            mvprintw(0, 23, "- yankee flipper hotel -     satisfaction guaranteed!  ");
            break;
        case HSTS.TEMPLE:
            mvprintw(0, 23, "- temple of dice -      you can always count on us.    ");
            break;
        case HSTS.SHOP:
            mvprintw(0, 23, "- albertsan's mart -     we love to see you smile.     ");
            break;
        case HSTS.TRAINING:
            mvprintw(0, 23, "- training ground -  wanna get a job? you'll find one! ");
            break;
        default:
            assert( 0 );
    }

    if( rewrite )
        rewriteOn;

    return;
}





/*====== text window ===========================================*/
/** テキストエリア表示(int) */
void textout( int i ){ textout( to!string( i ) ); }
/** テキストエリア表示(long) */
void textout( long l ){ textout( to!string( l ) ); }
/** テキストエリア表示(char) */
void textout( char c ){ textout( to!string( c ) ); }
/** テキストエリア表示(string) */
void textout( string text )
{

    /*-------------------- 
    line_disp - 行表示
    --------------------*/
    void line_disp( int winline , int lineno )
    {
        int i , pos ;
        string buf;

        char[] bufline = text_win_buffer[ lineno ].dup;
        char* c;

        bool flg = false ;
        pos = 0;

        for( i = 0; i < TXTW_X_SIZ; i++)
        {

            if( ! flg )
                if( pos >= bufline.length )
                    flg = true;

            if( flg )
            {
                buf ~= ' ';
            }
            else
            {
                c = &bufline[ pos ];

                if( isHankaku( *c ) )
                {
                    buf ~= *c;
                    pos++;
                }
                else
                {
                    buf ~= *c; c++;
                    buf ~= *c; c++;
                    buf ~= *c;
                    pos += 3;
                    i++;
                }
            }
        }

        CL tmp = cast(CL)text_color;
        setColor( text_win_buffer_color[ lineno ] );
        mvprintw( winline + TXTW_Y_TOP, TXTW_X_TOP,  buf );
        setColor( tmp );

        return;
    }


    /*-------------------- 
    scroll - スクロール
    --------------------*/
    void scroll()
    {
        int i;
        text_top++;

        if( text_top >= TXTW_Y_SIZ )
            text_top=0;

        for( i = 0 ; i < TXTW_Y_SIZ - 1 ; i++ )
            line_disp( i , ( text_top + i ) % TXTW_Y_SIZ );

        string spc;
        for( i = 0 ; i < TXTW_X_SIZ ; i++ )
            spc ~= " ";
        mvprintw( TXTW_Y_TOP + TXTW_Y_SIZ - 1 , TXTW_X_TOP , spc );

        return;
    }


    /*-------------------- 
    crlf - 改行
    --------------------*/
    void crlf()
    {
        line_disp( text_cury , ( text_top + text_cury ) % TXTW_Y_SIZ );
        text_cury++;
        text_win_buffer     [ ( text_top + text_cury ) % TXTW_Y_SIZ ] = "";
        text_win_buffer_size[ ( text_top + text_cury ) % TXTW_Y_SIZ ] = 0;

        if( text_cury > TXTW_Y_SIZ - 1)
        {
            text_cury = TXTW_Y_SIZ - 1;
            scroll();
        }
        return;
    }



    rewriteOff;

    char[] txt = text.dup;
    for( int i = 0 ; i < txt.length ; i++ )
    {
        if ( txt[ i ] == '\n' )
        {
            crlf;
        }
        else
        {
            if( isHankaku( txt[ i ] ) )
            {   // 半角
                text_win_buffer     [ ( text_top + text_cury ) % TXTW_Y_SIZ ] ~= txt[ i ];
                text_win_buffer_size[ ( text_top + text_cury ) % TXTW_Y_SIZ ] ++;
                text_win_buffer_color[ ( text_top + text_cury ) % TXTW_Y_SIZ ] = text_color;
                if( text_win_buffer_size[ ( text_top + text_cury ) % TXTW_Y_SIZ ] > TXTW_X_SIZ - 2 )
                    crlf;
            }
            else
            {   // 全角
                text_win_buffer[ ( text_top + text_cury ) % TXTW_Y_SIZ ] ~= txt[ i++ ];
                text_win_buffer[ ( text_top + text_cury ) % TXTW_Y_SIZ ] ~= txt[ i++ ];
                text_win_buffer[ ( text_top + text_cury ) % TXTW_Y_SIZ ] ~= txt[ i ];
                text_win_buffer_size[ ( text_top + text_cury ) % TXTW_Y_SIZ ] += 2;
                text_win_buffer_color[ ( text_top + text_cury ) % TXTW_Y_SIZ ] = text_color;
                if( text_win_buffer_size[ ( text_top + text_cury ) % TXTW_Y_SIZ ] > TXTW_X_SIZ - 2 )
                    crlf;
            }
        }
    }
    line_disp( text_cury, ( text_top + text_cury ) % TXTW_Y_SIZ );

    rewriteOn;

    return;
}




/*====== scroll window ===========================================*/
/**
  scrwin_clear - マップ表示エリア初期化
  */
void scrwin_clear()
{
    int x, y;
    string spc;
    
    rewriteOff;
    
    for( x = 0 ; x < SCRW_X_SIZ + 2 ; x++ )
        spc ~= " ";

    for( y = 1 ; y < SCRW_Y_SIZ + SCRW_Y_TOP ; y++ )
        mvprintw( y, SCRW_X_TOP - 1, spc );

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
   fill - 文字列長をそろえる
   --------------------*/
string fill( string word , int size )
{
    string spc;
    for( int i ; word.length + i < size ; i++ )
        spc ~= " ";
    word ~= spc;
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
char getChar()
{
    bool quit;
    char ret = gsdl.inkey( quit );

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
    textout( c );
    textout( '\n' );
    
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
   isHankaku - 半角文字かどうか
   --------------------*/
bool isHankaku( char c )
{
    return ( ( c & 0x80 ) == 0 );
}



