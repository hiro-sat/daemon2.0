// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.conv;
import std.string : indexOf;

// mysource 
import def;
import app;

import cmember;
import cmap;
import cevent;
import citem;

class Party
{

private:
    enum BIT_PARTY_STS_SCOPE    = 0x08;
    enum BIT_PARTY_STS_MAPPER   = 0x10;
    enum BIT_PARTY_STS_LIGHT    = 0x20;
    enum BIT_PARTY_STS_FLOAT    = 0x40;
    enum BIT_PARTY_STS_IDENTIFY = 0x80;


public:
    Member[ 6 ] mem;
    Map dungeon;


    int step;
    int x;
    int y;
    byte layer; // 0:castle , 1-8:dungeon
    int ox;
    int oy;
    byte olayer;
    byte status;  // bit7:i, latumapic
                  // bit6:f, litofeit
                  // bit5:l, milwa/lomilwa
                  // bit4:p, mapper
                  // bit3:s, scope
    int lightCount;   // milwacnt
    int scopeCount;

    // byte num;
    // byte actnum;

    byte ac;

    bool suprised;
    
    /*--------------------
       foreach -> パーティにいるメンバーを返す
       http://ddili.org/ders/d.en/foreach_opapply.html
       --------------------*/
    int opApply( int delegate( ref Member ) operations )  
    {

        int result = 0;

        foreach ( m ; mem ) {
            if( ( m !is null ) && ( m.name != "" ) )
                result = operations( m );  // (1)

            if (result) 
                break;
        }

        return result;                    // (5)
    }

    /*--------------------
       foreach( index ) -> パーティにいるメンバーを返す
       http://ddili.org/ders/d.en/foreach_opapply.html
       --------------------*/
    int opApply( int delegate( ref size_t ,
                               ref Member ) operations )  
    {

        int result = 0;

        foreach ( i , m ; mem ) {
            if( ( m !is null ) && ( m.name != "" ) )
                result = operations( i , m );  // (1)

            if (result) 
                break;
        }

        return result;                    // (5)
    }

    /*--------------------
       foreach_reverse -> パーティにいるメンバーを返す
       http://ddili.org/ders/d.en/foreach_opapply.html
       --------------------*/
    int opApplyReverse( int delegate( ref Member ) operations )  
    {

        int result = 0;

        foreach_reverse ( m ; mem ) {
            if( ( m !is null ) && ( m.name != "" ) )
                result = operations( m );  // (1)

            if (result) 
                break;
        }

        return result;                    // (5)
    }

    /*--------------------
       memCount - メンバー数
       --------------------*/
    int memCount()
    {
        int n;
        foreach( m ; this )
            n++;
        return n;
    }

    /*--------------------
       memCountAlive - メンバー数（動ける人）
       --------------------*/
    int memCountAlive()
    {
        int n;
        foreach( p ; this )
            if ( p.status < STS.PARALY )
                n++;
        return n;
    }


    /*--------------------
       this - コンストラクタ
       --------------------*/
    this()
    {
        ox     = 1;
        oy     = 2;
        x      = 1;
        y      = 2;
        layer  = 0;
        olayer = 0;
        status = 0;
        ac     = 0;

        disband;    // メンバースロット初期化

        return;
    }

    /*--------------------
       setDungeon - ダンジョンセット
       --------------------*/
    void setDungeon()
    {
        if( layer == 0 )
        {
            dungeon = null;
        }
        else
        {
            dungeon = dungeonMap[ layer - 1 ];
            /* dungeon.resetEncounterArea; */
        }
        return;
    }


    
    bool isMapper()   { return ( ( status & BIT_PARTY_STS_MAPPER   ) != 0 ); }
    bool isFloat()    { return ( ( status & BIT_PARTY_STS_FLOAT    ) != 0 ); }
    bool isLight()    { return ( ( status & BIT_PARTY_STS_LIGHT    ) != 0 ); }
    /* bool isScope()    { return ( ( status & BIT_PARTY_STS_SCOPE    ) != 0 ); } */
    bool isIdentify() { return ( ( status & BIT_PARTY_STS_IDENTIFY ) != 0 ); }
    /* void setScope()    { status |= BIT_PARTY_STS_SCOPE    ; } */
    void setMapper()   { status |= BIT_PARTY_STS_MAPPER   ; }
    void setFloat()    { status |= BIT_PARTY_STS_FLOAT    ; }
    void setLight()    { status |= BIT_PARTY_STS_LIGHT    ; }
    void setIdentify() { status |= BIT_PARTY_STS_IDENTIFY ; }
    /* void resetScope()    { status &= ~BIT_PARTY_STS_SCOPE    ;  */
    /*                        scopeCount = 0 ;} */
    void resetMapper()   { status &= ~BIT_PARTY_STS_MAPPER   ; 
                           scopeCount = 0 ;}
    void resetFloat()    { status &= ~BIT_PARTY_STS_FLOAT    ; 
                           lightCount = 0 ;}
    void resetLight()    { status &= ~BIT_PARTY_STS_LIGHT    ; 
                           lightCount = 0 ;}
    void resetIdentify() { status &= ~BIT_PARTY_STS_IDENTIFY ; }
    void resetAllFlg()
    {
        /* resetScope()    ; */
        resetMapper()   ;
        resetFloat()    ;
        resetLight()    ;
        resetIdentify() ;
    }

    /*--------------------
       add - 最後尾にメンバー追加
       --------------------*/
    void add( Member p )
    {
        mem[ memCount ] = p;
        return;
    }


    /*--------------------
       remove - 指定したメンバーを外す
       --------------------*/
    void remove( Member p )
    {
        assert( p !is null );

        for( int i = 0 ; i < 6 ; i++ )
        {
            if( p !is null )
            {
                if( mem[ i ] == p )
                {
                    mem[ i ] = null;
                    p = null;
                }
            }
            else
            {
                // 削除完了 → 1人ずつ前につめる
                mem[ i - 1 ] = mem[ i ];
            }
        }
        mem[ 5 ] = null;
        return;
    }
    /*--------------------
       disband - パーティ解散
       --------------------*/
    void disband()
    {
        // パーティ解散     
        // foreach だとnullにしくてれない
        // foreach( p ; party ) { p = null; } だと参照元の mem[ i ] がnullにならない
        for( int i = 0 ; i < 6 ; i++ )
            mem[ i ] = null;
        return;
    }

    /*--------------------
       divvy - ゴールドを分ける
       --------------------*/
    void divvy()
    {
        int i;
        long sum , each;

        if( memCount == 0 )
            return;

        sum = 0;

        foreach( p ; this )
            sum += p.gold;
        each = sum / memCount;
        foreach( p ; this )
        {
            p.gold = each;
            sum -= each;
        }
        mem[ 0 ].gold = sum + each;

        return;
    }


    /*--------------------
       poolGold - ゴールドを集める
       no : 集めるメンバー 
       --------------------*/
    void poolGold( Member m )
    {
        int i;
        long poolgold = 0;

        foreach( p ; this )
        {
            poolgold += p.gold;
            p.gold = 0;
        }
        m.gold = poolgold;
        txtMessage.textout( _( "%1 has %2 gp.\n" ) , m.name , poolgold );

        return;
    }
    /*--------------------
       poolGold - ゴールドを集める
       no : 集めるメンバー 
       --------------------*/
    void poolGold( int no )
    {
        poolGold( mem[ no ] );
        return;
    }

    /*--------------------
       checkAlive - 全滅判定
       --------------------*/
    bool checkAlive()
    {
        foreach( m ; this )
            if ( ( m.status ) < STS.PARALY )
                return true;

        return false;
    }

    /*--------------------
       dispPartyWindow - パーティウィンドウ表示
       --------------------*/
    void dispPartyWindow( bool rewrite = true )
    {
        int color = getColor;
        setColor( CL.NORMAL );

        order();
        dispPartyWindowSub( rewrite );

        setColor( color );
        return;
    }


    // dispPartyWindow without reordering
    void dispPartyWindow_NoReorder()    // in battle
    {

        int color = getColor;
        foreach( Member p ; party )
            p.dispStatusLine( false );
        setColor( color );
        return;

    }

    /*--------------------
       dispPartyWindowSub - パーティウィンドウ表示
       --------------------*/
    void dispPartyWindowSub( bool rewrite = true )
    {
        int i;
        calcAtkAC();

        rewriteOff;

        string spc = "                                                                               ";

        mvprintw( CHRW_Y_TOP , CHRW_X_TOP 
                , "# name             class  ac   hp /maxhp status action option" );
        for ( i = 0 ; i < 6 ; i++ )
        {
            if ( mem[ i ] is null || memCount <= i )
            {
                mvprintw( CHRW_Y_TOP + i + 1 , CHRW_X_TOP , spc );
                continue;
            }
            else
            {
                mem[ i ].dispStatusLine();
            }
        }

        if( rewrite )
            rewriteOn;

        return;
    }

    /*--------------------
       setMemberLocate - メンバーに位置情報を保存（save用）
       --------------------*/
    void setMemberLocate()
    {

        foreach( m ; this )
        {
            if( layer == 0 )
            {
                m.outflag = OUT_F.BAR;
                m.x = 0;
                m.y = 0;
                m.layer = 0;
            }
            else
            {
                m.outflag = OUT_F.DUNGEON;
                m.x = x;
                m.y = y;
                m.layer = layer;
            }
        }
        return;

    }

    /*--------------------
       order - メンバー並び換え（表示用ステータス識別）
       --------------------*/
    void order()
    {
        int i;

        Member[] ok;
        Member[] ng;
        Member[] dead;
      
        foreach( p ; this )
        {
            if( p.status <= STS.SLEEP )
                ok ~= p;
            else if( p.status < STS.DEAD )
                ng ~= p;
            else
                dead ~= p;
        }

        int no = 0;
        foreach( p ; ok )
            mem[ no++ ] = p;

        foreach( p ; ng )
            mem[ no++ ] = p;

        foreach( p ; dead )
            mem[ no++ ] = p;

        return;
    }

    /*--------------------
       reorder - メンバー並び換え（キャンプ中）
       --------------------*/
    void reorder( Member m )
    {
        char ch;
        int i;
        Member[ 6 ] tmp;
        string order = "";

        bool reorder_sub( string step )
        {
            txtMessage.textout( _( "who comes %1(z:leave(9))? " ) , step  );
            while ( true )
            {
                ch = getChar();
                if ( ch == 'z' || ch == '9' )
                {
                    txtMessage.textout( "leave\n" );
                    return false;
                }

                if (ch >= '1' && ch <= '0' + memCount )
                {
                    if( indexOf( order , ch ) >= 0 )
                        continue;

                    txtMessage.textout( "%1(%2)" , ch , mem[ ch - '1' ].name );
                    txtMessage.textout( '\n' );
                    break;
                }
            }
            order ~= to!string( ch );
            return true;
        }



        if( ! reorder_sub( _( "first" ) ) )
            return;
        if ( memCount <= 1 )
            goto EXIT;

        if( ! reorder_sub( _( "second" ) ) )
            return;
        if ( memCount <= 2 )
            goto EXIT;

        if( ! reorder_sub( _( "third" ) ) )
            return;
        if ( memCount <= 3 )
            goto EXIT;

        if( ! reorder_sub( _( "fourth" ) ) )
            return;
        if ( memCount <= 4 )
            goto EXIT;

        if( ! reorder_sub( _( "fifth" ) ) )
            return;
        if ( memCount <= 5 )
            goto EXIT;

        if( ! reorder_sub( _( "sixth" ) ) )
            return;

    EXIT:
        for ( i = 0; i < 6; i++ )
          tmp[ i ] = party.mem[i];
        i = 0;
        foreach( char o ; order )
            party.mem[ i++ ] = tmp[ o - '1' ];

        party.dispPartyWindow();

        m.inspect();

        return;
    }


    /*--------------------
       calcAtkAC - AC 計算
       --------------------*/
    void calcAtkAC()
    {
        int i;

        foreach( p ; party )
            p.calcAtkAC;

        return;
    }

    /*--------------------
       hpPlus - 移動時のHP増加処理
       --------------------*/
    void hpPlus()
    {
        
        int  j;

        foreach( p ; party )
        {
            if ( ( p.status ) >= STS.DEAD )
                continue;

            for ( j = 0; j < MAXCARRY; j++ )
                if ( ! p.item[ j ].isNothing )
                    p.healHP( p.item[ j ].hpPlus );
        }
        return;
    }


    /*--------------------
       theyGet - アイテム取得
       --------------------*/
    bool theyGet( int itemno )
    {
        Item itm;

        // パーティ最後尾からアイテム取得する
        for( int j = memCount - 1 ; j >= 0 ; j -- )
        {
            if( mem[ j ].canCarry )
            {
                itm = mem[ j ].getItem( itemno );
                itm.undefined = true;

                txtMessage.textout( _( "  %1 got a %2.\n" ) , mem[ j ].name , itm.getDispName );
                getChar();
                return true;
            }
        }
        txtMessage.textout( _( "you cannot carry anything more.\n" ) );
        return false;
    }


    /*--------------------
       doTheyHave - アイテム所持確認
       --------------------*/
    // rtn=1 as Yes.  Someone in the party has it.
    //     0 as No.  Noone in the party has it.
    bool doTheyHave( int item )
    {
        foreach( p ; party )
            if ( p.doesHeHave( item ) != 0 )
                return true;
        return false;
    }

    /*--------------------
       equip - メンバー選んで装備
       --------------------*/
    void equip()
    {

        char c;

        if( memCount == 0 )
            return;

        txtMessage.textout( _( "who(z:leave(9))? " ) );
        while( true )
        {
            c = getChar();
            if( c == 'z' || c == '9' )
                break;
            if( c >= '1' && c <= memCount + '0' )
                break;
        }

        txtMessage.textout( to!string( c ) ~ "\n" );

        if( c != 'z' && c != '9' )
        {
            mem[ c - '1' ].inspect;
            mem[ c - '1' ].equip;
        }

        return;
    }

    /*--------------------
       inspect - メンバー情報表示
        type: 1:camp , 2:battle
       --------------------*/
    /* void inspect_party() */
    void inspect( int type = 0 )
    {
        char c;
        
        txtMessage.textout( _( "who do you want to inspect(z:leave(9))? " ) );
        while ( true )
        {
            c = getChar();
            if ( c-'0' > 0 && c - '0' <= memCount )
                break;
            if ( c=='z' || c=='9' )
                break;
        }
        txtMessage.textout ( to!string( c ) ~ "\n" );

        if ( c == 'z' || c == '9' )
            return;

        mem[ c - '1' ].inspectCharacter;

        return;
    }


    /*--------------------
       heal_all - 全回復
       --------------------*/
    void healAll()
    {
        int i, j;
        foreach( t ; party )
        {
            if ( t.status >= STS.DEAD )
                continue;

            if ( t.status == STS.OK && t.hp == t.maxhp )
                continue;

            foreach( p ; party )
            {
                if ( p.status != STS.OK )
                    continue;
                if ( p.consumeSpell( "bless" ) )
                {
                    t.hp = t.maxhp;
                    t.status = STS.OK;
                    break;
                }
            }
        }
        return;
    }


    // vyzaakt&vyzakt&vetteny&xiang&mapper
    void protectAll() 
    {
        int i;
        string msg;

        // mapper
        if ( party.scopeCount == 0 || ! isMapper )
        {
            foreach( p ; party )
                if ( p.isSpellKnown( "map" ) && p.consumeSpell( "map" ) )
                {
                    magic_all[ "map" ].castSpell( p , false );    // camp = false
                    dungeon.disp;
                    msg ~= _( "  map...done.\n" );
                    break;
                }
        }
        // shine
        if ( ! isLight ){
            foreach( p ; party )
                if ( p.isSpellKnown( "xlight" ) && p.consumeSpell( "xlight" ) )
                {
                    magic_all[ "xlight" ].castSpell( p , false );    // camp = false
                    msg ~= _( "  xlight...done.\n" );
                    break;
                }
        }
        // awaken
        if ( ! isIdentify ){
            foreach( p ; party )
                if ( p.isSpellKnown( "identfy" ) && p.consumeSpell( "identfy" ) )
                {
                    magic_all[ "identfy" ].castSpell( p , false );    // camp = false
                    msg ~= _( "  identfy...done.\n" );
                    break;
                  }
        }
        // floatn
        if ( ! isFloat )
        {
            foreach( p ; party )
                if ( p.isSpellKnown( "floatn" ) && p.consumeSpell( "floatn" ) )
                {
                    magic_all[ "floatn" ].castSpell( p , false );    // camp = false
                    msg ~=  _( "  floatn...done.\n" );
                    break;
                }
        }
        // vyzaakt
        if ( ac == 0 )
        {
            foreach( p ; party )
                if ( p.isSpellKnown( "guard" ) && p.consumeSpell( "guard" ) )
                {
                    /* magic_all[ "guard" ].castSpell( p , true );    // camp = false */
                    // 一瞬「キャンプ」と表示されてしまうため、ここで処理を行う
                    party.ac =  - 2;
                    party.dispPartyWindow();
                    msg ~= _( "  guard...done.\n" );
                    break;
                }
        }

        if( msg.length > 0 )
            txtMessage.textout( msg );
        return;
    }

    //////////////////////////////////////////////////////////////////////////////////
    //
    //------ battle --------------------------
    //
    //////////////////////////////////////////////////////////////////////////////////
    void inputAction( ref bool escape , ref bool autoFlg )
    {
        char c;
        bool cancel;

        void resetDispAction()
        {
            foreach( i , pl ; this )
                if( pl.status == STS.OK )
                {
                    pl.setStatusColor;
                    mvprintw( CHRW_Y_TOP + i + 1, CHRW_X_TOP + 48, "?????? ???????????????????????" );
                }
                else
                {
                    mvprintw( CHRW_Y_TOP + i + 1, CHRW_X_TOP + 48, "                              " );
                }
            return;
        }


        while( true )
        {

            resetDispAction;
          
            cancel = false;
            foreach( row , pl ; this )
            {
                if ( pl.status != STS.OK )
                    continue;   // Next Member -> continue foreach

                /+ -------------------- 
                    input command
                   -------------------- +/
                pl.setStatusColor;
                mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 48, "what?  " );
                escape = false;
                if( ! inputActionSub( pl , escape , autoFlg ) )
                {
                    cancel = true;
                    break;      // break foreach loop -> AGAIN -> while( true )
                }
                if( escape )
                {
                    resetDispAction;
                    foreach( p ; this )
                        p.action = ACT.run;
                    txtMessage.textout( "\n" );
                    return;
                }
                if( autoFlg )
                {
                    resetDispAction;
                    foreach( p ; this )
                        if( p.status == STS.OK )
                            p.inputAction( ' ' );
                    return;
                }

            }
            if( cancel ) continue;  // AGAIN -> continue while( true )

            // input OK?
            setColor( CL.NORMAL );
            txtMessage.textout( _( " ok?(t:take back)" ) );
            c = getChar();
            if ( c == 't' || c == 'l' || c == '9' )
            {
                txtMessage.textout( _( "\ninput again ..." ) );
                continue;   // AGAIN -> continue while( true )
            }

            break;  // input OK! -> break while( true ) loop
        }

        txtMessage.textout( "\n" );
        return;
    }
    
    /+ -------------------- 
        input command sub routine
       -------------------- +/
    private bool inputActionSub( Member pl , ref bool escape , ref bool autoFlg )
    {
        char k;
        char c;
        char[] command = [ '?' ,'i' ,'r' ,'t' ,'l' ,'9' ,'e' ,';' ,'7' ,
                           ' ' ,'f' ,'j' ,'h' ,'n' ,'4' ,'1' ,'2' ,'3' ,
                           'p' ,'k' ,'5' ,'u' ,'8' ,'c' ,'s' ,'6' ,'d' ,'9' ,'a' ];


        void dispEncountMonsters()
        {
            setColor( CL.MONSTER );
            txtMessage.textout( "****** encounter ******\n" );
            monParty.disp();
            txtMessage.textout( "***********************\n" );
            return;
        }


        while ( true )
        {
            setColor( CL.NORMAL );
            txtMessage.textout( _( "input action...(%1)\n" ) , pl.name );

            c = 0;
            while( c == 0 )
            {
                k = getChar();
                foreach( com ; command )
                    if( k == com )
                    {
                        if( monParty.suprised && ( k == 'c' || k == 's' || k == 6 ) )
                            break;
                        c = k;
                        break;
                    }
            }

            switch( c )
            {
                case '?':
                    setColor( CL.MENU );
                    txtMessage.textout( _( "************ assigned keys ************\n" ) );
                    txtMessage.textout( _( "f/4:fight, p/5:parry, s/c/6:cast spell,\n" ) );
                    txtMessage.textout( _( "e/7:run, u/8:use, t/9:take back, \n" ) );
                    txtMessage.textout( _( "d/0:dispell, i:monster info\n" ) );
                    txtMessage.textout( _( "r:read spells book, a:auto\n" ) );
                    txtMessage.textout( _( "------ short cut ------\n" ) );
                    txtMessage.textout( _( "j/1:fight1, h/2:fight2, n/3:fight3\n" ) );
                    txtMessage.textout( _( "k:parry, l:take back, ;:run\n" ) );
                    txtMessage.textout( _( "***************************************" ) );
                    txtMessage.textout( "\n" );
                    getChar;
                    break;

                case 'i':   // monster info
                    setColor( CL.MONSTER );
                    monParty.dispMonsterInfo;
                    break;

                case 'r':   // read spell books
                    pl.dispSpellsInBattle();
                    break;

                case 't':   // take back
                case 'l':
                case '9':
                    // モンスター表示して戻る
                    dispEncountMonsters;
                    return false;

                case 'e':   // escape
                case ';':
                case '7':
                    escape = true;
                    return true;

                case 'a':   // auto
                    autoFlg = true;
                    return true;

                default:
                    /+ -------------------- 
                        input command
                       -------------------- +/
                    if( pl.inputAction( c ) )
                        return true;
                    break;
            }

            // モンスター表示して最初に戻る
            dispEncountMonsters;

        }
    }


    /*--------------------
       selectMember - メンバーを選択
       --------------------*/
    Member selectMember( string msg )
    {

        char c;

        txtMessage.textout( msg ~ "\n" );
        while( true )
        {
            c = getChar();
            if ( c == 'z' || c == '9' )
                break;
            if ( c >= '1' && c <= '0' + memCount )
                break;
        }

        if ( c == 'z' || c == '9' )
        {
            txtMessage.textout( c );
            txtMessage.textout( "\n" );
            return null;
        }

        txtMessage.textout( c );
        c -= '1';
        txtMessage.textout( "(" ~ mem[ c ].name ~ ")\n" );
        return mem[ c ];

    }

    /*--------------------
       selectActiveMember - status OK のメンバーを選択
       --------------------*/
    Member selectActiveMember( string msg , string msg_ret )
    {

        char c;

        txtMessage.textout( msg ~ "\n" );
        while( true )
        {
            c = getChar();
            if ( c == 'z' || c == '9' )
                break;
            if ( c >= '1' && c <= '0' + memCount 
                    && mem[ c - '1' ].status == STS.OK )
                break;
        }

        if ( c == 'z' || c == '9' )
        {
            txtMessage.textout( "%1:%2\n" , c , msg_ret );
            return null;
        }

        txtMessage.textout( c );
        c -= '1';
        txtMessage.textout( "(" ~ mem[ c ].name ~ ")\n" );
        return mem[ c ];

    }


    /*--------------------
       selectMemberInBattle - メンバー選択（戦闘時）
       --------------------*/
    Member selectMemberInBattle( int row )
    {
        char c;

        mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 54, _( " who?                   " ) );
        while ( true )
        {
            c = getChar();
            if ( c >= '1' && c <= memCount + '0' )
            {
                mvprintw( CHRW_Y_TOP + row + 1, CHRW_X_TOP + 54, "                        " );
                return party.mem[ c - '1' ];
            }
        }
    }
    
    /*--------------------
       getMemberNoy - メンバーの並び順を取得
       --------------------*/
    int getMemberNo( Member _m )
    {
        foreach( i , m ; mem )
            if( m is _m )
                return to!int( i );
        assert( 0 );
    }
    

    /*--------------------
       getCharList - メンバー選択時の入力可能文字列
       --------------------*/
    string getCharList()
    {
        string list;
        foreach( i ; 0 .. memCount )
            list ~= ( i + 1 ).to!string;
        return list;
    }
        
    /*--------------------
       saveLocate - ダンジョン位置をメンバークラスに記録
                    セーブ時、全滅時に実行
       --------------------*/
    void saveLocate()
    {
        foreach( p ; this )
        {
            p.x = this.x;
            p.y = this.y;
            p.layer = this.layer;
            p.outflag = OUT_F.DUNGEON;
        }
        return;
    }
}
