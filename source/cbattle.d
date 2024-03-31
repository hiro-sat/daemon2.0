// Phobos Runtime Library
import std.stdio;
import std.conv;

// mysource 
import app;
import def;

import ctextarea;
import cparty;
import cmember;
import cmonster_party;
import cmonster_team;
import cmonster;
import cmonster_def;
import cbattleturn;




class Battle
{

private:

    // friendly check
    bool checkFriendly( ref bool exit )
    {
        int ratio;
        char c;

        switch ( monParty.def.type )
        {
            case MON_TYPE.ETC :  ratio = 50; break;
            case MON_TYPE.FIG :  ratio = 10; break;
            case MON_TYPE.MAG :  ratio =  5; break;
            case MON_TYPE.PRI :  ratio = 15; break;
            case MON_TYPE.THI :  ratio =  3; break;
            case MON_TYPE.SHUM : ratio = 30; break;
            case MON_TYPE.DRA :  ratio = 25; break;
            case MON_TYPE.GOD :  ratio = 95; break;
            default :            ratio = 50; break;
        }

        if ( get_rand( 99 ) + 1 < ratio && party.layer <= 7 )
        { // friendly
            monParty.ident = true;
            txtMessage.textout( _( "*** a friendly group of \n            %1 ***\n" ) , monParty.getDispNameS );
            txtMessage.textout( _( "f)ight(5) or z)leave(7)? " ) );

            c = getCharFromList( "f5z7" );
            txtMessage.textout( c );
            txtMessage.textout( '\n' ); 

            foreach( p ; party )
                if ( get_rand( 99 ) + 1 <= 2 )
                {
                    if ( p.Align == ALIGN.GOOD  && (c == 'f' || c == '5') )
                        p.Align = ALIGN.EVIL;
                    else if ( p.Align == ALIGN.EVIL && (c == 'z' || c == '7') )
                        p.Align = ALIGN.GOOD;
                }

            if ( c == 'z' || c == '7' )
            {
                txtMessage.textout( _( "leaved...\n" ) ) ; 
                exit = true;
                return true;

            }

            // if ( c == 'f' || c == '5' )
            txtMessage.textout( "\n" );
            party.suprised = false;
            monParty.suprised = false;

            return true;

        }

        return false;

    }


    // suprised check
    void checkSuprised()
    {

        if ( get_rand(99) + 1 < 20 )
        { // surprised the monster(20%)
            party.suprised = false;
            monParty.suprised = true;
        }
        else if ( get_rand(99) + 1 < 20 )
        { // the monster suprised you(16%(0.8*0.2))
            party.suprised = true;
            monParty.suprised = false;
        }
        else
        {
            party.suprised = false;
            monParty.suprised = false;
        }

    }

    bool checkEscaped()
    {
        /* 95% run */
        if ( get_rand( 99 ) >= 95 )
            return false;

        foreach( p ; party )
        {
            p.silenced = false;
            if ( p.status == STS.SLEEP )
                p.status = STS.OK;
        }
        setColor( CL.NORMAL );
        txtMessage.textout( _(" ... escaped.\n") );
        party.layer = party.olayer;
        party.x     = party.ox;
        party.y     = party.oy;
        party.dungeon.disp( true );
        return true;
    }



public:

    /**
    // rtncode = 1 : won
    //           2 : ran
    //           3 : lost
    */
    BATTLE_RESULT battleMain()
    {
        BATTLE_RESULT result;
        bool exit;

        int i,j;
        char c;
        bool flg;
        bool escape;
        bool autoFlg;
      
        txtMessage.clear;
        party.calcAtkAC;
        get_exp = 0;

        foreach( p ; party )
        {
            p.ac[ 1 ] = 0;
            p.silenced = false;
        }
      
        // friendly check
        exit = false;
        if( checkFriendly( exit ) )
        {
            if( exit ) 
            {
                result = BATTLE_RESULT.LEAVE;
                goto EXIT;
            }
        }
        else
        {
            // suprised check -> party.suprised or monParty.suprised
            checkSuprised;
        }


        setColor( CL.MONSTER );
        txtMessage.textout( "****** encounter ****** - push space(5) -\n" );
        c = getCharFromList( " 5" );
        monParty.updateIdentify;
        monParty.disp();
        txtMessage.textout( "***********************\n" );
        setColor( CL.NORMAL );


        if ( monParty.suprised )
        {
            setColor( CL.MENU );
            txtMessage.textout( _( "\n *** you surprised the monsters ***\n\n" ) );
            setColor( CL.NORMAL );
        }

        if ( party.suprised )
        {
            setColor( CL.ENCOUNT );
            txtMessage.textout( _( "\n *** the monsters surprised you ***\n\n" ) );
            setColor( CL.NORMAL );
            getChar();
        }


        while ( true )
        {

            party.hpPlus;

            foreach( pl ; party )
                pl.actionDetails = "";

            if ( ! party.suprised )    // not ( mon -> you )
            {
                dispHeader( HSTS.BATTLE );

                /+ -------------------- 
                    input command
                   -------------------- +/
                escape = false;
                autoFlg = false;
                party.inputAction( escape , autoFlg );
                if ( escape )
                    if( checkEscaped )
                    {
                        result = BATTLE_RESULT.RAN;
                        goto EXIT;
                    }
            }

            /+ -------------------- 
                decide order
               -------------------- +/
            battleManager.decideOrder();

            /+ -------------------- 
                In combat !!!
               -------------------- +/
            foreach( bt ; battleManager )
            {
                scope(exit) messageNoWait = false;
                if( autoFlg )
                    messageNoWait = true;

                if ( monParty.count == 0 )
                    break;

                if( battleManager.isEnd( bt ) ) /* end of turn? */
                    break;

                bt.act();

            }

            /+ -------------------- 
                end of turn...
               -------------------- +/
            party.suprised = false;
            monParty.suprised = false;

            setColor( CL.NORMAL );

            if ( monParty.count == 0 )
            {
                result = BATTLE_RESULT.WON;
                break;
            }

            // check loose
            if( ! party.checkAlive ) 
            {
                party.dispPartyWindow();
                party.saveLocate;
                party.layer = 0;
                setColor( STS_CL.DEAD );
                txtMessage.textout( _( "\n*** your party is lost...<push space bar>\n" ) );
                c = getCharFromList( " 5" );
                result = BATTLE_RESULT.LOST;
                break;
            }

            // wakeup check( party )
            foreach( p ; party )
            {
                if ( ( p.status == STS.SLEEP )
                  && ( get_rand( 3 ) == 0 ) )
                    p.status = STS.OK;
            }

            // wakeup check( monster )
            foreach( mt ; monParty )
                foreach( m ; mt )
                    if( m.status == STS.SLEEP && get_rand( 1 ) == 0 )
                        m.status = STS.OK;

            // check poisoned( party )
            foreach( p ; party )
                if ( p.poisoned )
                    p.damagedByPoison;

            setColor( CL.MONSTER );
            txtMessage.textout( "*******  battle *******\n" );
            monParty.updateIdentify;
            monParty.disp();
            txtMessage.textout( "***********************\n" );
            setColor( CL.NORMAL );
      
            party.dispPartyWindow();
        }

        // battle is end
        dispHeader( HSTS.DUNGEON );
        party.dispPartyWindow();
        if( result == BATTLE_RESULT.WON )
        {
            /+ -------------------- 
                WIN !!
               -------------------- +/
            result = BATTLE_RESULT.WON ;
            txtMessage.textout( _( "\n  each survivor gets %1 ep.\n" ) , get_exp / party.memCountAlive );
            foreach( p ; party )
            {
                if ( p.status <= STS.AFRAID )
                    p.exp += get_exp / party.memCountAlive;
                p.ac[ 1 ] = 0;
            }
        }

    EXIT:
        foreach( Member p ; party )
        {
            p.ac[ 1 ] = 0;
            if ( p.status == STS.SLEEP )   /* sleep . Ok */
                p.status = STS.OK;
            p.silenced = false;
            p.actionDetails = "";
        }
        dispHeader( HSTS.DUNGEON );
        party.dispPartyWindow();
        return result;
      
    }

}
