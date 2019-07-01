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

struct TUIContext
{
    void centered_line(string text)
    {
       
    }

    void topLine(string text)
    {

    }

    void buttomLine(string text)
    {

    }
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
    termbox.tb_init();
    auto width = termbox.tb_width;
    auto height = termbox.tb_height;

    bool paused = false;
    Event e;
    v2i crosshair;
    Button b;

    int ycnt;
    int xcnt;

    string word_buffer;
    string input_buffer;

    bool exit = false;

    do with(termbox)
    {
        tb_peek_event(&e, 10);

        if (e.ch == 'p')
            paused = !paused;

        tb_select_output_mode(OutputMode.normal);
        //tb_set_cursor(0, 0);
        tb_set_cursor(TB_HIDE_CURSOR, TB_HIDE_CURSOR);

//        centered_text("nyautica dataset viewer", width);

        Cell cell;
        cell.fg = Color.red;

        int xpos = -1;
        int xlength = -1;

        if (paused)
            continue;
/+
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
+/
        foreach(int y;0 .. height)
        {
            if (y == 2)
            {
                if (e.ch != 0)
                    word_buffer = "  " ~ "Nyautica matrix dataset analyser" ~ "  ";

                if (e.ch)
                    input_buffer ~= e.ch;
                if (e.key == keyboard.Key.enter)
                {
                    input_buffer.length = 0;
                }
                else if (e.key == keyboard.Key.space)
                {
                    input_buffer ~= " ";
                }

                xlength = cast(int) input_buffer.length;
                xpos = cast(int)((width / 2) - (xlength / 2));
                exit = 
                    (e.key == keyboard.Key.esc || e.key == keyboard.Key.ctrlC || e.ch == 'q');
                   
            }
            if (y == 3)
            {
                word_buffer = "  " ~ to!string(e) ~ "  ";
                //word_buffer = "The password is shellfish";
                xlength = cast(int) word_buffer.length;
                xpos = cast(int)((width / 2) - (word_buffer.length / 2));
            }
            foreach(int x;0 .. width)
            {
                wchar ch = ' ';
/+
                char ch = ('0' + (x % 10));
                if (x == 0)
                {
                    ch = ('0' + (y % 10));
                }
                else
+/
/+                
                if (x == crosshair.x || y == crosshair.y)
                {
                    ch = '+';
                }
+/
                if ((x >= xpos && x < xpos + xlength) && (y == 2 || y == 3))
                {
                    const buffer = (y == 2 ? input_buffer : word_buffer);  
                    ch = buffer[x - xpos];
                }
                else if (y == (ycnt++ % (height - 1)))
                {
                    ch = ' ';
                }
                cell.ch = ch;
                tb_put_cell(x, y, &cell);
            }
        }

        Thread.sleep(dur!"msecs"(20));
        tb_present();
        
       


    } while (!exit);

    termbox.tb_shutdown();
    writeln("termdim = {", width, ", ", height, "}");
}
