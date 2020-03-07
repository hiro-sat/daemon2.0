// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.string;

// mysource 
import def;

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

}


