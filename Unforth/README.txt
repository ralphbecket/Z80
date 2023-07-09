Sweet80
=======

This is my take on a Sweet16 inspired notionally portable 16-bit
higher-level assembly language suitable for the 8-bit hey day, in
particular the Z80 (about as non-orthogonal as you could get) and
perhaps the 6502 (aggressively 8-bit).

My idea for this language is that essentially all variables will be
16-bit quantities at fixed addresses (i.e., no stack frames or anything
clever like that -- the 8-bitters just weren't up to that kind of
structure unless you want performance to go down the tubes).  The
abstract machine has a single 16-bit accumulator, the target of nearly
all operations, and a stack pointer.  The set of operations is small,
most take an argument (either a constant or a variable).

Here is the set of operations:

& k         A = k               Load a constant
& v         A = v               Load a variable address
<- k        A = *k              Read a word from memory
<- v        A = *v              Read a variable
-> v        *v = A              Write a variable
-> k        *k = A              Write to an address
PEEK        A = *A & 0xff       Read a byte
POKE k      *((byte *)A) = k    Write a byte
POKE v      *((byte *)A) = *v & 0xff
@           A = *A              Indirection
. k         A = A[k]            Subscripted indirection
. v         A = A[*v]

+ k         A += k              Arithmetic etc.
+ v         A += *v
- k         A -= k
- v         A -= *v
[Sim. for * / & | ^]

NEG         A = -A
CPL         A ^= 0xffff
LSL         A <<= 1
LSR         A = (unsigned A) >> 1
ASR         A >>= 1

PUSH        *--SP = A
POP         A = *SP++
<-SP        A = SP
->SP        SP = A

J k         goto k              Control flow
JZ k        if (A == 0) goto k
JNZ k       if (A != 0) goto k
JLT k       if (A < 0) goto k
JGE k       if (0 < A) goto k
JA          goto A

CALL k      *--SP = PC; goto k
RET         PC = *SP++

All of this has a reasonable Z80 translation (and presumably for 6502
too).  For example:

& k         ld HL, k
& v         ld HL, v
<- k        ld HL, (k)
<- v        ld HL, (v)
-> v        ld (v), HL
-> k        ld (k), HL
PEEK        ld L, (HL) : ld H, 0
POKE k      ld (HL), k
POKE v      ld A, (v) : ld (HL), A
@           ld A, (HL) : inc HL : ld H, (HL) : ld L, A
[] k        ld DE, k : ADD HL, DE : ADD HL : DE : @
[] v        ld DE, (v) : ADD HL, DE : ADD HL : DE : @

+ k         ld DE, k : add HL, DE
+ v         ld DE, (v) : add HL, DE
- k         ld DE, k : xor A : sbc HL, DE
- v         ld DE, (v) : xor A : sbc HL, DE
[* and / will involve calls to a small runtime library]
& k         ld DE, k : ld A, E : and L : ld L, A : ld A, D : and H : ld H, A
& v         ld DE, (v) : ld A, E : and L : ld L, A : ld A, D : and H : ld H, A
[Sim. for | ^]

NEG         ex DE, HL : xor A : ld L, A : ld H, A : sbc HL, DE
CPL         ld A, L : cpl : ld L, A : ld A, H : cpl : ld H, A
LSL         add HL, HL
LSR         srl H : rr L
ASR         sra H : rr L

PUSH        push HL
POP         pop HL
<-SP        ld HL, 0 : add HL, SP
->SP        ld HP, HL

J k         jp k
JZ k        ld A, L : or H : jp z, k
JNZ k       ld A, L : or H : jp nz, k
JLT k       bit 7, H : jp nz, k
JGE k       bit 7, H : jp z, k
JA          jp (HL)

CALL k      call k
RET         ret

Syntactic sugar: a constant k by itself (i.e., with no preceding op) is
interpreted as `K k`; a variable v by itself (i.e., with no preceding
op) is interpreted as `<- v`; within `{` ... `}` all new names are local
to that block; labels are declared with a `:` suffix in their names;
variables are defined using `.var`.

Example: Euclid's GCD Algorithm

    var x
    var y
    gcd: {
        x - y JZ done JLT ygtx
        xgty: -> x J gcd
        ygtx: NEG -> y J gcd
        done: x RET
    }

Notes on the compiler
---------------------
In the spirit of Forth (i.e., being something you can bootstrap with
minimal effort), I'd like to keep this on a token-by-token basis with
minimal state logic.

Here is the set of syntactic elements of Sweet80:

label:          Defines a label.  These can be referenced before
                they are defined.  Labels cannot be redefined.

J label         Jumps (etc.) to a label.  If the label is not yet
                defined, then this is a forward reference.

op0             A nullary operator.

op1 x           An operator taking a single argument.

var v           A variable declaration.  Variables cannot be redefined.
