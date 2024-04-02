// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.string : strip ;

// mysource 
import def;
import app;

import ctextarea;
import cparty;
import cmember;


//////////////////////////////////////////////////////////////////////////////////
//
/*====== egde of town  ==========================================*/
//
//////////////////////////////////////////////////////////////////////////////////

class EdgeOfTown
{
public:
    int egOfTown()
    {
        int i;
        Member mem;
        char c, ch;
        dispHeader( HSTS.EOT );
        txtStatus.clear();
      
        while ( true )
        {
            setColor( CL.MENU );
            txtMessage.textout( "\n" );
            txtMessage.textout( _( "*** edge of town ***\n" ) );
            txtMessage.textout( _( "c)astle q)uit game\n" ) );
            txtMessage.textout( _( "t)raining d)ungeon\n" ) );
            txtMessage.textout( _( "r)estart an out party\n" ) );
            txtMessage.textout( _( "********************\n" ) );
            setColor( CL.NORMAL );
            txtMessage.textout( "option? " );
        KEYIN:
            ch = getChar();
            switch (ch)
            {
                case 't': /* training */
                    txtMessage.textout( _( "training\n" ) );
                    training();
                    break;
                case 'q': /* leave game */
                    txtMessage.textout( _( "quit game\n" ) );
                    for (i = 0; i < MAXMEMBER ; i++)
                    {
                        if (member[ i ].outflag == OUT_F.CASTLE)
                            member[ i ].outflag = OUT_F.BAR;
                    }

                    appSave;

                    txtMessage.textout( _( "quit playing daemon(y/n)? " ) );
                    if ( answerYN == 'y' )
                    {
                        txtMessage.textout( "bye !\n" );
                        getChar;
                        return 2;   // -> quit
                    }
                    break;
                case 'd': /* dungeon */
                    if ( party.checkAlive )
                    {
                        txtMessage.textout( _( "dungeon...\n" ) );
                        party.olayer = 1;
                        party.layer = 1;
                        dungeonMap[ 0 ].setStartPos;    // party x , y <- layer1 Upstairs
                        foreach( d ; dungeonMap )
                            d.resetEventFlg;    // 全てのイベントフラグをクリア ※ダンジョンに入る時にリセット（フロア移動時はクリアされない）
                        return 1;   // -> dungeon
                    }
                    goto KEYIN;
                case 'r': // restart an out party
                    txtMessage.textout( _( "restart an out party\n" ) );
                    for ( i = 0; i < MAXMEMBER; i++ )
                        if ( member[ i ].outflag == OUT_F.CASTLE )
                            member[ i ].outflag = OUT_F.BAR ;

                    // パーティ解散
                    party.disband;
                    party.dispPartyWindow();

                    outmem_disp( null );
                    txtMessage.textout( _( "choose the first party member(z:leave(9))? " ) );
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
                            txtMessage.textout( c );
                            txtMessage.textout( _( "\n  choose an alive member(z:leave(9))? " ) );
                        }
                    }
                    txtMessage.textout( c );
                    txtMessage.textout( '\n' );

                    if ( c == 'z' || c == '9' )
                        break;
                    mem = member[ c - 'a' ];

                    party.mem[ 0 ]  = mem;
                    party.step       = 0;
                    party.x          = mem.x;
                    party.y          = mem.y;
                    party.layer      = mem.layer;
                    party.ox         = mem.x;
                    party.oy         = mem.y;
                    party.olayer     = mem.layer;
                    party.status     = 0;
                    party.ac         = 0;
                    party.dispPartyWindow();

                    // other party member
                    while ( party.memCount < 6 )
                    {
                        outmem_disp( mem );
                        txtMessage.textout( _( "  add a member(z:leave(9))? " ) );
                        while ( true )
                        {
                            c = getChar();
                            if ( c == 'z' || c == '9' )
                                break;
                            if ( c < 'a' || c >= 'a' + MAXMEMBER )
                                continue;
                            if( canAddMem( member[ c - 'a' ] ) )
                                break;
                        }
                        txtMessage.textout( c );
                        txtMessage.textout( '\n' );
                        if ( c == 'z' || c == '9' )
                            break;
                        party.add( member[ c - 'a' ] );
                        party.dispPartyWindow();
                    }
                    txtStatus.clear();
                    party.dispPartyWindow();
                    return 1; // maze
                case 'c': /* castle */
                    txtMessage.textout( _( "castle\n" ) );
                    return 0;
                default:
                    goto KEYIN;
            }
        }
        return 0;
    }

private:
    /*------ training ground --------------------------------*/
    private void training()
    {
        int i;
        char keycode;

        foreach( Member p ; party )
            p.outflag = OUT_F.BAR;

        for ( i = 0; i < MAXMEMBER ; i++ )
        {
            if ( member[ i ].outflag == OUT_F.CASTLE )
                member[ i ].outflag = OUT_F.BAR;
        }

        party.disband;      // 解散
        party.dispPartyWindow();
      
        dispHeader( HSTS.TRAINING );
        txtStatus.clear();
      
        while ( true )
        {
            setColor( CL.MENU );
            txtMessage.textout( _( "\n*** training ground ***\n" ) );
            txtMessage.textout( _( "c)reate a character\n" ) );
            txtMessage.textout( _( "d)elete a character\n" ) );
            txtMessage.textout( _( "h)change a character's class\n" ) );
            txtMessage.textout( _( "i)nspect a character\n" ) );
            txtMessage.textout( _( "n)change a character's name\n" ) );
            txtMessage.textout( _( "s)wap characters (reorder)\n" ) );
            txtMessage.textout( _( "z)leave(9)\n" ) );
            txtMessage.textout( _( "***********************\n" ) );
            setColor( CL.NORMAL );
            txtMessage.textout( "option? " );
            while ( true )
            {
                keycode = getChar();
                if (keycode == 'c' || keycode == 'd' || keycode == 'h' 
                        || keycode == 'i' || keycode == 'z' 
                        || keycode == 'n' || keycode == 's' 
                        || keycode == '9')
                    break;
            }
            txtMessage.textout( keycode );
            txtMessage.textout( '\n' );
            switch ( keycode )
            {
                case 'c': /* create */
                    txtMessage.textout( _( "create a character\n\n" ) );
                    createCharacter();
                    txtStatus.clear();
                    break;
                case 'd': // delete
                    txtMessage.textout( _( "delete a character\n\n" ) );
                    deleteCharacter();
                    txtStatus.clear();
                    break;
                case 'h': // change class
                    txtMessage.textout( _( "change a character's class\n\n" ) );
                    changeClass();
                    txtStatus.clear();
                    break;
                case 'i': // inspect
                    txtMessage.textout( _( "inspect a character\n\n" ) );
                    inspectCharacter();
                    txtStatus.clear();
                    break;
                case 'z': /* leave */
                case '9': /* leave */
                    txtMessage.textout( _( "leave the training ground.\n" ) );
                    dispHeader( HSTS.EOT );
                    return;
                case 'n': // change name
                    txtMessage.textout( _( "change a character's name\n\n" ) );
                    changeName();
                    txtStatus.clear();
                    break;
                case 's': // swap characters
                    txtMessage.textout( _( "swap a character (reorder)\n\n" ) );
                    swapCharacter();
                    txtStatus.clear();
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
      
        foreach( p ; party )
            if ( mem is p )
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
        int x;
        string name;

        txtStatus.clear();
        for ( i = 0; i < MAXMEMBER ; i++ )
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


                name = formatText( "%1)%2"  
                                , to!string( cast(char)( 'a' + i ) )
                                , leftB( member[ i ].name , 13 ) );

                x = ( ( num % 2 == 0 ) ? 1 : 17 );
                member[ i ].setStatusColor;
                txtStatus.print( 1 + ( num / 2 ),  x , name ) ;

                num++;

            }
        }
        setColor( CL.NORMAL );
        return;
    }


    /**
      changeClass - 転職
      */
    void changeClass()
    {
        int i;
        Member mem;
        char c;
        CLS cl;
      
        mem_disp();

        txtMessage.textout( _( "whose class will you change(z:leave(9))? " ) );
        while ( true )
        {
            c = getChar();
            if ( c - 'a' >= 0 && c - 'a' < MAXMEMBER 
                    && !( member[ c - 'a' ].name == "" ) )
                break;
            if ( c == 'z' || c == '9' )
                break;
        }
        txtMessage.textout( c );
        txtMessage.textout( '\n' );
        if ( c == 'z' || c == '9' )
            return;
        mem = member[ c - 'a' ];
      
        mem.dispCharacter;
        txtMessage.textout( _( "possible classes are:\n" ) );

        if (mem.str[ 0 ] >= 11 
                && mem.Class != CLS.FIG)
            txtMessage.textout("  f)ighter\n");

        if (mem.pie[ 0 ] >= 11 
            && mem.Align != 2 
            && mem.Class != CLS.PRI)
            txtMessage.textout("  p)riest\n");

        if (mem.agi[ 0 ] >= 11 
            && mem.Align != 0 
            && mem.Class != CLS.THI)
            txtMessage.textout("  t)hief\n");

        if (mem.iq[ 0 ] >= 11 
            && mem.Class != CLS.MAG)
                    txtMessage.textout("  m)age\n");

        if (mem.iq[ 0 ] >= 12 
            && mem.pie[ 0 ] >= 12 
            && mem.Align != 2 
            && mem.Class != CLS.BIS)
            txtMessage.textout("  b)ishop\n");

        if (mem.str[ 0 ] >= 15 
            && mem.iq[ 0 ] >= 11 
            && mem.pie[ 0 ] >= 10 
            && mem.vit[ 0 ] >= 14
            && mem.agi[ 0 ] >= 10 
            && mem.Align != 1 
            && mem.Class != CLS.SAM)
            txtMessage.textout("  s)amurai\n");

        if (mem.str[ 0 ] >= 15 
            && mem.iq[ 0 ] >= 12 
            && mem.pie[ 0 ] >= 12 
            && mem.vit[ 0 ] >= 15
            && mem.agi[ 0 ] >= 14 
            && mem.luk[ 0 ] >= 15 
            && mem.Align == 0 
            && mem.Class != CLS.LOR)
            txtMessage.textout("  l)ord\n");

        if (mem.str[ 0 ] >= 17 
            && mem.iq[ 0 ] >= 17 
            && mem.pie[ 0 ] >= 17 
            && mem.vit[ 0 ] >= 17
            && mem.agi[ 0 ] >= 17 
            && mem.luk[ 0 ] >= 17 
            && mem.Align == 1 
            && mem.Class != CLS.NIN)
            txtMessage.textout("  n)inja\n");

        txtMessage.textout( _( "select the Class(z:leave(9))? " ) );
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

        txtMessage.textout( c );
        txtMessage.textout( '\n' );
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
      
        mem.dispCharacter;
        getChar();
      
        return;
    }


    /**
      changeName - 名前をかえる
      */
    void changeName()
    {
        string name;
        char c;
        Member mem;
        
        mem_disp();
        txtMessage.textout( _( "whose name will you change(z:leave(9))? " ) );
        while ( true )
        {
            c = getChar();
            if ( c - 'a' >= 0 && c - 'a' < MAXMEMBER
                      && !( member[ c - 'a' ].name == "" ) )
                break;
            if ( c == 'z' || c == '9' )
                break;
        }
        txtMessage.textout( c );
        txtMessage.textout( '\n' );
        if ( c == 'z' || c == '9' )
            return;
        mem = member[ c - 'a' ];
        txtMessage.textout( _( " %1 will be:\n" ) , mem.name );
        name = txtMessage.input( MAX_MEMBER_NAME , "> " );
        txtMessage.textout( "> " );
        txtMessage.textout( name );
        txtMessage.textout( "\n" );
        if ( strip( name ) == "" )
        {
            txtMessage.textout( _( "what?\n" ) );
            getChar;
            return;
        }
        else
        {
            mem.name = name ;
            txtMessage.textout( _( "changed.\n" ) );
        }
        mem_disp();
        txtMessage.textout( "  push any key.\n" );
        getChar();
      
        return;
    }

    /**
      inspectCharacter - キャラクター表示
      */
    void inspectCharacter()
        
    {
        char c;
        
    TOP:
        mem_disp();

        txtMessage.textout( _( "who do you want to inspect(z:leave(9))? " ) );
        while ( true )
        {
            c = getChar();
            if ( c - 'a' >= 0 && c - 'a' < MAXMEMBER
                    && !( member[ c - 'a' ].name == "" ) )
                break;
            if (c == 'z' || c == '9')
                break;
        }
        txtMessage.textout( c );
        txtMessage.textout( '\n' );
        if ( c=='z' || c=='9' ) 
            return;


        member[ c - 'a' ].inspectCharacter( 0 );
        goto TOP;

    }

    /**
      deleteCharacter - キャラクタを消す
      */
    void deleteCharacter()
    {
        char c;
        int num;
        
        mem_disp();
        txtMessage.textout( _( "who do you want to delete(z:leave(9))? " ) );
        while ( true )
        {
            c = getChar();
            if ( c - 'a' >= 0 && c - 'a' < MAXMEMBER
                    && !( member[ c - 'a' ].name == "" ) )
                break;
            if ( c == 'z' || c == '9' )
                break;
        }
        txtMessage.textout( c );
        txtMessage.textout( '\n' );
        if ( c=='z' || c=='9' ) 
            return;

        num = c - 'a';
        txtMessage.textout( _( " %1 will be deleted(y/n)? " ) , member[ num ].name );

        if ( answerYN == 'n' )
            return;

        member[ num ].name = "";
        txtMessage.textout( _( "  deleted...\n" ) );
        mem_disp();
        txtMessage.textout( "\n      push any key\n" );
        getChar();

        return;
    }


    /**
      swap_disp - 入れ替え対象のキャラクタを表示する
      */
    void swap_disp()
    {
        int i;
        txtStatus.clear();
        for ( i = 0; i < MAXMEMBER ; i++ )
        {
            if ( i % 2 == 0 )
                mvprintw( SCRW_Y_TOP + 1 + ( i / 2 ), 1, to!char( 'a' + i ) );
            else
                mvprintw( SCRW_Y_TOP + 1 + ( i / 2 ), 17, to!char( 'a' + i ) );

            printw( ")" );
            if ( member[ i ].name != "" )
            {
                member[ i ].setStatusColor;
                printw( leftB( member[ i ].name , 13 ) );
                setColor( CL.NORMAL );
            }
        }
        return;
    }

    /**
      swapCharacter - キャラクタを入れ替える
      */
    void swapCharacter()
    {
        char c;
        int a, b;
        Member mem;

    TOP:
        swap_disp();
        
        txtMessage.textout( _( "choose first character(z:leave(9))? " ) );
        while ( true )
        {
            c = getChar();
            if ( c == 'z' || c == '9' )
                break;
            if ( c >= 'a' && c <= 'a' + MAXMEMBER )
                break;
        }
        txtMessage.textout( c );
        txtMessage.textout( '\n' );
        if ( c == 'z' || c == '9' )
            return;
        a = c - 'a';
        txtMessage.textout( c );
        txtMessage.textout( ')' );
        txtMessage.textout( member[ a ].name );
        txtMessage.textout('\n');
        
        txtMessage.textout( _( "choose second character(z:leave(9))? " ) );
        while ( true )
        {
            c = getChar();
            if ( c == 'z' || c == '9' )
                break;
            if ( c >= 'a' && c <= 'a' + MAXMEMBER )
                break;
        }
        txtMessage.textout( c );
        txtMessage.textout( '\n' );
        if ( c == 'z' || c == '9' )
            return;
        b = c - 'a';
        txtMessage.textout( c );
        txtMessage.textout( ')' );
        txtMessage.textout( member[ b ].name );
        txtMessage.textout( '\n' );
        
        mem = member[ a ];
        member[ a ] = member[ b ];
        member[ b ] = mem;
        
        txtMessage.textout( _( "done.\n" ) );
        // txtMessage.textout( "  push any key.\n" );
        // getChar();
      
        goto TOP;
    }


    /**
      mem_disp - キャラクタ一覧を表示
      */
    void mem_disp()
    {
        int i, num = 0;

        txtStatus.clear();

        for ( i = 0; i < MAXMEMBER; i++ )
        {
            if ( member[ i ].name != "" )
            {
                member[ i ].setStatusColor;
                if ( num % 2 == 0 )
                    mvprintw( SCRW_Y_TOP + 1 + ( num / 2 ),  1, to!char( 'a' + i ) );
                else
                    mvprintw( SCRW_Y_TOP + 1 + ( num / 2 ), 17, to!char( 'a' + i ) );

                printw(")");
                printw( leftB( member[ i ].name , 13 ) );
                num++;
            }
        }

        setColor( CL.NORMAL );
        return;
    }


    /**
      createCharactery - キャラクタを作成
      */
    void createCharacter()
    {
        Member mem;
        int bonus, classnum;
        int fellow, pnt;
        int i;
        int hpdice = 6;

        char keycode;
      
        for ( fellow = 0; fellow < MAXMEMBER ; fellow++ )
            if ( member[ fellow ].name == "" )
                break;
        if ( fellow == MAXMEMBER  )
        {
            txtMessage.textout( _( "too many characters\n" ) );
            return;
        }

        mem = new Member;
      
        setColor( CL.MENU );
        txtMessage.textout( _( "*** enter a name for your character\n" ) );
        setColor( CL.NORMAL );
        mem.name = txtMessage.input( MAX_MEMBER_NAME , "> " );

        txtMessage.textout( "> " );
        txtMessage.textout( mem.name );
        txtMessage.textout( "\n" );
        if ( mem.name == "" )
            return;
      
        /* check name */
        for ( i = 0; i < MAXMEMBER; i++ )
            if ( member[ i ].name != "" && member[ i ].name == mem.name )
            {
                txtMessage.textout( _( "already exists\n" ) );
                getChar;
                return;
            }
      
        setColor( CL.MENU );
        txtMessage.textout( _( "*** choose race ***\n" ) );
        txtMessage.textout( _( "h:human, e:elf\n" ) );
        txtMessage.textout( _( "d:dwarf, g:gnome\n" ) );
        txtMessage.textout( _( "o:hobbit\n" ) );
        txtMessage.textout( _( "*******************\n" ) );
        setColor( CL.NORMAL );
        txtMessage.textout( "option?" );

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
                    txtMessage.textout( "human\n" );
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
                    txtMessage.textout( "elf\n" );
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
                    txtMessage.textout( "dwarf\n" );
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
                    txtMessage.textout( "gnome\n" );
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
                    txtMessage.textout( "hobbit\n" );
                    break;
                default:
                    // continue;
            }
        }
      
        setColor( CL.MENU );
        txtMessage.textout( _( "*** choose alignment ***\n" ) );
        txtMessage.textout( _( "g:good\n" ) );
        txtMessage.textout( _( "n:neutral\n" ) );
        txtMessage.textout( _( "e:vil\n" ) );
        txtMessage.textout( _( "************************\n" ) );
        setColor( CL.NORMAL );
        txtMessage.textout( "option?" );
        mem.Align = 99;
        while ( mem.Align == 99 )
        {
            keycode = getChar();
            switch ( keycode )
            {
                case 'g' :
                    mem.Align = ALIGN.GOOD;
                    txtMessage.textout( "good\n" );
                    break;
                case 'n' : 
                    mem.Align = ALIGN.NEWT;
                    txtMessage.textout( "neutral\n" );
                    break;
                case 'e' : 
                    mem.Align = ALIGN.EVIL;
                    txtMessage.textout( "evil\n" );
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
        txtMessage.textout( _( "\n*** distribute bonus points ***\n" ) );
        txtMessage.textout( _( "h(4):minus\n" ) );
        txtMessage.textout( _( "j(2):lower pointer\n" ) );
        txtMessage.textout( _( "k(8):upper pointer\n" ) );
        txtMessage.textout( _( "l(6):plus\n" ) );
        txtMessage.textout( _( "z(5):accept\n" ) );
        txtMessage.textout( _( "*******************************\n" ) );
        setColor( CL.NORMAL );
        txtMessage.textout( "option?\n" );

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
                case LEFT_ARROW:
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
                case RIGHT_ARROW:
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
                case UP_ARROW:
                    if (pnt > 0)
                        pnt--;
                    classnum = bonus_disp( bonus, pnt, mem );
                    break;
                case 'j':
                case '2':
                case DOWN_ARROW:
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
        txtMessage.textout( _( "*** select class ***\n" ) );
        setColor( CL.NORMAL );
        txtMessage.textout( "class?\n" );
        
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
      
        mem.learnSpell;
      
        mem.dispCharacter;
      
        setColor( CL.MENU );
        txtMessage.textout(_( "keep this character(y/n)?\n" ));
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

}
