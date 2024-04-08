// Phobos Runtime Library
import std.stdio;
import std.string;
import std.conv;

// derelict SDL
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.ttf;

// my source
import lib_screen;
import def;


/**--------------------
   mySDL - SDL管理用
   --------------------*/
class MySDL
{

private:

    string window_name = "SDL";
    /* int window_width  = WINDOW_WIDTH; */
    /* int window_height = WINDOW_HEIGHT; */
    int window_width;
    int window_height;

    // draw color
    ubyte color_r = 20;
    ubyte color_g = 20;
    ubyte color_b = 20;
    ubyte color_a = 0;

    SDL_Window*     Window;
    SDL_Renderer*   renderer;

public:
    // keyboard stasus
    bool shiftkey = false;
    bool ctrlkey = false;

    this()
    {
        this( window_name);
    }
    this( string windowName )
    {

        window_width  = WINDOW_WIDTH;
        window_height = WINDOW_HEIGHT;

        DerelictSDL2.load();
        DerelictSDL2Image.load();
        DerelictSDL2ttf.load();

        SDL_Init(SDL_INIT_EVERYTHING);

        // ウィンドウを生成する
        Window = SDL_CreateWindow(
                /* toStringz(args[0]),     // とりあえずプロセス名 */
                toStringz( windowName ),  
                SDL_WINDOWPOS_CENTERED, // 中央表示
                SDL_WINDOWPOS_CENTERED, // 中央表示
                window_width,
                window_height,
                SDL_WINDOW_SHOWN);     // 最初から表示
        
        // レンダラーコンテキストを取得
        renderer = SDL_CreateRenderer( Window , -1 , 0 );

        return;
    }

    this( int w , int h )
    {
        window_width = w;
        window_height = h;
        this();
        return;
    }

    ~this()
    {
        /* if( ttfInitDone ) */
        /*     TTF_Quit(); */
        SDL_DestroyWindow( Window );
        SDL_DestroyRenderer( renderer );
        SDL_Quit();
    }

    /*--------------------
       InitScreen - スクリーン管理用クラス初期化
       --------------------*/
    Screen InitScreen()
    {
        // スクリーン→フォント を作成
        return new Screen( this , renderer );
    }

    /+
    // 画像よりテクスチャを作成
    Texture createTexture( string img , ubyte colorMod = 255 )
    {
        return new Texture( img , renderer 
                , false , colorMod );
    }
    // 画像よりテクスチャを作成（透過あり）
    Texture createTextureWithAlpha( string img , ubyte colorMod = 255 )
    {
        return new Texture( img , renderer 
                , true , colorMod );
    }
    +/


    /*--------------------
       setDrawColor - 背景色を設定
       --------------------*/
    void setDrawColor( ubyte r , ubyte g , ubyte b , ubyte a )
    {
        color_r = r;
        color_g = g;
        color_b = b;
        color_a = a;

        //ウィンドウを背景色で塗りつぶす　つまり消去
        SDL_SetRenderDrawColor( renderer, 
                color_r , color_g , color_b , color_a );

        return;
    }

    /*--------------------
       renderClear - レンダー初期化`
       --------------------*/
    void renderClear()
    {
        SDL_RenderClear( renderer );
        return;
    }


    /*--------------------
       disp - 画面表示
       --------------------*/
    void disp()
    {
        /* 画面表示 */
        SDL_RenderPresent( renderer );

        // gsdl.delay( 1 );

        return;
    }

    /*--------------------
       delay - wait処理
       --------------------*/
    void delayFPS()
    {
        static bool first = true;
        static Uint64 performanceFrequency;
        static Uint64 countPerFrame;
        static Uint64 frameStart;

        if( first )
        {
            first = false;
            // 1フレーム当たりのパフォーマンスカウンタ値計算。FPS制御のために使用する。
            performanceFrequency = SDL_GetPerformanceFrequency();
            countPerFrame = performanceFrequency / FPS;
            frameStart = SDL_GetPerformanceCounter();
        }

        // 次フレームまで待機
        immutable drawDelay = SDL_GetPerformanceCounter() - frameStart;
        if(countPerFrame < drawDelay) {
            SDL_Delay(0);
        } else {
            SDL_Delay(cast(uint)((countPerFrame - drawDelay) * 1000 / performanceFrequency));
        }

        // 次回カウンター用
        frameStart = SDL_GetPerformanceCounter();

        return;
    }


    /*--------------------
       delay - wait処理
       --------------------*/
    void delay( int wait )
    {
        if( wait != 0 )
            SDL_Delay( wait );
        return;
    }

    /*--------------------
       GetTicks - 時間取得
       --------------------*/
    uint GetTicks()
    {
        return SDL_GetTicks();
    }

    /*--------------------
       GetRenderer - レンダラー取得
       --------------------*/
    SDL_Renderer* GetRenderer()
    {
        return renderer;
    }
    
    /**--------------------
       inkey - キーボード入力(1文字取得)
       --------------------*/
    char inkey( int timeout , ref bool quit )
    {

        ulong ticks;
        string ch = "";

        ticks = GetTicks;

        while( ch.length == 0 )
        {
            // キューに溜まったイベントを処理
            for(SDL_Event e; SDL_PollEvent(&e);) 
            {
                switch(e.type) 
                {
                    // 終了イベント
                    case SDL_QUIT:
                        quit = true;
                        return 0;       // 抜ける
                    case SDL_KEYUP:
                    case SDL_KEYDOWN:
                        ch = keyInput( e );

                        /* if( ch == "@" ) */
                        /*     scr.debugDisp; */
                        /* if( ch == "#" ) */
                        /*     scr.debugDispColor; */

                        break;
                    default:
                        break;
                }
            }

            scr.disp;

            // check Timeout
            if( timeout >= 0 && timeout < GetTicks - ticks )
            {
                ch = "";
                ch ~= to!char( 0 );
                break;
            }

        }

        assert( ch.length > 0 , "ch.length error" );
        assert( ch[ 0 ] < char.max );

        return cast(char)ch[ 0 ];
    }

    /*--------------------
       keyInput - キーボード入力(1文字取得 / SDLイベント 処理)
       --------------------*/
    string keyInput( SDL_Event e )
    {
        string ch = "";

        if( e.type == SDL_KEYUP )
            switch( e.key.keysym.sym )
            {
                case SDLK_RSHIFT:
                case SDLK_LSHIFT:
                    shiftkey = false;
                    break;
                case SDLK_RCTRL:
                case SDLK_LCTRL:
                    ctrlkey = false;
                    break;
                default:
                    break;
            }
        else if( e.type == SDL_KEYDOWN )
        {
            if( ctrlkey )
                ch ~= "^";

            switch( e.key.keysym.sym )
            {

                case SDLK_RSHIFT:
                case SDLK_LSHIFT:
                    shiftkey = true;
                    break;
                case SDLK_RCTRL:
                case SDLK_LCTRL:
                    ctrlkey = true;
                    break;


                case SDLK_RIGHT:    ch ~= RIGHT_ARROW   ; break;
                case SDLK_LEFT:     ch ~= LEFT_ARROW    ; break;
                case SDLK_DOWN:     ch ~= DOWN_ARROW    ; break;
                case SDLK_UP:       ch ~= UP_ARROW      ; break;

                case SDLK_a: ch ~= shiftkey ? "A" : "a" ; break;
                case SDLK_b: ch ~= shiftkey ? "B" : "b" ; break;
                case SDLK_c: ch ~= shiftkey ? "C" : "c" ; break;
                case SDLK_d: ch ~= shiftkey ? "D" : "d" ; break;
                case SDLK_e: ch ~= shiftkey ? "E" : "e" ; break;
                case SDLK_f: ch ~= shiftkey ? "F" : "f" ; break;
                case SDLK_g: ch ~= shiftkey ? "G" : "g" ; break;
                case SDLK_h: ch ~= shiftkey ? "H" : "h" ; break;
                case SDLK_i: ch ~= shiftkey ? "I" : "i" ; break;
                case SDLK_j: ch ~= shiftkey ? "J" : "j" ; break;
                case SDLK_k: ch ~= shiftkey ? "K" : "k" ; break;
                case SDLK_l: ch ~= shiftkey ? "L" : "l" ; break;
                case SDLK_m: ch ~= shiftkey ? "M" : "m" ; break;
                case SDLK_n: ch ~= shiftkey ? "N" : "n" ; break;
                case SDLK_o: ch ~= shiftkey ? "O" : "o" ; break;
                case SDLK_p: ch ~= shiftkey ? "P" : "p" ; break;
                case SDLK_q: ch ~= shiftkey ? "Q" : "q" ; break;
                case SDLK_r: ch ~= shiftkey ? "R" : "r" ; break;
                case SDLK_s: ch ~= shiftkey ? "S" : "s" ; break;
                case SDLK_t: ch ~= shiftkey ? "T" : "t" ; break;
                case SDLK_u: ch ~= shiftkey ? "U" : "u" ; break;
                case SDLK_v: ch ~= shiftkey ? "V" : "v" ; break;
                case SDLK_w: ch ~= shiftkey ? "W" : "w" ; break;
                case SDLK_x: ch ~= shiftkey ? "X" : "x" ; break;
                case SDLK_y: ch ~= shiftkey ? "Y" : "y" ; break;
                case SDLK_z: ch ~= shiftkey ? "Z" : "z" ; break;
                case SDLK_1: ch ~= shiftkey ? "!" : "1" ; break;
                case SDLK_2: ch ~= shiftkey ? "@" : "2" ; break;
                case SDLK_3: ch ~= shiftkey ? "#" : "3" ; break;
                case SDLK_4: ch ~= shiftkey ? "$" : "4" ; break;
                case SDLK_5: ch ~= shiftkey ? "%" : "5" ; break;
                case SDLK_6: ch ~= shiftkey ? "^" : "6" ; break;
                case SDLK_7: ch ~= shiftkey ? "&" : "7" ; break;
                case SDLK_8: ch ~= shiftkey ? "*" : "8" ; break;
                case SDLK_9: ch ~= shiftkey ? "(" : "9" ; break;
                case SDLK_0: ch ~= shiftkey ? ")" : "0" ; break;
                case SDLK_MINUS:        ch ~= shiftkey ? "_" : "-" ; break;
                case SDLK_EQUALS:       ch ~= shiftkey ? "+" : "=" ; break;
                case SDLK_COMMA:        ch ~= shiftkey ? "<" : "," ; break;
                case SDLK_PERIOD:       ch ~= shiftkey ? ">" : "." ; break;
                case SDLK_SEMICOLON:    ch ~= shiftkey ? ":" : ";" ; break;
                case SDLK_QUOTE:        ch ~= shiftkey ? "\"": "'" ; break;
                case SDLK_SLASH:        ch ~= shiftkey ? "?" : "/" ; break;
                case SDLK_LEFTBRACKET:  ch ~= shiftkey ? "{" : "[" ; break;
                case SDLK_RIGHTBRACKET: ch ~= shiftkey ? "}" : "]" ; break;
                case SDLK_BACKSLASH:    ch ~= shiftkey ? "|" : "\\" ; break;
                case SDLK_BACKQUOTE:    ch ~= shiftkey ? "~" : "`" ; break;
                case SDLK_BACKSPACE:    ch ~= "BS"; break;
                case SDLK_SPACE:        ch ~= " "; break;
                case SDLK_RETURN:       ch ~= "\n"; break;
                default:
                     break;
            }

        }

        return ch;
    }

}

