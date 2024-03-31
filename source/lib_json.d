
import std.stdio;
import std.file;
import std.json;


class Json
{

private:
    string filename;

public:

    JSONValue json;

    alias json this;

    this()
    {
        this("");
        return;
    }
    this( JSONValue j )
    {
        json = j;
        return;
    }
    this(string f)
    {
        filename = f;

        if( exists( filename ) )
            // JSONファイルを取得
            json = parseJSON( readText( filename ) );

        return;
    }

    // 配列追加
    void addList( T )( string k , T v )
    {
        if( k in json )
        {
            json[ k ].array ~= JSONValue( v );
        }
        else
        {
            JSONValue a;
            a.array = [];
            a.array ~= JSONValue( v );
            json[ k ] = a;
        }
        return;
    }

    // 子ノードの追加
    void setChild( string k , Json j )
    {
        json[ k ] = parseJSON( j.obj.toString );
        return;
    }
    // 子ノード取得
    Json getChild( string k )
    {
        JSONValue j;
        j = json[ k ].object;
        return new Json( j );
    }



    void write()
    in
    {
        assert( filename.length > 0 );
    }
    body
    {
        // JSONファイルを出力
        File( filename , "w" ).writeln( json.toString );
        return;
    }

    JSONValue obj()
    {
        return json;
    }

/+
    // 値更新のテスト
    writeln( json[ "title" ].str );
    json[ "title" ] = "test";
    writeln( json[ "title" ].str );

    // 値取得のテスト
    writeln( json[ "number" ].integer );
    writeln( json[ "pie" ].floating );
    writeln( json[ "item" ].array );

    // 値追加のテスト
    json[ "test_appned" ] = "done.";

    // 値追加（リスト）のテスト
    json[ "item" ].array ~= JSONValue("D");
    writeln( json[ "item" ].array );

    // 値取得（リスト）のテスト
    foreach(  s ; json[ "item" ].array ){
        writeln( s.str );   // JSONValue
    }

    // オブジェクト取得・更新のテスト
    JSONValue json2 = json[ "child" ].object;
    writeln( json2[ "key01" ].str );
    json2[ "key99" ] = "DATA99";

    // JSONファイルを出力
    // json2 も同様に更新されているようである。
    File( FILENAME , "w" ).writeln( json.toString );

{
    "title" : "jsontest",
    "number" : 12345,
    "pie" : 3.14159,
    "item" : [ "a","b","c" ],
    "child" : { "key01" : "data01" , "key02" : "data02" }

}

+/

}

