// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.string;

// mysource 
import def;
import app;

class ItemDef
{

private:
    // class bit
    enum BIT_ITM_CLS_FIG = 0x80; 
    enum BIT_ITM_CLS_THI = 0x40; 
    enum BIT_ITM_CLS_PRI = 0x20; 
    enum BIT_ITM_CLS_MAG = 0x10; 
    enum BIT_ITM_CLS_BIS = 0x8 ; 
    enum BIT_ITM_CLS_SAM = 0x4 ; 
    enum BIT_ITM_CLS_LOR = 0x2 ; 
    enum BIT_ITM_CLS_NIN = 0x1 ; 


public:
    int id;
    string name;
    string unname;
  
    // byte kind; /* 0:weapon,1:armor,2:shield,3:helm,4:gloves,5:item */
    ITM_KIND kind; /* 0:weapon,1:armor,2:shield,3:helm,4:gloves,5:item */
    byte Class; /* bit7:FIG, bit6:THI, bit5:PRI, bit4:MAG*/
                /* bit3:BIS, bit2:SAM, bit1:LOR, bit0:NIN */
    byte Align; /* 0:ok/1:ng, bit7:Good, bit6:Evil, bit5:Newtral */
                /* curse - bit0:good,bit1:evil,bit2:neutral */
    // char ac;
    short ac;
    int gold; /* price when you buy */
  
    byte range; /* 1:short,2:long */
    short[ 3 ] atk; /* 0:min,1:add,2:addcnt */
    byte atkef; /* bit7:critical, bit6:stone, bit5:sleep */
                /* bit4:human*2,bit3:animal*2,bit2:dragon*2 */
                /* bit1:demon*2,bit0:insect*2*/
    byte defef; /* bit7:critical, bit6:stone, bit5:paralize, bit4:sleep */
                /* bit3:poison bit2:fire, bit1:cold, bit0:drain */
  
    byte magdef; /* tolarate at magdef/100 */
    byte hpplus;
    byte[ 3 ] effect; /* use effect - 0:camp,1:fight,2:equip */
                    /* bit7=1: spell */
    // char broken; /* broken item/100% */
    byte broken; /* broken item/100% */
    byte brokento; /* what it will be after it breaks */

    /*--------------------
       this - コンストラクタ
       data : readItem のデータ 
       --------------------*/
    this( char[][] data )
    {

        int i = 0;  // i = 0 : item ID

        id        = to!int( data[ i++ ] );
        name      = to!string( data[ i++ ] );
        unname    = to!string( data[ i++ ] );

        kind      = cast( ITM_KIND ) to!byte( data[ i++ ] );
        Class     = cast( byte ) parse!(int)( data[ i++ ], 16);
        Align     = cast( byte ) parse!(int)( data[ i++ ], 16);
        ac        = cast(short) to!int( data[ i++ ] );
        gold      = to!int( data[ i++ ] );

        range     = to!byte( data[ i++ ] );
        atk[0]    = cast(short) to!int( data[ i++ ] );
        atk[1]    = cast(short) to!int( data[ i++ ] );
        atk[2]    = cast(short) to!int( data[ i++ ] );
        atkef     = cast( byte ) parse!(int)( data[ i++ ], 16);
        defef     = cast( byte ) parse!(int)( data[ i++ ], 16);

        magdef    = to!byte( data[ i++ ] );
        hpplus    = to!byte( data[ i++ ] );
        effect[0] = cast( byte ) parse!(int)( data[ i++ ], 16);
        effect[1] = cast( byte ) parse!(int)( data[ i++ ], 16);
        effect[2] = cast( byte ) parse!(int)( data[ i++ ], 16);
        broken    = to!byte( data[ i++ ] );
        brokento  = to!byte( data[ i ] );

        /* writef( "%d : %s \n" , id , name ); */

        return;

    }

    /*--------------------
       canBeEquipped - 装備可能かどうか
       cl: Member.Class (int) 0:FIG,1:THI,2:PRI,3:MAG,4:BIS,5:SAM,6:LOR,7:NIN 
       --------------------*/
    bool canBeEquipped( int cl )
    {
        if( ( ( 0x80 >> cl ) & Class ) == 0 )
            return false;
        else
            return true; 
    }

    /*--------------------
       checkAtkEf - atkef 確認
       --------------------*/
    bool checkAtkEf( ITM_ATKEF ef )
    {
        return ( ( atkef & ef ) != 0 ); 
    }

    /*--------------------
       checkDefEf - defef 確認
       --------------------*/
    bool checkDefEf( ITM_DEFEF ef )
    {
        return ( ( defef & ef ) != 0 ); 
    }

    /*--------------------
       dispInfo - アイテム情報表示
       --------------------*/
    void dispInfo()
    {

        string ef;

        textout( "\n*** " );
        textout( name );
        switch( kind )
        {
            case ITM_KIND.WEAPON:
                if ( range == RANGE.SHORT )
                  textout( _( " ***\n it is a short range weapon.\n" ) );
                else
                  textout( _( " ***\n it is a long range weapon.\n" ) );
                textout( _( " it deals %1-%2 damage.\n" ) , atk[ 0 ] , atk[ 0 ] + atk[ 1 ] );
                break;
            case ITM_KIND.ARMOR:
                textout( _( " is an armor.\n" ) );
                textout( _( " it affects your AC by %1 points.\n" ) , ac );
                break;
            case ITM_KIND.SHIELD:
                textout( _( " is a shield.\n" ) );
                textout( _( " it affects your AC by %1 points.\n" ) , ac );
                break;
            case ITM_KIND.HELM:
                textout( " is a helm.\n" );
                textout( _( " it affects your AC by %1 points.\n" ) , ac );
                break;
            case ITM_KIND.GLOVES:
                textout( " are gloves.\n" );
                textout( _( " it affects your AC by %1 points.\n" ) , ac );
                break;
            case ITM_KIND.ITEM:
                textout( _( " is an item.\n" ) );
                break;
            default:
                assert( 0 );
        }
        
        if ( Class !=0 )
        {
            textout(" ");

            ef = "";
            if ( canBeEquipped( CLS.FIG ) ) ef ~= 'F' ;
            if ( canBeEquipped( CLS.THI ) ) ef ~= 'T' ;
            if ( canBeEquipped( CLS.PRI ) ) ef ~= 'P' ;
            if ( canBeEquipped( CLS.MAG ) ) ef ~= 'M' ;
            if ( canBeEquipped( CLS.BIS ) ) ef ~= 'B' ;
            if ( canBeEquipped( CLS.SAM ) ) ef ~= 'S' ;
            if ( canBeEquipped( CLS.LOR ) ) ef ~= 'L' ;
            if ( canBeEquipped( CLS.NIN ) ) ef ~= 'N' ;
            textout( _( " %1 can equip it. \n" ) , ef );
        }
        if ( ( atkef & 
                ( ITM_ATKEF.CRITICAL | ITM_ATKEF.STONE | ITM_ATKEF.SLEEP ) ) != 0 )
        {
            ef = "";
            if ( checkAtkEf( ITM_ATKEF.CRITICAL ) ) ef ~= " critical" ;
            if ( checkAtkEf( ITM_ATKEF.STONE ) )    ef ~= " stone" ;
            if ( checkAtkEf( ITM_ATKEF.SLEEP ) )    ef ~= " sleep" ;
            textout( _( " it has a %1 effect.\n" ) , ef );
        }
  
        if ( ( atkef & 
                ( ITM_ATKEF.HUMAN | ITM_ATKEF.ANIMAL| ITM_ATKEF.DRAGON 
                  | ITM_ATKEF.DEMON | ITM_ATKEF.INSECT ) ) != 0 )
        {
            ef = "";
            if( checkAtkEf( ITM_ATKEF.HUMAN ) )  ef ~= " human";
            if( checkAtkEf( ITM_ATKEF.ANIMAL ) ) ef ~= " animal";
            if( checkAtkEf( ITM_ATKEF.DRAGON ) ) ef ~= " dragon";
            if( checkAtkEf( ITM_ATKEF.DEMON ) )  ef ~= " demon";
            if( checkAtkEf( ITM_ATKEF.INSECT ) ) ef ~= " insect";
            textout(_( " damages will be doubled to\n %1 type monsters.\n" ) , ef );
        }
  
        if ( defef != 0 )
        {
            ef = "";
            if ( checkDefEf( ITM_DEFEF.CRITICAL ) ) ef ~= " critical";
            if ( checkDefEf( ITM_DEFEF.STONE    ) ) ef ~= " stone";
            if ( checkDefEf( ITM_DEFEF.PARALIZE ) ) ef ~= " paralize";
            if ( checkDefEf( ITM_DEFEF.SLEEP    ) ) ef ~= " sleep";
            if ( checkDefEf( ITM_DEFEF.POISON   ) ) ef ~= " poison";
            if ( checkDefEf( ITM_DEFEF.FIRE     ) ) ef ~= " fire";
            if ( checkDefEf( ITM_DEFEF.ICE      ) ) ef ~= " ice";
            if ( checkDefEf( ITM_DEFEF.DRAIN    ) ) ef ~= " drain";
            textout( _( " it is resistive to %1 attacks.\n" ) , ef ) ;
        }
  
        if ( magdef != 0 )
          textout( _( " it is resistive to spells.\n" ) );

        if ( hpplus > 0 )
          textout( _( " it is a healing item.\n" ) );

        if ( hpplus < 0 )
          textout( _( " it is a cursed item and\n" )
                 ~ _( "  just having it will hurt you badly.\n" ) );
  
        if ( effect[ 0 ] != 0 )
        {
            if ( ( effect[ 0 ] & 0x80 ) != 0 )
            {
                ef = magic_data[ effect[ 0 ] & 0x7f ].name ;
                textout( _( " you can cast a %1 by using it\n                 while you are in camp.\n" ) , ef );
            }
            else
            {
                textout( _( " using it while you are in camp\n               will cause something.\n" ) );
            }
        }

        if ( effect[ 1 ] != 0 )
        {
            if ( ( effect[ 1 ] & 0x80 ) != 0 )
            {
                ef = magic_data[ effect[ 1 ] & 0x7f ].name ;
                textout( _( " you can cast a %1 during battle.\n" ) , ef );
            }
            else
            {
                textout( _( " using it while you are in battle\n               will cause something.\n" ) );
            }
        }

        if ( effect[ 2 ] != 0 )
          textout( _( " using it during equip\n           will cause something.\n" ) );
  
        // 個別に
        if (id == 170) // vorpat_tooth
            textout( _( " you got it from the vorpal_bunnies\n" )
                   ~ _( "   on B2 layer, right?\n" ) );
        if (id == 149) // The_Muramasa_Blade!
            textout( _( " oh...finally, I got to see\n" )
                   ~ _( "    *** THE TRUE MURAMASA BLADE!! ***\n" ) );
        if (id == 148) // muramasa_katana
            textout( _( " I've heard a rumor that there's a more\n" )
                   ~ _( " powerful weapon than this. can it be true!\n" ) );
        if (id == 147) // 皆伝の書
            textout( _( " God!  written in this is\n" )
                   ~ _( "         the secret of ninja.\n" ) );
        if (id == 146) // garb_of_lords
            textout( _( " one of the top three items, you know.\n" ) );
        if (id == 143) // shurikens
            textout( _( " one of the top three items, you know.\n" ) );
        if (id == 137) // vorpal_weapon
            textout( _( " it is the most powerful sword for F&L.\n" ) );
        if (id == 135) // fox_gon's_mittens
            textout( _( " have you heard a sad story of the fox?\n" ) );
        if (id == 131) // vampire_killer
            textout( _( " Mmm...what happened to the hunter?\n" ) );
        if (id == 99) // gradius
            textout( _( " Mmm...it is a really good sword, you know.\n" ) );
        if (id == 43) // garcon_jacket(e)
            textout( _( " Mmm...very stylish, very...\n" ) );
        if (id == 42) // antwerp_sweater
            textout( _( " look at this!  what a beautiful color!\n" ));
  
        textout( _( " I would buy it for %1 gp.\n" ) , gold / 2 );

        if ( ( Align & 0x7 ) == 7 )
            textout( _( " Be aware! it is cursed.\n" ) );

        /* getChar; */
        return;
    }
}


