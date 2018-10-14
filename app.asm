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
SPR_ENABLE      = $D015 ; FLAGS FOR SPRITE ENABLING
SPR_MSBX        = $D010 ; FLAGS TO REPRESENT X VALUES LARGER THAN 255
SPR_COLORMODE   = $D01C ; FLAGS TO SET COLOR MODES (0 = HIGH RES/2-COLOR, 1 = MULTICOLOR/4-COLOR)
SPR0_PTR        = $07F8 ; SPRITE 0 DATA POINTER
SPR0_X          = $D000 ; SPRITE X COORDINATE
SPR0_Y          = $D001 ; SPRITE Y COORDINATE
SPR0_COLOR      = $D027 ; SPRITE 0 COLOR
DOWN_ADDR       = #$80
RIGHT_ADDR      = #$81
UP_ADDR         = #$82
LEFT_ADDR       = #$83
FRAME0_DATA     = $2000
COLOR_BLACK     = #0
JOYSTICK_B      = $DC01
COLL_REG        = $D01F
CIA1IRQ         = $DC0D
RASTERREG       = $D011
IRQRASTER       = $D012
IRQADDRMSB      = $0314
IRQADDRLSB      = $0315
IRQCTRL         = $D01A
IRQFLAG         = $D019
IRQFINISH       = $EA31

INIT
        ; HANDLE COLLISIONS AFTER RASTER LINE 250
        LDA #%01111111 ; SWITCH OFF CIA-1 INTERRUPTS
        STA CIA1IRQ

        AND $D011 ; CLEAR VIC RASTER REGISTER
        STA RASTERREG

        LDA #250
        STA IRQRASTER
        LDA #<CHECK_COLL
        STA IRQADDRMSB
        LDA #>CHECK_COLL
        STA IRQADDRLSB

        ; LOAD THE MAZE ========================================================
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

        ; LOAD SPRITES =========================================================
        ; ENABLE SPRITE
        LDA #%00000001
        STA SPR_ENABLE

        ; SET COLOR MODE
        LDA #%00000000
        STA SPR_COLORMODE

        ; SET SPRITE COLOR
        LDA COLOR_BLACK
        STA SPR0_COLOR

        ; SET SPRITE X
        LDX #%00000001
        STX SPR_MSBX
        LDX #40
        STX SPR0_X

        ; SET SPRITE Y
        LDY #233
        STY SPR0_Y

        ; SET INITIAL SPRITE POINTER
        LDA DOWN_ADDR
        STA SPR0_PTR

        ; LOAD SPRITE FRAMES IN A LOOP
        LDX #0
LDSPR   LDA SPRITES,X
        STA FRAME0_DATA,X
        INX
        CPX #255 ; 64 * 4 BYTES FOR 4 FRAMES
        BNE LDSPR

        LDA #%00000001 ; ENABLE RASTER INTERRUPTS ONLY AFTER SETUP
        STA IRQCTRL

MAIN    
        LDX #255 ; WAIT A BIT
        LDY #10
WAIT    DEX
        NOP
        BNE WAIT
        DEY
        BNE WAIT

        ; MOVE THE DUDE ========================================================
        CMP JOYSTICK_B
        BEQ MAIN_FINISH

UP      LDA #%00000001
        BIT JOYSTICK_B
        BNE DOWN
        DEC SPR0_Y
        LDX UP_ADDR
        STX SPR0_PTR

DOWN    LDA #%00000010
        BIT JOYSTICK_B
        BNE LEFT
        INC SPR0_Y
        LDX DOWN_ADDR
        STX SPR0_PTR

LEFT    LDA #%00000100
        BIT JOYSTICK_B
        BNE RIGHT
        DEC SPR0_X
        LDX LEFT_ADDR
        STX SPR0_PTR
        LDX SPR0_X ;TOGGLE X MSB IF GOING UNDER 256 OR 0
        CPX #255
        BNE RIGHT
        LDA #%00000001 ; TOGGLE SPRITE 0
        EOR SPR_MSBX
        STA SPR_MSBX

RIGHT   LDA #%00001000
        BIT JOYSTICK_B
        BNE MAIN_FINISH
        INC SPR0_X
        LDX RIGHT_ADDR
        STX SPR0_PTR
        LDX SPR0_X ;TOGGLE X MSB IF GOING OVER 255 OR 511
        CPX #0
        BNE MAIN_FINISH
        INC SPR_MSBX

MAIN_FINISH
        JMP MAIN

CHECK_COLL
        ; CHECK FOR COLLISION BY POLLING SPRITE-BACKGROUND HARDWARE COLLISION REGISTER
        LDX COLL_REG
        CPX #%00000001
        BNE NO_COLL
        ; MOVE SPRITE BACK TO PREVIOUS POSITION IF COLLIDED
        LDA $FA
        STA SPR0_X
        LDA $FB
        STA SPR0_Y
        LDA $FC
        STA SPR_MSBX

        ASL IRQFLAG
        JMP IRQFINISH
NO_COLL
        ; STORE PREVIOUS LOCATION WITH NO COLLISION
        LDA SPR0_X
        STA $FA
        LDA SPR0_Y
        STA $FB
        LDA SPR_MSBX
        STA $FC

        ASL IRQFLAG
        JMP IRQFINISH

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

; DOWN
SPRITES BYTE $00,$00,$00
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
; RIGHT
        BYTE $00,$00,$00
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

; UP
        BYTE $00,$00,$00
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

; LEFT  
        BYTE $00,$00,$00
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

