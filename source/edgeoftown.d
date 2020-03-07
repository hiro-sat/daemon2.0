// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.string : strip ;
/* import std.file; */
/* import std.random; */

/* // derelict SDL */
/* import derelict.sdl2.sdl; */

// mysource 
/* import lib_sdl; */
/* import lib_screen; */

import def;
import app;
import cParty;
import cMember;
/* import app; */
/* import stage; */
/* import cItem; */


//////////////////////////////////////////////////////////////////////////////////
//
/*====== egde of town  ==========================================*/
//
//////////////////////////////////////////////////////////////////////////////////


int eoftown()
{
    int i;
    Member mem;
    char c, ch;
    header_disp( HSTS.EOT );
    scrwin_clear();
  
    while ( true )
    {
        setColor( CL.MENU );
        textout( "*** edge of town ***\n" );
        textout( "c)astle q)uit game\n" );
        textout( "t)raining d)ungeon\n" );
        textout( "r)estart an out party\n" );
        textout( "********************\n" );
        setColor( CL.NORMAL );
        textout( "option? " );
    KEYIN:
        ch = getChar();
        switch (ch)
        {
            case 't': /* training */
                textout( ch );
                textout( '\n' );
                training();
                break;
            case 'q': /* leave game */
                textout( "quit game\n" );
                for (i = 0; i < 20; i++)
                {
                    if (member[ i ].outflag == OUT_F.CASTLE)
                        member[ i ].outflag = OUT_F.BAR;
                }

                appSave;

                textout( "quit playing daemon(y/n)? " );
                if ( answerYN == 'y' )
                {
                    textout( "bye !\n" );
                    getChar;
                    return 2;   // -> quit
                }
                break;
            case 'd': /* dungeon */
                if (party.num >= 1)
                {
                    textout( "dungeon...\n" );
                    party.olayer = 1;
                    party.layer = 1;
                    return 1;   // -> dungeon
                }
                goto KEYIN;
            case 'r': // restart an out party
                textout( ch );
                textout( '\n' );
                for ( i = 0; i < 20; i++ )
                    if ( member[ i ].outflag == OUT_F.CASTLE )
                        member[ i ].outflag = OUT_F.BAR ;
                party.num = 0;
                party.win_disp();
                outmem_disp( null );
                textout( "choose the first party member(z:leave(9))? " );
                while ( true )
                {
                    c = getChar();
                    if ( c == 'z' || c == '9' )
                        break;
                    if ( c >= 'a' && c <= 'a' + 19 
                            && member[ c - 'a' ].outflag == OUT_F.DUNGEON
                            && member[ c - 'a' ].status < STS.PARALY )
                        break;
                    if ( c >= 'a' && c <= 'a' + 19 
                            && member[ c - 'a' ].outflag == OUT_F.DUNGEON
                            && member[ c - 'a' ].status >= STS.PARALY )
                    {
                        textout( c );
                        textout( "\n  choose an alive member(z:leave(9))? " );
                    }
                }
                textout( c );
                textout( '\n' );

                if ( c == 'z' || c == '9' )
                    break;
                mem = member[ c - 'a' ];

                party.mem[ 0 ]  = mem;
                party.num        = 1;
                party.step       = 0;
                party.x          = mem.x;
                party.y          = mem.y;
                party.layer      = mem.layer;
                party.ox         = mem.x;
                party.oy         = mem.y;
                party.olayer     = mem.layer;
                party.status     = 0;
                party.actnum     = 0;
                party.ac         = 0;
                party.win_disp();

                // other party member
                while ( party.num < 6 )
                {
                    outmem_disp( mem );
                    textout( "  add a member(z:leave(9))? " );
                    while ( true )
                    {
                        c = getChar();
                        if ( c == 'z' || c == '9' )
                            break;
                        if ( c < 'a' || c >= 'a' + 20 )
                            continue;
                        if( canAddMem( member[ c - 'a' ] ) )
                            break;
                    }
                    textout( c );
                    textout( '\n' );
                    if ( c == 'z' || c == '9' )
                        break;
                    party.mem[ party.num ] = member[ c - 'a' ];
                    party.num++;
                    party.win_disp();
                }
                scrwin_clear();
                party.win_disp();
                return 1; // maze
            case 'c': /* castle */
                textout( ch );
                textout( '\n' );
                return 0;
            default:
                goto KEYIN;
        }
    }
    return 0;
}

/*------ training ground --------------------------------*/
private void training()
{
    int i;
    char keycode;

    for ( i = 0; i < party.num; i++ )
    {
        party.mem[ i ].outflag = OUT_F.BAR;
        party.mem[ i ] = null;
        party.memsv[ i ] = null;
    }
    for ( i = 0; i < 20; i++ )
    {
        if ( member[ i ].outflag == OUT_F.CASTLE )
            member[ i ].outflag = OUT_F.BAR;
    }
    party.num = 0;
    party.actnum = 0;
    party.win_disp();
  
    header_disp( HSTS.TRAINING );
    scrwin_clear();
  
    while ( true )
    {
        setColor( CL.MENU );
        textout( "\n*** training ground ***\n" );
        textout( "c)reate a character\n" );
        textout( "d)elete a character\n" );
        textout( "h)change a character's class\n" );
        textout( "i)nspect a character\n" );
        textout( "n)change a character's name\n" );
        textout( "s)wap characters (reorder)\n" );
        textout( "z)leave(9)\n" );
        textout( "***********************\n" );
        setColor( CL.NORMAL );
        textout( "option? " );
        while ( true )
        {
            keycode = getChar();
            if (keycode == 'c' || keycode == 'd' || keycode == 'h' 
                    || keycode == 'i' || keycode == 'z' 
                    || keycode == 'n' || keycode == 's' 
                    || keycode == '9')
                break;
        }
        textout( keycode );
        textout( '\n' );
        switch ( keycode )
        {
            case 'c': /* create */
                textout( "create a character\n\n" );
                create_chr();
                scrwin_clear();
                break;
            case 'd': // delete
                delete_chr();
                scrwin_clear();
                break;
            case 'h': // change class
                chg_class();
                scrwin_clear();
                break;
            case 'i': // inspect
                inspect_chr();
                scrwin_clear();
                break;
            case 'z': /* leave */
            case '9': /* leave */
                textout( "leave\n" );
                header_disp( HSTS.EOT );
                return;
            case 'n': // change name
                chg_name();
                scrwin_clear();
                break;
            case 's': // swap characters
                swap_chr();
                scrwin_clear();
                break;
            default:
                assert( 0 );
        }
    }
}



/** 
  canAddMem - パーティに参加できるかどうか
   true:can, false:not
 */
bool canAddMem( Member mem )
{
  
    int i;
  
    if ( mem.name == "" || mem.outflag != OUT_F.DUNGEON )
        return false;
  
    for ( i = 0; i < party.num; i++ )
        if ( mem is party.mem[ i ] )
            return false;
  
    if ( mem.x == party.x 
            && mem.y == party.y
            && mem.layer == party.layer )
        return true;
  
    return false;
}


/**
  outmem_disp - ダンジョンにいるメンバーを表示
   mem=-1 : the first to pick
 */
void outmem_disp( Member mem = null )
{
    int i, num=0;
    scrwin_clear();
    for ( i = 0; i < 20; i++ )
    {
        if ( member[ i ].name != "" && member[ i ].outflag == OUT_F.DUNGEON )
        {
            if( mem is null )
            {
                if ( member[ i ].status >= STS.PARALY )
                    continue;
            }
            else
            {   // mem is not null
                if ( ! canAddMem( member[ i ] ) )
                    continue;
            }

            if ( num % 2 == 0 )
                mvprintw( SCRW_Y_TOP + 1 + ( num / 2 ),  0, to!char( 'a' + i ) );
            else
                mvprintw( SCRW_Y_TOP + 1 + ( num / 2 ), 16, to!char( 'a' + i ) );

            printw(")");
            printw( leftB( member[ i ].name , 14 ) );
            num++;
        }
    }
    return;
}


/**
  chg_class - 転職
  */
void chg_class()
{
    int i;
    Member mem;
    char c;
    CLS cl;
  
    mem_disp();

    textout( "whose class will you change(z:leave(9))? " );
    while ( true )
    {
        c = getChar();
        if ( c - 'a' >= 0 && c - 'a' < 20 
                && !( member[ c - 'a' ].name == "" ) )
            break;
        if ( c == 'z' || c == '9' )
            break;
    }
    textout( c );
    textout( '\n' );
    if ( c == 'z' || c == '9' )
        return;
    mem = member[ c - 'a' ];
  
    mem.char_disp;
    textout( "possible classes are:\n" );

    if (mem.str[ 0 ] >= 11 
            && mem.Class != CLS.FIG)
        textout("  f)ighter\n");

    if (mem.pie[ 0 ] >= 11 
        && mem.Align != 2 
        && mem.Class != CLS.PRI)
        textout("  p)riest\n");

    if (mem.agi[ 0 ] >= 11 
        && mem.Align != 0 
        && mem.Class != CLS.THI)
        textout("  t)hief\n");

    if (mem.iq[ 0 ] >= 11 
        && mem.Class != CLS.MAG)
                textout("  m)age\n");

    if (mem.iq[ 0 ] >= 12 
        && mem.pie[ 0 ] >= 12 
        && mem.Align != 2 
        && mem.Class != CLS.BIS)
        textout("  b)ishop\n");

    if (mem.str[ 0 ] >= 15 
        && mem.iq[ 0 ] >= 11 
        && mem.pie[ 0 ] >= 10 
        && mem.vit[ 0 ] >= 14
        && mem.agi[ 0 ] >= 10 
        && mem.Align != 1 
        && mem.Class != CLS.SAM)
        textout("  s)amurai\n");

    if (mem.str[ 0 ] >= 15 
        && mem.iq[ 0 ] >= 12 
        && mem.pie[ 0 ] >= 12 
        && mem.vit[ 0 ] >= 15
        && mem.agi[ 0 ] >= 14 
        && mem.luk[ 0 ] >= 15 
        && mem.Align == 0 
        && mem.Class != CLS.LOR)
        textout("  l)ord\n");

    if (mem.str[ 0 ] >= 17 
        && mem.iq[ 0 ] >= 17 
        && mem.pie[ 0 ] >= 17 
        && mem.vit[ 0 ] >= 17
        && mem.agi[ 0 ] >= 17 
        && mem.luk[ 0 ] >= 17 
        && mem.Align == 1 
        && mem.Class != CLS.NIN)
        textout("  n)inja\n");

    textout( "select the Class(z:leave(9))? " );
    while ( true )
    {
        c = getChar();
        if ( c == 'z' || c == '9' )
            break;

        if ( c == 'f' 
            && mem.str[ 0 ] >= 11 
            && mem.Class != CLS.FIG )
        {
            cl = CLS.FIG;
            break;
        }

        if (c == 'p' 
            && mem.pie[ 0 ] >= 11 
            && mem.Align != 2 
            && mem.Class != CLS.PRI)
        {
            cl = CLS.PRI;
            break;
        }

        if (c == 't' 
            && mem.agi[ 0 ] >= 11 
            && mem.Align != 0 
            && mem.Class != CLS.THI)
        {
            cl = CLS.THI;
            break;
        }

        if (c == 'm' 
            && mem.iq[ 0 ] >= 11 
            && mem.Class != CLS.MAG)
        {
            cl = CLS.MAG;
            break;
        }
        if (c == 'b' 
            && mem.iq[ 0 ] >= 12 
            && mem.pie[ 0 ] >= 12 
            && mem.Align != 2 
            && mem.Class != CLS.BIS)
        {
            cl = CLS.BIS;
            break;
        }

        if (c == 's' 
            && mem.str[ 0 ] >= 15 
            && mem.iq[ 0 ] >= 11 
            && mem.pie[ 0 ] >= 10
            && mem.vit[ 0 ] >= 14 
            && mem.agi[ 0 ] >= 10 
            && mem.Align != 1 
            && mem.Class != CLS.SAM)
        {
            cl = CLS.SAM;
            break;
        }
        
        if (c == 'l' 
            && mem.str[ 0 ] >= 15 
            && mem.iq[ 0 ] >= 12 
            && mem.pie[ 0 ] >= 12
            && mem.vit[ 0 ] >= 15 
            && mem.agi[ 0 ] >= 14 
            && mem.luk[ 0 ] >= 15
            && mem.Align == 0 
            && mem.Class != CLS.LOR)
        {
            cl = CLS.LOR;
            break;
        }

        if (c == 'n' 
            && mem.str[ 0 ] >= 17 
            && mem.iq[ 0 ] >= 17 
            && mem.pie[ 0 ] >= 17
            && mem.vit[ 0 ] >= 17 
            && mem.agi[ 0 ] >= 17 
            && mem.luk[ 0 ] >= 17
            && mem.Align == 1 
            && mem.Class != CLS.NIN)
        {
            cl = CLS.NIN;
            break;
        }

    }

    textout( c );
    textout( '\n' );
    if (c == 'z' || c == '9')
        return;
  
    mem.exp = 0;
    mem.age += 5;
    mem.level = 1;
    mem.Class = to!byte( cl );

    for (i = 0; i < 8; i++)
        mem.item[ i ].equipped = false;

    switch ( mem.race )
    {
        case RACE.HUMAN:
            mem.str[ 0 ]=8, mem.iq[ 0 ]=8, mem.pie[ 0 ]=5;
            mem.vit[ 0 ]=8, mem.agi[ 0 ]=8, mem.luk[ 0 ]=8;
            break;
        case RACE.ELF:
            mem.str[ 0 ]=7, mem.iq[ 0 ]=10, mem.pie[ 0 ]=10;
            mem.vit[ 0 ]=6, mem.agi[ 0 ]=9, mem.luk[ 0 ]=6;
            break;
        case RACE.DWARF:
            mem.str[ 0 ]=10, mem.iq[ 0 ]=7, mem.pie[ 0 ]=10;
            mem.vit[ 0 ]=10, mem.agi[ 0 ]=5, mem.luk[ 0 ]=6;
            break;
        case RACE.GNOME:
            mem.str[ 0 ]=7, mem.iq[ 0 ]=7, mem.pie[ 0 ]=10;
            mem.vit[ 0 ]=8, mem.agi[ 0 ]=10, mem.luk[ 0 ]=7;
            break;
        case RACE.HOBBIT:
            mem.str[ 0 ]=5, mem.iq[ 0 ]=7, mem.pie[ 0 ]=7;
            mem.vit[ 0 ]=6, mem.agi[ 0 ]=10, mem.luk[ 0 ]=15;
            break;
        default:
            assert( 0 );
    }
    mem.str[ 1 ]=0, mem.iq[ 1 ]=0, mem.pie[ 1 ]=0;
    mem.vit[ 1 ]=0, mem.agi[ 1 ]=0, mem.luk[ 1 ]=0;
  
    mem.char_disp;
    getChar();
  
    return;
}


/**
  chg_name - 名前をかえる
  */
void chg_name()
{
    string name;
    char c;
    Member mem;
    
    mem_disp();
    textout( "whose name will you change(z:leave(9))? " );
    while ( true )
    {
        c = getChar();
        if ( c - 'a' >= 0 && c - 'a' < 20 
                  && !( member[ c - 'a' ].name == "" ) )
            break;
        if ( c == 'z' || c == '9' )
            break;
    }
    textout( c );
    textout( '\n' );
    if ( c == 'z' || c == '9' )
        return;
    mem = member[ c - 'a' ];
    textout( mem.name );
    textout( " will be:\n" );
    name = tline_input( MAX_MEMBER_NAME, text_cury + TXTW_Y_TOP, text_curx + TXTW_X_TOP );
    textout( ">" );
    textout( name );
    textout( "\n" );
    if ( strip( name ) == "" )
    {
        textout( "what?\n" );
        getChar;
        return;
    }
    else
    {
        mem.name = name ;
        textout( "changed.\n" );
    }
    mem_disp();
    textout( "  push any key.\n" );
    getChar();
  
    return;
}

/**
  inspect_chr - キャラクター表示
  */
void inspect_chr()
{
    char c;
    
    mem_disp();

    textout( "who do you want to inspect(z:leave(9))? " );
    while ( true )
    {
        c = getChar();
        if ( c - 'a' >= 0 && c - 'a' < 20 
                && !( member[ c - 'a' ].name == "" ) )
            break;
        if (c == 'z' || c == '9')
            break;
    }
    textout( c );
    textout( '\n' );
    if ( c=='z' || c=='9' ) 
        return;


    member[ c - 'a' ].inspect_chr;
    return;

}

/**
  delete_chr - キャラクタを消す
  */
void delete_chr()
{
    char c;
    int num;
    
    mem_disp();
    textout( "who do you want to delete(z:leave(9))? " );
    while ( true )
    {
        c = getChar();
        if ( c - 'a' >= 0 && c - 'a' < MAXMEMBER
                && !( member[ c - 'a' ].name == "" ) )
            break;
        if ( c == 'z' || c == '9' )
            break;
    }
    textout( c );
    textout( '\n' );
    if ( c=='z' || c=='9' ) 
        return;

    num = c - 'a';
    textout( member[ num ].name );
    textout( " will be deleted(y/n)? " );

    if ( answerYN == 'n' )
        return;

    member[ num ].name = "";
    textout( "  deleted...\n" );
    mem_disp();
    textout( "\n      push any key\n" );
    getChar();

    return;
}


/**
  swap_disp - 入れ替え対象のキャラクタを表示する
  */
void swap_disp()
{
    int i;
    scrwin_clear();
    for ( i = 0; i < 20; i++ )
    {
        if ( i % 2 == 0 )
            mvprintw( SCRW_Y_TOP + 1 + ( i / 2 ), 0, to!char( 'a' + i ) );
        else
            mvprintw( SCRW_Y_TOP + 1 + ( i / 2 ), 16, to!char( 'a' + i ) );

        printw( ")" );
        if ( member[ i ].name != "" )
            printw( leftB( member[ i ].name , 14 ) );
    }
    return;
}

/**
  swap_chr - キャラクタを入れ替える
  */
void swap_chr()
{
    char c;
    int a, b;
    Member mem;
  
    swap_disp();
    
    textout( "choose first character(z:leave(9))? " );
    while ( true )
    {
        c = getChar();
        if ( c == 'z' || c == '9' )
            break;
        if ( c >= 'a' && c <= 't' )
            break;
    }
    textout( c );
    textout( '\n' );
    if ( c == 'z' || c == '9' )
        return;
    a = c - 'a';
    textout( c );
    textout( ')' );
    textout( member[ a ].name );
    textout('\n');
    
    textout( "choose second character(z:leave(9))? " );
    while ( true )
    {
        c = getChar();
        if ( c == 'z' || c == '9' )
            break;
        if ( c >= 'a' && c <= 't' )
            break;
    }
    textout( c );
    textout( '\n' );
    if ( c == 'z' || c == '9' )
        return;
    b = c - 'a';
    textout( c );
    textout( ')' );
    textout( member[ b ].name );
    textout( '\n' );
    
    mem = member[ a ];
    member[ a ] = member[ b ];
    member[ b ] = mem;
    swap_disp();
    
    textout( "done.\n" );
    textout( "  push any key.\n" );
    getChar();
  
    return;
}


/**
  mem_disp - キャラクタ一覧を表示
  */
void mem_disp()
{
    int i, num = 0;

    scrwin_clear();

    for ( i = 0; i < MAXMEMBER; i++ )
    {
        if ( member[ i ].name != "" )
        {
            if ( num % 2 == 0 )
                mvprintw( SCRW_Y_TOP + 1 + ( num / 2 ),  0, to!char( 'a' + i ) );
            else
                mvprintw( SCRW_Y_TOP + 1 + ( num / 2 ), 16, to!char( 'a' + i ) );

            printw(")");
            printw( leftB( member[ i ].name , 14 ) );
            num++;
        }
    }

    return;
}


/**
  create_chr - キャラクタを作成
  */
void create_chr()
{
    Member mem;
    int bonus, classnum;
    int fellow, pnt;
    int i;
    int hpdice = 6;

    char keycode;
  
    for ( fellow = 0; fellow < 20; fellow++ )
        if ( member[ fellow ].name == "" )
            break;
    if ( fellow == 20 )
    {
        textout( "too many characters\n" );
        return;
    }

    mem = new Member;
  
    setColor( CL.MENU );
    textout( "*** enter a name for your character\n" );
    setColor( CL.NORMAL );
    mem.name = tline_input( MAX_MEMBER_NAME, text_cury + TXTW_Y_TOP, text_curx + TXTW_X_TOP );

    textout( ">" );
    textout( mem.name );
    textout( "\n" );
    if ( mem.name == "" )
        return;
  
    /* check name */
    for ( i = 0; i < MAXMEMBER; i++ )
        if ( member[ i ].name != "" && member[ i ].name == mem.name )
        {
            textout( "already exists\n" );
            return;
        }
  
    setColor( CL.MENU );
    textout( "*** choose race ***\n" );
    textout( "h:human, e:elf\n" );
    textout( "d:dwarf, g:gnome\n" );
    textout( "o:hobbit\n" );
    textout( "*******************\n" );
    setColor( CL.NORMAL );
    textout( "option?" );

    mem.str[ 1 ] = 0;
    mem.iq [ 1 ] = 0;
    mem.pie[ 1 ] = 0;
    mem.vit[ 1 ] = 0;
    mem.agi[ 1 ] = 0;
    mem.luk[ 1 ] = 0;
    mem.cha[ 1 ] = 0;
    mem.race = 99;

    while (mem.race == 99)
    {
        keycode = getChar();
        switch (keycode)
        {
            case 'h' : 
                mem.race = RACE.HUMAN;
                mem.str[ 0 ] = 8;
                mem.iq [ 0 ] = 8;
                mem.pie[ 0 ] = 5;
                mem.vit[ 0 ] = 8;
                mem.agi[ 0 ] = 8;
                mem.luk[ 0 ] = 9;
                mem.cha[ 0 ] = to!byte( get_rand( 13 ) + 5 );
                textout( "human\n" );
                break;
            case 'e' : 
                mem.race = RACE.ELF;
                mem.str[ 0 ] = 7;
                mem.iq [ 0 ] = 10;
                mem.pie[ 0 ] = 10;
                mem.vit[ 0 ] = 6;
                mem.agi[ 0 ] = 9;
                mem.luk[ 0 ] = 6;
                mem.cha[ 0 ] = to!byte( get_rand( 8 ) + 10 );
                textout( "elf\n" );
                break;
            case 'd' : 
                mem.race = RACE.DWARF;
                mem.str[ 0 ] = 10;
                mem.iq [ 0 ] = 7;
                mem.pie[ 0 ] = 10;
                mem.vit[ 0 ] = 10;
                mem.agi[ 0 ] = 5;
                mem.luk[ 0 ] = 6;
                mem.cha[ 0 ] = to!byte( get_rand( 18 ) );
                textout( "dwarf\n" );
                break;
            case 'g' : 
                mem.race = RACE.GNOME;
                mem.str[ 0 ] = 7;
                mem.iq [ 0 ] = 7;
                mem.pie[ 0 ] = 10;
                mem.vit[ 0 ] = 8;
                mem.agi[ 0 ] = 10;
                mem.luk[ 0 ] = 7;
                mem.cha[ 0 ] = to!byte( get_rand( 15 ) + 3 );
                textout( "gnome\n" );
                break;
            case 'o' : 
                mem.race = RACE.HOBBIT;
                mem.str[ 0 ] = 5;
                mem.iq [ 0 ] = 7;
                mem.pie[ 0 ] = 7;
                mem.vit[ 0 ] = 6;
                mem.agi[ 0 ] = 10;
                mem.luk[ 0 ] = 15;
                mem.cha[ 0 ] = to!byte( get_rand( 5 ) + 13 );
                textout( "hobbit\n" );
                break;
            default:
                // continue;
        }
    }
  
    setColor( CL.MENU );
    textout( "*** choose alignment ***\n" );
    textout( "g:good\n" );
    textout( "n:neutral\n" );
    textout( "e:vil\n" );
    textout( "************************\n" );
    setColor( CL.NORMAL );
    textout( "option?" );
    mem.Align = 99;
    while ( mem.Align == 99 )
    {
        keycode = getChar();
        switch ( keycode )
        {
            case 'g' :
                mem.Align = ALIGN.GOOD;
                textout( "good\n" );
                break;
            case 'n' : 
                mem.Align = ALIGN.NEWT;
                textout( "neutral\n" );
                break;
            case 'e' : 
                mem.Align = ALIGN.EVIL;
                textout( "evil\n" );
                break;
            default:
                // continue
        }
    }
  
    bonus = get_rand( 1000 );
    if ( bonus == 0 )
        bonus = get_rand( 17 ) + 40;
    else if ( bonus < 20 )
        bonus = get_rand( 9 ) + 30;
    else if ( bonus < 60 )
        bonus = get_rand( 9 ) + 20;
    else if ( bonus < 150 )
        bonus = get_rand( 6 ) + 13;
    else
        bonus = get_rand( 7 ) + 5;


    setColor( CL.MENU );
    textout( "\n*** distribute bonus points ***\n" );
    textout( "h(4):minus\n" );
    textout( "j(2):lower pointer\n" );
    textout( "k(8):upper pointer\n" );
    textout( "l(6):plus\n" );
    textout( "z(5):accept\n" );
    textout( "*******************************\n" );
    setColor( CL.NORMAL );
    textout( "option?\n" );

    pnt = 0;
    classnum = 0;
    byte para0;
    byte* para1;
    bool done = false;

    bonus_disp( bonus, pnt, mem );
    while ( !done )
    {
        keycode = getChar();
        switch ( keycode )
        {
            case 'h':
            case '4':
                para1 = mem.getParaPtr( pnt , para0 );
                if ( *para1 > 0)
                {
                    *para1 -= 1;
                    bonus ++;
                }
                classnum = bonus_disp( bonus, pnt, mem );
                break;
            case 'l':
            case '6':
                para1 = mem.getParaPtr( pnt , para0 );
                if ( ( *para1 + para0 < 18 ) && bonus > 0 )
                {
                    *para1 += 1;
                    bonus --;
                }
                classnum = bonus_disp( bonus, pnt, mem );
                break;
            case 'k':
            case '8':
                if (pnt > 0)
                    pnt--;
                classnum = bonus_disp( bonus, pnt, mem );
                break;
            case 'j':
            case '2':
                if (pnt < 5)
                    pnt++;
                classnum = bonus_disp( bonus, pnt, mem );
                break;
            case 'z':
            case '5':
            case '\n':
                if ( bonus == 0 && classnum != 0 )
                    done = true;
                break;
            default:
                break;
        }
    }
  
    mem.Class = 99;
    setColor( CL.MENU );
    textout( "*** select class ***\n" );
    setColor( CL.NORMAL );
    textout( "class?\n" );
    
    while ( mem.Class == 99 )
    {
        keycode = getChar();
        switch ( keycode )
        {
            case 'f':
                if ( mem.str[ 0 ] + mem.str[ 1 ] >= 11 )
                {
                    mem.Class = CLS.FIG;
                    hpdice = 10;
                }
                break;
            case 'm':
                if ( mem.iq[ 0 ] + mem.iq[ 1 ] >= 11 )
                {
                    mem.Class = CLS.MAG;
                    hpdice = 4;
                }
                break;
            case 'p':
                if ( mem.pie[ 0 ] + mem.pie[ 1 ] >= 11 
                        && mem.Align < 2 )
                {
                    mem.Class = CLS.PRI;
                    hpdice = 8;
                }
                break;
            case 't':
                if ( mem.agi[ 0 ] + mem.agi[ 1 ] >= 11 
                        && mem.Align > 0 )
                {
                  mem.Class = CLS.THI;
                  hpdice = 6;
                }
                break;
            case 'b':
                if ( mem.iq[ 0 ] + mem.iq[ 1 ] >= 12 
                        && mem.pie[ 0 ] + mem.pie[ 1 ] >= 12 
                        && mem.Align < 2 )
                {
                  mem.Class = CLS.BIS;
                  hpdice = 6;
                }
                break;
            case 's':
                if ( mem.str[ 0 ] + mem.str[ 1 ] >= 15 
                        && mem.pie[ 0 ] + mem.pie[ 1 ] >= 10
                        && mem.iq[ 0 ] + mem.iq[ 1 ] >= 11 
                        && mem.vit[ 0 ] + mem.vit[ 1 ] >= 14
                        && mem.agi[ 0 ] + mem.agi[ 1 ] >= 10 
                        && mem.Align != 1 )
                {
                    mem.Class = CLS.SAM;
                    hpdice = 8;
                }
                break;
            case 'l':
                if ( mem.str[ 0 ] + mem.str[ 1 ] >= 15 
                        && mem.pie[ 0 ] + mem.pie[ 1 ] >= 12 
                        && mem.iq[ 0 ] + mem.iq[ 1 ] >= 12 
                        && mem.vit[ 0 ] + mem.vit[ 1 ] >= 15 
                        && mem.agi[ 0 ] + mem.agi[ 1 ] >= 14 
                        && mem.luk[ 0 ] + mem.luk[ 1 ] >= 15 
                        && mem.Align == 0 )
                    {
                        mem.Class = CLS.LOR;
                        hpdice = 10;
                     }
                break;
            case 'n':
                if ( mem.str[ 0 ] + mem.str[ 1 ] >= 17 
                        && mem.pie[ 0 ] + mem.pie[ 1 ] >= 17
                        && mem.iq[ 0 ] + mem.iq[ 1 ] >= 17 
                        && mem.vit[ 0 ] + mem.vit[ 1 ] >= 17
                        && mem.agi[ 0 ] + mem.agi[ 1 ] >= 17 
                        && mem.luk[ 0 ] + mem.luk[ 1 ] >= 17 
                        && mem.Align == 1 )
                {
                    mem.Class = CLS.NIN;
                    hpdice = 6;
                }
                break;
            default:
                // continue
        }
    }
  
    mem.ac[ 0 ] = 10;
    mem.ac[ 1 ] = 0;
  
    mem.range = RANGE.SHORT;
    mem.atk[ 0 ] = 1;
    mem.atk[ 1 ] = 3;
    mem.atk[ 2 ] = 0;
    if ( mem.Class == CLS.NIN )
        mem.atk[ 1 ] = 7;
  
    mem.str[ 0 ] += mem.str[ 1 ];
    mem.str[ 1 ] = 0;
    mem.iq [ 0 ] += mem.iq[ 1 ];
    mem.iq [ 1 ] = 0;
    mem.pie[ 0 ] += mem.pie[ 1 ];
    mem.pie[ 1 ] = 0;
    mem.vit[ 0 ] += mem.vit[ 1 ];
    mem.vit[ 1 ] = 0;
    mem.agi[ 0 ] += mem.agi[ 1 ];
    mem.agi[ 1 ] = 0;
    mem.luk[ 0 ] += mem.luk[ 1 ];
    mem.luk[ 1 ] = 0;
    mem.cha[ 0 ] += mem.cha[ 1 ];
    mem.cha[ 1 ] = 0;
    mem.gold = get_rand( 150 ) + 50;
    mem.level = 1;
    mem.maxhp = get_rand( hpdice - 1 ) + 1;

    if ( mem.vit[ 0 ] >= 18 )
        mem.maxhp += 3;
    else if ( mem.vit[ 0 ] >= 17 )
        mem.maxhp += 2;
    else if ( mem.vit[ 0 ] >= 16 )
        mem.maxhp += 1;
    else if ( mem.vit[ 0 ] <= 3 )
        mem.maxhp -= 2;
    else if ( mem.vit[ 0 ] <= 5 )
        mem.maxhp--;

    if ( mem.maxhp <= 4 )
        mem.maxhp = 4;
    mem.hp = mem.maxhp;
    mem.age = get_rand( 6 ) + 14;
  
    for ( i = 0; i < MAXCARRY; i++ )
      mem.item[ i ].setNull;
  
    mem.learn_spell;
  
    mem.char_disp;
  
    setColor( CL.MENU );
    textout("keep this character(y/n)?\n");
    setColor( CL.NORMAL );

    if ( answerYN == 'y' )
        member[ fellow ] = mem;
    //else
    //    nothing done

    return;

}


private int bonus_disp( int bonus, int pnt, Member mem )
{
    int classnum = 0;
  
    rewriteOff;

    switch( mem.Align )
    {
        case ALIGN.GOOD:
            mvprintw( SCRW_Y_TOP + 1, SCRW_X_TOP + 16, "align:Good" );
            break;
        case ALIGN.EVIL:
            mvprintw( SCRW_Y_TOP + 1, SCRW_X_TOP + 16, "align:Evil" );
            break;
        case ALIGN.NEWT:
            mvprintw( SCRW_Y_TOP + 1, SCRW_X_TOP + 16, "align:Neutral" );
            break;
        default:
            assert( 0 );
    }

    mvprintw( SCRW_Y_TOP + 3, SCRW_X_TOP + 2, "strength " );
    intDispD( mem.str[0] + mem.str[1], 2 );
    mvprintw( SCRW_Y_TOP + 4, SCRW_X_TOP + 2, "i.q.     " );
    intDispD( mem.iq[0] + mem.iq[1], 2 );
    mvprintw( SCRW_Y_TOP + 5, SCRW_X_TOP + 2, "piety    " );
    intDispD( mem.pie[0] + mem.pie[1], 2 );
    mvprintw( SCRW_Y_TOP + 6, SCRW_X_TOP + 2, "vitality " );
    intDispD( mem.vit[0] + mem.vit[1], 2 );
    mvprintw( SCRW_Y_TOP + 7, SCRW_X_TOP + 2, "agility  " );
    intDispD( mem.agi[0] + mem.agi[1], 2 );
    mvprintw( SCRW_Y_TOP + 8, SCRW_X_TOP + 2, "luck     " );
    intDispD( mem.luk[0] + mem.luk[1], 2 );
    

    setColor( CL.BONUS );
    mvprintw( SCRW_Y_TOP + 10, SCRW_X_TOP + 2, "bonus    " );
    intDispD( bonus, 2 );
    setColor( CL.NORMAL );

    
    mvprintw( SCRW_Y_TOP + 3, SCRW_X_TOP + 2 - 1, ' ' );
    mvprintw( SCRW_Y_TOP + 4, SCRW_X_TOP + 2 - 1, ' ' );
    mvprintw( SCRW_Y_TOP + 5, SCRW_X_TOP + 2 - 1, ' ' );
    mvprintw( SCRW_Y_TOP + 6, SCRW_X_TOP + 2 - 1, ' ' );
    mvprintw( SCRW_Y_TOP + 7, SCRW_X_TOP + 2 - 1, ' ' );
    mvprintw( SCRW_Y_TOP + 8, SCRW_X_TOP + 2 - 1, ' ' );
    mvprintw( SCRW_Y_TOP + 3 + pnt, SCRW_X_TOP + 2 - 1, '>' );
    

    if ( mem.str[0] + mem.str[1] >= 11 )
    {
        mvprintw( SCRW_Y_TOP + 3, SCRW_X_TOP + 16, "f)ighter" );
        classnum++;
    }
    else
    {
        mvprintw( SCRW_Y_TOP + 3, SCRW_X_TOP + 16, "        " );
    }

    if (mem.iq[0] + mem.iq[1] >= 11)
    {
        mvprintw( SCRW_Y_TOP + 4, SCRW_X_TOP + 16, "m)age" );
        classnum++;
    }
    else
    {
        mvprintw( SCRW_Y_TOP + 4, SCRW_X_TOP + 16, "     " );
    }

    if ( mem.pie[0] + mem.pie[1] >= 11 
            && mem.Align < 2 )
    {
        mvprintw( SCRW_Y_TOP + 5, SCRW_X_TOP + 16, "p)riest" );
        classnum++;
    }
    else
    {
        mvprintw( SCRW_Y_TOP + 5, SCRW_X_TOP + 16, "       " );
    }

    if ( mem.agi[0] + mem.agi[1] >= 11 
            && mem.Align > 0 )
    {
        mvprintw( SCRW_Y_TOP + 6, SCRW_X_TOP + 16, "t)hief" );
        classnum++;
    }
    else
    {
        mvprintw( SCRW_Y_TOP + 6, SCRW_X_TOP + 16, "      " );
    }

    if ( mem.iq[0] + mem.iq[1] >= 12 
            && mem.pie[0] + mem.pie[1] >= 12 
            && mem.Align < 2 )
    {
        mvprintw( SCRW_Y_TOP + 7, SCRW_X_TOP + 16, "b)ishop" );
        classnum++;
    }
    else
    {
        mvprintw( SCRW_Y_TOP + 7, SCRW_X_TOP + 16, "       " );
    }

    if ( mem.str[0] + mem.str[1] >= 15 
            && mem.pie[0] + mem.pie[1] >= 10
            && mem.iq[0] + mem.iq[1] >= 11 
            && mem.vit[0] + mem.vit[1] >= 14
            && mem.agi[0] + mem.agi[1] >= 10 
            && mem.Align != ALIGN.EVIL )
    {
        mvprintw( SCRW_Y_TOP + 8, SCRW_X_TOP + 16, "s)amurai" );
        classnum++;
    }
    else
    {
        mvprintw( SCRW_Y_TOP + 8, SCRW_X_TOP + 16, "        " );
    }

    if ( mem.str[0] + mem.str[1] >= 15 
            && mem.pie[0] + mem.pie[1] >= 12
            && mem.iq[0] + mem.iq[1] >= 12 
            && mem.vit[0] + mem.vit[1] >= 15
            && mem.agi[0] + mem.agi[1] >= 14 
            && mem.luk[0] + mem.luk[1] >= 15 
            && mem.Align == ALIGN.GOOD )
    {
        mvprintw( SCRW_Y_TOP + 9, SCRW_X_TOP + 16, "l)ord" );
        classnum++;
    }
    else
    {
        mvprintw( SCRW_Y_TOP + 9, SCRW_X_TOP + 16, "     " );
    }

    if ( mem.str[0] + mem.str[1] >= 17 
            && mem.pie[0] + mem.pie[1] >= 17
            && mem.iq[0] + mem.iq[1] >= 17 
            && mem.vit[0] + mem.vit[1] >= 17
            && mem.agi[0] + mem.agi[1] >= 17 
            && mem.luk[0] + mem.luk[1] >= 17 
            && mem.Align == 1 )
    {
        mvprintw( SCRW_Y_TOP + 10, SCRW_X_TOP + 16, "n)inja" );
        classnum++;
    }
    else
    {
        mvprintw( SCRW_Y_TOP + 10, SCRW_X_TOP + 17, "      " );
    }

    rewriteOn;

    return classnum;
}
