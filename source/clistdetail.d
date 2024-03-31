import std.stdio;
import std.conv;


class ListDetails( T )
{

    /*--------------------
       自分自身が 子メンバの場合の処理
       --------------------*/
    T previous;
    T next;

    /*--------------------
       del 
       --------------------*/
    void del( T me , ref T top )
    {

        if( me is top )
        {
            if( me.next is null )
                top = null;
            else
                top = me.next;
        }


        if( previous is null && next is null )
        {
            // nothing to do 
        }
        else if( previous !is null && next is null )
        {
            previous.next = null;
        }
        else if( previous is null && next !is null )
        {
            next.previous = null;
        }
        else if( previous !is null && next !is null )
        {
            previous.next = next;
            next.previous = previous;
        }

        return;

    }

    /*--------------------
       insertNext
       --------------------*/
    void insertNext( T me , T i )
    {
        if( next is null )
        {
            next = i;
            i.previous = me;
            i.next = null;
        }
        else
        {
            next.previous = i;
            i.previous = me;

            i.next = next;
            next = i;
        }

        return;
    }

    /*--------------------
       insertBefore
       --------------------*/
    void insertBefore( T me , T i )
    {
        if( previous is null )
        {
            previous = i;
            i.next = me;
            i.previous = null;
        }
        else
        {
            previous.next = i;
            i.next = me;

            i.previous = previous;
            previous = i;
        }
        return;
    }

}


