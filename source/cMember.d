// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.string : format , split , chop , isNumeric;
import std.conv;

// mysource 
import cItem;
import cBattleTurn;
import cMonsterTeam;
import cMonster;

import def;
import app;


class Member
{
private:

    // status bit
    enum BIT_STS_POISONED           = 0x80;
    enum BIT_STS_EXCEPTING_POISONED = 0x7f;

    void equip_sub( ITM_KIND itm_kind )
    {
        int i;
        char ch;
        int curseflag = 0;

        Item itm;

        for ( i = 0; i < 8; i++ )
        {
            if ( item[ i ].isNothing )
                continue ;

            if ( ( item[ i ].kind == itm_kind ) && item[ i ].canBeEquipped( Class ) )
            {
                if ( item[ i ].cursed )
                    curseflag = 1;

                textout( to!string( i + 1 ) ~ ")" ~ item[ i ].getDispNameA ~ "\n" );

                if( ! item[ i ].cursed && item[ i ].equipped )
                    item[ i ].equipped = false;
            }
        }

        ch = getChar();

        if ( curseflag != 0 )
        {
            textout( _( "you are cursed...\n" ) );
        }
        else if ( ( ch <= '8' && ch >= '1' ) && ( ! item[ ch-'1' ].isNothing ) )
        {
            itm = item[ ch - '1' ];
            if ( ( itm.kind == itm_kind ) && itm.canBeEquipped( Class )  )
            {
                if ( ( itm.Align & ( 1 << Align ) ) != 0 )
                {
                    itm.equipped = true;
                    itm.cursed = true;
                    textout( _( "*** oops! you got cursed ...\n" ) );
                }
                else
                {
                    itm.equipped = true;
                }
            }
            else if ( ! itm.isNothing )
            {
                textout( _( "you cannot equip it.\n" ) );
            }
        }

        for ( i = 0; i < MAXCARRY; i++ )
        {
            itm = item[ i ];
            if ( itm.isNothing )
                continue;

            if ( itm.kind != itm_kind )
                continue;

            if ( itm.effect[ 2 ] == 0 )
                continue;

            textout( _( "do you want to use the special power\n  of %1 (y/n)?" ) , itm.getDispName );

            while ( true )
            {
                ch = getChar();
                if ( ch == 'y' || ch == 'n' )
                    break;
            }
            textout( to!string( ch ) ~ "\n" );

            if ( ch == 'y' )
            {
                switch ( itm.effect[ 2 ] )
                {
                //  個別スペシャルパワー処理
                    case 2: // vit+1(shurikens)
                        if ( vit[ 0 ] < 18 )
                            vit[ 0 ]++;
                        break;
                    case 3: // str+1(muramasa_katana)
                        if ( str[ 0 ] < 18 )
                            str[ 0 ]++;
                        break;
                    default:
                        assert( 0 );
                }
                if ( itm.broken >= get_rand(99) + 1 )
                    itm.setItem = 0; // broken item
            }
        }
        inspect();

        return;
    }
    

    /*--------------------
       getTargetMonster - target から Monster 取得。MonsterTeamはMonsterから取得
       --------------------*/
    Monster getTargetMonster()
    {
        int i;

        MonsterTeam mt;

        if ( monParty.num - 1 < target )
          target = 0; /* if not exist . top team */

        mt = monParty.top;

        for ( i = 0; i < target; i++ )
            mt = mt.next;

        if ( mt !is null )
            return  mt.top;

        /* else */
        mt = monParty.top;
        return mt.top;

    }

    /*--------------------
       getTargetMonsterTeam - target から MonsterTeam を取得。
       --------------------*/
    MonsterTeam getTargetMonsterTeam()
    {
        MonsterTeam mt;

        if ( monParty.num - 1 < target )
            target = 0; /* if not exist . top team */

        mt = monParty.top;

        for ( int i = 0 ; i < target ; i++)
            mt = mt.next;
        
        return mt;

    }

public:
    long exp;
    long nextexp;
    long gold;
    int level;
    int hp;
    int maxhp;
    int marks;
    int rip;
    int age;
    int day;

    /* int[MAXCARRY] item;  /* item (Max8) bit15:equipped, bit14:cursed, bit13:unidentified */
    /*                     // equiped / cursed / undefined / 1fff : itemno */
    Item[ MAXCARRY ] item;

    byte[8] mspl_know;
    byte[8] pspl_know;
    /* byte[8] msplcnt; */
    /* byte[8] psplcnt; */
    byte[8] mspl_max;
    byte[8] mspl_pt;
    byte[8] pspl_max;
    byte[8] pspl_pt;

    string name; /* name (Max32chr) */
    byte status; /* 0:Ok,1:Sleep,2:Afraid,3:Pararized,4:Stoned */
                 /* 5:Dead,6:Ashed,7:Lost, and bit7:Poisoned */
    bool poisoned; // class 時でのみ利用。保存時は statusとマージ
    byte race; /* 0:Human,1:Elf,2:Dwarf,3:Gnome,4:Hobbit */
    byte Class; /* (int) 0:FIG,1:THI,2:PRI,3:MAG,4:BIS,5:SAM,6:LOR,7:NIN */
    byte Align; /* 0:Good,1:Evil,2:Newtral */
    int[2] ac;
    byte[2] str; /* 1:additonal(item, etc) */
    byte[2] iq;
    byte[2] pie;
    byte[2] vit;
    byte[2] agi;
    byte[2] luk;
    byte[2] cha;
    byte range;  /* 1:short, 2:long, 0:don't equip */
    short[3] atk; /* 0:mindmg, 1:adddmg, 2:cnt */

    byte atkef; /* same as item */
    bool isAtkefCritical()
        { return ( ( atkef & ITM_ATKEF.CRITICAL   ) != 0 );  }
    bool isAtkefStone()
        { return ( ( atkef & ITM_ATKEF.STONE      ) != 0 );  }
    bool isAtkefSleep()
        { return ( ( atkef & ITM_ATKEF.SLEEP      ) != 0 );  }
    bool isAtkefHuman()
        { return ( ( atkef & ITM_ATKEF.HUMAN      ) != 0 );  }
    bool isAtkefAnimal()
        { return ( ( atkef & ITM_ATKEF.ANIMAL     ) != 0 );  }
    bool isAtkefDragon()
        { return ( ( atkef & ITM_ATKEF.DRAGON     ) != 0 );  }
    bool isAtkefDemon()
        { return ( ( atkef & ITM_ATKEF.DEMON      ) != 0 );  }
    bool isAtkefInsect()
        { return ( ( atkef & ITM_ATKEF.INSECT     ) != 0 );  }


    byte defef; /* same as item */
    bool isDefefCritical()
        { return ( ( defef & ITM_DEFEF.CRITICAL   ) != 0 );  }
    bool isDefefStone()
        { return ( ( defef & ITM_DEFEF.STONE      ) != 0 );  }
    bool isDefefParalize()
        { return ( ( defef & ITM_DEFEF.PARALIZE   ) != 0 );  }
    bool isDefefSleep()
        { return ( ( defef & ITM_DEFEF.SLEEP      ) != 0 );  }
    bool isDefefPoison()
        { return ( ( defef & ITM_DEFEF.POISON     ) != 0 );  }
    bool isDefefFire()
        { return ( ( defef & ITM_DEFEF.FIRE       ) != 0 );  }
    bool isDefefIce()
        { return ( ( defef & ITM_DEFEF.ICE        ) != 0 );  }
    bool isDefefDrain()
        { return ( ( defef & ITM_DEFEF.DRAIN      ) != 0 );  }


    byte magdef; /* tolerate at magdef/256 */
 
    // for battle ( not saved )
    int  action; // 0:fight,1:parry,3:use,4:run, 0x80-:spell
    int  actitem; // item number
    int  target; /* target monster team or spell or item */
    bool silenced; // 1:silenced, 0:not
    
    byte outflag; /* 0:in bar, 1:in castle, 3:in maze */
    byte x;
    byte y;
    byte layer;

    // for treasure ( not saved )
    int predict;

    /*--------------------
       this - コンストラクタ（ファイル読取）
        data : MEMBERFILE の1行
       --------------------*/
    this( string line )
    {

        auto data = split( line.chop, "\t" );

        int i = 0; 
        name = to!string( data[ i++ ] );

        range = to!byte( data[ i++ ] );
        atk[0] = cast(short) to!int( data[ i++ ] );
        atk[1] = cast(short) to!int( data[ i++ ] );
        atk[2] = cast(short) to!int( data[ i++ ] );

        level = to!int( data[ i++ ] );
        exp = to!long( data[ i++ ] );
        gold = to!long( data[ i++ ] );
        hp = to!int( data[ i++ ] );
        maxhp = to!int( data[ i++ ] );
        ac[ 0 ] = to!int( data[ i++ ] );
        nextexp = 0;

        marks  = to!int( data[ i++ ] );
        rip    = to!int( data[ i++ ] );

        byte sts  = to!byte( data[ i++ ] );
        status   = sts & BIT_STS_EXCEPTING_POISONED;
        poisoned = ( ( sts & BIT_STS_POISONED ) != 0 );

        race   = to!byte( data[ i++ ] );
        Class  = to!byte( data[ i++ ] );
        Align  = to!byte( data[ i++ ] );

        str[0] = to!byte( data[ i++ ] );
        iq[0]  = to!byte( data[ i++ ] );
        pie[0] = to!byte( data[ i++ ] );
        vit[0] = to!byte( data[ i++ ] );
        agi[0] = to!byte( data[ i++ ] );
        luk[0] = to!byte( data[ i++ ] );
        cha[0] = to!byte( data[ i++ ] );

        str[1] = to!byte( data[ i++ ] );
        iq[1]  = to!byte( data[ i++ ] );
        pie[1] = to!byte( data[ i++ ] );
        vit[1] = to!byte( data[ i++ ] );
        agi[1] = to!byte( data[ i++ ] );
        luk[1] = to!byte( data[ i++ ] );
        cha[1] = to!byte( data[ i++ ] );


        item[0] = new Item( this , to!int( data[ i++ ] ) );
        item[1] = new Item( this , to!int( data[ i++ ] ) );
        item[2] = new Item( this , to!int( data[ i++ ] ) );
        item[3] = new Item( this , to!int( data[ i++ ] ) );
        item[4] = new Item( this , to!int( data[ i++ ] ) );
        item[5] = new Item( this , to!int( data[ i++ ] ) );
        item[6] = new Item( this , to!int( data[ i++ ] ) );
        item[7] = new Item( this , to!int( data[ i++ ] ) );

        mspl_know[0] = cast( byte ) parse!(int)( data[ i++ ], 16);
        mspl_know[1] = cast( byte ) parse!(int)( data[ i++ ], 16);
        mspl_know[2] = cast( byte ) parse!(int)( data[ i++ ], 16);
        mspl_know[3] = cast( byte ) parse!(int)( data[ i++ ], 16);
        mspl_know[4] = cast( byte ) parse!(int)( data[ i++ ], 16);
        mspl_know[5] = cast( byte ) parse!(int)( data[ i++ ], 16);
        mspl_know[6] = cast( byte ) parse!(int)( data[ i++ ], 16);

        pspl_know[0] = cast( byte ) parse!(int)( data[ i++ ], 16);
        pspl_know[1] = cast( byte ) parse!(int)( data[ i++ ], 16);
        pspl_know[2] = cast( byte ) parse!(int)( data[ i++ ], 16);
        pspl_know[3] = cast( byte ) parse!(int)( data[ i++ ], 16);
        pspl_know[4] = cast( byte ) parse!(int)( data[ i++ ], 16);
        pspl_know[5] = cast( byte ) parse!(int)( data[ i++ ], 16);
        pspl_know[6] = cast( byte ) parse!(int)( data[ i++ ], 16);

        mspl_max[0]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        mspl_pt [0]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 
        mspl_max[1]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        mspl_pt [1]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 
        mspl_max[2]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        mspl_pt [2]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 
        mspl_max[3]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        mspl_pt [3]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 
        mspl_max[4]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        mspl_pt [4]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 
        mspl_max[5]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        mspl_pt [5]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 
        mspl_max[6]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        mspl_pt [6]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 

        pspl_max[0]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        pspl_pt [0]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 
        pspl_max[1]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        pspl_pt [1]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 
        pspl_max[2]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        pspl_pt [2]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 
        pspl_max[3]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        pspl_pt [3]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 
        pspl_max[4]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        pspl_pt [4]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 
        pspl_max[5]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        pspl_pt [5]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 
        pspl_max[6]  = to!byte( to!int( data[ i   ][ 0 ] ) - '0') ; 
        pspl_pt [6]  = to!byte( to!int( data[ i++ ][ 1 ] ) - '0') ; 


        age     = to!int( data[ i++ ] );
        day     = to!int( data[ i++ ] );
        x       = to!byte( data[ i++ ] );
        y       = to!byte( data[ i++ ] ); 
        layer   = to!byte( data[ i++ ] );
        outflag = to!byte( data[ i++ ] );

        return;

    }


    /*--------------------
       this - コンストラクタ（初期化用）
       --------------------*/
    this()
    {

        int j;

        name = "";
        
        exp     = 0;
        nextexp = 0;
        gold    = 0;
        level   = 1;
        hp      = 6;
        maxhp   = 6;
        marks   = 0;
        rip     = 0;
        age     = 18;
        day     = 0;

        for ( j = 0 ; j < MAXCARRY ; j++ )
              item[j] = new Item( this );

        for ( j = 0 ; j < 8 ; j++ )
        {
            mspl_know[j] = 0;
            pspl_know[j] = 0;
            mspl_max[j]  = 0;
            pspl_max[j]  = 0;
            mspl_pt [j]  = 0;
            pspl_pt [j]  = 0;
        }
        status   = STS.OK;
        poisoned = false; 
        race    = RACE.HUMAN;
        Class   = CLS.FIG;
        Align   = ALIGN.NEWT;
        ac[0]   = 10;
        ac[1]   = 0;
        str[0]  = 10;
        iq[0]   = 10;
        pie[0]  = 10;
        vit[0]  = 10;
        agi[0]  = 10;
        luk[0]  = 10;
        cha[0]  = 10;
        str[1]  = 0;
        iq[1]   = 0;
        pie[1]  = 0;
        vit[1]  = 0;
        agi[1]  = 0;
        luk[1]  = 0;
        cha[1]  = 0;
        range   = 1;
        atk[0]  = 1;
        atk[1]  = 3;
        atk[2]  = 0;
        atkef   = 0;
        defef   = 0;
        magdef  = 0;
        outflag = OUT_F.BAR;
        x       = 0;
        y       = 0;
        layer   = 0;

        return;
    }

    /* bool isPoisoned() { return ( ( status & BIT_STS_POISONED ) != 0 ); } */
    /* void curePoison() { status &= BIT_STS_EXCEPTING_POISONED; } */


    /*--------------------
       save - ファイル保存
       --------------------*/
    void save( File fout )
    {

        fout.writef( "%s\t" , name );
        fout.writef( "%d\t" , range );
        fout.writef( "%d\t" , atk[ 0 ]);
        fout.writef( "%d\t" , atk[ 1 ]);
        fout.writef( "%d\t" , atk[ 2 ]);

        fout.writef( "%d\t" , level );
        fout.writef( "%d\t" , exp );
        fout.writef( "%d\t" , gold );
        fout.writef( "%d\t" , hp );
        fout.writef( "%d\t" , maxhp );
        fout.writef( "%d\t" , ac[ 0 ] );
        /* fout.writef( "%ld\t" , nextexp ); */

        fout.writef( "%d\t" , marks  ) ;
        fout.writef( "%d\t" , rip    ) ;

        int sts = status;
        if( poisoned )
            sts |= BIT_STS_POISONED;
        fout.writef( "%d\t" , sts ) ;

        fout.writef( "%d\t" , race   ) ;
        fout.writef( "%d\t" , Class  ) ;
        fout.writef( "%d\t" , Align  ) ;

        fout.writef( "%d\t" , str[0] ) ;
        fout.writef( "%d\t" , iq[0]  ) ;
        fout.writef( "%d\t" , pie[0] ) ;
        fout.writef( "%d\t" , vit[0] ) ;
        fout.writef( "%d\t" , agi[0] ) ;
        fout.writef( "%d\t" , luk[0] ) ;
        fout.writef( "%d\t" , cha[0] ) ;

        fout.writef( "%d\t" , str[1] ) ;
        fout.writef( "%d\t" , iq[1]  ) ;
        fout.writef( "%d\t" , pie[1] ) ;
        fout.writef( "%d\t" , vit[1] ) ;
        fout.writef( "%d\t" , agi[1] ) ;
        fout.writef( "%d\t" , luk[1] ) ;
        fout.writef( "%d\t" , cha[1] ) ;

        fout.writef( "%d\t" , item[0].getItemSavedata ) ;
        fout.writef( "%d\t" , item[1].getItemSavedata ) ;
        fout.writef( "%d\t" , item[2].getItemSavedata ) ;
        fout.writef( "%d\t" , item[3].getItemSavedata ) ;
        fout.writef( "%d\t" , item[4].getItemSavedata ) ;
        fout.writef( "%d\t" , item[5].getItemSavedata ) ;
        fout.writef( "%d\t" , item[6].getItemSavedata ) ;
        fout.writef( "%d\t" , item[7].getItemSavedata ) ;

        fout.writef( "%02x\t" , mspl_know[0] ) ;
        fout.writef( "%02x\t" , mspl_know[1] ) ;
        fout.writef( "%02x\t" , mspl_know[2] ) ;
        fout.writef( "%02x\t" , mspl_know[3] ) ;
        fout.writef( "%02x\t" , mspl_know[4] ) ;
        fout.writef( "%02x\t" , mspl_know[5] ) ;
        fout.writef( "%02x\t" , mspl_know[6] ) ;

        fout.writef( "%02x\t" , pspl_know[0] ) ;
        fout.writef( "%02x\t" , pspl_know[1] ) ;
        fout.writef( "%02x\t" , pspl_know[2] ) ;
        fout.writef( "%02x\t" , pspl_know[3] ) ;
        fout.writef( "%02x\t" , pspl_know[4] ) ;
        fout.writef( "%02x\t" , pspl_know[5] ) ;
        fout.writef( "%02x\t" , pspl_know[6] ) ;

        fout.writef( "%02x\t" , mspl_max[0] * 0x10 + mspl_pt[0]  ) ;
        fout.writef( "%02x\t" , mspl_max[1] * 0x10 + mspl_pt[1]  ) ;
        fout.writef( "%02x\t" , mspl_max[2] * 0x10 + mspl_pt[2]  ) ;
        fout.writef( "%02x\t" , mspl_max[3] * 0x10 + mspl_pt[3]  ) ;
        fout.writef( "%02x\t" , mspl_max[4] * 0x10 + mspl_pt[4]  ) ;
        fout.writef( "%02x\t" , mspl_max[5] * 0x10 + mspl_pt[5]  ) ;
        fout.writef( "%02x\t" , mspl_max[6] * 0x10 + mspl_pt[6]  ) ;
                                           
        fout.writef( "%02x\t" , pspl_max[0] * 0x10 + pspl_pt[0]  ) ;
        fout.writef( "%02x\t" , pspl_max[1] * 0x10 + pspl_pt[1]  ) ;
        fout.writef( "%02x\t" , pspl_max[2] * 0x10 + pspl_pt[2]  ) ;
        fout.writef( "%02x\t" , pspl_max[3] * 0x10 + pspl_pt[3]  ) ;
        fout.writef( "%02x\t" , pspl_max[4] * 0x10 + pspl_pt[4]  ) ;
        fout.writef( "%02x\t" , pspl_max[5] * 0x10 + pspl_pt[5]  ) ;
        fout.writef( "%02x\t" , pspl_max[6] * 0x10 + pspl_pt[6]  ) ;

        fout.writef( "%d\t" , age     ) ;
        fout.writef( "%d\t" , day     ) ;
        fout.writef( "%d\t" , x       ) ;
        fout.writef( "%d\t" , y       ) ;
        fout.writef( "%d\t" , layer   ) ;
        fout.writef( "%d\t" , outflag ) ;

        fout.writef( "\n" ) ;

        return;
    }

    /*--------------------
       getPartyNo - パーティ内の番号を取得
       --------------------*/
    int getPartyNo()
    {
        return party.getMemberNo( this );
    }

    /*--------------------
       char_disp - ステータス表示 does not display items nor magics 
       --------------------*/
    void char_disp()
    {
        int difflevel;

        scrwin_clear();

        rewriteOff;

        mvprintw( SCRW_Y_TOP + 1, SCRW_X_TOP, "                 ");
        mvprintw( SCRW_Y_TOP + 1, SCRW_X_TOP, leftB( name , 20 ) );
        
        mvprintw( SCRW_Y_TOP + 1, SCRW_X_TOP + 21, " age ");
        intDispD( age, 3 );
      
        switch( Align )
        {
            case ALIGN.GOOD:
                mvprintw(SCRW_Y_TOP + 2, SCRW_X_TOP, "g" );
                break;
            case ALIGN.EVIL:
                mvprintw(SCRW_Y_TOP + 2, SCRW_X_TOP, "e" );
                break;
            case ALIGN.NEWT:
                mvprintw(SCRW_Y_TOP + 2, SCRW_X_TOP, "n" );
                break;
            default:
                assert( 0 );
        }
        switch( Class )
        {
            case CLS.FIG:
                printw("-fig ");
                break;
            case CLS.THI:
                printw("-thi ");
                break;
            case CLS.PRI:
                printw("-pri ");
                break;
            case CLS.MAG:
                printw("-mag ");
                break;
            case CLS.BIS:
                printw("-bis ");
                break;
            case CLS.SAM:
                printw("-sam ");
                break;
            case CLS.LOR:
                printw("-lor ");
                break;
            case CLS.NIN:
                printw("-nin ");
                break;
            default:
                assert( 0 );
        }
        switch( race )
        {
            case RACE.HUMAN:
                printw("human ");
                break;
            case RACE.ELF:
                printw("elf   ");
                break;
            case RACE.DWARF:
                printw("dwarf ");
                break;
            case RACE.GNOME: 
                printw("gnome ");
                break;
            case RACE.HOBBIT:
                printw("hobbit");
                break;
            default:
                assert( 0 );
        }
        mvprintw( SCRW_Y_TOP + 2, SCRW_X_TOP + 13, "ac " );
        if( ac[ 0 ] >=  - 999 )
            intDispD( ac[ 0 ] , 4 );
        else
            printw( "VVVL" );

        printw("  day ");
        intDispD( day, 3 );
        mvprintw( SCRW_Y_TOP + 3, SCRW_X_TOP + 10, "level " );
        difflevel = calcLevel() - level;
        if (difflevel == 0)
        {
            intDispD( level, 13 );
        }
        else
        {
            intDispD( level, 8 );
            printw("(+");
            intDispD( difflevel, 2 );
            printw(")");
        }
      
        mvprintw( SCRW_Y_TOP + 4, SCRW_X_TOP, " str " );
        intDispD( str[ 0 ] + str[ 1 ], 2);
        printw("   gold ");
        intDispD( gold, 14 );
      
        mvprintw( SCRW_Y_TOP + 5, SCRW_X_TOP, " i.q " );
        intDispD( iq[ 0 ] + iq[ 1 ], 2 );
        printw( "   ep" );
        intDispD( exp, 17 );
      
        mvprintw( SCRW_Y_TOP + 6, SCRW_X_TOP, " pie " );
        intDispD( pie[ 0 ] + pie[ 1 ] , 2 );
        printw( "   next" );
        if( nextexp - exp >= 0 )
        {
            intDispD( nextexp - exp, 15 );
        }
        else
        {
            intDispD( 0, 7 );
            printw( "(" );
            intDispD( calcNextExp( calcLevel() ) - exp, 6 );
            printw( ")" );
        }
      
        mvprintw( SCRW_Y_TOP + 7 , SCRW_X_TOP , " vit " );
        intDispD( vit[ 0 ] + vit[ 1 ] , 2 );
        printw( "   marks " );
        intDispD( marks, 13 );
      
        mvprintw( SCRW_Y_TOP + 8 , SCRW_X_TOP , " agi " );
        intDispD( agi[ 0 ] + agi[ 1 ] , 2 );
        printw( "   h.p. " );
        intDispD( hp, 6 );
        printw( "/" );
        intDispD( maxhp, 7 );
      
        mvprintw( SCRW_Y_TOP + 9 , SCRW_X_TOP , " luk " );
        intDispD( luk[ 0 ] + luk[ 1 ] , 2 );
        printw( "   rip" );
        intDispD( rip, 3 );
        printw( " sts " );
      
        switch( status )
        {
            case STS.OK:
                if( poisoned )
                    printw( "poisoned" );
                else
                    printw( "      ok" );
                break;
            case STS.SLEEP:
                printw( "   sleep" );
                break;
            case STS.AFRAID:
                printw( "  afraid" );
                break;
            case STS.PARALY:
                printw( "paralizd" );
                break;
            case STS.STONED:
                printw( "  stoned" );
                break;
            case STS.DEAD:
                printw( "    dead" );
                break;
            case STS.ASHED:
                printw( "   ashed" );
                break;
            case STS.LOST:
                printw( "    lost" );
                break;
            default:
                assert( 0 );
        }
      
        mvprintw( SCRW_Y_TOP + 10 , SCRW_X_TOP , " cha " );
        intDispD( cha[ 0 ] + cha[ 1 ], 2 );

        printw( "   mage " );
        intDispD( mspl_pt[ 0 ] , 1 );
        printw( "/" );
        intDispD( mspl_pt[ 1 ] , 1 );
        printw( "/" );
        intDispD( mspl_pt[ 2 ] , 1 );
        printw( "/" );
        intDispD( mspl_pt[ 3 ] , 1 );
        printw( "/" );
        intDispD( mspl_pt[ 4 ] , 1 );
        printw( "/" );
        intDispD( mspl_pt[ 5 ] , 1 );
        printw( "/" );
        intDispD( mspl_pt[ 6 ] , 1 );

        mvprintw( SCRW_Y_TOP + 11 , SCRW_X_TOP , "       " );
        printw( "    max " );
        intDispD( mspl_max[ 0 ] , 1 );
        printw( "/" );
        intDispD( mspl_max[ 1 ] , 1 );
        printw( "/" );
        intDispD( mspl_max[ 2 ] , 1 );
        printw( "/" );
        intDispD( mspl_max[ 3 ] , 1 );
        printw( "/" );
        intDispD( mspl_max[ 4 ] , 1 );
        printw( "/" );
        intDispD( mspl_max[ 5 ] , 1 );
        printw( "/" );
        intDispD( mspl_max[ 6 ] , 1 );
      
        mvprintw( SCRW_Y_TOP + 12 , SCRW_X_TOP , "       " );
        printw( "   prst " );
        intDispD( pspl_pt[ 0 ] , 1 );
        printw( "/" );
        intDispD( pspl_pt[ 1 ] , 1 );
        printw( "/" );
        intDispD( pspl_pt[ 2 ] , 1 );
        printw( "/" );
        intDispD( pspl_pt[ 3 ] , 1 );
        printw( "/" );
        intDispD( pspl_pt[ 4 ] , 1 );
        printw( "/" );
        intDispD( pspl_pt[ 5 ] , 1 );
        printw( "/" );
        intDispD( pspl_pt[ 6 ] , 1 );

        mvprintw( SCRW_Y_TOP + 13 , SCRW_X_TOP , "       " );
        printw( "    max " );
        intDispD( pspl_max[ 0 ] , 1 );
        printw( "/" );
        intDispD( pspl_max[ 1 ] , 1 );
        printw( "/" );
        intDispD( pspl_max[ 2 ] , 1 );
        printw( "/" );
        intDispD( pspl_max[ 3 ] , 1 );
        printw( "/" );
        intDispD( pspl_max[ 4 ] , 1 );
        printw( "/" );
        intDispD( pspl_max[ 5 ] , 1 );
        printw( "/" );
        intDispD( pspl_max[ 6 ] , 1 );
      
        rewriteOn;

        return;
    }

    /*--------------------
       inspect - ステータス情報等表示
       --------------------*/
    void inspect()
    {
        int i, difflevel;
      
        scrwin_clear();
      
        rewriteOff;

        /* mem = party.mem[ no ]; */
        
        mvprintw( SCRW_Y_TOP + 1, SCRW_X_TOP, "                 ");
        mvprintw( SCRW_Y_TOP + 1, SCRW_X_TOP, leftB( name , 20 ) );
        mvprintw( SCRW_Y_TOP + 1 + 1, SCRW_X_TOP, "age ");
        intDispD( age, 3);
        printw( " rip " );
        intDispD( rip, 3 ); /*++++++++++++++++++++++++++++*/
        printw(" marks ");
        intDispD( marks, 7 );

        difflevel = calcLevel() - level;
        mvprintw( SCRW_Y_TOP + 3, SCRW_X_TOP, "lvl" );
        if ( difflevel == 0 )
        {
            intDispD( level, 11 );
        }
        else
        {
           intDispD( level, 6 );
           printw( "(+" );
           intDispD( difflevel, 2 );
           printw( ")" );
        }
      
        printw( " gp" );
        intDispD( gold, 12 );
        mvprintw( SCRW_Y_TOP + 4, SCRW_X_TOP, "ep" );
        intDispD( exp, 12 );
        printw( " next" );
        if ( nextexp - exp >= 0 )
        {
            intDispD( nextexp - exp, 10 );
        }
        else
        {
            printw( " 0(" );
            intDispD( calcNextExp( calcLevel() ) - exp, 6 );
            printw(")");
        }
      
        // spell
        mvprintw( SCRW_Y_TOP + 5, SCRW_X_TOP, "m0/0/0/0/0/0/0 p0/0/0/0/0/0/0" );
        for (i = 0; i < 7; i++)
        {
            mvIntDispD( SCRW_Y_TOP + 5, SCRW_X_TOP +  1 + i * 2, mspl_pt[ i ] , 1 );
            mvIntDispD( SCRW_Y_TOP + 5, SCRW_X_TOP + 16 + i * 2, pspl_pt[ i ] , 1 );
        }

        // item
        for ( i = 0; i < 8; i++ )
        {
            if ( item[ i ].isNothing )
                continue;

            mvprintw( SCRW_Y_TOP + 6 + i, SCRW_X_TOP, "                             " );
            mvIntDispD( SCRW_Y_TOP + 6 + i, SCRW_X_TOP, i + 1, 1 );
            printw( ") " );

            printw( item[ i ].getDispNameA );

            if ( ! item[ i ].canBeEquipped( Class ) )
                mvprintw( SCRW_Y_TOP + 6 + i, SCRW_X_TOP + 2, "#" ); /* cannot equip */

            if ( item[ i ].equipped )
                mvprintw( SCRW_Y_TOP + 6 + i, SCRW_X_TOP + 2, "*" ); /* equipped */

            if ( item[ i ].cursed )
                mvprintw( SCRW_Y_TOP + 6 + i, SCRW_X_TOP + 2, "$" ); /* cursed */
        }
        mvprintw( SCRW_Y_TOP, SCRW_X_TOP, "                             " );

        rewriteOn;

        return;
    }


    /*--------------------
       inspect_chr - メンバー詳細情報表示
        type: 1:camp , 2:battle
       --------------------*/
    void inspect_chr( int type = 0 )
    {

        char_disp;

        textout( _( "  push any key to see items\n" ) );
        getChar();
        item_disp;

        textout( _( "  push any key to read mage spells\n" ) );
        getChar();
        disp_mspell();

        textout( _( "  push any key to read priest spells\n" ) );
        getChar();
        disp_pspell();

        textout( _( "  push any key to return\n" ) );
        getChar();

        return;

    }




    /*--------------------
       dispStatusLine - パーティウィンドウ ステータス表示
       --------------------*/
    /* void partymem_disp( int num ) */
    void dispStatusLine( int num )
    {
        char ch_diff;
        int plus, diff;
        int line_y = CHRW_Y_TOP + num + 1;
        string line;

        line = to!string( num + 1 );

        nextexp = calcNextExp();
        if( nextexp <= exp )
        {
            diff = calcLevel() - level;
            if (diff > 15)
                diff = 15;
            ch_diff = cast(char)( '!' + diff - 1 );
            line ~= to!string( ch_diff ) ;
        }
        else
        {
            line ~= " ";
        }
        line ~= ( leftB( name , 16 ) ) ~ " " ;

        /* align & class */
        switch( Align )
        {
            case ALIGN.GOOD:
                line ~= "g-";
                break;
            case ALIGN.EVIL:
                line ~= "e-";
                break;
            default:
                line ~= "n-";
        }

        switch( Class )
        {
            case CLS.FIG:
                line ~= "fig";
                break;
            case CLS.THI:
                line ~= "thi";
                break;
            case CLS.PRI:
                line ~= "pri";
                break;
            case CLS.MAG:
                line ~= "mag";
                break;
            case CLS.BIS:
                line ~= "bis";
                break;
            case CLS.SAM:
                line ~= "sam";
                break;
            case CLS.LOR:
                line ~= "lor";
                break;
            case CLS.NIN:
                line ~= "nin";
                break;
              default:
                line ~= "???";
          }

        if( ac[ 0 ] + ac[ 1 ] >=  -99 )
        {
            line ~= intFormat( ac[ 0 ] + ac[ 1 ] + party.ac , 4 );
        }
        else
        {
            line ~= "  VL";
        }

        plus = getHpPlus();
        if( plus > 0 )
            line ~= "+";
        else if ( plus < 0 || poisoned )
            line ~= "-";
        else
            line ~= " ";

        line ~= intFormat( hp, 5 ) ~ "/" ~ ( to!string( maxhp ) ~ "      ")[ 0 .. 6 ];

        switch( status )
        {
            case STS.OK:
                if( silenced )
                    line ~= "silenc ";
                else
                if( poisoned )
                    line ~= "poison " ;
                else
                    /* line ~= "ok     "; */
                    line ~= "lv." ~ intFormat( level , 3 ) ~ " ";
                break;
            case STS.SLEEP:
                line ~= "sleep  ";
                break;
            case STS.AFRAID:
                line ~= "afraid ";
                break;
            case STS.PARALY:
                line ~= "pararz ";
                break;
            case STS.STONED:
                line ~= "stoned ";
                break;
            case STS.DEAD:
                line ~= "dead   ";
                break;
            case STS.ASHED:
                line ~= "ashed  ";
                break;
            case STS.LOST:
                line ~= "lost   ";
                break;
            default:
                assert( 0 );
                /* mvprintw( line_y , CHRW_X_TOP + 41 , "poison" ); */
        }
        line ~= "?????? ???????????????????????" ;

        mvprintw( line_y , CHRW_X_TOP , line );

        return;
    }


    /*--------------------
       calcNextExp - Next Exp 計算
       --------------------*/
    long calcNextExp()
    {
        return calcNextExp( level );
    }
    long calcNextExp( int lv )
    {
        int i;
        long next ,add;

        switch( Class ) 
        {
            case CLS.FIG: 
                next = 1000;
                add = 289709;
                break;
            case CLS.THI: 
                next = 900;
                add = 260369;
                break;
            case CLS.PRI: 
                next = 1050;
                add = 304132;
                break;
            case CLS.MAG: 
                next = 1100;
                add = 318529;
                break;
            case CLS.BIS: 
                next = 1200;
                add = 438479;
                break;
            case CLS.SAM: 
                next = 1250;
                add = 456601;
                break;
            case CLS.LOR: 
                next = 1300;
                add = 475008;
                break;
            case CLS.NIN: 
                next = 1450;
                add = 529756;
                break;

            default:
                break;
        }

        if( lv != 1 )
        {
            if ( lv > 13 )
            {
                for( i = 0 ; i < 12 ; i++ )
                {
                    next *= 1723;
                    next /= 1000;
                }
                for( i = 0 ; i < lv - 13 ; i++ )
                    next += add;
            }
            else
            {
                for( i = 0 ; i < lv - 1 ; i++ )
                {
                    next *= 1723;
                    next /= 1000;
                }
            }
        }

        /* nextexp = next; */
        return next;
    }

    /*--------------------
       calcLevel - 現在のレベル計算？
       --------------------*/
    int calcLevel()
    {
        int lv = level;

        while ( true )
        {
            if( calcNextExp( lv ) > exp)
                break;
            lv++;
        }

        return lv;
    }

    /*--------------------
       calcAtkAC - AC 計算`
       --------------------*/
    void calcAtkAC()
    {
        int i, equip, _ac;
        Item itm;

        range    = 1;
        ac[ 0 ]  = 10;
        atk[ 0 ] = 1;
        atk[ 1 ] = 3;
        atk[ 2 ] = 0;
        atkef    = 0;
        defef    = 0;
        magdef   = 0;

        for( i = 0 ; i < 8 ; i++ )
        {
            if ( item[ i ].isNothing )
                continue;

            if ( ! item[ i ].equipped )
                continue;

            if ( item[ i ].cursed )
                continue;

            itm = item[ i ];

            ac[ 0 ] += itm.ac;
            if ( itm.kind == 0 )
            {
                atk[ 0 ] = itm.atk[ 0 ];
                atk[ 1 ] = itm.atk[ 1 ];
                atk[ 2 ] += itm.atk[ 2 ];
                range = itm.range;
            }
            atkef |= itm.atkef;
            defef |= itm.defef;
            if( itm.magdef > magdef )
                magdef = itm.magdef;
    //      if (mem.magdef>100) mem.magdef = 100;
        }
        if( Class == CLS.NIN )
        {
            equip = 0;
            for( i = 0 ; i < 8 ; i++ )
                if ( item[ i ].equipped )
                    equip = 1;

            if ( equip == 0 )
            {
                atk[ 0 ] = 2;
                atk[ 1 ] = 7;
                atkef |= 0x80; // critical
                _ac = ( 8 - ( level -1 ) / 3 );
                if( _ac < -9999 )
                    _ac = -9999 ;
                ac[0] = _ac;
            }
        }

        return;
    }


    /*--------------------
       getParaPtr - キャラメイク用パラメーターポインタ取得
       --------------------*/
    byte* getParaPtr( int idx , ref byte para0 )
    {
        switch( idx )
        {
            case 0:
                para0 = str[ 0 ];
                return & str[ 1 ];
            case 1:
                para0 = iq[ 0 ];
                return & iq [ 1 ];
            case 2:
                para0 = pie[ 0 ];
                return & pie[ 1 ];
            case 3:
                para0 = vit[ 0 ];
                return & vit[ 1 ];
            case 4:
                para0 = agi[ 0 ];
                return & agi[ 1 ];
            case 5:
                para0 = luk[ 0 ];
                return & luk[ 1 ];
            default:
                assert( 0 );
        }
    }



    /*--------------------
       getHpPlus - HP 効果確認
       --------------------*/
    int getHpPlus()
    {
      int i, j = 0;
      if( status >= STS.DEAD )
          return 0;

      for( i = 0 ; i < MAXCARRY; i++)
          if( ! item[ i ].isNothing )
              j += item[ i ].hpplus;

      return j;
    }

    /*--------------------
       healHP - MAX超えないように回復
       --------------------*/
    void healHP( int plus )
    {
        hp += plus;
        if( hp > maxhp )
            hp = maxhp;
        return;
    }

    /*--------------------
       doesHeHav - アイテム持ってる？
       --------------------*/
    // rtn=1 as Yes, he/she does!
    //     0 as No, he/she doesn't have it.
    bool doesHeHave( int itm )
    {
        int i;
        for( i = 0 ; i < 8 ; i++ )
            if( item[ i ].itemNo == itm )
                return true;
        return false;
    }


    /*--------------------
       item_disp - 所持アイテム表示
       --------------------*/
    void item_disp()
    {
        int i;
        scrwin_clear();

        rewriteOff;

        setColor( CL.KIND );
        mvprintw( SCRW_Y_TOP + 1 , SCRW_X_TOP, "[ items ]" );
        setColor( CL.NORMAL );

        for ( i = 0; i < 8; i++ )
        {
            if ( item[ i ].isNothing )
                continue;

            mvprintw( SCRW_Y_TOP + i + 2, SCRW_X_TOP, "                             " );
            mvIntDispD( SCRW_Y_TOP + i + 2, SCRW_X_TOP, i + 1, 1 );
            printw( ") " );

            printw( item[ i ].getDispNameA );

            if ( ! item[ i ].canBeEquipped( Class ) )
                mvprintw( SCRW_Y_TOP + i + 2, SCRW_X_TOP + 2, "#" ); /* cannot equip */

            if ( item[ i ].equipped )
                mvprintw( SCRW_Y_TOP + i + 2, SCRW_X_TOP + 2, "*" ); /* equipped */

            if ( item[ i ].cursed )
                mvprintw( SCRW_Y_TOP + i + 2, SCRW_X_TOP + 2, "$" ); /* cursed */
       }

       rewriteOn;
       
       return;

    }


    /*--------------------
       dispSpellsInCamp - 戦闘中呪文表示
       --------------------*/
    void dispSpellsInCamp()
    {
        disp_mspell();
        getChar();
        disp_pspell();
        getChar();
        inspect;
        return;
    }

    /*--------------------
       dispSpellsInBattle - 戦闘中呪文表示
       --------------------*/
    void dispSpellsInBattle()
    {
        textout( _( "  %1 read mage spells\n" ) , name  );
        disp_mspell();
        getChar();
        textout( _( "  %1 read priest spells\n" ) , name  );
        disp_pspell();
        getChar();
        party.dungeon.disp();
        return;
    }

    /*--------------------
       disp_mspell - 魔法使い呪文表示
        type: 1:camp , 2:battle
       --------------------*/
    void disp_mspell()
    {
        int i;
        int type;

        if( now_mode == HSTS.CAMP )
            type = 1;
        else if( now_mode == HSTS.BATTLE )
            type = 2;
        else
            type = 0;

        scrwin_clear();
        rewriteOff;

        for ( i = 0; i < 4; i++ )
            if ( ( mspl_know[ 0 ] & ( 0x80 >> i ) ) != 0 )
            {
                if( type == 1 && magic_data[ i + 1 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 1 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                mvprintw( SCRW_Y_TOP + 1 + i, SCRW_X_TOP,  magic_data[ i + 1 ].name );
            }

        for ( i = 0; i < 3; i++ )
            if ((mspl_know[ 1 ] & ( 0x80 >> i )) != 0)
            {
                if( type == 1 && magic_data[ i + 5 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 5 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                    mvprintw( SCRW_Y_TOP + 1 + i, SCRW_X_TOP + 10,  magic_data[ i + 5 ].name );
            }
        
        for ( i = 0; i < 2; i++ )
            if ((mspl_know[ 2 ] & (0x80 >> i)) != 0)
            {
                if( type == 1 && magic_data[ i + 8 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 8 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                    mvprintw(SCRW_Y_TOP + 1 + i, SCRW_X_TOP + 20,  magic_data[ i + 8 ].name );
            }

        for ( i = 0; i < 4; i++ )
            if ((mspl_know[ 3 ] & (0x80 >> i)) != 0)
            {
                if( type == 1 && magic_data[ i + 10 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 10 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                    mvprintw(SCRW_Y_TOP + 6 + i, SCRW_X_TOP,  magic_data[ i + 10 ].name );
            }

        for ( i = 0; i < 3; i++ )
            if ((mspl_know[ 4 ] & (0x80 >> i)) != 0)
            {
                if( type == 1 && magic_data[ i + 14 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 14 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                    mvprintw(SCRW_Y_TOP + 6 + i, SCRW_X_TOP + 10,  magic_data[ i + 14 ].name );
            }

        for ( i = 0; i < 3; i++ )
            if ((mspl_know[ 5 ] & (0x80 >> i)) != 0)
            {
                if( type == 1 && magic_data[ i + 17 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 17 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                    mvprintw(SCRW_Y_TOP + 6 + i, SCRW_X_TOP + 20,  magic_data[ i + 17 ].name );
            }

        for ( i = 0; i < 3; i++ )
            if ((mspl_know[ 6 ] & (0x80 >> i)) != 0)
            {
                if( type == 1 && magic_data[ i + 20 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 20 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                    mvprintw(SCRW_Y_TOP + 11 + i, SCRW_X_TOP,  magic_data[ i + 20 ].name );
            }

        setColor( CL.KIND );
        mvprintw( SCRW_Y_TOP + 11 , SCRW_X_TOP + 10 , "[ mage spell ]" );
        setColor( CL.NORMAL );

        mvprintw( SCRW_Y_TOP + 12 , SCRW_X_TOP + 10 , "pnt:" );
        intDispD( mspl_pt[ 0 ] , 1 );
        printw( "/" );
        intDispD( mspl_pt[ 1 ] , 1 );
        printw( "/" );
        intDispD( mspl_pt[ 2 ] , 1 );
        printw( "/" );
        intDispD( mspl_pt[ 3 ] , 1 );
        printw( "/" );
        intDispD( mspl_pt[ 4 ] , 1 );
        printw( "/" );
        intDispD( mspl_pt[ 5 ] , 1 );
        printw( "/" );
        intDispD( mspl_pt[ 6 ] , 1 );

        mvprintw( SCRW_Y_TOP + 13 , SCRW_X_TOP + 10 , "max:" );
        intDispD( mspl_max[ 0 ] , 1 );
        printw( "/" );
        intDispD( mspl_max[ 1 ] , 1 );
        printw( "/" );
        intDispD( mspl_max[ 2 ] , 1 );
        printw( "/" );
        intDispD( mspl_max[ 3 ] , 1 );
        printw( "/" );
        intDispD( mspl_max[ 4 ] , 1 );
        printw( "/" );
        intDispD( mspl_max[ 5 ] , 1 );
        printw( "/" );
        intDispD( mspl_max[ 6 ] , 1 );

        rewriteOn;

        return;

    }

    /*--------------------
       disp_pspell - 僧侶呪文表示
        type: 1:camp , 2:battle
       --------------------*/
    void disp_pspell()
    {
        int i;
        int type;

        if( now_mode == HSTS.CAMP )
            type = 1;
        else if( now_mode == HSTS.BATTLE )
            type = 2;
        else
            type = 0;

        scrwin_clear();
        rewriteOff;

        for ( i = 0; i < 5; i++ )
            if ((pspl_know[ 0 ] & (0x80 >> i)) != 0)
            {
                if( type == 1 && magic_data[ i + 30 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 30 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                mvprintw(SCRW_Y_TOP + 1 + i, SCRW_X_TOP,  magic_data[ i + 30 ].name);
            }

        for ( i = 0; i < 4; i++ )
            if ((pspl_know[ 1 ] & (0x80 >> i)) != 0)
            {
                if( type == 1 && magic_data[ i + 35 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 35 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                mvprintw(SCRW_Y_TOP + 1 + i, SCRW_X_TOP + 10,  magic_data[ i + 35 ].name);
            }

        for ( i = 0; i < 4; i++ )
            if ((pspl_know[ 2 ] & (0x80 >> i)) != 0)
            {
                if( type == 1 && magic_data[ i + 39 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 39 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                mvprintw(SCRW_Y_TOP + 1 + i, SCRW_X_TOP + 20,  magic_data[ i + 39 ].name);
            }

        for ( i = 0; i < 4; i++ )
            if ((pspl_know[ 3 ] & (0x80 >> i)) != 0)
            {
                if( type == 1 && magic_data[ i + 43 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 43 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                mvprintw(SCRW_Y_TOP + 6 + i, SCRW_X_TOP,  magic_data[ i + 43 ].name);
            }

        for ( i = 0; i < 5; i++ )
            if ((pspl_know[ 4 ] & (0x80 >> i)) != 0)
            {
                if( type == 1 && magic_data[ i + 47 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 47 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                mvprintw(SCRW_Y_TOP + 6 + i, SCRW_X_TOP + 10,  magic_data[ i + 47 ].name);
            }

        for ( i = 0; i < 4; i++ )
            if ((pspl_know[ 5 ] & (0x80 >> i)) != 0)
            {
                if( type == 1 && magic_data[ i + 52 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 52 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                mvprintw(SCRW_Y_TOP + 6 + i, SCRW_X_TOP + 20,  magic_data[ i + 52 ].name);
            }

        for ( i = 0; i < 3; i++ )
            if ((pspl_know[ 6 ] & (0x80 >> i)) != 0)
            {
                if( type == 1 && magic_data[ i + 56 ].camp == 0 )
                    setColor( CL.CANT_SPELL );
                else if( type == 2 && magic_data[ i + 56 ].batl == 0 )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                mvprintw(SCRW_Y_TOP + 11 + i, SCRW_X_TOP,  magic_data[ i + 56 ].name);
            }
        
        setColor( CL.KIND );
        mvprintw( SCRW_Y_TOP + 11 , SCRW_X_TOP + 10 , "[ priest spell ]" );
        setColor( CL.NORMAL );

        mvprintw( SCRW_Y_TOP + 12 , SCRW_X_TOP + 10 , "pnt:" );
        intDispD( pspl_pt[ 0 ] , 1 );
        printw( "/" );
        intDispD( pspl_pt[ 1 ] , 1 );
        printw( "/" );
        intDispD( pspl_pt[ 2 ] , 1 );
        printw( "/" );
        intDispD( pspl_pt[ 3 ] , 1 );
        printw( "/" );
        intDispD( pspl_pt[ 4 ] , 1 );
        printw( "/" );
        intDispD( pspl_pt[ 5 ] , 1 );
        printw( "/" );
        intDispD( pspl_pt[ 6 ] , 1 );

        mvprintw( SCRW_Y_TOP + 13 , SCRW_X_TOP + 10 , "max:" );
        intDispD( pspl_max[ 0 ] , 1 );
        printw( "/" );
        intDispD( pspl_max[ 1 ] , 1 );
        printw( "/" );
        intDispD( pspl_max[ 2 ] , 1 );
        printw( "/" );
        intDispD( pspl_max[ 3 ] , 1 );
        printw( "/" );
        intDispD( pspl_max[ 4 ] , 1 );
        printw( "/" );
        intDispD( pspl_max[ 5 ] , 1 );
        printw( "/" );
        intDispD( pspl_max[ 6 ] , 1 );

        rewriteOn;
        
        return;
    }

    /*--------------------
       equip - 装備
       --------------------*/
    void equip()
    {
        int i;

        setColor( CL.MENU );
        textout( _( "which weapon(1,2,...,l:leave)?\n" ) );
        setColor( CL.NORMAL );
        equip_sub( ITM_KIND.WEAPON );

        setColor( CL.MENU );
        textout( _( "which armor(1,2,...,l:leave)?\n" ) );
        setColor( CL.NORMAL );
        equip_sub( ITM_KIND.ARMOR );

        setColor( CL.MENU );
        textout( _( "which shield(1,2,...,l:leave)?\n" ) );
        setColor( CL.NORMAL );
        equip_sub( ITM_KIND.SHIELD );

        setColor( CL.MENU );
        textout( _( "which helm(1,2,...,l:leave)?\n" ) );
        setColor( CL.NORMAL );
        equip_sub( ITM_KIND.HELM );

        setColor( CL.MENU );
        textout( _( "which gloves(1,2,...,l:leave)?\n" ) );
        setColor( CL.NORMAL );
        equip_sub( ITM_KIND.GLOVES );

        setColor( CL.MENU );
        textout( _( "which item(1,2,...,l:leave)?\n" ) );
        setColor( CL.NORMAL );
        equip_sub( ITM_KIND.ITEM );

        range    = 1;
        ac[ 0 ]  = 10;
        ac[ 1 ]  = 0;
        atk[ 0 ] = 1;
        atk[ 1 ] = 3;
        atk[ 2 ] = 0;

        if ( Class == CLS.NIN )
            atk[ 1 ] = 7;


        Item itm;

        for ( i = 0; i < 8; i++ )
        {
            if( item[ i ].isNothing )
                continue;

            if ( item[ i ].equipped == false && item[ i ].cursed == false )
                continue;

            itm = item[ i ];
            /* mem.hpplus += item.hpplus; */
            ac[ 0 ] += itm.ac;
            if ( itm.kind == 0 )
            {
                atk[ 0 ]  = itm.atk[ 0 ];
                atk[ 1 ]  = itm.atk[ 1 ];
                atk[ 2 ] += itm.atk[ 2 ];
                range     = itm.range;
            }
            atkef  |= itm.atkef;
            defef  |= itm.defef;
            magdef += itm.magdef;
            if ( magdef > 100 )
                magdef = 100;
        }

      inspect();
      party.win_disp();

      return;
    }

    /*--------------------
       tradeitem - 交換する
       --------------------*/
    void tradeitem()
    {
        int i;
        char ch;

        Member toMem;


        textout( _( "to whom(z:leave(9))? " ) );
        while ( true )
        {
            ch = getChar();
            if ( ch == 'z' || ch == '9' )
            {
                textout( _( "leave\n" ) );
                return;
            }
            else if ( ch >= '1' 
                    && ch <= '0' + party.num 
                    && party.mem[ ch - '1' ] !is this )
            {
                break;
            }
        }
        textout( ch );
        textout( "(" ~ party.mem[ ch - '1' ].name ~ ")" );
        textout( '\n' );
        toMem = party.mem[ ch - '1' ];

        while ( ! item[ 0 ].isNothing )
        {
            if ( ! toMem.item[ 7 ].isNothing )
            {
                textout( _( "full...\n" ) );
                return;
            }

            textout( _( "which item(z:leave(9))? " ) );
            while ( true )
            {
                ch = getChar();
                if (ch == 'z' || ch == '9')
                {
                    textout("z\n");
                    /* goto TOP; */
                    return;
                }
                if ( ch >= '1' && ch <= '8' 
                        && ( ! item[ ch - '1' ].isNothing ) )
                    break;
            }
            textout( ch );
            ch -= '1';
            textout( "(" ~ item[ ch ].getDispNameA ~ ")" );


            if ( item[ ch ].cursed )
            {
                textout( _( "\ncursed ...\n" ) );
            }
            else if ( item[ ch ].equipped )
            {
                textout( _( "\nequipped ...\n" ) );
            }
            else
            {
                for ( i = 0; i < 7; i++ )
                    if ( toMem.item[ i ].isNothing )
                        break;
                toMem.item[ i ].trade( item[ ch ] );
                item[ ch ].release;

                inspect();
                party.win_disp();
                textout( _( "\ndone.\n" ) );
            }
        }
    }

    /*--------------------
       dropitem - 捨てる
       --------------------*/
    void dropitem()
    {
        char ch;
        Item itm;

        textout( _( "which item will you drop(z:leave(9))? " ) );
        while ( true )
        {
            ch = getChar();
            if ( ch == 'z' || ch == '9' )
            {
                textout( _( "leave\n" ) );
                return;
            }
            else if ( ch >= '1' && ch <= '8' )
            {
                if ( ! item[ ch - '1' ].isNothing )
                    break;
            }
        }
        textout( ch );
        itm = item[ ch - '1' ];
        textout( "(" ~ itm.getDispNameA ~ ")" );
        textout( '\n' );

        if ( itm.cursed )
        {
            textout( _( "cursed item ...\n" ) );
            return;
        }
        else if ( itm.equipped )
        {
            textout( _( "equipped ...\n" ) );
            return;
        }
        else
        {
            itm.release;
            textout( _( "dropped.\n" ) );
        }

        inspect();
        party.win_disp();

        return;
    }

    /*--------------------
       useitem - 使う
       --------------------*/
    void useitem()
    {
        char ch;
        Item itm;

        int i, mag;

      
        textout( _( "which item do you use(z:leave(9))? " ) );
        while ( true )
        {
            ch = getChar();
            if ( ch == 'z' || ch == '9' )
            {
                textout( _( "leave\n" ) );
                return;
            }
            else if ( ch >= '1' && ch <= '8' )
            {
                if ( ! item[ ch - '1' ].isNothing )
                    break;
            }
        }
        textout( ch );
        itm = item[ ch - '1' ];
        textout( "(" ~ itm.getDispNameA ~ ")" );
        textout( '\n' );


      
        if ( itm.effect[ 0 ] == 0 )
            return; // no effect

        if ( ( itm.effect[ 0 ] & 0x80 ) != 0 )
        { // spell
            mag = itm.effect[ 0 ] & 0x7f;
            camp_spell_sub( mag );
        }
        else
        {
            switch ( itm.effect[ 0 ] )
            {
                // 魔法アイテム以外の効果
                case 1 :  // THI->NIN(dagger_of_thieves)
                    if ( Class == CLS.THI )
                    {
                        Class = CLS.NIN;
                        for ( i = 0; i < 8; i++ )
                            if ( ! item[ i ].isNothing )
                            {
                                item[i].equipped  = false;
                                item[i].cursed    = false;
                                item[i].undefined = false;
                            }
                    }
                    break;
                case 4 :  // 全員HP回復(garb_of_lords)
                    for ( i = 0; i < 8; i++ )
                    {
                        if ( party.mem[ i ].status < STS.DEAD )
                            party.mem[ i ].hp = party.mem[ i ].maxhp;
                    }
                    break;
                case 5 :  // age-1(The_Muramas_Blade!)
                    age -= get_rand( 4 ) + 1;
                    if ( age < 0 )
                        age = 0;
                    day = 0;
                    break;
                default:
                    break;
            }
        }

        if ( itm.broken >= get_rand( 99 ) + 1 )
          item[ ch-'1' ].setItem( 0 ); // broken item

        return;
    }

    
    /*--------------------
       levelup_chk - レベルアップ
       --------------------*/
    void levelup_chk()
    {

        int nexthp;
  
        nextexp = calcNextExp();
  
        if ( exp > nextexp )
        {
            level++;
            textout( _( "you made the next level!\n" ) );
            getChar();
  
            nexthp = calcHp;
            int hpp;

            if ( nexthp <= maxhp )
            {
                hpp = 1;
                maxhp++;
            }
            else
            {
                hpp = nexthp - maxhp;
                maxhp = nexthp;
            }
            hp = maxhp;

            textout( _( "  you gained %1 h.p.\n" ) , hpp );
            change_property( true );
            learn_spell();
        }
        else
        {
            long more = nextexp - exp;
            textout( _( "you need %1 more\n  ep to make the next level.\n" ) , more );
        }
        return;
    }

    /*--------------------
       hp calc - (クラスに合った)レベルに相当するHPを計算して返す
       --------------------*/
    int calcHp()
    {
        int i, dice, addhp, nextaddhp, nexthp;
        switch ( Class )
        {
            case CLS.FIG: 
                dice = 10;
                break;
            case CLS.THI: 
                dice = 6;
                break;
            case CLS.PRI: 
                dice = 8;
                break;
            case CLS.MAG: 
                dice = 4;
                break;
            case CLS.BIS: 
                dice = 6;
                break;
            case CLS.SAM: 
                dice = 8;
                break;
            case CLS.LOR: 
                dice = 10;
                break;
            case CLS.NIN: 
                dice = 6;
                break;
            default:
                assert( 0 );
        }

        if ( vit[ 0 ] + vit[ 1 ] >= 18 )
            addhp = 3;
        else if ( vit[ 0 ] + vit[ 1 ] >= 17 )
            addhp = 2;
        else if ( vit[ 0 ] + vit[ 1 ] >= 16 )
            addhp = 1;
        else if ( vit[ 0 ] + vit[ 1 ] <= 3 )
            addhp =  - 2;
        else if ( vit[ 0 ] + vit[ 1 ] <= 5 )
            addhp =  - 1;
        else
            addhp = 0;

        nexthp = 0;
        for ( i = 0 ; i < level; i++ )
        {
            nextaddhp = get_rand( dice - 1 ) + 1 + addhp;
            if ( nextaddhp < 1 )
                nextaddhp = 1;
            nexthp += nextaddhp;
        }

        if ( Class == CLS.SAM )
        {
            nextaddhp = get_rand( dice - 1 ) + 1 + addhp;
            if (nextaddhp < 1)
                nextaddhp = 1;
            nexthp += nextaddhp;
        }
        return nexthp;
    }


    void nlevelup( int n )
    {
        int nexthp;
        int i;
        
        for ( i = 0; i < n; i++ )
        {
            if ( i % ( n / 40 ) == 0 )
                textout( "." );

            nextexp = calcNextExp();

            if ( exp > nextexp )
            {
                level++;
        
                nexthp = calcHp();
                if ( nexthp <= maxhp )
                    maxhp++;
                else
                    maxhp = nexthp;
                hp = maxhp;

                change_property( false );
                learn_spell();
            }
            else
            {

                long more = nextexp - exp;
                textout( "\n" );
                textout( _( "you need %1 more\n  ep to make the next level.\n" ) , more );
                return;
            }
        }
        textout( "\n" );
        return; 
    }


    /*--------------------
       change_property 
       message : true / false
       --------------------*/
    /* rtncode=1 : lost */
    int change_property( bool message )
    {
        
        void checkGain( ref byte para , string para_name )
        {
            if ( get_rand( 99 ) >= 25 )
            {
                if ( age > get_rand( 129 ) + 1 )
                {
                    if ( ( para >= 3 && para < 18 ) 
                            || (para >= 18 && get_rand( 5 ) == 0) )
                    {
                        para --;
                        if ( message )
                            textout( _( "  you lost %1 \n" ) , para_name );
                    }
                }
                else
                {
                    if (para < 18)
                    {
                        para ++;
                        if ( message )
                            textout( _( "  you gained %1 \n" ) , para_name );
                    }
                }
            }
            return;
        }

        checkGain( str[ 0 ] , "strength" );
        checkGain( iq [ 0 ] , "iq"       );
        checkGain( pie[ 0 ] , "piety"    );
        checkGain( vit[ 0 ] , "vitality" );
        checkGain( agi[ 0 ] , "agility"  );
        checkGain( luk[ 0 ] , "luck"     );
        
        if ( vit[ 0 ] <= 2 )
        {
            textout( _( "The character died of age...\n" ) );
            getChar();
            status = STS.LOST;
            return 1;
        }

        return 0;

    }

    /*--------------------
       propcalc 
       --------------------*/
    // (クラスに合った)レベルに相当するpropertyにする
    // (ドレイン時に使用)
    void calcProperty()
    {

        void checkDrainPara( ref byte para )
        {
            if ( get_rand( 99 ) >= 25 )
            {
                if ( age > get_rand( 129 ) + 1 )
                {
                    if ( ( para >= 3 && para < 18 ) 
                            || (para >= 18 && get_rand( 5 ) == 0) )
                        para --;
                }
                else
                {
                    if (para < 18)
                        para ++;
                }
            }
            return;
        }

        int i;
        switch ( race )
        {
            case RACE.HUMAN :
                str[ 0 ] = 8, iq[ 0 ]  = 8, pie[ 0 ] = 5;
                vit[ 0 ] = 8, agi[ 0 ] = 8, luk[ 0 ] = 8;
                break;
            case RACE.ELF : 
                str[ 0 ] = 7,  iq[ 0 ]  = 10, pie[ 0 ] = 10;
                vit[ 0 ] = 6,  agi[ 0 ] = 9 , luk[ 0 ] = 6;
                break;
            case RACE.DWARF : 
                str[ 0 ] = 10, iq[ 0 ]  = 7, pie[ 0 ] = 10;
                vit[ 0 ] = 10, agi[ 0 ] = 5, luk[ 0 ] = 6;
                break;
            case RACE.GNOME : 
                str[ 0 ] = 7,  iq[ 0 ]  = 7 , pie[ 0 ] = 10;
                vit[ 0 ] = 8,  agi[ 0 ] = 10, luk[ 0 ] = 7;
                break;
            case RACE.HOBBIT : 
                str[ 0 ] = 5,  iq[ 0 ]  = 7 , pie[ 0 ] = 7;
                vit[ 0 ] = 6,  agi[ 0 ] = 10, luk[ 0 ] = 15;
                break;
            default:
                assert( 0 );
        }
        str[ 1 ]=0, iq[ 1 ]=0 , pie[ 1 ]=0;
        vit[ 1 ]=0, agi[ 1 ]=0, luk[ 1 ]=0;

        for (i = 0; i < level - 1; i++)
        {
            checkDrainPara( str[ 0 ] );
            checkDrainPara( iq [ 0 ] );
            checkDrainPara( pie[ 0 ] );
            checkDrainPara( vit[ 0 ] );
            checkDrainPara( agi[ 0 ] );
            checkDrainPara( luk[ 0 ] );
        }

        // しない？
        // if ( vit[ 0 ] <= 2 )
        // {
        //     textout( "The character died of age...\n" );
        //     getChar();
        //     status = STS_LOST;
        //     return 1;
        // }

        return;
    }


    /*--------------------
       learn_spell 
       --------------------*/
    void learn_spell()
    {
        switch ( Class )
        {
            case CLS.FIG: /* fighter */
            case CLS.THI: /* thief */
            case CLS.NIN: /* ninja */
                break;
            case CLS.PRI: /* priest */ 
                learn_pspell( ( level - 1 ) / 2 );
                break;
            case CLS.MAG: /* mage */
                learn_mspell( ( level - 1 ) / 2 );
                break;
            case CLS.BIS: /* bishop */
                learn_mspell( ( level - 1 ) / 4 );
                learn_pspell( ( level - 4 ) / 4 );
                break;
            case CLS.SAM: /* samurai */
                learn_mspell( ( level - 4 ) / 3 );
                break;
            case CLS.LOR: /* lord */
                learn_pspell( ( level - 4 ) / 2 );
                break;
            default:
                assert( 0 );
        }
        return;
    }

    /*--------------------
       learn_mspell 
       --------------------*/
    void learn_mspell( int lvl )
    {
        int i,cnt, j;
        byte[ 7 ] oldknow;
  
        for ( i = 0; i < 7; i++ )
            oldknow[ i ] = mspl_know[ i ];
  
        lvl ++;
        if ( lvl > 7 )
            lvl = 7;
        for ( i = 0; i < lvl; i++ )
        {
            for ( j = 0; j < get_rand( 2 ) + 1; j++ )
                mspl_know[ i ] |= 0x10 << get_rand( 3 );
          
            cnt = ( iq[ 0 ] + iq[ 1 ] - 10 ) / 4;
            if ( cnt < 0 )
                cnt = 0;
            cnt += get_rand( 1 );
            mspl_max[ i ] += cnt ;
            if ( mspl_max[ i ] > 9 )
                mspl_max[ i ] = 9;
            mspl_pt[ i ]|= mspl_max[ i ];
        }
        mspl_know[ 0 ] &= 0xf0;
        mspl_know[ 1 ] &= 0xe0;
        mspl_know[ 2 ] &= 0xc0;
        mspl_know[ 3 ] &= 0xf0;
        mspl_know[ 4 ] &= 0xe0;
        mspl_know[ 5 ] &= 0xe0;
        mspl_know[ 6 ] &= 0xe0;
        for ( i = 0; i < 7; i++ )
        {
            if ( oldknow[ i ] != mspl_know[ i ] )
            {
                textout( _( "  you've learned new mage spells!\n" ) );
                return;
            }
        }
        return;
    }

    /*--------------------
       learn_pspell 
       --------------------*/
    void learn_pspell( int lvl )
    {
        int i,cnt, j;
        byte[ 7 ] oldknow;
  
        for ( i = 0; i < 7; i++ )
            oldknow[ i ] = pspl_know[ i ];
  
        lvl++;
        if ( lvl > 7 )
            lvl = 7;
        for ( i = 0; i < lvl; i++ )
        {
            for (j = 0; j < get_rand( 2 ) + 1; j++)
                pspl_know[ i ] |= 0x8 << get_rand( 4 );
  
            cnt = ( pie[ 0 ] + pie[ 1 ] - 10 ) / 4;
            if ( cnt < 0 )
                cnt = 0;
            cnt += get_rand( 1 );
            pspl_max[ i ] += cnt;
            if ( pspl_max[ i ] > 9 )
                pspl_max[ i ] = 9; 
            pspl_pt[ i ] = pspl_max[ i ];
        }
        pspl_know[ 0 ] &= 0xf8;
        pspl_know[ 1 ] &= 0xf0;
        pspl_know[ 2 ] &= 0xf0;
        pspl_know[ 3 ] &= 0xf0;
        pspl_know[ 4 ] &= 0xf8;
        pspl_know[ 5 ] &= 0xf0;
        pspl_know[ 6 ] &= 0xe0;
        for ( i = 0; i < 7; i++ )
        {
            if ( oldknow[ i ] != pspl_know[ i ] )
            {
                textout( _( "  you've learned new priest spells!\n" ) );
                return;
            }
        }
        return;
    }

    /*--------------------
       spell_know - この呪文覚えてる？
       rtn 0 : know      
           1 : don't know    
           3 : no such spell 
       --------------------*/
    int spell_know( int no )
    {
        if ( no >= 1 && no <= 4 )
        {
            if ( ( ( 0x80 >> ( no - 1 ) ) & mspl_know[ 0 ] ) == 0 )
                return 1;
        }
        else if ( no >= 5 && no <= 7 )
        {
            if ( ( ( 0x80 >> ( no - 5 ) ) & mspl_know[ 1 ] ) == 0 )
                return 1;
        }
        else if ( no >= 8 && no <= 9 )
        {
            if ( ( ( 0x80 >> ( no - 8 ) ) & mspl_know[ 2 ] ) == 0 )
                return 1;
        }
        else if ( no >= 10 && no <= 13 )
        {
            if ( ( ( 0x80 >> ( no - 10 ) ) & mspl_know[ 3 ] ) == 0 )
                return 1;
        }
        else if ( no >= 14 && no <= 16 )
        {
            if ( ( ( 0x80 >> ( no - 14 ) ) & mspl_know[ 4 ] ) == 0 )
                return 1;
        }
        else if ( no >= 17 && no <= 19 )
        {
            if ( ( ( 0x80 >> ( no - 17 ) ) & mspl_know[ 5 ] ) == 0 )
                return 1;
        }
        else if ( no >= 20 && no <= 22 )
        {
            if ( ( ( 0x80 >> ( no - 20 ) ) & mspl_know[ 6 ] ) == 0 )
                return 1;
        
        }
        else if ( no >= 30 && no <= 34 )
        {
            if ( ( ( 0x80 >> ( no - 30 ) ) & pspl_know[ 0 ] ) == 0 )
                return 1;
        }
        else if ( no >= 35 && no <= 38 )
        {
            if ( ( ( 0x80 >> ( no - 35 ) ) & pspl_know[ 1 ] ) == 0 )
                return 1;
        }
        else if ( no >= 39 && no <= 42 )
        {
            if ( ( ( 0x80 >> ( no - 39 ) ) & pspl_know[ 2 ] ) == 0 )
                return 1;
        }
        else if ( no >= 43 && no <= 46 )
        {
            if ( ( ( 0x80 >> ( no - 43 ) ) & pspl_know[ 3 ] ) == 0 )
                return 1;
        }
        else if ( no >= 47 && no <= 51 )
        {
            if ( ( ( 0x80 >> ( no - 47 ) ) & pspl_know[ 4 ] ) == 0 )
                return 1;
        }
        else if ( no >= 52 && no <= 55 )
        {
            if ( ( ( 0x80 >> ( no - 52 ) ) & pspl_know[ 5 ] ) == 0 )
                return 1;
        }
        else if ( no >= 56 && no <= 58 )
        {
            if ( ( ( 0x80 >> (no - 56) ) & pspl_know[ 6 ] ) == 0 )
                return 1;
        }
        else
        {
            return 3;
        }
        return 0;
    }

    /* rtn 0 : suceeded      */
    /*     1 : don't know    */
    /*     2 : have used up   */
    /*     3 : no such spell */
    int consume_spell( int sno )
    { 
        if ( sno >= 1 && sno <= 4 )
        {
            if ( ( ( 0x80 >> ( sno - 1 ) ) & mspl_know[ 0 ] ) == 0 )
                return 1;
            if ( ( mspl_pt[ 0 ] ) < 1 )
                return 2;
            mspl_pt[ 0 ]--;
        }
        else if ( sno >= 5 && sno <= 7 )
        {
            if ( ( ( 0x80 >> ( sno - 5 ) ) & mspl_know[ 1 ] ) == 0 )
                return 1;
            if ( ( mspl_pt[ 1 ] ) < 1 )
                return 2;
            mspl_pt[ 1 ]--;
        }
        else if ( sno >= 8 && sno <= 9 )
        {
            if ( ( ( 0x80 >> ( sno - 8 ) ) & mspl_know[ 2 ] ) == 0 )
                return 1;
            if ( ( mspl_pt[ 2 ] ) < 1 )
                return 2;
            mspl_pt[ 2 ]--;
        }
        else if ( sno >= 10 && sno <= 13 )
        {
            if ( ( ( 0x80 >> ( sno - 10 ) ) & mspl_know[ 3 ] ) == 0 )
                return 1;
            if ( ( mspl_pt[ 3 ] ) < 1 )
                return 2;
            mspl_pt[ 3 ]--;
        }
        else if ( sno >= 14 && sno <= 16 )
        {
            if ( ( ( 0x80 >> ( sno - 14 ) ) & mspl_know[ 4 ] ) == 0 )
                return 1;
            if ( ( mspl_pt[ 4 ] ) < 1 )
                return 2;
            mspl_pt[ 4 ]--;
        }
        else if ( sno >= 17 && sno <= 19 )
        {
            if ( ( ( 0x80 >> ( sno - 17 ) ) & mspl_know[ 5 ] ) == 0 )
                return 1;
            if ( ( mspl_pt[ 5 ] ) < 1 )
                return 2;
            mspl_pt[ 5 ]--;
        }
        else if ( sno >= 20 && sno <= 22 )
        {
            if ( ( ( 0x80 >> ( sno - 20 ) ) & mspl_know[ 6 ] ) == 0 )
                return 1;
            if ( ( mspl_pt[ 6 ] ) < 1 )
                return 2;
            mspl_pt[ 6 ]--;
        
        }
        else if ( sno >= 30 && sno <= 34 )
        {
            if ( ( ( 0x80 >> ( sno - 30 ) ) & pspl_know[ 0 ] ) == 0 )
                return 1;
            if ( ( pspl_pt[ 0 ] ) < 1 )
                return 2;
            pspl_pt[ 0 ]--;
        }
        else if ( sno >= 35 && sno <= 38 )
        {
            if ( ( ( 0x80 >> ( sno - 35 ) ) & pspl_know[ 1 ] ) == 0 )
                return 1;
            if ( ( pspl_pt[ 1 ] ) < 1 )
                return 2;
            pspl_pt[ 1 ]--;
        }
        else if ( sno >= 39 && sno <= 42 )
        {
            if ( ( ( 0x80 >> ( sno - 39 ) ) & pspl_know[ 2 ] ) == 0 )
                return 1;
            if ( ( pspl_pt[ 2 ] ) < 1 )
                return 2;
            pspl_pt[ 2 ]--;
        }
        else if ( sno >= 43 && sno <= 46 )
        {
            if ( ( ( 0x80 >> ( sno - 43 ) ) & pspl_know[ 3 ] ) == 0 )
                return 1;
            if ( ( pspl_pt[ 3 ] ) < 1 )
                return 2;
            pspl_pt[ 3 ]--;
        }
        else if ( sno >= 47 && sno <= 51 )
        {
            if ( ( ( 0x80 >> ( sno - 47 ) ) & pspl_know[ 4 ] ) == 0 )
                return 1;
            if ( ( pspl_pt[ 4 ] ) < 1 )
                return 2;
            pspl_pt[ 4 ]--;
        }
        else if ( sno >= 52 && sno <= 55 )
        {
            if ( ( ( 0x80 >> ( sno - 52 ) ) & pspl_know[ 5 ] ) == 0 )
                return 1;
            if ( ( pspl_pt[ 5 ] ) < 1 )
                return 2;
            pspl_pt[ 5 ]--;
        }
        else if ( sno >= 56 && sno <= 58 )
        {
            if ( ( ( 0x80 >> ( sno - 56 ) ) & pspl_know[ 6 ] ) == 0 )
                return 1;
            if ( ( pspl_pt[ 6 ] ) < 1 )
                return 2;
            pspl_pt[ 6 ]--;
        }
        else
        {
            return 3;
        }
        return 0;
     }



    /*--------------------
       camp_spell - 呪文を唱える（キャンプ中）
       --------------------*/
    void camp_spell()
    {
        int mag;
        string spell_name;

        textout( _( "what spell?\n" ) );
        /* spell_name = tline_input( 32, text_cury + TXTW_Y_TOP, text_curx + TXTW_X_TOP ); */
        spell_name = tline_input_spell( this , 32, text_cury + TXTW_Y_TOP, text_curx + TXTW_X_TOP );
        textout( '>' );
        textout( spell_name );
        textout( '\n' );

        for ( mag = 0; mag < MAXMAGIC; mag++ )
          if ( spell_name ==  magic_data[ mag ].name )
              break;

        if ( mag == MAXMAGIC 
                || magic_data[ mag ].camp == 0
                || spell_know( mag ) !=0 )  // 0 : know  , 1 : don't know , 3 : no such spell 
        {
            if ( mag == MAXMAGIC )
                textout( _( "no such spell\n" ) );
            else if ( magic_data[ mag ].camp == 0 )
                textout( _( "cannot cast now\n" ) );
            else
                textout( _( "don't know the spell\n" ) );
            getChar();
            return;
        }
        if ( consume_spell( mag ) == 2 )    // 2 : have used up 
        {
            textout( _( "you've used that up\n" ) );
            getChar();
            return;
        }
        camp_spell_sub( mag );
        inspect;
        //  getchar();
        return;
    }


    /*--------------------
       camp_spell_sub - 呪文を唱える（キャンプ中）
       --------------------*/
    void camp_spell_sub( int mag )
    {

        Member mem;

        if ( magic_data[ mag ].camp == 2 )
        { // select member
            mem = party.selectMember( _("to whom?: ") );
            if( mem is null )
                return;
        }

        switch ( magic_data[ mag ].type )
        {
            case MAG_TYPE.MAPPER :
                spell_mapper;
                break;
            case MAG_TYPE.FLASH :       // flash
                spell_flash;
                break;
            case MAG_TYPE.SHINE :     // shine
                spell_shine;
                break;
            case MAG_TYPE.FLOATN :        // float
                spell_floatn;
                break;
            case MAG_TYPE.RCGNIZE :      // identify
                spell_recognize;
                break;
            case MAG_TYPE.Bless :       // resurrection
                target = mem.getPartyNo;
                spell_Bless(); 
                break;
            case MAG_TYPE.BREATHE :
                target = mem.getPartyNo;
                spell_breathe();
                break;
            case MAG_TYPE.HEALONE :
                spell_healOne( mag , mem.getPartyNo );
                break;
            case MAG_TYPE.HEALALL:
                spell_healAll( mag );
                break;
            case MAG_TYPE.GUARD :       // ac - 2
                party.ac =  - 2;
                party.win_disp();
                header_disp( HSTS.CAMP );
                break;
            case MAG_TYPE.DETXIFY :     // cure poison
                target = mem.getPartyNo;
                spell_curePoison;
                break;
            case MAG_TYPE.CURE :     // cure paralyze
                target = mem.getPartyNo;
                spell_cureParalize;
                break;
            case MAG_TYPE.BLESS :        // cure stone
                target = mem.getPartyNo;
                spell_bless;
                break;
            case MAG_TYPE.RETURN :       // return castle
                party.x = 1;
                party.y = 2;
                party.layer = 0;
                textout( _( "teleport to the castle!\n" ) );
                break;
            case MAG_TYPE.TELEPT :       // teleport
                spell_telept;
                break;
            default :
                assert( 0 );
        }
        return;
    }

    /*--------------------
       identify - 識別する（キャンプ中）
       --------------------*/
    void identify()
    {

        char ch;
        int i, ratio;
        bool n;

        if ( status != STS.OK )
            return;

        textout( _( "which item will you identify(z:leave(9))? " ) );
        while( true )
        {
            ch = getChar();
            if ( ch == 'z' || ch == '9' )
            {
              textout( _( "leave\n" ) );
              return;
            }
            else if ( ch >= '1' && ch <= '8' 
                    && ! item[ ch - '1' ].isNothing 
                    && item[ ch - '1' ].undefined )
                break;
        }
        textout( ch );
        ch -= '1';
        ratio = level * 5;
        if ( ratio > 95 )
            ratio = 95;
        if ( get_rand( 99 ) + 1 > ratio )
        {
            n = true;
            for ( i = 0; i < luk[ 0 ] + luk[ 1 ]; i++ )
                if (get_rand( 99 ) < 10 )
                    n = false;
            if ( n )
            {
                textout( _( "\n * oops! *\n" ) );
                n = false;
                switch ( Align )
                {
                  case ALIGN.GOOD:
                      if ( ( item[ ch ].Align & 0x1 ) !=  0 )
                          n = true;
                      break;
                  case ALIGN.EVIL:
                      if ( ( item[ ch ].Align & 0x2 ) !=  0 )
                          n = true;
                      break;
                  case ALIGN.NEWT:
                      if ( ( item[ ch ].Align & 0x4 ) !=  0 )
                          n = true;
                      break;
                  default:
                      break;
                }
                if ( n )
                { /* cursed */
                    item[ ch ].cursed = true;
                }
                else
                { /* afraid */
                    if ( status == STS.OK )
                        status = STS.AFRAID;
                }
                party.win_disp();
                getChar();
            }
            else
            {
                textout( _( "\nno clue ...\n" ) );
            }
        }
        else
        {
            item[ ch ].undefined = false;
            textout( "\n" );
        }
        inspect;
        party.win_disp();
        return;
    }


    /*--------------------
       canCarry - 持ち物に空きがあるか？
       --------------------*/
    bool canCarry()
    {
        return ( item[ 7 ].isNothing );
    }

    /*--------------------
       getItem - アイテム取得
       --------------------*/
    Item getItem( int itemNo )
    {

        assert( item[ 7 ].isNothing );

        int i;

        for ( i = 0; i < 8; i++ )
            if ( item[ i ].isNothing )
                break;

        item[ i ].setItem( itemNo );
        return item[ i ];
    }

    /*--------------------
       releaseItem - アイテム手放す`
       itm - item[ 0-7 ]
       --------------------*/
    void releaseItem( Item itm )
    {
        for( int i = 0 ; i < 8 ; i++ )
            if( item[ i ] is itm )
            {
                releaseItem( i );
                return;
            }

        assert( 0 );    // ???
    }


    /*--------------------
       releaseItem - アイテム手放す`
       no - itme[ 0-7 ]
       --------------------*/
    void releaseItem( int no )
    {

        assert( no >= 0 && no <= 7 );

        Item tmp = item[ no ];

        for ( int i = no ; i < 7; i++ )  // i : no+1 ~ 6
          item[ i ] = item[ i + 1 ];
        item[ 7 ] = tmp;
        item[ 7 ].setNull ;

        return;
    }

    /*--------------------
       inputAction - 戦闘時コマンド入力
       --------------------*/
    bool inputAction( int row , char command )
    {

        char c;
        int i;
        int magic , mag;
        string spell_name;

        void dispCommand( string com )
        { mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 48, com ); }
        void dispTargetInt( int t )
            { mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 54, " " ~ to!string( t ) ); }
        void dispTarget( string txt )
            { mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 54, " " ~ txt ); }



        if ( command == ' ' )
        {
            if ( row >= 3 && range != RANGE.LONG )
            {
                dispCommand( "parry                         " );
                action = ACT.PARRY;
                return true;
            }
            else
            {
                dispCommand( "fight  1)" ~ fill( monParty.top.getDispNameS ,21 ) );
                action = ACT.FIGHT;
                target = 0;
                return true;
            }
        }


        // fight
        else if ( command == 'f'      // fight
                || command == 'j'     // fight 1
                || command == 'h'     // fight 2
                || command == 'n'     // fight 3
                || command == '4'     // fight
                || command == '1'     // fight 1
                || command == '2'     // fight 2
                || command == '3' )   // fight 3
        {
            if ( range == RANGE.NOT )
                return false;

            if ( range == RANGE.SHORT && row >= 3 )
                return false;

            if ( command == 'j' 
                || command == '1' )
            {
                dispCommand( "fight  1)" ~ fill( monParty.getDispNameS( 0 ) ,21 ) );
                action = ACT.FIGHT;
                target = 0;
                return true;
            }
            else if ( ( command == 'h' || command == '2' )
                    && monParty.num >= 2 )
            {
                dispCommand( "fight  2)" ~ fill( monParty.getDispNameS( 1 ) ,21 ) );
                action = ACT.FIGHT;
                target = 1;
                return true;
            }
            else if ( ( command == 'n' || command == '3' ) 
                    && monParty.num >= 3 )
            {
                dispCommand( "fight  3)" ~ fill( monParty.getDispNameS( 2 ) ,21 ) );
                action = ACT.FIGHT;
                target = 2;
                return true;
            }
            else if ( command == 'f' 
                    || command == '4' )
            {
                action = ACT.FIGHT;
                dispCommand( "fight  " );
                target = monParty.selectGroup( row );
                dispTargetInt( target + 1 );
                printw( ")" ~ fill( monParty.getDispNameS( target ) , 21 ) );
                
                return true;
            }
        }


        // parry
        else if ( command == 'p'  
                || command == 'k' 
                || command == '5' )
        {

            dispCommand( "parry                         " );
            action = ACT.PARRY;
            return true;
        }


        // use
        else if ( command == 'u'  
                || command == '8' )
        {
            textout( _( "you have:\n" ) );
            for ( i = 0; i < 8; i++ )
            {
                if ( ! item[ i ].isNothing )
                {
                    textout( to!char( i + 'a' ) );
                    textout( ")" );
                    textout( item[ i ].getDispNameA ~ "\n" );
                }
            }
            textout( _( "which item(z:leave(9))? " ) );

            while ( true )
            {
                c = getChar();
                if ( c == 'z' 
                        || c == '9' 
                        || ( c <= 'h' && c >= 'a' && !item[ c - 'a' ].isNothing ) )
                    break;
            }
            textout( c );
            textout( '\n' );
            
            if ( c=='z' || c=='9' )
                return false;

            magic = item[ c - 'a' ].effect[ 1 ];
            if ( ( magic & 0x80 ) == 0 
                    || magic_data[ magic & 0x7f ].batl == 0 )
            {
                textout( _( "you can't use it now\noption? \n" ) );
                return false;
            }

            actitem = c - 'a';
            magic &= 0x7f;
            dispCommand( leftB( magic_data[ magic ].name , 6 ) ~ " " );

            if ( magic_data[ magic ].batl == 1 )
            { /* row target */
                /* dispTarget( " ???????????????????????" ); */
                dispTarget( "                        " );
            }
            else if ( magic_data[ magic ].batl == 2 )
            { /* to a party member */
                target = party.selectMemberInBattle( row );
                dispTargetInt( target + 1 );
                printw( fill( "(" ~ party.mem[ target ].name ~ ")" , 22 ) );
            }
            else if ( magic_data[ magic ].batl == 3 )
            { /* to monsters */
                target = monParty.selectGroup( row );
                dispTargetInt( target + 1 );
                printw( ")" ~ fill( monParty.getDispNameS( target ) , 22 ) );
            }
            
            action = ACT.USE;
            return true;
        }

        // cast spell
        else if ( ( command == 'c' || command == 's' || command == '6' ) && ! monParty.suprised )
        {
            dispCommand( "spell  ?                      " );
            /* spell_name = tline_input( 20, CHRW_Y_TOP + row + 1, CHRW_X_TOP + 55 ); */
            spell_name = tline_input_spell( this , 20, CHRW_Y_TOP + row + 1, CHRW_X_TOP + 55 );

            for ( mag = 0; mag < MAXMAGIC; mag++ )
              if ( spell_name == magic_data[ mag ].name )
                  break;

            if ( mag == MAXMAGIC 
                    || magic_data[ mag ].batl == 0 
                    || spell_know( mag ) !=0  )
            {
                if ( mag == MAXMAGIC )
                    dispTarget( _( " no such spell" ) );
                else if ( magic_data[ mag ].batl == 0 )
                    dispTarget( _( " cannot cast now" ) );
                else
                    dispTarget( _( " don't know the spell" ) );

                getChar();
                dispCommand( "what?  ???????????????????????" );
                return false;
            }

            if ( consume_spell( mag ) == 2 )
            {
                dispTarget( _( " you've used that up" ) );
                getChar();
                dispCommand( "what?  ???????????????????????" );
                return false;
            }

            dispCommand( leftB( spell_name , 6 ) ~ " " );
            if ( magic_data[ mag ].batl == 1 )
            { /* row target */
                /* dispTarget( " ???????????????????????" ); */
                dispTarget( "                        " );
            }
            else if ( magic_data[ mag ].batl == 2 )
            { /* to a party member */
                target = party.selectMemberInBattle( row );
                dispTargetInt( target + 1 );
                printw( fill( "(" ~ party.mem[ target ].name ~ ")" , 22 ) );
            }
            else if ( magic_data[ mag ].batl == 3 )
            { /* to monsters */
                target = monParty.selectGroup( row );
                dispTargetInt( target + 1 );
                printw( ")" ~ fill( monParty.getDispNameS( target ) , 22 ) );
            }
            action = mag + 0x80;
            return true;
        }


        // dispell
        else if ( ( command == 'd' || command == '0' )
                && ( Class == CLS.PRI 
                    || Class==CLS.LOR 
                    || Class==CLS.BIS ) )
        {
            action = ACT.DISPEL;
            dispCommand( "dispel " );
            target = monParty.selectGroup( row );
            dispTargetInt( target + 1 );
            printw( ")" ~ fill( monParty.getDispNameS( target ) , 22 ) );
            return true;
        }

        return false;
    }

    /*--------------------
       act - 戦闘ターン実行
       --------------------*/
    int act()
    {
        MonsterTeam mt;
        Monster     m;

        if ( status != STS.OK )
            return 0;

        if ( ( action & 0x80 ) != 0 )   // spell magic
        {
            if ( actSpellInBattle() == 2 )
                return 2; // malor/kadorto
            return 0;
        }

        switch ( action )
        {
            case ACT.USE:  // use item
                action  = item[ actitem ].effect[ 1 ] | 0x80;
                actSpellInBattle();
                if ( item[ actitem ].broken >= get_rand( 99 ) + 1 )
                { 
                    textout( _( "The %1 gets broken!\n" ) , item[ actitem ].getDispName );
    
                    item[ actitem ].setItem( 0 ); // broken
                }
                break;

            case ACT.FIGHT: /* fight */
                m = getTargetMonster();
                actFight( m );
                break;

            case ACT.PARRY: /* parry */
            case ACT.RUN: /* couldn't run away */
                break;

            case ACT.DISPEL: /* dispel */
                mt = getTargetMonsterTeam;
                if( mt !is null )
                   actDispel( mt );
                break;

            default:
                assert( 0 , "action :" ~ to!string( action )  );
        }

        return 0;
    }
    

    /*--------------------
       actFight - fight
       --------------------*/
    void actFight( Monster m )
    {
        int damage = 0, ratio;
        bool equip_flg;
        int i;
        int flvl, atk_cnt;

        int hit_rate;
        int hit_times;
        
        switch ( get_rand( 7 ) )
        {
            case 0:
                textout( _( "%1 thrusts hard at a %2\n" ) , name , m.getDispNameA );
                break;
            case 1:
                textout( _( "%1 tries to slice a %2\n" ) , name , m.getDispNameA ) ;
                break;
            case 2:
                textout( _( "%1 swings at a %2\n" ), name , m.getDispNameA  );
                break;
            case 3:
                textout( _( "%1 chops savagely at a %2\n" ), name , m.getDispNameA  );
                break;
            case 4:
                textout( _( "%1 tries to bash a %2\n" ), name , m.getDispNameA  );
                break;
            case 5:
                textout( _( "%1 attempts to stab a %2\n" ), name , m.getDispNameA  );
                break;
            case 7:
            default:
                textout( _( "%1 lunges at a %2\n" ) , name , m.getDispNameA );
                break;
        }
      
        if ( Class == CLS.FIG 
                || Class == CLS.PRI 
                || Class == CLS.SAM 
                || Class == CLS.LOR 
                || Class == CLS.NIN )
            flvl = 2 + level / 3;
        else
            flvl = level / 5;

             if ( str[ 0 ] + str[ 1 ] >= 18 ) flvl += 3;
        else if ( str[ 0 ] + str[ 1 ] >= 16 ) flvl += 2;
        else if ( str[ 0 ] + str[ 1 ] >= 13 ) flvl += 1;
        else if ( str[ 0 ] + str[ 1 ] >=  8 ) flvl += 0;
        else if ( str[ 0 ] + str[ 1 ] >=  6 ) flvl -= 1;
        else if ( str[ 0 ] + str[ 1 ] >=  4 ) flvl -= 2;
        else                                  flvl -= 3;


        hit_rate = 21 - m.ac - m.acplus - flvl - 3;

        if ( m.status != 0 )
            hit_rate -= AC_UP_SLEEP;

        if ( hit_rate >= 20 )
            hit_rate = 19;

        if ( hit_rate < 1 )
            hit_rate = 1;

        atk_cnt = atk[ 2 ] + ( level / 5 ) + 1;
        if ( atk_cnt > 10 )
        {
            if ( Class == CLS.NIN )
            {
                equip_flg = false;
                for ( i = 0; i < 8; i++ )
                  if ( item[ i ].equipped || item[ i ].cursed ) 
                      equip_flg = true;

                if ( equip_flg && doesHeHave( 147 ) )
                {
                    // atk_cnt += 10; 
                }
                else
                {
                    atk_cnt = 10;
                }
            }
            else
            {
                atk_cnt = 10;
            }
        }

        hit_times = 0;
        for ( i = 0; i < atk_cnt; i++ )
            if ( hit_rate <= ( 1 + get_rand( 19 ) ) )
            {
                hit_times++;
                damage += atk[ 0 ] + get_rand( atk[ 1 ] );
            }

        // 属性が合えば倍の効果
        switch ( m.type )
        {
            case MON_TYPE.FIG:  // human
            case MON_TYPE.MAG:
            case MON_TYPE.PRI:
            case MON_TYPE.THI:
                if ( ( atkef & ITM_ATKEF.HUMAN ) != 0 )
                    damage *= 2;
                break;
            case MON_TYPE.ANML: // animal
                if ( ( atkef & ITM_ATKEF.ANIMAL ) != 0 )
                    damage *= 2;
                break;
            case MON_TYPE.DRA: // dragon
                if ( ( atkef & ITM_ATKEF.DRAGON  ) != 0 )
                    damage *= 2;
                break;
            case MON_TYPE.DEM:  // demon
                if ( ( atkef & ITM_ATKEF.DEMON ) != 0 )
                    damage *= 2;
                break;
            case MON_TYPE.INS: // insect
                if ( ( atkef & ITM_ATKEF.INSECT ) != 0 )
                    damage *= 2;
                break;
            default:
                break;
        }
        if ( m.status == MON_STS.SLEEP )
            damage *= 2; // sleep

        if ( hit_times > 0 )
        {
            textout( N_( "  and hits once for %1 damage!\n" 
                       , "  and hits %2 times for %1 damage!\n" , hit_times )
                   , damage , hit_times );
            m.hp -= damage;
            
            if ( ( ( atkef & ITM_ATKEF.CRITICAL ) != 0 || Class == CLS.NIN ) 
                    && ( m.defef & MON_ACT.ATK_ATK ) == 0 )
            {
                // critical hit
                ratio = ( ( level - m.level ) / 5 + 2 ) * 5;

                if ( ratio < 10 )
                    ratio = 10;

                if ( ratio > 65 )
                    ratio = 65;

                if ( Class != CLS.NIN && ratio > 35 )
                    ratio = 35;

                if ( get_rand( 99 ) + 1 <= ratio )
                {
                    textout( _( "  The %1 gets the head cut off!\n" ) , m.getDispNameA );
                    get_exp += m.exp;
                    m.marksUp;
                    marks ++;
          
                    m.turn.del;
                    m.del;
                }
                else if ( m.hp <= 0 )
                {
                    textout( _( "    The %1 is killed!\n" ) , m.getDispNameA );
                    get_exp += m.exp;
                    m.marksUp;
                    marks ++;
          
                    m.turn.del;
                    m.del;
                }
            }
            else if ( m.hp <= 0 )
            {
                textout( _( "    The %1 is killed!\n" ) , m.getDispNameA );
                get_exp += m.exp;
                m.marksUp;
                marks ++;
      
                m.turn.del;
                m.del;
            }
            else
            {
                // 武器の追加効果 
                if ( ( atkef & ITM_ATKEF.SLEEP ) != 0 && m.isDefefSleep )
                {
                    // sleep
                    if ( get_rand( 99 ) + 1 <= 25 )
                    { // 25%
                        textout( _( "  The %1 is slept!\n" ) , m.getDispNameA );
                        m.status = STS.SLEEP;
                        getChar();
                    }
                }
            }
        }
        else
        {
            textout( _( "   ... and misses\n" ) );
        }
        getChar();

        return;
    }

    /*--------------------
       actDispel - dispell
       --------------------*/
    void actDispel( MonsterTeam mt )
    {
        int i, chance;
        int succeed;

        chance = 50 + ( 5 * level ) - ( 10 * mt.top.def.level );
      
        if ( ( mt.top.def.defef & 0x40 ) == 0 )
            goto FAIL;
      
        if ( Class == CLS.LOR )
            chance -= 40;

        if ( Class == CLS.BIS )
            chance -= 20;

        if ( chance < 5 )
            chance = 5;
      
        succeed = 0;
        for ( i = 0; i < mt.num; i++ )
          if ( get_rand( 100 ) < chance )
              succeed++;
      
        for (i = 0; i < succeed; i++)
        {
            mt.top.turn.del;
            mt.top.del;
        }
      
        if ( succeed > 0 )
        {
            textout( N_( "%1 dispels %2 monster\n" 
                       , "%1 dispels %2 monsters\n" , succeed )
                        , name , succeed );
        }
        else
        { // failed
    FAIL:
            textout( _( "%1 attempts to dispel\n   and fails.\n" ) , name );
        }
        getChar();
      
        return;
    }

    /*--------------------
       actSpellInBattle - 戦闘中の呪文
        // magic: action & 0x80
        // rtn=2: malor/kadorto
       --------------------*/
    int actSpellInBattle()
    {
      
        int i;

        int mag;
        mag = action & 0x7f;

      
        textout( _( "%1 casts a %2.\n" ) , name , magic_data[ mag ].name );
      
        if ( silenced == true)
        {
            textout( _( "  but, %1 is silenced!\n" ) , name );
            getChar();
            return 0;
        }
      
        switch ( magic_data[ mag ].type )
        {
            case MAG_TYPE.RETURN:    // return castle
                party.x     = 1;
                party.y     = 2;
                party.layer = 0;
                for (i = 0; i < party.num; i++)
                    party.mem[ i ].outflag = OUT_F.CASTLE ; // in castle
                return 2;
            case MAG_TYPE.TELEPT:                        // escape( random )
                party.x = to!byte( get_rand( MAP_MAX_X ) + 1 );
                party.y = to!byte( get_rand( MAP_MAX_Y ) + 1 );
                return 2;
            case MAG_TYPE.RCGNIZE:       // identify
                spell_latuma;
                break;
            case MAG_TYPE.ATKONE: /* atk(1) */
                spell_atk( mag , getTargetMonster );
                break;
            case MAG_TYPE.ATKGRP: /* atk(gr) */
                spell_atkGrp( mag , getTargetMonsterTeam );
                break;
            case MAG_TYPE.ATKALL: /* atk(all) */
                spell_atkAll( mag );
                break;
            case MAG_TYPE.SUFCATN:     // vanished
                spell_sufcatn( getTargetMonsterTeam );
                break;
            case MAG_TYPE.VACUITY:
                spell_vacuity();
                break;
            case MAG_TYPE.HEALONE: /* HP+(1) */
                spell_healOne( mag , target );
                break;
            case MAG_TYPE.ACONE: /* ac+(1) */
                textout("MAG_TYPE.ACONE: まだ作ってないよ!\n");
                break;
            case MAG_TYPE.ACGRP: /* ac+(gr) */
                spell_acDownGrp( getTargetMonsterTeam , magic_data[ mag ].min );
                break;
            case MAG_TYPE.ACALL: /* ac+(all) */
                spell_acDownAll( magic_data[ mag ].min );
                break;
            case MAG_TYPE.ACPONE: /* ac+(party:1) */
                spell_acPlusPlayer( mag );
                break;
            case MAG_TYPE.ACPGR: /* ac+(party:all) */
                spell_acPlusParty( mag );
                break;
            case MAG_TYPE.HEALALL: /* HP(all) */
                spell_healAll( mag );
                break;
            case MAG_TYPE.DETXIFY: /* latumofis */
                spell_curePoison;
                break;
            case MAG_TYPE.CURE: /* dialko */
                spell_cureParalize;
                break;
            case MAG_TYPE.BLESS: /* madi */
                spell_bless();
                break;
            case MAG_TYPE.Bless: 
                spell_Bless();
                break;
            case MAG_TYPE.GUARD: /* maporfic */
                party.ac = -2;
                party.win_disp_noreorder;
                getChar();
                break;
            case MAG_TYPE.SILENC: // montino(gr)
                spell_silenc( getTargetMonsterTeam );
                break;
            case MAG_TYPE.SLEEP: /* sleep(gr) */
                spell_sleep( getTargetMonsterTeam );
                break;
            case MAG_TYPE.BIND: /* manifo(gr) */
                spell_bind( getTargetMonsterTeam );
                break;
            case MAG_TYPE.NOKESSN:
                spell_nokessn( getTargetMonsterTeam.getRandMonster );
                break;
            case MAG_TYPE.DYNG:
                spell_dyng( getTargetMonsterTeam.getRandMonster );
                break;
            default:
                assert( 0 );
        }
        return 0;
    }



    /*--------------------
       spell_latuma - モンスター識別
       --------------------*/
    void spell_latuma()
    {

        party.setIdentify;

        MonsterTeam mt = monParty.top;
        for (int i = 0; i < monParty.num; i++)
        {
          mt.ident = false; // identified
          mt = mt.next;
        }
        getChar();

        return;
    }

    /*--------------------
       spell_atk - 1体魔法攻撃
       --------------------*/
    /* void pspl_atk(battle_turnt *btp, int nGroup, int nMember) */
    void spell_atk( int mag , Monster m )
    {
        int damage;
        
        MonsterTeam mt;
        mt = m.team;

        if ( m.def.magdef >= get_rand( 99 ) + 1 )
        {
            textout( _( "  %1 resisted the spell.\n" ) , m.getDispNameA );
            getChar();
            return;
        }

        damage = magic_data[ mag ].min + get_rand( magic_data[ mag ].add );
        switch ( magic_data[ mag ].attr )
        {
            case 1: /* fire */
            case 3: /* small fire */
                if( m.def.isDefefFire )
                    damage /= 2;
                  break;
            case 2: /* ice */
                if( m.def.isDefefCold )
                    damage /= 2;
                break;
            case 4: /* undead only */
                if( m.def.isDefefUndead )
                    damage = 0;
                break;
            case 0:
            default:
                break;
        }

        if (damage != 0)
        {
            textout( _( "  %1 takes %2 damage.\n" ) , m.getDispNameA , damage );
            m.hp -= damage;
            if ( m.hp <= 0 )
            {
                textout( _( "    %1 is dead!\n" ) , m.getDispNameA );
                
                get_exp += m.exp;
                m.marksUp;
                marks ++;
          
                m.turn.del;
                m.del;
            }
        }
        getChar();
        return;
    }


    /*--------------------
       spell_atkGrp - 
       --------------------*/
    void spell_atkGrp( int mag , MonsterTeam mt )
    {
        Monster m;

        m = mt.top;
        while( m !is null )
        {
            spell_atk( mag , m );
            m = m.next;
        }
        return;
    }

    /*--------------------
       spell_atkAll  
       --------------------*/
    void spell_atkAll( int mag )
    {
        MonsterTeam mt;

        mt = monParty.top;
        while( mt !is null )
        {
            spell_atkGrp( mag , mt );
            mt = mt.next;
        }
        return;
    }

    /*--------------------
       spell_sufcatn
       --------------------*/
    void spell_sufcatn( MonsterTeam mt )
    {
        Monster m;

        m = mt.top;
        while( m !is null )
        {
            if ( m.def.level < 8 )
            {
                textout( _( "  %1 is vanished!\n" ) , m.getDispNameA );

                get_exp += m.exp;
                m.marksUp;
                marks ++;

                m.turn.del;
                m.del;
            }
            else
            {
                textout( _( "  %1 is alive.\n" ) , m.getDispNameA );
            }
            getChar();
            m = m.next;
        }
        return;
    }

    /*--------------------
       spell_vacuity
       --------------------*/
    void spell_vacuity()
    {
        MonsterTeam mt;

        mt = monParty.top;
        while( mt !is null )
        {
            spell_sufcatn( mt );
            mt = mt.next;
        }
        return;
    }

    /*--------------------
       spell_healOne
       --------------------*/
    void spell_healOne( int mag , int target )
    {
        int nPoints;
        Member mem;
        mem = party.mem[ target ];

        if ( mem.status >= STS.DEAD )
            return;

        nPoints = magic_data[ mag ].min + get_rand( magic_data[ mag ].add );

        textout( "  " );
        if ( mem.hp + nPoints >= mem.maxhp )
        {
            mem.hp = mem.maxhp;
            textout( _( "%1 is completely healed.\n" ) , mem.name );
        }
        else
        {
            mem.hp += nPoints;
            textout( _( "%1 hit points are restored\n  to %2.\n" ) , nPoints , mem.name );
        }

        if( now_mode == HSTS.BATTLE )
        {
            party.win_disp_noreorder();
            getChar();
        }
        else
        {
            party.win_disp();
        }

        return;
    }

    /*--------------------
       spell_healAll
       --------------------*/
    void spell_healAll( int mag )
    {
        for (int i = 0; i < party.num; i++)
            spell_healOne( mag , i );
        if( now_mode != HSTS.BATTLE )
            getChar;
        return;
    }

    /*--------------------
       spell_curePoison
       --------------------*/
    void spell_curePoison()
    {
        Member mem = party.mem[ target ];
        if( mem.poisoned )
        {
            mem.poisoned = false;
            textout( _( "  %1 is cured.\n" ) , mem.name );
        }
        else
        {
            textout( _( "  * done *\n" ) );
        }
        if( now_mode == HSTS.BATTLE )
            party.win_disp_noreorder();
        else
            party.win_disp;
        getChar();

        return;
    }
    
    /*--------------------
       spell_cureParalize
       --------------------*/
    void spell_cureParalize()
    {
        Member mem = party.mem[ target ];
        if( mem.status <= STS.PARALY )
        {
            mem.status = STS.OK;
            textout( _( "  %1 is cured.\n" ) , mem.name );
        }
        else
        {
            textout( _( "  * done *\n" ) );
        }
        if( now_mode == HSTS.BATTLE )
            party.win_disp_noreorder();
        else
            party.win_disp();

        getChar();

        return;
    }
    
    /*--------------------
       spell_acDownGrp
       --------------------*/
    void spell_acDownGrp( MonsterTeam mt , int acplus )
    {

        Monster m;

        m = mt.top;
        while( m !is null )
        {
            m.acplus += acplus;
            m = m.next;
        }

        textout( N_( "  %1's AC +%2.\n" 
                   , "  %1' AC +%2.\n", mt.num )
                        , mt.getDispNameS , acplus );
        return;

    }

    /*--------------------
       spell_acDownAll
       --------------------*/
    void spell_acDownAll(  int acplus )
    {
        MonsterTeam mt;

        mt = monParty.top;
        while ( mt !is null )
        {
            spell_acDownGrp( mt , acplus );
            mt = mt.next;
        }
        return;
    }

    /*--------------------
       spell_acPlusPlayer
       --------------------*/
    void spell_acPlusPlayer( int mag )
    {
        if ( magic_data[ mag ].batl == 1 ) /* target = caller */
            ac[ 1 ] += magic_data[ mag ].min;
        else
            party.mem[ target ].ac[ 1 ] += magic_data[ mag ].min;

        party.win_disp_noreorder;
        getChar();

        return;
    }

    /*--------------------
       spell_acPlusParty
       --------------------*/
    void spell_acPlusParty( int mag )
    {
        for (int i = 0; i < party.num; i++)
            party.mem[ i ].ac[ 1 ] += magic_data[ mag ].min;
        party.win_disp_noreorder;
        getChar();

        return;
    }


    /*--------------------
       spell_bless
       --------------------*/
    void spell_bless()
    {

        if ( party.mem[ target ].status >= STS.DEAD )
        {
            textout( _( "  * done *\n" ) );
        }
        else
        {
            party.mem[ target ].status = STS.OK;

            textout( "  " );
            party.mem[ target ].hp = party.mem[ target ].maxhp;
            textout( _( "%1 is completely healed.\n" ) , party.mem[ target ].name );
            party.win_disp_noreorder;
        }
        getChar();
        return;
    }

    /*--------------------
       spell_Bless
       --------------------*/
    void spell_Bless()
    {

        int total;
        int plus;

        Member mem = party.mem[ target ];

        if ( ! ( mem.status != STS.DEAD || mem.status != STS.ASHED ) )
        {
            textout( _( "  what?\n" ) );
        }
        else
        {
            total = mem.vit[ 0 ] + mem.vit[ 1 ]
                  + mem.luk[ 0 ] + mem.luk[ 1 ];
            total /= 2;
            if ( total <= 3 )
                plus =  - 2;
            else if ( total <= 5 )
                plus =  - 1;
            else if ( total <= 15 )
                plus = 0;
            else if ( total <= 16 )
                plus = 1;
            else if ( total <= 17 )
                plus = 2;
            else
                plus = 3;

            if ( mem.status == STS.ASHED )
            {
                plus += 5; // possibility of resurrection is 1/3(ASHED) if plus=0
            }
            else
            {
                plus += 14; // possibility of resurrection is 14/19(DEAD) if plus=0
            }

            if ( get_rand( 18 ) <= plus )
            {
                textout( _( "  * ok *\n" ) );
                mem.status = STS.OK;
                mem.hp = mem.maxhp;
            }
            else
            {
                textout( _( "  oops!!\n" ) );
                if ( mem.status == STS.ASHED )
                    mem.status = STS.LOST;
                else
                    mem.status = STS.ASHED;
            }
            if( get_rand( 3 ) == 0 )
                mem.vit[ 0 ]--;
        }
        party.win_disp();
        return;
    }

    /*--------------------
       spell_breathe
       --------------------*/
    void spell_breathe()
    {

        int total;
        int plus;

        Member mem = party.mem[ target ];

        if ( mem.status != STS.DEAD )
        {
            textout( _( "  what?\n" ) );
        }
        else
        {
            total = mem.vit[ 0 ] + mem.vit[ 1 ]
                  + mem.luk[ 0 ] + mem.luk[ 1 ];
            total /= 2;
            if ( total <= 3 )
                plus =  - 2;
            else if ( total <= 5 )
                plus =  - 1;
            else if ( total <= 15 )
                plus = 0;
            else if ( total <= 16 )
                plus = 1;
            else if ( total <= 17 )
                plus = 2;
            else
                plus = 3;

            if ( get_rand( 18 ) <= 11 + plus )
            { // possibility of resurrection is 2/3 if plus=0
                textout( "  * ok *\n" );
                mem.status = STS.OK;
                mem.hp = 1;
            }
            else
            {
                textout( _( "  oops!!\n" ) );
                mem.status = STS.ASHED;
            }
            if( get_rand( 3 ) == 0 )
                mem.vit[ 0 ]--;
        }
        party.win_disp();
        return;
    }



    /*--------------------
       spell_silenc - silence
       --------------------*/
    void spell_silenc( MonsterTeam mt )
    {

        getChar();

        Monster m;
        m = mt.top;

        while( m !is null )
        {
            if ( m.magdef >= get_rand( 99 ) + 1 )
            {
                textout( _( "  %1 resisted the spell.\n" ) ,m.getDispNameA );
            }
            else if ( ! m.silenced )
            {
                if ( get_rand( 1 ) == 0 )
                {
                    m.silenced = true;
                    textout( _( "  %1 is silenced!\n" ) , m.getDispNameA );
                }
                else
                {
                    textout( _( "  %1 is not silenced.\n" ) , m.getDispNameA );
                }
            }
            getChar();
            m = m.next;
        }
        return;
    }

    /*--------------------
       spell_sleep sleep
       --------------------*/
    void spell_sleep( MonsterTeam mt )
    {

        Monster m;

        getChar();

        m = mt.top;

        while( m !is null )
        {
            if ( m.magdef >= get_rand( 99 ) + 1 )
            {
                textout( _( "  %1 resisted the spell.\n" ) ,m.getDispNameA );
            }
            else if  ( m.def.isDefefSlpEzy )
            { // sleep easily
                if ( get_rand( 5 ) != 0 && m.status == MON_STS.OK )
                {
                    m.status = MON_STS.SLEEP ; // sleep
                    textout( _( "  %1 is slept.\n" ) , m.getDispNameA );
                }
                else
                {
                    textout( _( "  %1 is not slept.\n" ) , m.getDispNameA );
                }
            }
            else
            {
                if ( get_rand( 1 ) != 0 && m.status == MON_STS.OK )
                {
                    m.status = MON_STS.SLEEP  ; // sleep
                    textout( _( "  %1 is slept.\n" ) , m.getDispNameA );
                }
                else
                {
                    textout( _( "  %1 is not slept.\n" ) , m.getDispNameA );
                }
            }

            getChar();
            m = m.next;
        }
        return;

    }

    /*--------------------
       spell_bind - paralyze
       --------------------*/
    void spell_bind( MonsterTeam mt )
    {


        getChar();

        Monster m;
        m = mt.top;

        while( m !is null )
        {
            if ( m.magdef >= get_rand( 99 ) + 1 )
            {
                textout( _( "  %1 resisted the spell.\n" ) ,m.getDispNameA );
            }
            else if ( m.def.isDefefSlpEzy ) // sleep easily
            { // sleep easily
                if ( get_rand( 5 ) != 0 && m.status == MON_STS.OK )
                {
                    m.status = MON_STS.SLEEP ; // sleep
                    textout( _( "  %1 is held.\n" ) , m.getDispNameA );
                }
                else
                {
                    textout( _( "  %1 is not held.\n" ) , m.getDispNameA );
                }
            }
            else
            {
                if ( get_rand( 1 ) != 0 && m.status == MON_STS.OK )
                {
                    m.status = MON_STS.SLEEP ; // sleep
                    textout( _( "  %1 is held.\n" ) , m.getDispNameA );
                }
                else
                {
                    textout( _( "  %1 is not held.\n" ) , m.getDispNameA );
                }
            }
            getChar();
            m = m.next;
        }
        return;
    }

    /*--------------------
       spell_nokessn - sudden death
       --------------------*/
    void spell_nokessn( Monster m )
    {
        if ( m.magdef >= get_rand( 99 ) + 1 )
        {
            textout( _( "  %1 resisted the spell.\n" ) ,m.getDispNameA );
        }
        else if ( ! m.def.isDefefUndead && get_rand( 3 ) == 0 )
        { // possibility is 1/4
            textout( _( "  %1 is dead!\n" ) , m.getDispNameA );

            get_exp += m.exp;
            m.marksUp;
            marks ++;

            m.turn.del;
            m.del;
        }
        else
        {
            textout( _( "  %1 is alive!\n" ) , m.getDispNameA );
        }
        getChar();
        return;
    }

    /*--------------------
       spell_dyng - dying
       --------------------*/
    void spell_dyng( Monster m )
    {

        int mon_hp;

        if ( m.magdef >= get_rand( 99 ) + 1 )
        {
            textout( _( "  %1 resisted the spell.\n" ) ,m.getDispNameA );
        }
        else
        {
            mon_hp = get_rand( 7 ) + 1;
            if ( mon_hp > m.hp )
                mon_hp = m.hp;
            int damage = m.hp - mon_hp;
            textout( _( "  %1 gets %2 damage!\n" ) , m.getDispNameA , damage );
            m.hp = mon_hp;
        }
        getChar();
        return;
    }

    /*--------------------
       spell_mapper
       --------------------*/
    void spell_mapper()
    {
        party.setMapper;
        party.setScope;
        party.scopeCount += 1;
        textout( _( "done.\n" ) );
        header_disp( HSTS.CAMP );
        return;
    }

    /*--------------------
       spell_flash
       --------------------*/
    void spell_flash()
    {
        party.setLight;
        party.lightCount += S_LIGHT_COUNT;
        party.setScope;
        party.scopeCount += S_SCOPE_COUNT;
        textout( _( "done.\n" ) );
        header_disp( HSTS.CAMP );
        return;
    }

    /*--------------------
       spell_shine
       --------------------*/
    void spell_shine()
    {
        party.setLight;
        party.lightCount += L_LIGHT_COUNT;
        party.setScope;
        party.scopeCount += L_SCOPE_COUNT;
        textout( _( "done.\n" ) );
        header_disp(HSTS.CAMP);
        return;
    }

    /*--------------------
       spell_floatn
       --------------------*/
    void spell_floatn()
    {
        party.setFloat;
        textout( _( "done.\n" ) );
        header_disp( HSTS.CAMP );
        return;
    }

    /*--------------------
       spell_recognize
       --------------------*/
    void spell_recognize()
    {
        party.setIdentify;
        textout( _( "done.\n" ) );
        header_disp( HSTS.CAMP );
        return;
    }

    /*--------------------
       spell_telept（キャンプ中`）
       --------------------*/
    void spell_telept()
    {
        int xpos, ypos, layer;
        string numtext;


        textout( _( "\n*** where do you want to teleport? ***\n" ) );

    XPOS:
        textout( _( "enter xpos(z:leave): \n" ) );
        numtext = tline_input(  3 , text_cury + TXTW_Y_TOP, text_curx + TXTW_X_TOP );
        textout( ">%1\n" , numtext );

        if ( numtext.length == 0 || numtext[ 0 ] == 'z' )
        {
            textout( _( "quit.\n" ) );
            return;
        }

        if( ! isNumeric( numtext ) )
        {
            textout( _( "what?\n" ) );
            goto XPOS;
        }

        xpos = to!int( numtext );

        if( xpos < 0 || xpos >= MAP_MAX_X )
        {
            textout( _( "what?\n" ) );
            goto XPOS;
        }

    YPOS:
        textout( _("enter ypos(z:enter xpos again): \n") );

        numtext = tline_input(  3 , text_cury + TXTW_Y_TOP, text_curx + TXTW_X_TOP );
        textout( ">%1\n" , numtext );

        if ( numtext.length == 0 || numtext[ 0 ] == 'z' )
            goto XPOS;

        if( ! isNumeric( numtext ) )
        {
            textout( _( "what?\n" ) );
            goto YPOS;
        }

        ypos = to!int( numtext );

        if( ypos < 0 || ypos >= MAP_MAX_Y )
        {
            textout( _( "what?\n" ) );
            goto YPOS;
        }

    LAYER:
        textout( _( "enter layer(z:enter ypos again): \n" ) );
        numtext = tline_input(  3 , text_cury + TXTW_Y_TOP, text_curx + TXTW_X_TOP );
        textout( ">%1\n" ,  numtext );

        if ( numtext.length == 0 || numtext[ 0 ] == 'z' )
            goto YPOS;

        if( ! isNumeric( numtext ) )
        {
            textout( _( "what?\n" ) );
            goto LAYER;
        }

        layer = to!int( numtext );

        if( layer < 0 || layer >= MAXLAYER )
        {
            textout( _( "what?\n" ) );
            goto LAYER;
        }


        party.x     = to!byte( xpos );
        party.y     = to!byte( ypos );

        if( party.layer != layer )
        {
            party.layer = to!byte( layer );
            party.setDungeon;
            /* party.dungeon.setEndPos; */
            party.dungeon.initDisp;
        }

        textout( _( "done.\n" ) );
        header_disp( HSTS.CAMP );
        party.win_disp();
        return;
    }
}


