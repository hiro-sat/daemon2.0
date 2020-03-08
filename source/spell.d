// vim: set nowrap :

// Phobos Runtime Library
import std.stdio;
import std.string : isNumeric ;
import std.conv;
/* import std.file; */
/* import std.random; */

/* // derelict SDL */
/* import derelict.sdl2.sdl; */

// mysource 
import def;
import app;
import cMember;
import cBattleTurn;

/* import lib_sdl; */
/* import lib_screen; */


void camp_spell_sub( int mag )
{
    int target, nPoints, total, plus;
    int xpos, ypos, layer;

    string numtext;

    Member mem;

    if ( magic_data[ mag ].camp == 2 )
    { // select member
        textout( "to whom?: " );
        while ( true )
        {
            target = getChar() - '1';
            if (target >= 0 && target < party.num)
                break;
        }
        textout( to!char( target + '1' ) );
        textout( "(" ~ party.mem[ target ].name ~ ")" );
        textout( '\n' );
    }
    mem = party.mem[ target ];


    switch ( magic_data[ mag ].type )
    {
        case MAG_TYPE.MAPPER :
            party.setMapper;
            party.setScope;
            party.scopeCount += 1;
            textout( "done.\n" );
            header_disp( HSTS.CAMP );
            break;
        case MAG_TYPE.MILWA :       // flash
            party.setLight;
            party.lightCount += S_LIGHT_COUNT;
            party.setScope;
            party.scopeCount += S_SCOPE_COUNT;
            textout( "done.\n" );
            header_disp( HSTS.CAMP );
            break;
        case MAG_TYPE.LOMILWA :     // shine
            party.setLight;
            party.lightCount += L_LIGHT_COUNT;
            party.setScope;
            party.scopeCount += L_SCOPE_COUNT;
            textout( "done.\n" );
            header_disp(HSTS.CAMP);
            break;
        case MAG_TYPE.LITO :        // float
            party.setFloat;
            textout( "done.\n" );
            header_disp( HSTS.CAMP );
            break;
        case MAG_TYPE.LATUMA :      // identify
            party.setIdentify;
            textout( "done.\n" );
            header_disp( HSTS.CAMP );
            break;
        case MAG_TYPE.KADOR :       // resurrection
            if ( ! ( mem.status != STS.DEAD || mem.status != STS.ASHED ) )
            {
                textout( "  what?\n" );
            }
            else
            {
                total = mem.vit[ 0 ] + mem.vit[ 1 ]
                      + mem.luk[ 0 ] + mem.luk[ 1 ];
                total /= 2;
                if ( total <= 3 )
                    plus =  - 2;
                else if ( total <= 5 )
                    plus =  - 1;
                else if ( total <= 15 )
                    plus = 0;
                else if ( total <= 16 )
                    plus = 1;
                else if ( total <= 17 )
                    plus = 2;
                else
                    plus = 3;

                if ( mem.status == STS.ASHED )
                {
                    plus += 5; // possibility of resurrection is 1/3(ASHED) if plus=0
                }
                else
                {
                    plus += 14; // possibility of resurrection is 14/19(DEAD) if plus=0
                }

                if ( get_rand( 18 ) <= plus )
                {
                    textout( "  * ok *\n" );
                    mem.status = STS.OK;
                    mem.hp = mem.maxhp;
                }
                else
                {
                    textout( "  oops!!\n" );
                    if ( mem.status == STS.ASHED )
                        mem.status = STS.LOST;
                    else
                        mem.status = STS.ASHED;
                }
                mem.vit[ 0 ]--;
            }
            party.win_disp();
            break;
        case MAG_TYPE.DI :
            if ( mem.status != STS.DEAD )
            {
                textout( "  what?\n" );
            }
            else
            {
                total = mem.vit[ 0 ] + mem.vit[ 1 ]
                      + mem.luk[ 0 ] + mem.luk[ 1 ];
                total /= 2;
                if ( total <= 3 )
                    plus =  - 2;
                else if ( total <= 5 )
                    plus =  - 1;
                else if ( total <= 15 )
                    plus = 0;
                else if ( total <= 16 )
                    plus = 1;
                else if ( total <= 17 )
                    plus = 2;
                else
                    plus = 3;

                if ( get_rand( 18 ) <= 11 + plus )
                { // possibility of resurrection is 2/3 if plus=0
                    textout( "  * ok *\n" );
                    mem.status = STS.OK;
                    mem.hp = 1;
                }
                else
                {
                    textout( "  oops!!\n" );
                    mem.status = STS.ASHED;
                }
                mem.vit[ 0 ]--;
            }
            party.win_disp();
            break;
        case MAG_TYPE.HEALONE :
            if ( mem.status < STS.DEAD )
            {
                nPoints = magic_data[ mag ].min + get_rand( magic_data[ mag ].add );
                if ( mem.hp + nPoints >= mem.maxhp )
                    mem.hp = mem.maxhp;
                else
                    mem.hp += nPoints;
            }
            party.win_disp();
            break;
        case MAG_TYPE.HEALALL:
            for ( target = 0; target < party.num; target++ )
            {
                if ( mem.status < STS.DEAD)
                {
                    nPoints = magic_data[ mag ].min + get_rand( magic_data[ mag ].add );
                    if ( mem.hp + nPoints >= mem.maxhp )
                        mem.hp = mem.maxhp;
                    else
                        mem.hp += nPoints;
                }
            }
            party.win_disp();
            break;
        case MAG_TYPE.MAPOR :       // ac - 2
            party.ac =  - 2;
            party.win_disp();
            header_disp( HSTS.CAMP );
            break;
        case MAG_TYPE.CUREPOI :     // cure poison
            mem.poisoned = false;
            party.win_disp();
            break;
        case MAG_TYPE.CUREPAR :     // cure paralyze
            if ( mem.status <= STS.PARALY )
                mem.status = STS.OK;
            party.win_disp();
            break;
        case MAG_TYPE.MADI :        // cure stone
            if ( mem.status <= STS.STONED  )
            {
                mem.status = STS.OK ;
                mem.hp = mem.maxhp;
                party.win_disp();
            }
            break;
        case MAG_TYPE.LOKTO :       // return castle
            party.x = 1;
            party.y = 2;
            party.layer = 0;
            textout( "teleport to the castle!\n" );
            break;
        case MAG_TYPE.MALOR :       // teleport
            textout( "\n*** where do you want to teleport? ***\n" );

        XPOS:
            textout( "enter xpos(z:leave): \n" );
            numtext = tline_input(  3 , text_cury + TXTW_Y_TOP, text_curx + TXTW_X_TOP );
            textout( ">" );
            textout( numtext );
            textout( "\n" );

            if ( numtext.length == 0 || numtext[ 0 ] == 'z' )
            {
                textout( "quit.\n" );
                break;
            }

            if( ! isNumeric( numtext ) )
            {
                textout( "what?\n" );
                goto XPOS;
            }

            xpos = to!int( numtext );

            if( xpos < 0 || xpos >= MAP_MAX_X )
            {
                textout( "what?\n" );
                goto XPOS;
            }

        YPOS:
            textout("enter ypos(z:enter xpos again): \n");

            numtext = tline_input(  3 , text_cury + TXTW_Y_TOP, text_curx + TXTW_X_TOP );
            textout( ">" );
            textout( numtext );
            textout( "\n" );

            if ( numtext.length == 0 || numtext[ 0 ] == 'z' )
                goto XPOS;

            if( ! isNumeric( numtext ) )
            {
                textout( "what?\n" );
                goto YPOS;
            }

            ypos = to!int( numtext );

            if( ypos < 0 || ypos >= MAP_MAX_Y )
            {
                textout( "what?\n" );
                goto YPOS;
            }

        LAYER:
            textout( "enter layer(z:enter ypos again): \n" );
            numtext = tline_input(  3 , text_cury + TXTW_Y_TOP, text_curx + TXTW_X_TOP );
            textout( ">" );
            textout( numtext );
            textout( "\n" );

            if ( numtext.length == 0 || numtext[ 0 ] == 'z' )
                goto YPOS;

            if( ! isNumeric( numtext ) )
            {
                textout( "what?\n" );
                goto LAYER;
            }

            layer = to!int( numtext );

            if( layer < 0 || layer >= MAXLAYER )
            {
                textout( "what?\n" );
                goto LAYER;
            }


            party.x     = to!byte( xpos );
            party.y     = to!byte( ypos );
            party.layer = to!byte( layer );

            textout( "done.\n" );
            header_disp( HSTS.CAMP );
            party.win_disp();
            break;
        default :
            assert( 0 );
    }
    return;
}



