
// Phobos Runtime Library
import std.stdio;
import std.string : format , split , chop , isNumeric;
import std.conv;

// mysource 
import citem;
import cmagic_def;
import cbattleturn;
import cmonster_team;
import cmonster;

import def;
import app;


class Member
{
private:

    // status bit
    enum BIT_STS_POISONED           = 0x80;
    enum BIT_STS_EXCEPTING_POISONED = 0x7f;

    /+ 
    enum ITM_KIND : WEAPON = 0, ARMOR  = 1, SHIELD = 2, HELM   = 3, GLOVES = 4, ITEM   = 5
    +/
    void equipSub( ITM_KIND itmKind )
    {
        int i;
        char ch;
        string list;
        int curseflag = 0;

        Item itm;


        for ( i = 0; i < MAXCARRY; i++ )
        {
            if ( item[ i ].isNothing )
                continue ;

            if ( ( item[ i ].kind == itmKind ) 
                    && item[ i ].canBeEquipped( Class ) )
            {

                list ~= ( i + 1 ).to!string;

                if ( item[ i ].cursed )
                    curseflag = 1;

                txtMessage.textout( "%1)%2\n" 
                                    , to!string( i + 1 ) 
                                    , item[ i ].getDispNameA );

                if( ! item[ i ].cursed 
                        && item[ i ].equipped )
                    item[ i ].equipped = false;
            }
        }

        ch = getCharFromList( list ~ "l" );

        if ( curseflag != 0 )
        {
            txtMessage.textout( _( "you are cursed...\n" ) );
        }
        else if ( ch == 'l' )
        {
            // nothing done
        }
        else if ( ! item[ ch-'1' ].isNothing )
        {
            itm = item[ ch - '1' ];
            if ( ( itm.kind == itmKind ) && itm.canBeEquipped( Class )  )
            {
                if ( ( itm.Align & ( 1 << Align ) ) != 0 )
                {
                    itm.equipped = true;
                    itm.cursed = true;
                    txtMessage.textout( _( "*** oops! you got cursed ...\n" ) );
                }
                else
                {
                    itm.equipped = true;
                }
            }
            else if ( ! itm.isNothing )
            {
                txtMessage.textout( _( "you cannot equip it.\n" ) );
            }
        }

        for ( i = 0; i < MAXCARRY; i++ )
        {
            itm = item[ i ];
            if ( itm.isNothing )
                continue;

            if ( itm.kind != itmKind )
                continue;

            if ( itm.effect[ 2 ] == 0 )
                continue;

            txtMessage.textout( _( "do you want to use the special power\n  of %1 (y/n)?" ) 
                                , itm.getDispName );

            ch = answerYN;

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


    byte[7] mspl_know;
    byte[7] pspl_know;

    MagicDef[] mspl;    // 覚えている魔法
    MagicDef[] pspl;    // 覚えている魔法

    byte[7] mspl_max;
    byte[7] mspl_pt;
    byte[7] pspl_max;
    byte[7] pspl_pt;

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
    ACT  action; // 0:fight,1:parry,3:use,4:run,5:dispell,6:magic
    /* int  actItem; // item number */
    string actionDetails;           // in battle disp action & target
    Item  actItem; // use item
    MagicDef  actMagic; // cast spell
    MonsterTeam  targetMonster; /* target monster team or spell or item */
    Member       targetPlayer;  /* target monster team or spell or item */
    bool silenced; // 1:silenced, 0:not
    
    byte outflag; /* 0:in bar, 1:in castle, 3:in maze */
    int x;
    int y;
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

        ubyte sts  = to!ubyte( data[ i++ ] ); 
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
        setKnownSpell( TYPE_MAGIC.mage );

        pspl_know[0] = cast( byte ) parse!(int)( data[ i++ ], 16);
        pspl_know[1] = cast( byte ) parse!(int)( data[ i++ ], 16);
        pspl_know[2] = cast( byte ) parse!(int)( data[ i++ ], 16);
        pspl_know[3] = cast( byte ) parse!(int)( data[ i++ ], 16);
        pspl_know[4] = cast( byte ) parse!(int)( data[ i++ ], 16);
        pspl_know[5] = cast( byte ) parse!(int)( data[ i++ ], 16);
        pspl_know[6] = cast( byte ) parse!(int)( data[ i++ ], 16);
        setKnownSpell( TYPE_MAGIC.priest );

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
        x       = to!int( data[ i++ ] );
        y       = to!int( data[ i++ ] ); 
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

        for ( j = 0 ; j < 7 ; j++ )
        {
            mspl_know[j] = 0;
            pspl_know[j] = 0;
            mspl_max[j]  = 0;
            pspl_max[j]  = 0;
            mspl_pt [j]  = 0;
            pspl_pt [j]  = 0;
            mspl.length  = 0;
            pspl.length  = 0;
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

    /*--------------------
       setKnownSpell - フラグにあわせ覚えている呪文を設定
       --------------------*/
    void setKnownSpell( TYPE_MAGIC type )
    {
        MagicDef[ string ] spellList;
        MagicDef[] spl;
        byte[ 7 ] flg;

        switch( type )
        {
            case TYPE_MAGIC.mage:
                spellList = magic_mag;
                flg = mspl_know;
                mspl.length = 0;
                break;
            case TYPE_MAGIC.priest:
                spellList = magic_prt;
                flg = pspl_know;
                pspl.length = 0;
                break;
            default:
                assert( 0 );
        }

        foreach( MagicDef m ; spellList )
            if( ( flg[ m.level ] & ( 0x01 << m.index ) ) != 0 )
                spl ~= m;

        if( type == TYPE_MAGIC.mage )
            mspl = spl.dup;
        else
            pspl = spl.dup;

        return;

    }

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
       dispCharacter - ステータス表示 does not display items nor magics 
       --------------------*/
    void dispCharacter()
    {
        int difflevel;

        /* txtStatus.clear; */

        rewriteOff;

        txtStatus.clear;

        txtStatus.print( 1 , 0 , leftB( name , 20 ) );
        txtStatus.print( 1 , 21 , " age %1" , fillR( age , 3 ) );
      
        switch( Align )
        {
            case ALIGN.GOOD:
                txtStatus.print( 2, 0, "g-" );
                break;
            case ALIGN.EVIL:
                txtStatus.print( 2, 0, "e-" );
                break;
            case ALIGN.NEWT:
                txtStatus.print( 2, 0, "n-" );
                break;
            default:
                assert( 0 );
        }
        switch( race )
        {
            case RACE.HUMAN:
                txtStatus.print("human ");
                break;
            case RACE.ELF:
                txtStatus.print("elf   ");
                break;
            case RACE.DWARF:
                txtStatus.print("dwarf ");
                break;
            case RACE.GNOME: 
                txtStatus.print("gnome ");
                break;
            case RACE.HOBBIT:
                txtStatus.print("hobbit");
                break;
            default:
                assert( 0 );
        }
        if( ac[ 0 ] >=  - 999 )
            txtStatus.print(  2 , 13 , "ac %1" , fillR( ac[ 0 ] , 4 ) );
        else
            txtStatus.print(  2 , 13 , "ac VVVL" );

        txtStatus.print( "  day %1" , fillR( day , 3 ) );

        switch( Class )
        {
            case CLS.FIG:
                txtStatus.print( 3 , 10 , "Fighter");
                break;
            case CLS.THI:
                txtStatus.print( 3 , 10 , "Thief");
                break;
            case CLS.PRI:
                txtStatus.print( 3 , 10 , "Priest");
                break;
            case CLS.MAG:
                txtStatus.print( 3 , 10 , "Mage");
                break;
            case CLS.BIS:
                txtStatus.print( 3 , 10 , "Bishop");
                break;
            case CLS.SAM:
                txtStatus.print( 3 , 10 , "Samurai ");
                break;
            case CLS.LOR:
                txtStatus.print( 3 , 10 , "Lord");
                break;
            case CLS.NIN:
                txtStatus.print( 3 , 10 , "Ninja ");
                break;
            default:
                assert( 0 );
        }

        difflevel = calcLevel() - level;
        if (difflevel == 0)
            txtStatus.print( 3 , 19 , "lv %1" , fillR( level, 7 ) );
        else
            txtStatus.print( 3 , 19 , "lv%1(+%2)" , fillR( level, 3 ) , fillR( difflevel, 2 ) );

        txtStatus.print(  4 , 0 , " str %1" , fillR( str[ 0 ] + str[ 1 ] , 2 ) );
        txtStatus.print(  5 , 0 , " i.q %1" , fillR( iq[ 0 ]  + iq[ 1 ]  , 2 ) );
        txtStatus.print(  6 , 0 , " pie %1" , fillR( pie[ 0 ] + pie[ 1 ] , 2 ) );
        txtStatus.print(  7 , 0 , " vit %1" , fillR( vit[ 0 ] + vit[ 1 ] , 2 ) );
        txtStatus.print(  8 , 0 , " agi %1" , fillR( agi[ 0 ] + agi[ 1 ] , 2 ) );
        txtStatus.print(  9 , 0 , " luk %1" , fillR( luk[ 0 ] + luk[ 1 ] , 2 ) );
        txtStatus.print( 10 , 0 , " cha %1" , fillR( cha[ 0 ] + cha[ 1 ] , 2 ) );



        txtStatus.print( 4 , 10 , "gold %1" , fillR( gold, 14 ) );
        txtStatus.print( 5 , 10 , "ep%1" , fillR( exp, 17 ) );

        if( nextexp - exp >= 0 )
            txtStatus.print( 6 , 10 , "next%1" , fillR( nextexp - exp, 15 ) );
        else
            txtStatus.print( 6 , 10 , "next      0(%1)" , fillR( calcNextExp( calcLevel() ) - exp, 6 ) );
      
        txtStatus.print( 7 , 10 , "marks %1" , fillR( marks, 13 ) );
        txtStatus.print( 8 , 10 , "h.p. %1/%2" , fillR( hp, 6 ) , fillR( maxhp, 7 ) );
        txtStatus.print( 9 , 10 , "rip%1" , fillR( rip, 3 ) );

        txtStatus.print( 10, 10 , " sts " );
        setStatusColor;
        switch( status )
        {
            case STS.OK:
                if( poisoned )
                    txtStatus.print( "poisoned" );
                else
                    txtStatus.print( "      ok" );
                break;
            case STS.SLEEP:
                txtStatus.print( "   sleep" );
                break;
            case STS.AFRAID:
                txtStatus.print( "  afraid" );
                break;
            case STS.PARALY:
                txtStatus.print( "paralizd" );
                break;
            case STS.STONED:
                txtStatus.print( "  stoned" );
                break;
            case STS.DEAD:
                txtStatus.print( "    dead" );
                break;
            case STS.ASHED:
                txtStatus.print( "   ashed" );
                break;
            case STS.LOST:
                txtStatus.print( "    lost" );
                break;
            case STS.NIL:
                txtStatus.print( "     nil" );
                break;
            default:
                assert( 0 );
        }
        setColor( CL.NORMAL );
      
        txtStatus.print( 11 , 10 , "mage %1/%2/%3/%4/%5/%6/%7" 
                                    , fillR( mspl_pt[ 0 ] , 1 )
                                    , fillR( mspl_pt[ 1 ] , 1 )
                                    , fillR( mspl_pt[ 2 ] , 1 )
                                    , fillR( mspl_pt[ 3 ] , 1 )
                                    , fillR( mspl_pt[ 4 ] , 1 )
                                    , fillR( mspl_pt[ 5 ] , 1 )
                                    , fillR( mspl_pt[ 6 ] , 1 ) );
        txtStatus.print( 12 , 10 , " max %1/%2/%3/%4/%5/%6/%7" 
                                    , fillR( mspl_max[ 0 ] , 1 ) 
                                    , fillR( mspl_max[ 1 ] , 1 ) 
                                    , fillR( mspl_max[ 2 ] , 1 ) 
                                    , fillR( mspl_max[ 3 ] , 1 ) 
                                    , fillR( mspl_max[ 4 ] , 1 ) 
                                    , fillR( mspl_max[ 5 ] , 1 ) 
                                    , fillR( mspl_max[ 6 ] , 1 ) );
        txtStatus.print( 13 , 10 , "prst %1/%2/%3/%4/%5/%6/%7" 
                                    , fillR( pspl_pt[ 0 ] , 1 )
                                    , fillR( pspl_pt[ 1 ] , 1 )
                                    , fillR( pspl_pt[ 2 ] , 1 )
                                    , fillR( pspl_pt[ 3 ] , 1 )
                                    , fillR( pspl_pt[ 4 ] , 1 )
                                    , fillR( pspl_pt[ 5 ] , 1 )
                                    , fillR( pspl_pt[ 6 ] , 1 ) );
        txtStatus.print( 14 , 10 , " max %1/%2/%3/%4/%5/%6/%7" 
                                    , fillR( pspl_max[ 0 ] , 1 ) 
                                    , fillR( pspl_max[ 1 ] , 1 ) 
                                    , fillR( pspl_max[ 2 ] , 1 ) 
                                    , fillR( pspl_max[ 3 ] , 1 ) 
                                    , fillR( pspl_max[ 4 ] , 1 ) 
                                    , fillR( pspl_max[ 5 ] , 1 ) 
                                    , fillR( pspl_max[ 6 ] , 1 ) );
        rewriteOn;

        return;
    }

    /*--------------------
       inspect - ステータス情報等表示
       --------------------*/
    void inspect()
    {
        int i, difflevel;
        string align_race;
      
        txtStatus.clear();
      
        rewriteOff;

        txtStatus.print( 1 , 0 , "                 ");
        txtStatus.print( 1 , 0 , leftB( name , MAX_MEMBER_NAME ) );
        switch( Align )
        {
            case ALIGN.GOOD:
                align_race = "(g-";
                break;
            case ALIGN.EVIL:
                align_race = "(e-";
                break;
            case ALIGN.NEWT:
                align_race = "(n-";
                break;
            default:
                assert( 0 );
        }

        switch( race )
        {
            case RACE.HUMAN:
                align_race ~= "human)";
                break;
            case RACE.ELF:
                align_race ~= "elf)";
                break;
            case RACE.DWARF:
                align_race ~= "dwarf)";
                break;
            case RACE.GNOME: 
                align_race ~= "gnome)";
                break;
            case RACE.HOBBIT:
                align_race ~= "hobbit)";
                break;
            default:
                assert( 0 );
        }

        txtStatus.print( 1, 14, fillR( align_race , 15 ) );
        txtStatus.print( 2 , 0 , "age %1 rip %2 marks %3" 
                                    , fillR( age , 3) 
                                    , fillR( rip , 3 )
                                    , fillR( marks , 7 ) );

        switch( Class )
        {
            case CLS.FIG:
                txtStatus.print( 3 , 0 , "Fig." );
                break;
            case CLS.THI:
                txtStatus.print( 3 , 0 , "Thi." );
                break;
            case CLS.PRI:
                txtStatus.print( 3 , 0 , "Pri." );
                break;
            case CLS.MAG:
                txtStatus.print( 3 , 0 , "Mag." );
                break;
            case CLS.BIS:
                txtStatus.print( 3 , 0 , "Bis." );
                break;
            case CLS.SAM:
                txtStatus.print( 3 , 0 , "Sam." );
                break;
            case CLS.LOR:
                txtStatus.print( 3 , 0 , "Lor." );
                break;
            case CLS.NIN:
                txtStatus.print( 3 , 0 , "Nin." );
                break;
            default:
                assert( 0 );
        }

        difflevel = calcLevel() - level;
        if ( difflevel == 0 )
        {
            txtStatus.print( 3, 4, "lv%1" , fillR( level, 8 ) );
        }
        else
        {
            txtStatus.print( 3, 4, "lv%1(+%2)" 
                                   , fillR( level, 3 )
                                   , fillR( difflevel, 2 ) );
        }
      
        txtStatus.print( " gp%1" ,fillR( gold, 12 ) );
        txtStatus.print( 4, 0, "ep%1" , fillR( exp, 12 ) );
        if ( nextexp - exp >= 0 )
            txtStatus.print( " next%1" , fillR( nextexp - exp, 10 ) );
        else
            txtStatus.print( " next 0(%1)" , fillR( calcNextExp( calcLevel() ) - exp, 6 ) );
      
        // spell
        txtStatus.print( 5, 0, formatText( "m%1/%2/%3/%4/%5/%6/%7 "
                                            , fillR( mspl_pt[ 0 ] , 1 )
                                            , fillR( mspl_pt[ 1 ] , 1 )
                                            , fillR( mspl_pt[ 2 ] , 1 )
                                            , fillR( mspl_pt[ 3 ] , 1 )
                                            , fillR( mspl_pt[ 4 ] , 1 )
                                            , fillR( mspl_pt[ 5 ] , 1 )
                                            , fillR( mspl_pt[ 6 ] , 1 ) ) ~ 
                                formatText( "p%1/%2/%3/%4/%5/%6/%7"
                                            , fillR( pspl_pt[ 0 ] , 1 )
                                            , fillR( pspl_pt[ 1 ] , 1 )
                                            , fillR( pspl_pt[ 2 ] , 1 )
                                            , fillR( pspl_pt[ 3 ] , 1 )
                                            , fillR( pspl_pt[ 4 ] , 1 )
                                            , fillR( pspl_pt[ 5 ] , 1 )
                                            , fillR( pspl_pt[ 6 ] , 1 ) ) );

        // item
        for ( i = 0; i < 8; i++ )
        {
            if ( item[ i ].isNothing )
                continue;

            string flg;
            flg = " ";
            if ( ! item[ i ].canBeEquipped( Class ) )
                flg = "#";/* cannot equip */
            if ( item[ i ].equipped )
                flg = "*";/* equipped */
            if ( item[ i ].cursed )
                flg = "$";/* cursed */

            txtStatus.print( 6 + i, 0, "%1)%2%3" 
                                        , i + 1
                                        , flg
                                        , item[ i ].getDispNameA );

        }

        rewriteOn;

        return;
    }


    /*--------------------
       inspectCharacter - メンバー詳細情報表示
        type: 1:camp , 2:battle
       --------------------*/
    void inspectCharacter( int type = 0 )
    {

        dispCharacter;

        txtMessage.textout( _( "  push any key to see items\n" ) );
        getChar();
        item_disp;

        txtMessage.textout( _( "  push any key to read mage spells\n" ) );
        getChar();
        dispSpellList( TYPE_MAGIC.mage );

        txtMessage.textout( _( "  push any key to read priest spells\n" ) );
        getChar();
        dispSpellList( TYPE_MAGIC.priest );

        txtMessage.textout( _( "  push any key to return\n" ) );
        getChar();

        return;

    }


    /*--------------------
       setStatusColor
       --------------------*/
    void setStatusColor()
    {
        int cl;
        switch( status )
        {
            case STS.OK       :
                if( poisoned )
                    cl = STS_CL.POISONED;
                else
                    cl = STS_CL.OK;
                break;
            case STS.SLEEP    :
                cl = STS_CL.SLEEP;
                break;
            case STS.AFRAID   :
                cl = STS_CL.AFRAID;
                break;
            case STS.PARALY   :
                cl = STS_CL.PARALY;
                break;
            case STS.STONED   :
                cl = STS_CL.STONED;
                break;
            case STS.DEAD     :
                cl = STS_CL.DEAD;
                break;
            case STS.ASHED    :
                cl = STS_CL.ASHED;
                break;
            case STS.LOST     :
                cl = STS_CL.LOST;
                break;
            case STS.NIL     :
                cl = STS_CL.NIL;
                break;
            default:
                assert( 0 );
        }
        setColor( cl );
        return;
    }

    /*--------------------
       dispStatusLine - パーティウィンドウ ステータス表示
       --------------------*/
    void dispStatusLine( bool resetStatusLine = true )
    {
        char ch_diff;
        int plus, diff;
        int line_y = CHRW_Y_TOP + getPartyNo + 1;
        string line;

        line = to!string( getPartyNo + 1 );

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

                if( resetStatusLine )
                    line ~= "?????? ???????????????????????" ;
                else
                    line ~= actionDetails;

                break;
            case STS.SLEEP:
                line ~= "sleep  " ~ "                              " ;
                break;
            case STS.AFRAID:
                line ~= "afraid " ~ "                              " ;
                break;
            case STS.PARALY:
                line ~= "pararz " ~ "                              " ;
                break;
            case STS.STONED:
                line ~= "stoned " ~ "                              " ;
                break;
            case STS.DEAD:
                line ~= "dead   " ~ "                              " ;
                break;
            case STS.ASHED:
                line ~= "ashed  " ~ "                              " ;
                break;
            case STS.LOST:
                line ~= "lost   " ~ "                              " ;
                break;
            case STS.NIL:
                line ~= "nil    " ~ "                              " ;
                break;
            default:
                assert( 0 );
        }

        setStatusColor;
        mvprintw( line_y , CHRW_X_TOP , line );
        setColor( CL.NORMAL );

        return;
    }

    /*--------------------
       damegedByPoison - 毒ダメージ
       --------------------*/
    void damagedByPoison()
    {
        if( hp == 0 )
            return;

        if( hp < 10 )
            hp --;
        else
            hp -= hp / 10 ;

        if ( hp < 1 )
            hp = 1;

        return;
    }


    /*--------------------
       calcNextExp - Next Exp 計算
       --------------------*/
    long calcNextExp() { return calcNextExp( level ); }
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
              j += item[ i ].hpPlus;

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
        txtStatus.clear();

        rewriteOff;

        setColor( CL.KIND );
        txtStatus.print( 1 , SCRW_X_TOP, "[ items ]" );
        setColor( CL.NORMAL );

        for ( i = 0; i < 8; i++ )
        {
            if ( item[ i ].isNothing )
                continue;

            string flg;
            flg = " ";
            if ( ! item[ i ].canBeEquipped( Class ) )
                flg = "#";/* cannot equip */
            if ( item[ i ].equipped )
                flg = "*";/* equipped */
            if ( item[ i ].cursed )
                flg = "$";/* cursed */

            txtStatus.print( i + 2 , 0 , "%1)%2%3" 
                                        , i + 1
                                        , flg
                                        , item[ i ].getDispNameA );
        }

        rewriteOn;
        return;
    }


    /*--------------------
       dispSpellsInCamp - 戦闘中呪文表示
       --------------------*/
    void dispSpellsInCamp()
    {
        setColor( CL.NORMAL );
        dispSpellList( TYPE_MAGIC.mage );
        getChar();
        dispSpellList( TYPE_MAGIC.priest );
        getChar();
        inspect;
        return;
    }

    /*--------------------
       dispSpellsInBattle - 戦闘中呪文表示
       --------------------*/
    void dispSpellsInBattle()
    {

        int cl = getColor;

        setColor( CL.NORMAL );

        txtMessage.textout( _( "  %1 read mage spells\n" ) , name  );
        dispSpellList( TYPE_MAGIC.mage );
        getChar();
        txtMessage.textout( _( "  %1 read priest spells\n" ) , name  );
        dispSpellList( TYPE_MAGIC.priest );
        getChar();
        party.dungeon.disp( true );

        setColor( cl );

        return;
    }

    /*--------------------
       dispSpellList - 魔法使い / 僧侶 呪文表示
       --------------------*/
    void dispSpellList( TYPE_MAGIC type )
    {
        txtStatus.clear;
        rewriteOff;

        byte[7] max;
        byte[7] pt;
        MagicDef[ string ] spellList;

        switch( type )
        {
            case TYPE_MAGIC.mage:
                spellList = magic_mag;
                max  = mspl_max;
                pt   = mspl_pt;
                break;
            case TYPE_MAGIC.priest:
                spellList = magic_prt;
                max  = pspl_max;
                pt   = pspl_pt;
                break;
            default:
                assert( 0 );
        }

        // 表示位置
        int[ 7 ] x ,y;
        x[ 0 ] =  0 ; y[ 0 ] =  1;
        x[ 1 ] = 10 ; y[ 1 ] =  1;
        x[ 2 ] = 20 ; y[ 2 ] =  1;
        x[ 3 ] =  0 ; y[ 3 ] =  6;
        x[ 4 ] = 10 ; y[ 4 ] =  6;
        x[ 5 ] = 20 ; y[ 5 ] =  6;
        x[ 6 ] =  0 ; y[ 6 ] = 11;

        int lv;         // 表示レベル
        byte[ 7 ] flg;  // フラグ 何個目の呪文？
        foreach( i , dummy ; flg )
            flg[ i ] = cast( byte ) 1;
        
        // 呪文名
        foreach( MagicDef m ;  spellList )
        {

            lv = m.level;

            // 覚えてる？
            if( isSpellKnown( m ) )
            {
                // 知ってる
                if( now_mode == HSTS.CAMP
                   && m.camp == TYPE_MAGIC_CAMPMODE.cant )
                    setColor( CL.CANT_SPELL );
                else if( now_mode == HSTS.BATTLE
                        && m.batl == TYPE_MAGIC_BATTLEMODE.cant )
                    setColor( CL.CANT_SPELL );
                else
                    setColor( CL.NORMAL );
                txtStatus.print( y[ m.level ] + m.index , x[ m.level ], m.name );
            }

        }

        // MP
        setColor( CL.KIND );
        if( type == TYPE_MAGIC.mage )
            txtStatus.print( 11 , 10 , "[ mage spell ]" );
        else     // TYPE_MAGIC.priest
            txtStatus.print( 11 , 10 , "[ priest spell ]" );
        setColor( CL.NORMAL );

        txtStatus.print( 12 , 10 , "pnt:%1/%2/%3/%4/%5/%6/%7"
                                    , fillR( pt[ 0 ] , 1 )
                                    , fillR( pt[ 1 ] , 1 )
                                    , fillR( pt[ 2 ] , 1 )
                                    , fillR( pt[ 3 ] , 1 )
                                    , fillR( pt[ 4 ] , 1 )
                                    , fillR( pt[ 5 ] , 1 )
                                    , fillR( pt[ 6 ] , 1 ) );

        txtStatus.print( 13 , 10 , "max:%1/%2/%3/%4/%5/%6/%7"
                                    , fillR( max[ 0 ] , 1 )
                                    , fillR( max[ 1 ] , 1 )
                                    , fillR( max[ 2 ] , 1 )
                                    , fillR( max[ 3 ] , 1 )
                                    , fillR( max[ 4 ] , 1 )
                                    , fillR( max[ 5 ] , 1 )
                                    , fillR( max[ 6 ] , 1 ) );
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
        txtMessage.textout( _( "which weapon(1,2,...,l:leave)?\n" ) );
        setColor( CL.NORMAL );
        equipSub( ITM_KIND.WEAPON );

        setColor( CL.MENU );
        txtMessage.textout( _( "which armor(1,2,...,l:leave)?\n" ) );
        setColor( CL.NORMAL );
        equipSub( ITM_KIND.ARMOR );

        setColor( CL.MENU );
        txtMessage.textout( _( "which shield(1,2,...,l:leave)?\n" ) );
        setColor( CL.NORMAL );
        equipSub( ITM_KIND.SHIELD );

        setColor( CL.MENU );
        txtMessage.textout( _( "which helm(1,2,...,l:leave)?\n" ) );
        setColor( CL.NORMAL );
        equipSub( ITM_KIND.HELM );

        setColor( CL.MENU );
        txtMessage.textout( _( "which gloves(1,2,...,l:leave)?\n" ) );
        setColor( CL.NORMAL );
        equipSub( ITM_KIND.GLOVES );

        setColor( CL.MENU );
        txtMessage.textout( _( "which item(1,2,...,l:leave)?\n" ) );
        setColor( CL.NORMAL );
        equipSub( ITM_KIND.ITEM );

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
      party.dispPartyWindow();

      return;
    }

    /*--------------------
       tradeItem - 交換する
       --------------------*/
    void tradeItem()
    {
        int i;
        char ch;

        Member toMem;


        txtMessage.textout( _( "to whom(z:leave(9))? " ) );
        while ( true )
        {
            ch = getChar();
            if ( ch == 'z' || ch == '9' )
            {
                txtMessage.textout( _( "leave\n" ) );
                return;
            }
            else if ( ch >= '1' 
                    && ch <= '0' + party.memCount 
                    && party.mem[ ch - '1' ] !is this )
            {
                break;
            }
        }
        txtMessage.textout( ch );
        txtMessage.textout( "(" ~ party.mem[ ch - '1' ].name ~ ")" );
        txtMessage.textout( '\n' );
        toMem = party.mem[ ch - '1' ];

        while ( ! item[ 0 ].isNothing )
        {
            if ( ! toMem.item[ 7 ].isNothing )
            {
                txtMessage.textout( _( "full...\n" ) );
                return;
            }

            txtMessage.textout( _( "which item(z:leave(9))? " ) );
            while ( true )
            {
                ch = getChar();
                if (ch == 'z' || ch == '9')
                {
                    txtMessage.textout("z\n");
                    /* goto TOP; */
                    return;
                }
                if ( ch >= '1' && ch <= '8' 
                        && ( ! item[ ch - '1' ].isNothing ) )
                    break;
            }
            txtMessage.textout( ch );
            ch -= '1';
            txtMessage.textout( "(" ~ item[ ch ].getDispNameA ~ ")" );


            if ( item[ ch ].cursed )
            {
                txtMessage.textout( _( "\ncursed ...\n" ) );
            }
            else if ( item[ ch ].equipped )
            {
                txtMessage.textout( _( "\nequipped ...\n" ) );
            }
            else
            {
                for ( i = 0; i < 7; i++ )
                    if ( toMem.item[ i ].isNothing )
                        break;
                toMem.item[ i ].trade( item[ ch ] );
                item[ ch ].release;

                inspect();
                party.dispPartyWindow();
                txtMessage.textout( _( "\ndone.\n" ) );
            }
        }
    }

    /*--------------------
       dropItem - 捨てる
       --------------------*/
    void dropItem()
    {
        char ch;
        Item itm;

        txtMessage.textout( _( "which item will you drop(z:leave(9))? " ) );
        while ( true )
        {
            ch = getChar();
            if ( ch == 'z' || ch == '9' )
            {
                txtMessage.textout( _( "leave\n" ) );
                return;
            }
            else if ( ch >= '1' && ch <= '8' )
            {
                if ( ! item[ ch - '1' ].isNothing )
                    break;
            }
        }
        txtMessage.textout( ch );
        itm = item[ ch - '1' ];
        txtMessage.textout( "(" ~ itm.getDispNameA ~ ")" );
        txtMessage.textout( '\n' );

        if ( itm.cursed )
        {
            txtMessage.textout( _( "cursed item ...\n" ) );
            return;
        }
        else if ( itm.equipped )
        {
            txtMessage.textout( _( "equipped ...\n" ) );
            return;
        }
        else
        {
            itm.release;
            txtMessage.textout( _( "dropped.\n" ) );
        }

        inspect();
        party.dispPartyWindow();

        return;
    }

    /*--------------------
       useItem - 使う
       --------------------*/
    void useItem()
    {
        char ch;
        Item itm;

        int i, mag;

      
        txtMessage.textout( _( "which item do you use(z:leave(9))? " ) );
        while ( true )
        {
            ch = getChar();
            if ( ch == 'z' || ch == '9' )
            {
                txtMessage.textout( _( "leave\n" ) );
                return;
            }
            else if ( ch >= '1' && ch <= '8' )
            {
                if ( ! item[ ch - '1' ].isNothing )
                    break;
            }
        }
        txtMessage.textout( ch );
        itm = item[ ch - '1' ];
        txtMessage.textout( "(" ~ itm.getDispNameA ~ ")" );
        txtMessage.textout( '\n' );


      
        if ( itm.effect[ 0 ] == 0 )
            return; // no effect

        if ( ( itm.effectMagic[ 0 ] ) != "0" )
        { // spell
            magic_all[ itm.effectMagic[ 0 ] ].castInCamp( this );
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
    bool checkLevelUp()
    {

        int nexthp;
  
        nextexp = calcNextExp();
  
        if ( exp > nextexp )
        {
            level++;
            txtMessage.textout( _( "you made the next level!\n" ) );
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

            txtMessage.textout( _( "  you gained %1 h.p.\n" ) , hpp );
            changeProperty( true );
            learnSpell();

            return true;
        }
        else
        {
            long more = nextexp - exp;
            txtMessage.textout( _( "you need %1 more\n  ep to make the next level.\n" ) , more );

            return false;
        }
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


    /*--------------------
       change_property 
       message : true / false
       --------------------*/
    /* rtncode=1 : lost */
    int changeProperty( bool message )
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
                            txtMessage.textout( _( "  you lost %1 \n" ) , para_name );
                    }
                }
                else
                {
                    if (para < 18)
                    {
                        para ++;
                        if ( message )
                            txtMessage.textout( _( "  you gained %1 \n" ) , para_name );
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
            txtMessage.textout( _( "The character died of age...\n" ) );
            getChar();
            status = STS.NIL;
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

        void checkDrainParameter( ref byte para )
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
            checkDrainParameter( str[ 0 ] );
            checkDrainParameter( iq [ 0 ] );
            checkDrainParameter( pie[ 0 ] );
            checkDrainParameter( vit[ 0 ] );
            checkDrainParameter( agi[ 0 ] );
            checkDrainParameter( luk[ 0 ] );
        }

        // しない？
        // if ( vit[ 0 ] <= 2 )
        // {
        //     txtMessage.textout( "The character died of age...\n" );
        //     getChar();
        //     status = STS_LOST;
        //     return 1;
        // }

        return;
    }


    /*--------------------
       learnSpell 
       --------------------*/
    void learnSpell()
    {
        switch ( Class )
        {
            case CLS.FIG: /* fighter */
            case CLS.THI: /* thief */
            case CLS.NIN: /* ninja */
                return;
            case CLS.PRI: /* priest */ 
                learnSpellSub( TYPE_MAGIC.priest , pspl_know , pspl_pt , pspl_max , ( level - 1 ) / 2 );
                break;
            case CLS.MAG: /* mage */
                learnSpellSub( TYPE_MAGIC.mage   , mspl_know , mspl_pt , mspl_max , ( level - 1 ) / 2 );
                break;
            case CLS.BIS: /* bishop */
                learnSpellSub( TYPE_MAGIC.mage   , mspl_know , mspl_pt , mspl_max , ( level - 1 ) / 4 );
                learnSpellSub( TYPE_MAGIC.priest , pspl_know , pspl_pt , pspl_max , ( level - 4 ) / 4 );
                break;
            case CLS.SAM: /* samurai */
                learnSpellSub( TYPE_MAGIC.mage   , mspl_know , mspl_pt , mspl_max , ( level - 4 ) / 3 );
                break;
            case CLS.LOR: /* lord */
                learnSpellSub( TYPE_MAGIC.priest , pspl_know , pspl_pt , pspl_max , ( level - 4 ) / 2 );
                break;
            default:
                assert( 0 );
        }
        setKnownSpell( TYPE_MAGIC.mage );
        setKnownSpell( TYPE_MAGIC.priest );
        return;
    }

    /*--------------------
       learnSpellSub
       --------------------*/
    void learnSpellSub( TYPE_MAGIC type , 
            ref byte[ 7 ] know , ref byte[ 7 ] pnt , ref byte[ 7 ] max , int lvl )
    {
        int i,cnt, j;
        int mask;
        byte[ 7 ] oldknow = know.dup;
        MagicDef spell;
        int lvSpellCount;

        foreach( m ; magic_all )
        {
            spell = m; // dummy .何でもＯＫ
            break;
        }

        lvl ++;
        if ( lvl > 7 )
            lvl = 7;

        for ( i = 0 ; i < lvl ; i++ )
        {
            if( type == TYPE_MAGIC.mage )
                lvSpellCount = spell.magLvSpellCount[ i ];
            else
                lvSpellCount = spell.priLvSpellCount[ i ];

            for ( j = 0 ; j < get_rand( 2 ) + 1 ; j++ )
                know[ i ] |= 0x01 << get_rand( lvSpellCount );
          
            for ( j = 0 ; j < lvSpellCount ; j++ )
                mask |= 0x01 << j;
            know[ i ] &= mask;

            if( type == TYPE_MAGIC.mage )
                cnt = ( iq[ 0 ] + iq[ 1 ] - 10 ) / 4;
            else
                cnt = ( pie[ 0 ] + pie[ 1 ] - 10 ) / 4;

            if ( cnt < 0 )
                cnt = 0;
            cnt += get_rand( 1 );

            max[ i ] += cnt ;
            if ( max[ i ] > 9 )
                max[ i ] = 9;
            pnt[ i ] = max[ i ];
            
        }

        for ( i = 0; i < 7; i++ )
            if ( oldknow[ i ] != know[ i ] )
            {
                if( type == TYPE_MAGIC.mage )
                    txtMessage.textout( _( "  you've learned new mage spells!\n" ) );
                else
                    txtMessage.textout( _( "  you've learned new priest spells!\n" ) );
                return;
            }
        return;
    }


    /*--------------------
       isSpellKnown - この呪文覚えてる？
       --------------------*/
    bool isSpellKnown( string spellName )
    {
        return isSpellKnown( magic_all[ spellName ] );
    }
    bool isSpellKnown( MagicDef mdef )
    {
        
        if( mdef.Class == TYPE_MAGIC.mage )
            foreach( k ; mspl )
                if( k == mdef )
                    return true;

        if( mdef.Class == TYPE_MAGIC.priest )
            foreach( k ; pspl )
                if( k == mdef )
                    return true;

        return false;
    }

    /*--------------------
       consumeSpell - 呪文を消費
       --------------------*/
    bool consumeSpell( string spellName )
    {
        return consumeSpell( magic_all[ spellName ] );
    }
    bool consumeSpell( MagicDef mdef )
    { 
        switch( mdef.Class )
        {
            case TYPE_MAGIC.mage:
                if( mspl_pt[ mdef.level ] <= 0 )
                    return false;
                mspl_pt[ mdef.level ] --;
                return true;

            case TYPE_MAGIC.priest:
                if( pspl_pt[ mdef.level ] <= 0 )
                    return false;
                pspl_pt[ mdef.level ] --;
                return true;

            default:
                assert( 0 );
        }
    }


    /*--------------------
       castSpellInCamp - 呪文を唱える（キャンプ中）
       --------------------*/
    void castSpellInCamp()
    {
        int mag;
        string spell;

        txtMessage.textout( _( "what spell?\n" ) );
        spell = txtMessage.inputSpell( this , 32 , "> " );
        txtMessage.textout( "> " );
        txtMessage.textout( spell );
        txtMessage.textout( '\n' );

        foreach( MagicDef m ; magic_all )
            if( spell == m.name ) 
            {
                if( m.camp == TYPE_MAGIC_CAMPMODE.cant ) 
                {
                    txtMessage.textout( _( "cannot cast now\n" ) );
                    getChar();
                    return;
                }

                if( ! isSpellKnown( m ) )
                {
                    txtMessage.textout( _( "don't know the spell\n" ) );
                    getChar();
                    return;
                }

                if ( ! consumeSpell( m ) )    // 2 : have used up 
                {
                    txtMessage.textout( _( "you've used that up\n" ) );
                    getChar();
                    return;
                }

                m.castInCamp( this );
                inspect;
                return;
            }

        txtMessage.textout( _( "no such spell\n" ) );
        getChar();
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

        txtMessage.textout( _( "which item will you identify(z:leave(9))? " ) );
        while( true )
        {
            ch = getChar();
            if ( ch == 'z' || ch == '9' )
            {
              txtMessage.textout( _( "leave\n" ) );
              return;
            }
            else if ( ch >= '1' && ch <= '8' 
                    && ! item[ ch - '1' ].isNothing 
                    && item[ ch - '1' ].undefined )
                break;
        }
        txtMessage.textout( ch );
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
                txtMessage.textout( _( "\n * oops! *\n" ) );
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
                party.dispPartyWindow();
                getChar();
            }
            else
            {
                txtMessage.textout( _( "\nno clue ...\n" ) );
                getChar();
            }
        }
        else
        {
            item[ ch ].undefined = false;
            txtMessage.textout( "\n" );
        }
        inspect;
        party.dispPartyWindow();
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
    bool inputAction( char command )
    {

        char c;
        int i;
        int row = getPartyNo;
        string spell_name;
        MagicDef spell;

        void dispCommand( string com )
        { 
            mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 48, com ); 
            actionDetails = com;
        }
        void dispTarget( string txt )
        { 
            mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 54, " " ~ txt ); 
            actionDetails ~= ( txt) ; 
        }
        void dispTargetWithNo( int no , string txt )
        { 
            mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 54, " " ~ no.to!string ~ txt ); 
            actionDetails ~= ( no.to!string ~ txt) ; 
        }


        /*--------------------
           start inputAction - 戦闘時コマンド入力
           --------------------*/
        switch( command )
        {
            case ' ':
                if ( row >= 3 && range != RANGE.LONG )
                {
                    dispCommand( "parry                         " );
                    action = ACT.parry;
                    return true;
                }
                else
                {
                    dispCommand( "fight  1)" ~ fillL( monParty.top.getDispNameS ,21 ) );
                    action = ACT.fight;
                    targetMonster = monParty.top ;
                    return true;
                }

            // fight
            case 'f': // fight
            case 'j': // fight 1
            case 'h': // fight 2
            case 'n': // fight 3
            case '4': // fight
            case '1': // fight 1
            case '2': // fight 2
            case '3': // fight 3
                if ( range == RANGE.NOT )
                    return false;

                if ( range == RANGE.SHORT && row >= 3 )
                    return false;

                if ( command == 'j' || command == '1' )
                {
                    dispCommand( "fight  1)" ~ fillL( monParty.top.getDispNameS ,21 ) );
                    action = ACT.fight;
                    targetMonster = monParty.top ;
                    return true;
                }
                else if ( ( command == 'h' || command == '2' ) && monParty.count >= 2 )
                {
                    dispCommand( "fight  2)" ~ fillL( monParty.top.next.getDispNameS ,21 ) );
                    action = ACT.fight;
                    targetMonster = monParty.top.next ;
                    return true;
                }
                else if ( ( command == 'n' || command == '3' ) && monParty.count >= 3 )
                {
                    dispCommand( "fight  3)" ~ fillL( monParty.top.next.next.getDispNameS ,21 ) );
                    action = ACT.fight;
                    targetMonster = monParty.top.next.next ;
                    return true;
                }
                else if ( command == 'f' || command == '4' )
                {
                    action = ACT.fight;
                    dispCommand( "fight  " );
                    targetMonster = monParty.selectGroup( row );
                    dispTargetWithNo( targetMonster.getPartyNo + 1 , 
                            ")" ~ fillL( targetMonster.getDispNameS , 21 ) );
                    
                    return true;
                }
                return false;

            // parry
            case 'p': 
            case 'k':
            case '5':
                dispCommand( "parry                         " );
                action = ACT.parry;
                return true;

            // use item
            case 'u':
            case '8':
                txtMessage.textout( _( "you have:\n" ) );
                foreach( j , itm ; item )
                    if ( ! itm.isNothing )
                    {
                        txtMessage.textout( to!char( j + 'a' ) );
                        txtMessage.textout( ")" );
                        txtMessage.textout( itm.getDispNameA ~ "\n" );
                    }
                txtMessage.textout( _( "which item(z:leave(9))? " ) );

                while ( true )
                {
                    c = getChar();
                    if ( c == 'z' 
                            || c == '9' 
                            || ( c <= 'h' && c >= 'a' && !item[ c - 'a' ].isNothing ) )
                        break;
                }
                txtMessage.textout( c );
                txtMessage.textout( '\n' );
                
                if ( c=='z' || c=='9' )
                    return false;

                spell_name = item[ c - 'a' ].effectMagic[ 1 ];       // 1:battle
                if ( spell_name != "0"
                        || magic_all[ spell_name ].batl == TYPE_MAGIC_BATTLEMODE.cant )
                {
                    txtMessage.textout( _( "you can't use it now\noption? \n" ) );
                    return false;
                }

                actItem = item[ c - 'a' ];
                dispCommand( leftB( magic_all[ spell_name ].name , 6 ) ~ " " );

                if ( magic_all[ spell_name ].batl == TYPE_MAGIC_BATTLEMODE.notarget )
                { /* no target */
                    dispTarget( "                        " );
                }
                else if ( magic_all[ spell_name ].batl == TYPE_MAGIC_BATTLEMODE.player )
                { /* to a party member */
                    targetPlayer = party.selectMemberInBattle( row );
                    dispTargetWithNo( targetPlayer.getPartyNo + 1 ,
                              fillL( "(" ~ targetPlayer.name ~ ")" , 22 ) );
                }
                else if ( magic_all[ spell_name ].batl == TYPE_MAGIC_BATTLEMODE.monster )
                { /* to monsters */
                    targetMonster = monParty.selectGroup( row );
                    dispTargetWithNo( targetMonster.getPartyNo + 1 
                            , ")" ~ fillL( targetMonster.getDispNameS , 22 ) );
                }
                
                action = ACT.use;
                return true;

            // cast spell
            case 'c':
            case 's':
            case '6':  
                if( monParty.suprised )
                    return false;

                setStatusColor;     // 毒の場合は色変更

                dispCommand( "spell  ?                      " );
                spell_name = tline_input_spell( this , 20, CHRW_Y_TOP + row + 1, CHRW_X_TOP + 55 , "> " );

                if( ! ( spell_name in magic_all ) )
                {
                    dispTarget( _( " no such spell" ) );
                    getChar();
                    dispCommand( "what?  ???????????????????????" );
                    return false;
                }

                spell = magic_all[ spell_name ];
                if( spell.batl == TYPE_MAGIC_BATTLEMODE.cant )
                {
                    dispTarget( _( " cannot cast now" ) );
                    getChar();
                    dispCommand( "what?  ???????????????????????" );
                    return false;
                }

                if( ! isSpellKnown( spell ) )
                {
                    dispTarget( _( " don't know the spell" ) );
                    getChar();
                    dispCommand( "what?  ???????????????????????" );
                    return false;
                }

                if ( ! consumeSpell( spell ) )
                {
                    dispTarget( _( " you've used that up" ) );
                    getChar();
                    dispCommand( "what?  ???????????????????????" );
                    return false;
                }

                dispCommand( leftB( spell_name , 6 ) ~ " " );
                if ( spell.batl == TYPE_MAGIC_BATTLEMODE.notarget )
                { /* no target */
                    dispTarget( "                        " );
                }
                else if ( spell.batl == TYPE_MAGIC_BATTLEMODE.player )
                { /* to a party member */

                    targetPlayer = party.selectMemberInBattle( row );
                    dispTargetWithNo( targetPlayer.getPartyNo + 1 , 
                            fillL( "(" ~ targetPlayer.name ~ ")" , 22 ) );
                }
                else if ( spell.batl == TYPE_MAGIC_BATTLEMODE.monster )
                { /* to monsters */
                    targetMonster = monParty.selectGroup( row );
                    dispTargetWithNo( targetMonster.getPartyNo + 1 , 
                            ")" ~ fillL( targetMonster.getDispNameS , 22 ) );
                }
                action = ACT.magic ;
                actMagic = spell;
                return true;

            // dispell
            case 'd':
            case '9':
                if( ! ( Class == CLS.PRI || Class == CLS.LOR || Class == CLS.BIS ) )
                    return false;
                
                action = ACT.dispel;
                dispCommand( "dispel " );
                targetMonster = monParty.selectGroup( row );
                dispTargetWithNo( targetMonster.getPartyNo + 1 , 
                        ")" ~ fillL( targetMonster.getDispNameS , 22 ) );
                return true;

            default:
                return false;   // not inputAction...
        }
    }

    /*--------------------
       act - 戦闘ターン実行
       --------------------*/
    int act()
    {
        MonsterTeam mt;
        Monster     m;
        bool escape = false;

        if ( status != STS.OK )
            return 0;

        switch ( action )
        {
            case ACT.magic:     // cast spell
                castSpellInBattle( escape );
                if( escape )
                    return 2;       // return / telept
                else
                    return 0;

            case ACT.use:  // use item
                actMagic = magic_all[ actItem.effectMagic[ 1 ] ];
                castSpellInBattle( escape );
                if( escape )
                    return 2;       // return / telept
                if ( actItem.broken >= get_rand( 99 ) + 1 )
                { 
                    txtMessage.textout( _( "The %1 gets broken!\n" ) , actItem.getDispName );
    
                    actItem.setItem( 0 ); // broken
                }
                break;

            case ACT.fight: /* fight */
                actFight( getTargetMonster );
                break;

            case ACT.parry: /* parry */
            case ACT.run: /* couldn't run away */
                break;

            case ACT.dispel: /* dispel */
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
        
        assert( m.def !is null , "m.def is null" );

        switch ( get_rand( 7 ) )
        {
            case 0:
                txtMessage.textout( _( "%1 thrusts hard at a %2\n" ) , name , m.getDispNameA );
                break;
            case 1:
                txtMessage.textout( _( "%1 tries to slice a %2\n" ) , name , m.getDispNameA ) ;
                break;
            case 2:
                txtMessage.textout( _( "%1 swings at a %2\n" ), name , m.getDispNameA  );
                break;
            case 3:
                txtMessage.textout( _( "%1 chops savagely at a %2\n" ), name , m.getDispNameA  );
                break;
            case 4:
                txtMessage.textout( _( "%1 tries to bash a %2\n" ), name , m.getDispNameA  );
                break;
            case 5:
                txtMessage.textout( _( "%1 attempts to stab a %2\n" ), name , m.getDispNameA  );
                break;
            case 7:
            default:
                txtMessage.textout( _( "%1 lunges at a %2\n" ) , name , m.getDispNameA );
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
            txtMessage.textout( N_( "  and hits once for %1 damage!\n" 
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
                    txtMessage.textout( _( "  The %1 gets the head cut off!\n" ) , m.getDispNameA );
                    get_exp += m.exp;
                    m.marksUp;
                    marks ++;
          
                    m.del;
                }
                else if ( m.hp <= 0 )
                {
                    txtMessage.textout( _( "    The %1 is killed!\n" ) , m.getDispNameA );
                    get_exp += m.exp;
                    m.marksUp;
                    marks ++;
          
                    m.del;
                }
            }
            else if ( m.hp <= 0 )
            {
                txtMessage.textout( _( "    The %1 is killed!\n" ) , m.getDispNameA );
                get_exp += m.exp;
                m.marksUp;
                marks ++;
      
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
                        txtMessage.textout( _( "  The %1 is slept!\n" ) , m.getDispNameA );
                        m.status = STS.SLEEP;
                        getChar();
                    }
                }
            }
        }
        else
        {
            txtMessage.textout( _( "   ... and misses\n" ) );
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
        for ( i = 0; i < mt.count; i++ )
          if ( get_rand( 100 ) < chance )
              succeed++;
      
        for (i = 0; i < succeed; i++)
            mt.top.del;
      
        if ( succeed > 0 )
        {
            txtMessage.textout( N_( "%1 dispels %2 monster\n" 
                       , "%1 dispels %2 monsters\n" , succeed )
                        , name , succeed );
        }
        else
        { // failed
    FAIL:
            txtMessage.textout( _( "%1 attempts to dispel\n   and fails.\n" ) , name );
        }
        getChar();
      
        return;
    }

    /*--------------------
       castSpellInBattle - 戦闘中の呪文
        // actMagic: cast spell
        // escape: return / telept -> true
       --------------------*/
    void castSpellInBattle( ref bool escape )
    {
      
        txtMessage.textout( _( "%1 casts a %2.\n" ) , name , actMagic.name );
      
        if ( silenced )
        {
            txtMessage.textout( _( "  but, %1 is silenced!\n" ) , name );
            getChar();
            return;
        }
      
        if( actMagic.castInBattle( this ) == 2 )
            escape = true;

        return;

    }

    
    /*--------------------
       getTargetMonster - target から Monster 取得。MonsterTeamはMonsterから取得
       --------------------*/
    Monster getTargetMonster()
    {
        Monster m;
        m = getTargetMonsterTeam.getRandMonster;

        assert( m !is null ,"getTargetMonster is null" );
        return m;

        /* return getTargetMonsterTeam.getRandMonster; */
    }

    /*--------------------
       getTargetMonsterTeam - target から MonsterTeam を取得。
       --------------------*/
    MonsterTeam getTargetMonsterTeam()
    {
        if( ! targetMonster.isExist )
            return monParty.top;
        return targetMonster;
    }

    /*--------------------
       getCharItemList - アイテム選択時の入力可能文字列
       --------------------*/
    string getCharItemList()
    {
        string list;
        foreach( i ; 0 .. MAXCARRY )
        {
            if( item[ i ].isNothing )
                break;
            list ~= ( i + 1 ).to!string;
        }
        return list;
    }

    /*--------------------
       isLost - ロスト→アイテム没収
       --------------------*/
    void isLost()
    {
        status = STS.LOST;
        outflag = OUT_F.BAR;
        gold = 0;
        foreach( i ; 0 .. MAXCARRY )
            item[ i ].setNull;
        calcAtkAC;
        return;
    }

}


