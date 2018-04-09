; ALLOWS ONE TO START THE APPLICATION WITH RUN
; SYS 2064
*=$0801 
         BYTE $0C, $8, $0A, $00, $9E, $20, $32, $30, $36, $34, $00, $00, $00, $00, $00

; PLAN:
; * SCREEN SHALL DISPLAY FULL SIZED MAZE MADE OF BACKGROUND CHARACTERS
;       ** BACKGROUND CHARACTERS SHALL BE MULTICOLOR, WITH FLOOR TEXTURE WHICH DOES NOT TRIGGER COLLISION
;       ** MAZE WALLS WILL BE OF COLORS THAT WILL TRIGGER THE COLLISION
; * THERE SHALL BE A JOYSTICK CONTROLLABLE SPRITE WHICH DOES NOT GO THOUGHT WALLS
; * THERE SHALL BE A STATIONARY SPRITE IN THE MIDDLE OF THE MAZE
;       ** CONTROLLABLE SPRITE SHALL NOT GO THOUGH THE STATIONARY SPRITE
; * MAZE AND SPRITES SHALL DISPLAY STRAIGHT FROM ABOVE

CHMEMPTR        = $D018 ; CHARACTER MEMORY POINTER TO $3000
CHMAPMEM        = $3000 ; CHARACTER MEMORY POINTER
CPUPORT         = $0001 ; PROCESSOR PORT FLAGS
SCRCTRL2        = $D016
BGCOLOR0        = $D021
BGCOLOR1        = $D022
BGCOLOR2        = $D023

INIT
        ; DISABLED INTERRUPTS
        SEI

        ; TURN CHARACTER ROM VISIBLE AT $D000
        LDA CPUPORT
        AND #%11111011
        STA CPUPORT

        ; DEFINE CHAR RAM START $3000
        LDA #$00
        STA $FA
        LDA #$30
        STA $FB

        ; DEFINE CHAR ROM START $D000
        LDA #$00
        STA $FC
        LDA #$D0
        STA $FD

        ; COPY CHARACTERS ROM -> RAM
        LDY #0          ; Y ACTS AS A READ/WRITE LSB OFFSET
CPYLOOP
        LDA ($FC),Y     ; READ BYTE FROM ROM (TO ADDRESS *FD+*FC+Y)
        STA ($FA),Y     ; WRITE BYTE TO RAM (TO ADDRESS *FB+*FA+Y)
        INY             ; WRITE UNTIL Y OVERFLOWS BACK TO ZERO
        BNE CPYLOOP

        INC $FD         ; INCREMENT ROM READ MSB
        LDX $FB         ; INCREMENT RAM WRITE MSB
        INX
        STX $FB
        CPX #$38        ; KEEP COPYING UNTIL AT THE END OF CHAR RAM
        BNE CPYLOOP

        ; TURN I/O BACK VISIBLE AT $D000
        LDA CPUPORT
        ORA #%00000100
        STA CPUPORT

        ; SET CHARACTER MEMORY POINTER
        LDA CHMEMPTR
        AND #%11110000
        ORA #%00001100
        STA CHMEMPTR

        ; MULTICOLOR MODE
        LDA SCRCTRL2
        ORA #%00010000
        STA SCRCTRL2

        ; DEFINE BACKGROUD COLOR AND 2 SHARED CHAR COLORS
        LDA #13
        STA BGCOLOR0
        LDA #15
        STA BGCOLOR1
        LDA #5
        STA BGCOLOR2

        ; RE-ENABLE INTERRUPTS
        CLI

        ; LOAD CUSTOM CHARACTER SET
        LDX #0
LDCHMAP LDA CHMAP,X
        STA CHMAPMEM,X
        INX
        CPX #16
        BNE LDCHMAP


        ; LOAD SCREEN
        ; DEFINE SCREEN RAM START $0400
        LDA #$00
        STA $FA
        LDA #$04
        STA $FB

        ; DEFINE SCREEN DATA START
        LDA #<MAZE
        STA $FC
        LDA #>MAZE
        STA $FD

        ; COPY SCREEN TO RAM
        LDY #0          ; Y ACTS AS A READ/WRITE LSB OFFSET
CPLOOP2
        LDA ($FC),Y     ; READ BYTE (TO ADDRESS *FD+*FC+Y)
        STA ($FA),Y     ; WRITE BYTE (TO ADDRESS *FB+*FA+Y)

        LDX $FB         ; READ UNTIL AT THE END OF SCREEN RAM ($07E7)
        CPX #$07
        BNE CONTCPY     ; (NOT AT THE LAST CHUNK OF 256 BYTES)
        CPY #$E7
        BEQ CPYEND      ; COPY DONE

CONTCPY INY             ; WRITE UNTIL Y OVERFLOWS BACK TO ZERO
        BNE CPLOOP2

        INC $FD         ; INCREMENT READ MSB
        INC $FB         ; INCREMENT WRITE MSB
        JMP CPLOOP2     ; KEEP COPYING
CPYEND

MAIN    
        JMP MAIN

CHMAP   BYTE    $AA,$EE,$9A,$AE,$AA,$BA,$96,$AB
        BYTE    $00,$44,$00,$11,$00,$11,$00,$04

MAZE    BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00
        BYTE    $00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00
        BYTE    $00,$01,$01,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$01,$01,$00,$01,$01,$00,$00,$00,$00
        BYTE    $00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00
        BYTE    $00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00
        BYTE    $00,$01,$01,$00,$01,$01,$00,$01,$01,$00,$01,$01,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$01,$01,$00,$01,$01,$00
        BYTE    $00,$01,$01,$00,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$00
        BYTE    $00,$01,$01,$00,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$00
        BYTE    $00,$01,$01,$00,$01,$01,$00,$00,$00,$00,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00
        BYTE    $00,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00
        BYTE    $00,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00
        BYTE    $00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$01,$01,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00
        BYTE    $00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00
        BYTE    $00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$01,$01,$00,$01,$01,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00
        BYTE    $00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00
        BYTE    $00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00
        BYTE    $00,$01,$01,$00,$00,$00,$00,$01,$01,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$01,$01,$00,$01,$01,$00,$01,$01,$00,$01,$01,$00
        BYTE    $00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$00
        BYTE    $00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$00,$01,$01,$00
        BYTE    $00,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$01,$01,$00,$01,$01,$00,$00,$00,$00,$01,$01,$00,$01,$01,$00,$01,$01,$00
        BYTE    $00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$00
        BYTE    $00,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$01,$01,$01,$01,$01,$01,$00,$01,$01,$00,$01,$01,$00
        BYTE    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00

S_DOWN  BYTE $00,$00,$00
        BYTE $03,$C0,$00
        BYTE $07,$E0,$00
        BYTE $05,$A0,$00
        BYTE $05,$A0,$00
        BYTE $07,$E0,$00
        BYTE $03,$C0,$00
        BYTE $0F,$F0,$00
        BYTE $0F,$F0,$00
        BYTE $0F,$F0,$00
        BYTE $1F,$F8,$00
        BYTE $1F,$F8,$00
        BYTE $1F,$F8,$00
        BYTE $1F,$F8,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00

S_RIGHT BYTE $00,$00,$00
        BYTE $03,$C0,$00
        BYTE $07,$E0,$00
        BYTE $07,$B0,$00
        BYTE $07,$B8,$00
        BYTE $07,$E0,$00
        BYTE $03,$C0,$00
        BYTE $0F,$F0,$00
        BYTE $0F,$F0,$00
        BYTE $0F,$F0,$00
        BYTE $1F,$F8,$00
        BYTE $1F,$F8,$00
        BYTE $1F,$F8,$00
        BYTE $1F,$F8,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00

S_UP    BYTE $00,$00,$00
        BYTE $03,$C0,$00
        BYTE $07,$E0,$00
        BYTE $07,$E0,$00
        BYTE $07,$E0,$00
        BYTE $07,$E0,$00
        BYTE $03,$C0,$00
        BYTE $0F,$F0,$00
        BYTE $0F,$F0,$00
        BYTE $0F,$F0,$00
        BYTE $1F,$F8,$00
        BYTE $1F,$F8,$00
        BYTE $1F,$F8,$00
        BYTE $1F,$F8,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00

S_LEFT  BYTE $00,$00,$00
        BYTE $03,$C0,$00
        BYTE $07,$E0,$00
        BYTE $0D,$E0,$00
        BYTE $1D,$E0,$00
        BYTE $07,$E0,$00
        BYTE $03,$C0,$00
        BYTE $0F,$F0,$00
        BYTE $0F,$F0,$00
        BYTE $0F,$F0,$00
        BYTE $1F,$F8,$00
        BYTE $1F,$F8,$00
        BYTE $1F,$F8,$00
        BYTE $1F,$F8,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00,$00,$00
        BYTE $00

