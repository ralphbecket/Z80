                ; 32 SPC
PropChars       db %00000001 + 2
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                ; 33 !
                db %10000000 + 1
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  ........
                dg  #.......
                dg  ........
                ; 34 "
                db %10100000 + 3
                dg  #.#.....
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                ; 35 #
                db %01010000 + 5
                dg  .#.#....
                dg  #####...
                dg  .#.#....
                dg  #####...
                dg  .#.#....
                dg  .#.#....
                dg  ........
                ; 36 $
                db %00100000 + 5
                dg  .####...
                dg  #.#.....
                dg  .###....
                dg  ..#.#...
                dg  ####....
                dg  ..#.....
                dg  ........
                ; 37 %
                db %11001000 + 5
                dg  ##..#...
                dg  ...#....
                dg  ..#.....
                dg  .#......
                dg  #..##...
                dg  #..##...
                dg  ........
                ; 38 &
                db %01100000 + 5
                dg  #..#....
                dg  #.#.....
                dg  .#......
                dg  #.#.#...
                dg  #..#....
                dg  .##.#...
                dg  ........
                ; 39 '
                db %10000000 + 1
                dg  #.......
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                ; 40 (
                db %00100000 + 3
                dg  .#......
                dg  .#......
                dg  .#......
                dg  .#......
                dg  .#......
                dg  .#......
                dg  ..#.....
                ; 41 )
                db %10000000 + 2
                dg  .#......
                dg  .#......
                dg  .#......
                dg  .#......
                dg  .#......
                dg  .#......
                dg  #.......
                ; 42 *
                db %00000000 + 5
                dg  ..#.....
                dg  #.#.#...
                dg  .###....
                dg  #.#.#...
                dg  ..#.....
                dg  ........
                dg  ........
                ; 43 +
                db %00000000 + 5
                dg  ..#.....
                dg  ..#.....
                dg  #####...
                dg  ..#.....
                dg  ..#.....
                dg  ........
                dg  ........
                ; 44 ,
                db %00000000 + 2
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  .#......
                dg  #.......
                ; 45 -
                db %00000000 + 4
                dg  ........
                dg  ........
                dg  ####....
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                ; 46 .
                db %00000000 + 2
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  .#......
                dg  ........
                ; 47 /
                db %00001000 + 5
                dg  ....#...
                dg  ...#....
                dg  ..#.....
                dg  .#......
                dg  #.......
                dg  #.......
                dg  ........
                ; 48 0
                db %01110000 + 5
                dg  #...#...
                dg  #...#...
                dg  #...#...
                dg  #...#...
                dg  #...#...
                dg  .###....
                dg  ........
                ; 49 1
                db %00100000 + 5
                dg  .##.....
                dg  #.#.....
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  #####...
                dg  ........
                ; 50 2
                db %01110000 + 5
                dg  #...#...
                dg  ....#...
                dg  ..##....
                dg  .#......
                dg  #.......
                dg  #####...
                dg  ........
                ; 51 3
                db %01110000 + 5
                dg  #...#...
                dg  ....#...
                dg  ..##....
                dg  ....#...
                dg  #...#...
                dg  .###....
                dg  ........
                ; 52 4
                db %00110000 + 5
                dg  ..##....
                dg  .#.#....
                dg  .#.#....
                dg  #..#....
                dg  #####...
                dg  ...#....
                dg  ........
                ; 53 5
                db %11111000 + 5
                dg  #.......
                dg  ####....
                dg  ....#...
                dg  ....#...
                dg  #...#...
                dg  .###....
                dg  ........
                ; 54 6
                db %01110000 + 5
                dg  #...#...
                dg  #.......
                dg  ####....
                dg  #...#...
                dg  #...#...
                dg  .###....
                dg  ........
                ; 55 7
                db %11111000 + 5
                dg  ....#...
                dg  ...#....
                dg  ...#....
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  ........
                ; 56 8
                db %01110000 + 5
                dg  #...#...
                dg  #...#...
                dg  .###....
                dg  #...#...
                dg  #...#...
                dg  .###....
                dg  ........
                ; 57 9
                db %01110000 + 5
                dg  #...#...
                dg  #...#...
                dg  .####...
                dg  ....#...
                dg  #...#...
                dg  .###....
                dg  ........
                ; 58 :
                db %00000000 + 2
                dg  ........
                dg  ........
                dg  .#......
                dg  ........
                dg  ........
                dg  .#......
                dg  ........
                ; 59 ;
                db %00000000 + 2
                dg  ........
                dg  ........
                dg  .#......
                dg  ........
                dg  ........
                dg  .#......
                dg  #.......
                ; 60 <
                db %00010000 + 4
                dg  ..#.....
                dg  .#......
                dg  #.......
                dg  .#......
                dg  ..#.....
                dg  ...#....
                dg  ........
                ; 61 =
                db %00000000 + 4
                dg  ........
                dg  ####....
                dg  ........
                dg  ####....
                dg  ........
                dg  ........
                dg  ........
                ; 62 >
                db %10000000 + 4
                dg  .#......
                dg  ..#.....
                dg  ...#....
                dg  ..#.....
                dg  .#......
                dg  #.......
                dg  ........
                ; 63 ?
                db %01110000 + 5
                dg  #...#...
                dg  ....#...
                dg  ...#....
                dg  ..#.....
                dg  ........
                dg  ..#.....
                dg  ........
                ; 64 @
                db %01110000 + 5
                dg  #...#...
                dg  #.###...
                dg  #.#.#...
                dg  #.###...
                dg  #.......
                dg  .###....
                dg  ........
                ; 65 A
                db %00100000 + 5
                dg  ..#.....
                dg  .#.#....
                dg  .#.#....
                dg  .###....
                dg  #...#...
                dg  #...#...
                dg  ........
                ; 66 B
                db %11100000 + 4
                dg  #..#....
                dg  #..#....
                dg  ###.....
                dg  #..#....
                dg  #..#....
                dg  ###.....
                dg  ........
                ; 67 C
                db %01100000 + 4
                dg  #..#....
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #..#....
                dg  .##.....
                dg  ........
                ; 68 D
                db %11100000 + 4
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  ###.....
                dg  ........
                ; 69 E
                db %11110000 + 4
                dg  #.......
                dg  #.......
                dg  ###.....
                dg  #.......
                dg  #.......
                dg  ####....
                dg  ........
                ; 70 F
                db %11110000 + 4
                dg  #.......
                dg  #.......
                dg  ###.....
                dg  #.......
                dg  #.......
                dg  #.......
                dg  ........
                ; 71 G
                db %01100000 + 4
                dg  #..#....
                dg  #.......
                dg  #.##....
                dg  #..#....
                dg  #..#....
                dg  .##.....
                dg  ........
                ; 72 H
                db %10010000 + 4
                dg  #..#....
                dg  #..#....
                dg  ####....
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  ........
                ; 73 I
                db %11100000 + 3
                dg  .#......
                dg  .#......
                dg  .#......
                dg  .#......
                dg  .#......
                dg  ###.....
                dg  ........
                ; 74 J
                db %11110000 + 4
                dg  ...#....
                dg  ...#....
                dg  ...#....
                dg  ...#....
                dg  #..#....
                dg  .##.....
                dg  ........
                ; 75 K
                db %10010000 + 4
                dg  #..#....
                dg  #.#.....
                dg  ##......
                dg  #.#.....
                dg  #..#....
                dg  #..#....
                dg  ........
                ; 76 L
                db %10000000 + 4
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  ####....
                dg  ........
                ; 77 M
                db %10001000 + 5
                dg  ##.##...
                dg  #.#.#...
                dg  #.#.#...
                dg  #...#...
                dg  #...#...
                dg  #...#...
                dg  ........
                ; 78 N
                db %10010000 + 4
                dg  ##.#....
                dg  ##.#....
                dg  ####....
                dg  #.##....
                dg  #.##....
                dg  #..#....
                dg  ........
                ; 79 O
                db %01100000 + 4
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  .##.....
                dg  ........
                ; 80 P
                db %11100000 + 4
                dg  #..#....
                dg  #..#....
                dg  ###.....
                dg  #.......
                dg  #.......
                dg  #.......
                dg  ........
                ; 81 Q
                db %01100000 + 4
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  ##.#....
                dg  #.#.....
                dg  .#.#....
                dg  ........
                ; 82 R
                db %11100000 + 4
                dg  #..#....
                dg  #..#....
                dg  ###.....
                dg  #.#.....
                dg  #..#....
                dg  #..#....
                dg  ........
                ; 83 S
                db %01100000 + 4
                dg  #..#....
                dg  #.......
                dg  .##.....
                dg  ...#....
                dg  #..#....
                dg  .##.....
                dg  ........
                ; 84 T
                db %11111000 + 4
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  ........
                ; 85 U
                db %10010000 + 4
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  .##.....
                dg  ........
                ; 86 V
                db %10001000 + 5
                dg  #...#...
                dg  #...#...
                dg  .#.#....
                dg  .#.#....
                dg  ..#.....
                dg  ..#.....
                dg  ........
                ; 87 W
                db %10001000 + 5
                dg  #...#...
                dg  #...#...
                dg  #.#.#...
                dg  #.#.#...
                dg  .#.#....
                dg  .#.#....
                dg  ........
                ; 88 X
                db %10001000 + 5
                dg  #...#...
                dg  .#.#....
                dg  ..#.....
                dg  .#.#....
                dg  #...#...
                dg  #...#...
                dg  ........
                ; 89 Y
                db %10001000 + 5
                dg  #...#...
                dg  .#.#....
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  ........
                ; 90 Z
                db %11111000 + 5
                dg  ....#...
                dg  ...#....
                dg  ..#.....
                dg  .#......
                dg  #.......
                dg  #####...
                dg  ........
                ; 91 [
                db %11100000 + 3
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  ###.....
                ; 92 \
                db %10000000 + 5
                dg  #.......
                dg  .#......
                dg  ..#.....
                dg  ...#....
                dg  ....#...
                dg  ....#...
                dg  ........
                ; 93 ]
                db %11100000 + 3
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  ###.....
                ; 94 ^
                db %00100000 + 5
                dg  .#.#....
                dg  #...#...
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                ; 95 _
                db %00000000 + 4
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ####....
                dg  ........
                ; 96 `
                db %10000000 + 2
                dg  .#......
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                dg  ........
                ; 97 a
                db %00000000 + 4
                dg  ........
                dg  .##.....
                dg  #..#....
                dg  .###....
                dg  #..#....
                dg  .###....
                dg  ........
                ; 98 b
                db %10000000 + 4
                dg  #.......
                dg  #.#.....
                dg  ##.#....
                dg  #..#....
                dg  #..#....
                dg  .##.....
                dg  ........
                ; 99 c
                db %00000000 + 4
                dg  ........
                dg  .##.....
                dg  #..#....
                dg  #.......
                dg  #..#....
                dg  .##.....
                dg  ........
                ; 100 d
                db %00010000 + 4
                dg  ...#....
                dg  .#.#....
                dg  #.##....
                dg  #..#....
                dg  #..#....
                dg  .##.#...
                dg  ........
                ; 101 e
                db %00000000 + 4
                dg  ........
                dg  .##.....
                dg  #..#....
                dg  ###.....
                dg  #.......
                dg  .###....
                dg  ........
                ; 102 f
                db %01100000 + 2
                dg  #.......
                dg  #.......
                dg  ##......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  ........
                ; 103 g
                db %00000000 + 4
                dg  ........
                dg  .##.....
                dg  #..#....
                dg  #..#....
                dg  .###....
                dg  #..#....
                dg  .##.....
                ; 104 h
                db %10000000 + 4
                dg  #.......
                dg  #.#.....
                dg  ##.#....
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  ........
                ; 105 i
                db %10000000 + 2
                dg  ........
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  .#......
                dg  ........
                ; 106 j
                db %00100000 + 3
                dg  ........
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  ..#.....
                dg  #.#.....
                dg  .#......
                ; 107 k
                db %00000000 + 4
                dg  #.......
                dg  #..#....
                dg  #.#.....
                dg  ##......
                dg  #.#.....
                dg  #..#....
                dg  ........
                ; 108 l
                db %10000000 + 2
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  .#......
                dg  ........
                ; 109 m
                db %00000000 + 5
                dg  ........
                dg  .#.#....
                dg  #.#.#...
                dg  #.#.#...
                dg  #...#...
                dg  #...#...
                dg  ........
                ; 110 n
                db %00000000 + 4
                dg  ........
                dg  .##.....
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  ........
                ; 111 o
                db %00000000 + 4
                dg  ........
                dg  .##.....
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  .##.....
                dg  ........
                ; 112 p
                db %00000000 + 4
                dg  ........
                dg  .##.....
                dg  #..#....
                dg  #..#....
                dg  ##.#....
                dg  #.#.....
                dg  #.......
                ; 113 q
                db %00000000 + 4
                dg  ........
                dg  .##.....
                dg  #..#....
                dg  #..#....
                dg  #.##....
                dg  .#.##...
                dg  ...#....
                ; 114 r
                db %00000000 + 4
                dg  ........
                dg  #.##....
                dg  ##......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  ........
                ; 115 s
                db %00000000 + 4
                dg  ........
                dg  .##.....
                dg  #.......
                dg  .##.....
                dg  ...#....
                dg  ###.....
                dg  ........
                ; 116 t
                db %01000000 + 3
                dg  .#......
                dg  ###.....
                dg  .#......
                dg  .#......
                dg  .#......
                dg  ..#.....
                dg  ........
                ; 117 u
                db %00000000 + 4
                dg  ........
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  .##.....
                dg  ........
                ; 118 v
                db %00000000 + 5
                dg  ........
                dg  #...#...
                dg  .#.#....
                dg  .#.#....
                dg  ..#.....
                dg  ..#.....
                dg  ........
                ; 119 w
                db %00000000 + 5
                dg  ........
                dg  #...#...
                dg  #...#...
                dg  #.#.#...
                dg  .#.#....
                dg  .#.#....
                dg  ........
                ; 120 x
                db %00000000 + 5
                dg  ........
                dg  #...#...
                dg  .#.#....
                dg  ..#.....
                dg  .#.#....
                dg  #...#...
                dg  ........
                ; 121 y
                db %00000000 + 4
                dg  ........
                dg  #..#....
                dg  #..#....
                dg  #..#....
                dg  .###....
                dg  ...#....
                dg  ###.....
                ; 122 z
                db %00000000 + 4
                dg  ........
                dg  ####....
                dg  ..#.....
                dg  .#......
                dg  #.......
                dg  ####....
                dg  ........
                ; 123 {
                db %00100000 + 3
                dg  .#......
                dg  .#......
                dg  #.......
                dg  .#......
                dg  .#......
                dg  .#......
                dg  ..#.....
                ; 124 |
                db %10000000 + 1
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                dg  #.......
                ; 125 }
                db %10000000 + 3
                dg  .#......
                dg  .#......
                dg  ..#.....
                dg  .#......
                dg  .#......
                dg  .#......
                dg  #.......
                ; 126 ~
                db %00000000 + 4
                dg  ........
                dg  ........
                dg  ##.#....
                dg  #.##....
                dg  ........
                dg  ........
                dg  ........

