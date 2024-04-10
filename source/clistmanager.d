import std.stdio;
import std.conv;


class ListManager( P , T )
{

private:
    int detailsCount;

public:
   
    T[] details;
    T top;
    T end;

    this( int length )
    {
        details.length = length;
        foreach( i ; 0 .. details.length )
            details[ i ] = new T( cast(P) this );
        return ;
    }

    int count() { return detailsCount; }

    void reset()
    {
        foreach( d ; details )
        {
            d.previous  = null;
            d.next      = null;
        }
        top = null;
        end = null;
        detailsCount = 0;
        return;
    }


    T add()
    {
        if( detailsCount == 0 )
        {
            detailsCount ++;
            return details[ 0 ];
        }

        // detailsCount >= 1
        foreach( i , d ; details )
        {
            if( detailsCount == 1 && i == 0 )
            {
                // 要素が1つのとき、( d.previous is null && d.next is null )
                detailsCount ++;
                return details[ 1 ];
            }

            // i >= 1
            if( d.previous is null && d.next is null )
            {
                detailsCount ++;
                return d;
            }
        }

        return null;
    }

    void delDetail()     // clistdetail からの呼出のみ
    {
        detailsCount --;   // del
        assert( detailsCount >= 0 , detailsCount.to!string );
        return;
    }

    /*--------------------
       foreach -> details を返す
       http://ddili.org/ders/d.en/foreach_opapply.html
       --------------------*/
    int opApply( int delegate( ref T ) operations )  
    {

        int result = 0;
        T dt = top;

        /* assert( dt !is null , "foreach is null" ); */

        while( true )
        {
            if( dt is null )
                break;
            result = operations( dt );  // (1)
            dt = dt.next;
        }

        return result;
    }

    /*--------------------
       foreach -> details を返す
       http://ddili.org/ders/d.en/foreach_opapply.html
       --------------------*/
    int opApply( int delegate( ref size_t ,
                               ref T ) operations )  
    {

        int result = 0;
        ulong i = 0;
        T dt = top;

        /* assert( dt !is null , "foreach is null" ); */

        while( true )
        {
            if( dt is null )
                break;
            result = operations( i , dt );  // (1)
            dt = dt.next;
            i ++;
        }

        return result;
    }

}

