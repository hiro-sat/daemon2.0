import std.stdio;
import std.conv;


class ListManager( T )
{

public:

    T[] details;
    T top;
    T end;

    void initListDetails( int length )
    {
        details.length = length;
        foreach( i ; 0 .. details.length )
            details[ i ] = new T();
        return ;
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

