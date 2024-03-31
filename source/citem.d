// vim: set nowrap :
// Phobos Runtime Library
import std.stdio;

// mysource 
import def;
import citem_def;
import cmember;


/**
  Item - メンバー所持のアイテム
  */
class Item
{

private:
    // item bit
    enum BIT_ITM_EQUIPPED  = 0x8000;
    enum BIT_ITM_CURSED    = 0x4000;
    enum BIT_ITM_UNDEFINED = 0x2000;
    enum BIT_ITM_NO        = 0x1fff;

    int item_no;    // nothing : 9999
    ItemDef data;


public:
    Member parent;

    bool equipped;
    bool cursed;
    bool undefined;

    @property
    {

        int itemNo(){ return item_no; }
        bool isNothing(){ return ( item_no == 9999 ); }
        bool defined(){ return ! undefined; }
        void defined( bool flg ){ undefined = !flg; }

        string name(){ return data.name; }
        string unname(){ return data.unname; }
      
        /* byte kind(){ return data.kind; } */
        ITM_KIND kind(){ return data.kind; }
        /* 0:weapon,1:armor,2:shield,3:helm,4:gloves,5:item */

        byte Class(){ return data.Class; }
        /* bit7:FIG, bit6:THI, bit5:PRI, bit4:MAG*/
        /* bit3:BIS, bit2:SAM, bit1:LOR, bit0:NIN */

        byte Align(){ return data.Align; }
        /* 0:ok/1:ng, bit7:Good, bit6:Evil, bit5:Newtral */
        /* curse - bit0:good,bit1:evil,bit2:neutral */

        // char ac;
        short ac(){ return data.ac; }
        int gold(){ return data.gold; }
        /* price when you buy */
      
        byte range(){ return data.range; }
        /* 1:short,2:long */

        /* short atk( int i ){ return data.atk[ i ]; }  */
        short[] atk(){ return data.atk; } 
        /* 0:min,1:add,2:addcnt */

        byte atkef(){ return data.atkef; }
        /* bit7:critical, bit6:stone, bit5:sleep */
        /* bit4:human*2,bit3:animal*2,bit2:dragon*2 */
        /* bit1:demon*2,bit0:insect*2*/

        byte defef(){ return data.defef; }
        /* bit7:critical, bit6:stone, bit5:paralize, bit4:sleep */
        /* bit3:poison bit2:fire, bit1:cold, bit0:drain */
      
        byte magdef(){ return data.magdef; }
        /* tolarate at magdef/100 */

        byte hpPlus(){ return data.hpPlus; }

        byte effect( int i ){ return data.effect[ i ]; };
        byte[] effect(){ return data.effect; }
        /* use effect - 0:camp,1:fight,2:equip */
        /* bit7=1: spell */
        string effectMagic( int i ){ return data.effectMagic[ i ]; };
        string[] effectMagic(){ return data.effectMagic; }

        // char broken; /* broken item/100% */
        byte broken(){ return data.broken; }
        /* broken item/100% */

        byte brokento(){ return data.brokento; }
        /* what it will be after it breaks */


        /*--------------------
           setItem - アイテム設定
           --------------------*/
        void setItem( int no )
        {

            if( no == 9999 )
            {
                setNull;
                return;
            }

            item_no = no & BIT_ITM_NO;
            data = item_data[ item_no ];

            if( ( no & BIT_ITM_EQUIPPED ) != 0 )
                equipped = true;
            else
                equipped = false;

            if( ( no & BIT_ITM_CURSED ) != 0 )
                cursed = true;
            else
                cursed = false;

            if( ( no & BIT_ITM_UNDEFINED ) != 0 )
                undefined = true;
            else
                undefined = false;

            return;
        }

        /*--------------------
           setItem - アイテム設定
           --------------------*/
        int getItemSavedata()
        {
            int ret = item_no;

            if( equipped )
                ret |= BIT_ITM_EQUIPPED;

            if( cursed )
                ret |= BIT_ITM_CURSED;

            if( undefined )
                ret |= BIT_ITM_UNDEFINED;

            return ret;
        }

        /*--------------------
           getDispName - 表示名（UNDEFINED による）
           --------------------*/
        string getDispName()
        {
            if( undefined )
                return unname();
            else
                return name();
        }
        /*--------------------
           getDispNameA - 表示名（UNDEFINED による）
           undefined の場合 ? をつける。
           --------------------*/
        string getDispNameA()
        {
            if( undefined )
                return "?" ~ unname();
            else
                return name();
        }

    }

    /*--------------------
       this - コンストラクタ
       --------------------*/
    this( Member p )
    {
        parent = p;
        item_no = 9999;
        data = null;
        return;
    }

    this( Member p , int itm_no )
    {
        parent = p;
        setItem( itm_no );
        return;
    }

    /*--------------------
       dispInfo - アイテム情報表示
       --------------------*/
    void dispInfo()
    {
        data.dispInfo;
        return;
    }

    /*--------------------
       canBeEquipped - 装備可能かどうか
       cl: Member.Class (int) 0:FIG,1:THI,2:PRI,3:MAG,4:BIS,5:SAM,6:LOR,7:NIN 
       --------------------*/
    bool canBeEquipped( int cl )
    {
        return data.canBeEquipped( cl );
    }

    /*--------------------
       checkAtkEf - atkef 確認
       --------------------*/
    bool checkAtkEf( ITM_ATKEF ef )
    {
        return data.checkAtkEf( ef );
    }

    /*--------------------
       checkDefEf - defef 確認
       --------------------*/
    bool checkDefEf( ITM_DEFEF ef )
    {
        return checkDefEf( ef );
    }

    /*--------------------
       setNull - アイテムなくなる。 ... 9999 設定
       --------------------*/
    void setNull()
    {
        item_no = 9999;
        data = null;
        equipped = false;
        cursed = false;
        undefined = false;
        return;
    }

    /*--------------------
       release- アイテム手放す`
       --------------------*/
    void release()
    {
        parent.releaseItem( this );
        return;
    }

    /*--------------------
       trade- アイテム渡す（Item を入れ替える）
       --------------------*/
    void trade( Item itm )
    {
        Member toMem;
        int i , j ;

        // this
        for( i = 0 ; i < 8 ; i++ )
            if( parent.item[ i ] is this )
                break;
        assert( i < 8 );
        
        // to
        for( j = 0 ; j < 8 ; j++ )
            if( itm.parent.item[ j ] is itm )
                break;
        assert( j < 8 );
        toMem = itm.parent;
        
        parent.item[ i ] = itm;
        itm.parent.item[ j ] = this;

        itm.parent = parent;
        parent     = toMem;

        return;
    }
}
