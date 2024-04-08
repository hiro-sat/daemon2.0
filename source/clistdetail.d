import std.stdio;
import std.conv;

import clistmanager;


class ListDetails( P , T )
{

    /*--------------------
       自分自身が 子メンバの場合の処理
       --------------------*/
    P parent;
    T previous;
    T next;

    this( P mgr )
    {
        parent = mgr;
        return;
    }

    /*--------------------
       del 
       --------------------*/
    void del()
    {

        if( previous is null && next is null )
        {
            // 最後の１要素を削除
            parent.top = null;
            parent.end = null;
        }
        else if( previous is null && next !is null )
        {
            // top is me
            parent.top = next;
            next.previous = null;
        }
        else if( previous !is null && next is null )
        {
            // end is me
            parent.end = previous;
            previous.next = null;
        }
        else if( previous !is null && next !is null )
        {
            previous.next = next;
            next.previous = previous;
        }

        previous = null;
        next = null;

        parent.delDetail();

        return;

    }

    /*--------------------
       insertNext
       --------------------*/
    void insertNext( T ins )
    {
        if( next is null )
        {
            next = ins;
            ins.previous = cast(T) this;
            ins.next = null;
        }
        else
        {
            next.previous = ins;

            ins.next = next;
            ins.previous = cast(T) this;

            next = ins;
        }

        return;
    }

    /*--------------------
       insertBefore
       --------------------*/
    void insertBefore( T ins )
    {
        if( previous is null )
        {
            previous = ins;
            ins.next = cast(T) this;
            ins.previous = null;
        }
        else
        {
            previous.next = ins;

            ins.previous = previous;
            ins.next = cast(T) this;

            previous = ins;
        }
        return;
    }

}
