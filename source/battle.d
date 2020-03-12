// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;

// mysource 
import app;
import def;
import cParty;
import cMember;
import cMonsterParty;
import cMonsterTeam;
import cMonster;
import cMonsterDef;
import cBattleTurn;

/* import lib_screen; */
/* import lib_readline; */



/**
// rtncode = 1 : won
//           2 : ran
//           3 : lost
*/
BATTLE_RESULT battle_main()
{

    BattleTurn  bt;
    MonsterTeam mt;
    Monster     m;

    int num, ratio;
    int i,j;
    int rtncode = 0;
    char c;
  
    party.calcAtkAC;

    get_exp = 0;

    for ( i = 0; i < party.num; i++ )
    {
        party.mem[ i ].ac[ 1 ] = 0;
        party.mem[ i ].silenced = false;
    }
  
    // friendly check
    switch ( monParty.def.type )
    {
        case MON_TYPE.ETC : ratio = 50;
            break;
        case MON_TYPE.FIG : ratio = 10;
            break;
        case MON_TYPE.MAG : ratio = 5;
            break;
        case MON_TYPE.PRI : ratio = 15;
            break;
        case MON_TYPE.THI : ratio = 3;
            break;
        case MON_TYPE.SHUM : ratio = 30;
            break;
        case MON_TYPE.DRA : ratio = 25;
            break;
        case MON_TYPE.GOD : ratio = 95;
            break;
        default : ratio = 50;
            break;
    }
    if ( get_rand( 99 ) + 1 < ratio && party.layer <= 7 )
    { // friendly
        monParty.ident = true;
        textout( "*** a friendly group of \n            " );
        textout( monParty.getDispNameS );
        textout( " ***\nf)ight(5) or z)leave(7)? " );
        while ( true )
        {
            c = getChar();
            if ( c == 'f' || c == 'z' || c == '5' || c == '7' )
                break;
        }
        textout( c );
        textout( '\n' ); 

        for ( i = 0; i < party.num; i++ )
        {
            if ( get_rand( 99 ) + 1 <= 2 )
            {
                if ( party.mem[ i ].Align == ALIGN.GOOD
                        && (c == 'f' || c == '5') )
                {
                    party.mem[ i ].Align = ALIGN.EVIL;
                }
                else if ( party.mem[i].Align == ALIGN.EVIL 
                        && (c == 'z' || c == '7') )
                {
                    party.mem[ i ].Align = ALIGN.GOOD;
                }
            }
        }

        if ( c == 'z' )
        {
            rtncode = BATTLE_RESULT.LEAVE;
            goto EXIT;
        }
    }
    else if ( get_rand(99) + 1 < 20 )
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
    
    setColor( CL.MONSTER );
    textout( "\n\n****** encounter ****** - push space(5) -\n" );
    while ( true )
    {
        c = getChar();
        if ( c == ' ' || c == '5' )
            break;
    }
    monParty.updateIdentify;
    monParty.disp();
    textout( "***********************\n" );
    setColor( CL.NORMAL );


    if ( monParty.suprised )
    {
        setColor( CL.MENU );
        textout( "\n *** you surprised the monsters ***\n\n" );
        setColor( CL.NORMAL );
    }
    if ( party.suprised )
    {
        setColor( CL.ENCOUNT );
        textout( "\n *** the monsters surprised you ***\n\n" );
        setColor( CL.NORMAL );
        getChar();
    }

    while ( true )
    {
        party.hpplus;

        if ( ! party.suprised )    // not ( mon -> you )
        {
            party.action_input;
            if ( party.mem[ 0 ].action == ACT.RUN )
            { /* run */
                if ( get_rand( 99 ) < 94 )
                { /* 95% run */
                    for ( i = 0; i < party.num; i++ )
                    {
                        party.mem[ i ].silenced = false;
                        if ( party.mem[ i ].status == STS.SLEEP )
                            party.mem[ i ].status = STS.OK;
                    }
                    textout( " ... escaped.\n" );
                    party.layer = party.olayer;
                    party.x     = party.ox;
                    party.y     = party.oy;
                    party.dungeon.disp;
                    rtncode = BATTLE_RESULT.RAN ;
                    goto EXIT;
                }
            }
        }
        num = decide_order();
        bt = top_turn;
        
        while ( true )
        {
            if ( monParty.num == 0 )
            {
                rtncode = BATTLE_RESULT.WON;
                break;
            }

            bt = bt.next;
            if ( bt.agi == 0 ) /* end of turn? */
                break;

            bt.act();

        }
        party.suprised = false;
        monParty.suprised = false;

        setColor( CL.NORMAL );

  //      if (monParty.num==0 || party.actnum==0)
        if ( monParty.num == 0 )
          break;

        // check loose
        if( ! party.checkAlive ) 
        {
            party.win_disp();
            party.num = 0;
            party.layer = 0;
            textout( "\n*** your party is lost...<push space bar)>\n" );
            while ( true )
            {
                c = getChar();
                if ( c == ' ' || c == '5' )
                    break;
            }
            rtncode = BATTLE_RESULT.LOST;
            goto BATTLE_LOOP_EXIT;
        }

        // wakeup check( party )
        for ( i = 0; i < party.num; i++ )
        {
            if ( ( party.mem[ i ].status == STS.SLEEP )
                        && ( get_rand( 3 ) == 0 ) )
                party.mem[i].status = STS.OK;
        }

        // wakeup check( monster )
        mt = monParty.top;
        for (i = 0; i < monParty.num; i++)
        {
            m = mt.top;
            for ( j = 0; j < mt.num; j++ )
            {
                if( m.status == STS.SLEEP && get_rand( 1 ) == 0 )
                    m.status = STS.OK;
                m = m.next;
            }
            mt = mt.next;
        }

        // check poisoned( party )
        for ( i = 0; i < party.num; i++ )
            if ( party.mem[ i ].poisoned )
            {
                if( party.mem[ i ].hp < 10 )
                    party.mem[ i ].hp --;
                else
                    party.mem[ i ].hp -= party.mem[ i ].hp / 10 ;
                if ( party.mem[ i ].hp < 1 )
                    party.mem[ i ].hp = 1;
            }

        setColor( CL.MONSTER );
        textout( "*******  battle *******\n" );
        monParty.updateIdentify;
        monParty.disp();
        textout( "***********************\n" );
        setColor( CL.NORMAL );
  
        party.win_disp();
    }

BATTLE_LOOP_EXIT:
    party.win_disp();
    if ( monParty.num == 0 )
    {
      rtncode = BATTLE_RESULT.WON ; /* win!! */
      textout( "\n  each survivor gets " );
      textout( get_exp / party.actnum );
      textout( " E.P.\n" );
      for ( i = 0; i < party.num; i++ )
      {
          if ( party.mem[ i ].status <= STS.AFRAID )
              party.mem[ i ].exp += get_exp / party.actnum;
          party.mem[ i ].ac[ 1 ] = 0;
      }
    }
EXIT:
    for ( i = 0; i < party.num; i++ )
    {
        party.mem[ i ].ac[ 1 ] = 0;
        if ( party.mem[ i ].status == STS.SLEEP )   /* sleep . Ok */
            party.mem[i].status = STS.OK;
        party.mem[ i ].silenced = false;
    }
    party.win_disp();
    return cast(BATTLE_RESULT)rtncode;
  
}


/*--------------------
   decide_order - 戦闘時行動順設定
   --------------------*/
int decide_order()
{
    BattleTurn  bt;
    MonsterTeam mt;
    Monster     m;
    int num;
    int i, j;
  
    top_turn.agi = 127; /* max */
    top_turn.next = end_turn;
    end_turn.agi = 0;   /* min */
    end_turn.previous = top_turn;
  
    /* party member */
    num = 0;
    for ( i = 0; i < party.num; i++ )
    {
        if ( party.mem[ i ].name != "" 
                && ( party.mem[ i ].status  == STS.OK ) )
        {
            turn[ num ].set = party.mem[ i ];
            
            bt = top_turn;
            while ( true )
            {
                if ( bt.agi < turn[ num ].agi )
                {
                    turn[ num ].previous = bt.previous;
                    bt.previous.next = turn[ num ];

                    turn[ num ].next     = bt;
                    bt.previous = turn[ num ];
            
                    num++;
                    break;
                }
                bt = bt.next;
            }
        }
    }  
  
    /* monster */
    mt = monParty.top;
    for ( j = 0; j < monParty.num; j++ )
    {
        m = mt.top;
        for ( i = 0; i < mt.num; i++ )
        {
            turn[ num ].set = m;
  
            bt = top_turn;

            while ( true )
            {
                if ( bt.agi < turn[ num ].agi )
                {
                    turn[ num ].previous = bt.previous;
                    bt.previous.next = turn[ num ];

                    turn[ num ].next = bt;
                    bt.previous = turn[ num ];

                    /* m.turn = turn[ num ]; // いらない？ */
                    num++;
                    break;
                }
                bt = bt.next;
            }
            m = m.next;
        }
        mt = mt.next;
    }
  
    return num;
}


/**
  btl_pspell -
  */
int btl_pspell( BattleTurn btn )
{
    writeln( btn );
    return 0;
}

