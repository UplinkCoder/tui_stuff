import std.stdio;

import termbox;
import std.conv : to;
import std.algorithm;
import std.range;
import std.datetime;
import core.thread;
import util;

version (ArenaAllocate)
{
struct ArenaChunk
{
    void* memory;

    ArenaChunk* next;

    uint free;
    uint used;

    uint chunkIndex;
    uint allocCount;

    Arena* arena;
}

struct Arena
{
    string name;

    @NoPrint ArenaChunk[8] chunkCache;
    ArenaChunk[] chunks;

    int freeInLastChunk;
    uint used;
    uint chunkSize = ushort.max * 2;

    void* allocate(int size, string filename = "", int line = 0)
    {
        ArenaChunk* chunk = null;
        size = (size + 16) & ~16;
        void* returnPointer = null;
        int neededChunks = (size + chunkSize) / chunkSize;

        if (freeInLastChunk >= size)
        {
            chunk = &chunks[$-1];
            returnPointer = chunks[$-1].memory + chunk.used;
        LchunkHasSpace:
            int uses = 
                size - ((neededChunks - 1) * chunkSize);

            assert(uses <= chunkSize);

            chunk = chunk ? chunk : &chunks[$-1];
            if (chunk.used == 0 && chunk.free == 0)
            {
                chunk.free = chunkSize;
            }
            chunk.free -= uses;
            chunk.used += uses;
            chunk.allocCount++;
            freeInLastChunk = chunk.free;
        }
        else // in this case we need to allocate new chunks
        {
            auto chunkIndex = chunks.length;
            if (chunks.length + neededChunks <= chunkCache.length)
            {
                chunks = chunkCache[0 .. chunks.length + neededChunks];
            }
            else
            {
                // we've run out of chunkCache
                // let's go the slow-poke-druntime path for now
                chunks.length += neededChunks;
            }
            import core.stdc.stdlib : calloc;
            auto chunkMem = calloc(chunkSize, neededChunks);
            returnPointer = chunkMem;

            foreach(nc;0 .. neededChunks)
            {
                chunks[chunkIndex + nc].memory = chunkMem;
                chunkMem += chunkSize;
            }

            goto LchunkHasSpace;
        }

        this.used += size;

        assert(returnPointer, "Allocate is fucked");
        
        return returnPointer;
    }

    string arenaStats()
    {
        return structToString(this);
    }
}
}
struct TrieNode
{
    string data;
    TrieNode*[26 + 10] children;
    bool leaf;
}

alias AllocFn = void* function(int, string = "", int = 0);

struct Trie
{
    TrieNode root;
    version (ArenaAllocate)
    {
        Arena* arena;
    }

    string[] matchingPrefix(TrieNode *prefix_node)
    {
        string[] result; 

        if (prefix_node !is null)
        {
            auto node = *prefix_node;
            if (node.data)
            {
                result ~= node.data;
                goto Lloop;
            }
            else 
                Lloop: foreach(child;node.children)
            {
                result ~= matchingPrefix(child);
            }
        }

        return result;
    }

    TrieNode* findPrefix(string prefix)
    {
        import std.ascii : toLower;
        alias lowerASCII = std.ascii.toLower;

        TrieNode* test = &root;

        foreach(c;prefix)
        {
            if (test)
                test = test.children[lowerASCII(c) - 'a'];
            else
                break;
        }

        return test;
    }

    auto addWord(string word)
    {
        StopWatch sw;
        sw.start();
        TrieNode* n = &root;
        TrieNode* new_node = null;
        import std.ascii : toLower;
        alias lowerASCII = std.ascii.toLower;
        char c;

        foreach(char _c;word)
        {
            c = cast(char)(lowerASCII(_c) - 'a');
            if (n.children[c])
            {
                n = n.children[c];
            }
            else
            {
                version(ArenaAllocate)
                {
                    new_node = cast(TrieNode*) arena.allocate(TrieNode.sizeof);
                    *new_node = (*new_node).init;
                }
                else
                {
                    new_node = new TrieNode;
                }
                n.children[c] = new_node;
                n = new_node;
            }
        }
        n.data = word;
        sw.stop();
        return sw.peek();
    }

    void remove(TrieNode* node)
    {

    }

    string printTrie()
    {
        return matchingPrefix(&root).join(", "); 
    }
}

static immutable figure =
[ "    *    ",
  "   * *   ",
  "  *   *  ",
  " *     * ",
  "*********" ];  

// import derelict.imgui.imgui;

import std.file : dirEntries;

struct SizeBox
{
    v2i dim;
} 

struct v2i
{
    union 
    {
        struct 
        {
            int x = 0;
            int y = 0;
        }
        int[2] E;
    }
}

struct rectangle2i
{
    v2i min;
    v2i max;
}


struct TUIContext
{
    v2i screen_dim;
    rectangle2i modified_region;

    void centeredLine(string text)
    {
       
    }

    void topLine(string text)
    {

    }

    void buttomLine(string text)
    {

    }


}


TUIContext initUI()
{
    TUIContext ctx;

 
    bool isAlreadyInitialzed =
        termbox.tb_width() >= 0;


    assert(!isAlreadyInitialzed); 

    termbox.tb_init();
    termbox.tb_select_input_mode(InputMode.mouse | InputMode.alt);

    auto width = termbox.tb_width();
    auto height = termbox.tb_height();

    ctx.screen_dim.x = width;
    ctx.screen_dim.y = height;

    return ctx;
}

enum full_block_char = '\u2588';
enum heart_char = '\u2764';

enum Button
{
    Up,
    Down,
    Enter
}

void main(string[] args)
{
    term_ui(args);
}


void term_ui(string[] args)
{
    version (ArenaAllocate)
    {
        Arena trieArena = Arena("TrieArena");
    }

    auto ctx = initUI();

    auto width = ctx.screen_dim.x;
    auto height = ctx.screen_dim.y;

    bool paused = false;
    bool command_mode = false;
    bool crosshair_shown = false;

    Event e;
    Event lastEvent;

    v2i crosshair;
    Button b;

    int ycnt;
    int xcnt;

    string message_buffer;
    string word_buffer;
    string input_buffer;
    string command_buffer;

    string command;

    version (ArenaAllocate)
    {
        Trie* trie  = cast(Trie*) trieArena.allocate(Trie.sizeof);
        *trie = (*trie).init;
        trie.arena = &trieArena;
    }
    else
    {
        Trie trie;
    }
    bool exit = false;

    static string history(string buffer, string[] history_list)
    {
        string result = null;

        if (!history_list.length)
        {
            result = buffer;
        }

        return result;
    }


    static immutable string[] command_list =
    [
        "add",
        "findPrefix",
        "print",
        "q",
        "p",
        "arenaStats",
        "center",
        "crosshair"
    ];

    static string tab_complete(string buffer, const string[] word_list)
    {
        string result = null;

        if (!buffer.length)
            result = word_list[0];
        // TODO PERFORMANCE: change to prefix tree or trie search
        // instead of doing foreach
        foreach(i, word;word_list)
        {
            if (buffer == word)
            {
                result = word_list[(i + 1) % word_list.length];
                break;
            }
            else if (word.startsWith(buffer))
            {
                result = word;
                break;
            }
        }

        return result;
    }

    void handle_command()
    {
        command_mode = false;
        command = command_buffer;
        command_buffer.length = 0;

        if (command)
        {
            assert(command[0] == ':');
            if (command.length >= 2)
            {
                command = command[1 .. $];
                auto split = command.split(' ');
                command = split[0];
                auto args = split[1 .. $];

                message_buffer = "Command: '" ~ command ~ "'";
                switch(command)
                {
                    default:
                        command_buffer = "> Unknown command ...";
                    break;
                    case "p" :
                        paused = true;
                    break;
                    case "center" :
                        crosshair.x = ctx.screen_dim.x / 2;
                        crosshair.y = ctx.screen_dim.y / 2;
                    break;
                    case "crosshair" :
                        crosshair_shown = !crosshair_shown;
                    break;
                    version (ArenaAllocate)
                    {
                        case "arenaStats" :
                            message_buffer = trieArena.arenaStats();
                        break;
                    }
                    case "add" :
                    {
                        if (args.length == 1)
                        {
                            auto word = args[0]; 
                            message_buffer = "Adding word: '" ~ word ~ "'";
                            auto time_taken = trie.addWord(word);
                            message_buffer = structToString(time_taken);
                        }
                        else
                        {
                            message_buffer = "Invalid args for addWord command";
                        }
                    }
                    break;
                    case "print" :
                    {
                        message_buffer = trie.printTrie();
                    }
                    break;
                    case "findPrefix" :
                    {
                        if (args.length == 1)
                        {
                            auto word = args[0]; 
                            message_buffer = " findPrefix: '" ~ word ~ "'";
                            auto prefix_node = trie.findPrefix(word);
                            if (prefix_node)
                            {
                                message_buffer = trie.matchingPrefix(prefix_node).join(", ");
                            }
                            else
                            {
                                message_buffer = "Prefix '" ~ word ~ "' not found";
                            }
                        }
                        else
                        {
                            message_buffer = "Invalid args for findPrefix command";
                        }
                    }
                    break;
                    case "q" :
                        exit = true;
                    break;
                }
                command = null;
            }
        }
    }

    static immutable defaultEvent = Event(EventType.key);


    do with(termbox)
    {

//        centered_text("nyautica dataset viewer", width);

        Cell cell;
        cell.fg = Color.green;

        int xpos = -1;
        int xlength = -1;

        tb_peek_event(&e, 10);


        /// don't show the default event

        if (e != defaultEvent && e != lastEvent)
        {
            lastEvent = e;
        }

        // update_status();

        if (paused)
        {
            if (e.type != 3 && e.ch == 'p')
            {
                paused = false;
            }
            goto Lsleep;
        }

        if (e.type == 2) // resize event
        {
            width = e.w;
            height = e.h;
        }
/+
        if (command_mode && e.type != 3 && e.key == Key.arrowUp)
        {
            auto history_result = history(command_buffer[1 .. $], history_list);
            if (history_result)
            {
                command_buffer = ":" ~ history_result;
            }
        }
+/
        if (!command_mode && e.type != 3 && e.ch == ':')
        {
            command_mode = true;
            command_buffer.length = 0;
        }

        if (command_mode && e.type != 3 && e.key == Key.tab)
        {
            auto complete_result = tab_complete(command_buffer[1 .. $], command_list);
            if (complete_result)
            {
                command_buffer =  ":" ~ complete_result;
            }
        }
        
        tb_select_output_mode(OutputMode.normal);
        //tb_set_cursor(0, 0);
        tb_set_cursor(TB_HIDE_CURSOR, TB_HIDE_CURSOR);


        if (e.key == Key.arrowDown)
        {
            crosshair.y += 1;
        }

        if (e.key == Key.arrowUp)
        {
            crosshair.y -= 1;
        }

        if (e.key == Key.arrowRight)
        {
            crosshair.x += 1;
        }

        if (e.key == Key.arrowLeft)
        {
            crosshair.x -= 1;
        }

        {
            if (e.ch == 0)
                word_buffer = "  " ~ "Nyautica matrix dataset analyser" ~ "  ";
            
            if (e.type != EventType.mouse && e.ch)
                (command_mode ? command_buffer : input_buffer) ~= e.ch;

            if (e.type != EventType.mouse && e.key == keyboard.Key.enter)
            {
                if (command_mode)
                {
                    handle_command();
                }
                else
                {
                    input_buffer.length = 0;
                }
            }
            else if (e.type != 3 && e.key == keyboard.Key.space)
            {
                (command_mode ? command_buffer : input_buffer) ~= " ";
            }
            else if (e.type != 3 && e.key == 127)
            {
                auto buffer = &(command_mode ? command_buffer : input_buffer);
                if (command_mode ? buffer.length > 1 : buffer.length) buffer.length--;
            }
        }

        foreach(int y;0 .. height)
        {
            if (y == 2)
            {
                xlength = cast(int) input_buffer.length;
                xpos = cast(int)((width / 2) - (xlength / 2));
            }
            if (y == 3)
            {
                word_buffer = "  " ~ structToString(lastEvent) ~ "  ";
                //word_buffer = "The password is shellfish";
                xlength = cast(int) word_buffer.length;
                xpos = cast(int)((width / 2) - (word_buffer.length / 2));
            }
            else if (y == 4)
            {
                word_buffer = "Status {command_mode: " ~ command_mode.to!string ~ ", paused: " ~ paused.to!string ~ "}";
                xlength = cast(int) word_buffer.length;
                xpos = cast(int)((width / 2) - (word_buffer.length / 2));
            }
            else if (y == 5)
            {
                word_buffer = message_buffer;
                xlength = cast(int) word_buffer.length;
                xpos = cast(int)((width / 2) - (word_buffer.length / 2));
            }
            else if (y == height - 2)
            {
                import core.memory;
                auto gc_stats = GC.stats();
                word_buffer = structToString(gc_stats);
                xlength = cast(int) word_buffer.length;
                xpos = cast(int)((width / 2) - (word_buffer.length / 2));
            }
            else if (y == height - 1)
            {
                if (command_buffer.length > 0)
                {
                    word_buffer = command_buffer;
                    xlength = cast(int) word_buffer.length;
                    xpos = 2;
                }
            }
            foreach(int x;0 .. width)
            {
                wchar ch = ' ';

                if ((x >= xpos && x < xpos + xlength) && (y == 2 || y == 3 || y == 4 || y == 5 || y == height-2 ||(y == height-1 && command_buffer.length > 0)))
                {
                    const buffer = (y == 2 ? input_buffer : word_buffer);  
                    ch = buffer[x - xpos];
                }
                else if (crosshair_shown && (x == crosshair.x || y == crosshair.y))
                {
                    ch = '+';
                }
                else if (y == (ycnt++ % (height - 1)))
                {
                    ch = ' ';
                }
                cell.ch = ch;
                tb_put_cell(x, y, &cell);
            }
        }
    Lsleep:
        import core.memory;
        GC.collect();
        GC.minimize();
        Thread.sleep(dur!"msecs"(20));
        tb_present();


    } while (!exit);

    termbox.tb_shutdown();
    writeln("last Event: ", e);
    writeln("termdim = {", width, ", ", height, "}");
}
