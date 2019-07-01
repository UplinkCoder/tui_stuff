# Termbox

This is a wrapper of the TUI library [Termbox](https://github.com/nsf/termbox). 

From the termbox Readme:

Termbox is a library that provides minimalistic API which allows the programmer to write text-based user interfaces.

It is based on a very simple abstraction. The main idea is viewing terminals as a table of fixed-size cells and input being a stream of structured messages. Would be fair to say that the model is inspired by windows console API. The abstraction itself is not perfect and it may create problems in certain areas. The most sensitive ones are copy & pasting and wide characters (mostly Chinese, Japanese, Korean (CJK) characters). When it comes to copy & pasting, the notion of cells is not really compatible with the idea of text. And CJK runes often require more than one cell to display them nicely. Despite the mentioned flaws, using such a simple model brings benefits in a form of simplicity. And KISS principle is important.

At this point one should realize, that CLI (command-line interfaces) aren't really a thing termbox is aimed at. But rather pseudo-graphical user interfaces.

# Installation

Termbox-d is meant to be used as a dub package. Just install it by putting it in your
`dub.sdl` or `dub.json` file.

```sdl
dependency "termbox" version="*"
```

or

```json
"dependencies": {
    "termbox": { "version": "*" }
}
```

# Getting Started

See the `examples/` directory for some examples of how to use Termbox.

The library consists of the following functions:

```d
init() // Start termbox
shutdown() // Shutdown

width() // Width of the terminal screen
height() // Height of the terminal screen

clear() // Clear the screen
setClearAttributes(ushort fg, ushort bg) // Attributes for clearing the screen
flush() // Sync internal buffer with terminal

putCell(int x, int y, Cell* cell) // Draw cell at position x y
setCell(int x, int y, uint ch, ushort fg, ushort bg) // Put the character ch at position x y with color fg and bg

setInputMode(InputMode mode) // Change the input mode
setOutputMode(OutputMode mode) // Change the output mode

peekEvent(Event* e) // Peek an event
pollEvent(Event* e) // Wait for an event

setCursor(int x, int y) // Put the cursor at x, y
hideCursor() // Hide the cursor
```

For full detail, `source/termbox/package.d`.

# Links

- https://github.com/nsf/termbox - Termbox library
- http://pecl.php.net/package/termbox - PHP Termbox wrapper
- https://github.com/nsf/termbox-go - Go pure Termbox implementation
- https://github.com/gchp/rustbox - Rust Termbox wrapper
- https://github.com/fouric/cl-termbox - Common Lisp Termbox wrapper

# License

Termbox-d is (like termbox) provided under the MIT license.
