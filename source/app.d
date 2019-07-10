import std.stdio;

import termbox;
import std.conv : to;
import std.algorithm;
import std.range;
import std.datetime;
import core.thread;

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
    auto ctx = initUI();

    auto width = ctx.screen_dim.x;
    auto height = ctx.screen_dim.y;

    bool paused = false;
    bool command_mode = false;

    Event e;
    v2i crosshair;
    Button b;

    int ycnt;
    int xcnt;

    string word_buffer;
    string input_buffer;
    string command_buffer;

    string command;

    bool exit = false;

    void handle_command()
    {
        command_mode = false;
        command_buffer = command;
        command_buffer.length = 0;

        if (command)
        {
            assert(command[0] == ':');
            if (command.length >= 2)
            {
                command = command[1 .. $];
                switch(command)
                {
                    default:
                        command_buffer = "> Unknown command";
                    break;
                    case "p" :
                        paused = true;
                    break;
                    case "q" :
                        exit = true;
                    break;
                }
                command = null;
            }
        }
    }


    do with(termbox)
    {

//        centered_text("nyautica dataset viewer", width);

        Cell cell;
        cell.fg = Color.green;

        int xpos = -1;
        int xlength = -1;

        tb_peek_event(&e, 10);

        // update_status();

        if (paused)
        {
            printf("%c", e.ch);
            if (e.ch == 'p')
            {
                paused = false;
            }
            goto Lsleep;
        }

        if (e.ch == ':')
            command_mode = true;
        
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

        foreach(int y;0 .. height)
        {
            if (y == 2)
            {
                if (e.ch != 0)
                    word_buffer = "  " ~ "Nyautica matrix dataset analyser" ~ "  ";

                if (e.ch)
                    (command_mode ? command_buffer : input_buffer) ~= e.ch;

                if (e.key == keyboard.Key.enter)
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
                else if (e.key == keyboard.Key.space)
                {
                    (command_mode ? command_buffer : input_buffer) ~= " ";
                }
                else if (e.key == 127)
                {
                    auto buffer = &(command_mode ? command_buffer : input_buffer);
                    if (buffer.length) buffer.length--;
                }
                xlength = cast(int) input_buffer.length;
                xpos = cast(int)((width / 2) - (xlength / 2));
                exit = exit ? exit :
                    (e.key == keyboard.Key.esc || e.key == keyboard.Key.ctrlC || (!command_mode && e.ch == 'q'));
                   
            }
            if (y == 3)
            {
                word_buffer = "  " ~ to!string(e) ~ "  ";
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
            else if (y == height -1)
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

                if ((x >= xpos && x < xpos + xlength) && (y == 2 || y == 3 || y == 4 || (y == height-1 && command_buffer.length > 0)))
                {
                    const buffer = (y == 2 ? input_buffer : word_buffer);  
                    ch = buffer[x - xpos];
                }
                else if (x == crosshair.x || y == crosshair.y)
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
        Thread.sleep(dur!"msecs"(20));
        tb_present();


    } while (!exit);

    termbox.tb_shutdown();
    writeln("termdim = {", width, ", ", height, "}");
}
