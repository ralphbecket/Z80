; Display.asm

; Addresses.

DisplayBitmap   equ $4000
DisplayAttrMap  equ $5800
DisplayWidth    equ 32
DisplayHeight   equ 24

; Colours.asm

Black           equ 0
Blue            equ 1
Red             equ 2
Magenta         equ 3
Green           equ 4
Cyan            equ 5
Yellow          equ 6
White           equ 7

FgBlack         equ Black << 0
FgBlue          equ Blue << 0
FgRed           equ Red << 0
FgMagenta       equ Magenta << 0
FgGreen         equ Green << 0
FgCyan          equ Cyan << 0
FgYellow        equ Yellow << 0
FgWhite         equ White << 0

BgBlack         equ Black << 3
BgBlue          equ Blue << 3
BgRed           equ Red << 3
BgMagenta       equ Magenta << 3
BgGreen         equ Green << 3
BgCyan          equ Cyan << 3
BgYellow        equ Yellow << 3
BgWhite         equ White << 3

Bright          equ 1 << 6
Flash           equ 1 << 7

SolidBlack      equ FgBlack + BgBlack
SolidBlue       equ FgBlue + BgBlue
SolidRed        equ FgRed + BgRed
SolidMagenta    equ FgMagenta + BgMagenta
SolidGreen      equ FgGreen + BgGreen
SolidCyan       equ FgCyan + BgCyan
SolidYellow     equ FgYellow + BgYellow
SolidWhite      equ FgWhite + BgWhite
