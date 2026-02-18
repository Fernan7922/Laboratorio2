;===========================================================
; Universidad del Valle de Guatemala
; Departamento de Ingenieria Electronica y Mecatronica
; IE2009 - Programacion de Microcontroladores
; Laboratorio 2: Botones y Timer0
;Fernando José Guzman González
;
; Archivo    : Lab2.asm
; Dispositivo: ATmega328P (Arduino Nano)
; Frecuencia : 16 MHz
; Anio       : 2024
;
; Descripcion:
;   Pre-Lab : Contador binario de 4 bits en LEDs,
;             incrementa cada 1s usando Timer0 sin interrupciones
;   Lab     : Contador hexadecimal 0-F en display 7 segmentos
;             controlado por 2 botones con anti-rebote por software
;   Post-Lab: Cuando el contador de segundos iguala el contador
;             del display, se reinicia y se togglea un LED de alarma
;
; Pinout:
;   PC0-PC3 : LEDs contador de segundos (salidas)
;   PC4     : Boton B1 - Incrementar display (entrada, pull-up)
;   PC5     : Boton B2 - Decrementar display (entrada, pull-up)
;   PD0-PD6 : Segmentos A-G display 7 seg catodo comun (salidas)
;   PB0     : LED de alarma (salida)
;
; Registros:
;   R16     : Registro temporal de trabajo
;   R17     : Patron actual del display
;   R18     : Contador de segundos (0-15)
;   R21     : Contador ticks 10ms  (0-9)
;   R22     : Contador ticks 100ms (0-9)
;   R23     : Valor contador display (0-15)
;   R24,R25 : Registros para delay anti-rebote
;   R26     : Mascara para toggle LED alarma
;   Z(ZH:ZL): Puntero a tabla 7 segmentos en Flash
;
; Calculo Timer0:
;   16MHz / 1024 = 15625 Hz
;   tick = 1/15625 = 0.064ms
;   256 - 100 = 156 ticks x 0.064ms = 9.984ms ~ 10ms
;   10 ticks x 10ms = 100ms
;   10 x 100ms = 1 segundo
;===========================================================

.include "M328PDEF.inc"

;===========================================================
; VECTOR DE RESET
;===========================================================
.org 0x00
RJMP START

;===========================================================
; SECCION 1: CONFIGURACION INICIAL
;===========================================================
START:

    ;--- Stack Pointer ---
    LDI R16, LOW(RAMEND)
    OUT SPL, R16
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16

    ;--- Puerto D: PD0-PD6 salidas para segmentos del display ---
    LDI R16, 0b01111111
    OUT DDRD, R16
    LDI R16, 0x00
    STS UCSR0B, R16

    ;--- Puerto C: PC0-PC3 salidas LEDs | PC4-PC5 entradas botones ---
    LDI R16, 0b00001111
    OUT DDRC, R16
    LDI R16, 0b00110000
    OUT PORTC, R16

    ;--- Puerto B: PB0 salida LED alarma ---
    LDI R16, 0b00000001
    OUT DDRB, R16
    LDI R16, 0x00
    OUT PORTB, R16

    ;--- Timer0: modo normal, prescaler 1024 ---
    LDI R16, 0x00
    OUT TCCR0A, R16
    LDI R16, 0b00000101
    OUT TCCR0B, R16
    LDI R16, 100
    OUT TCNT0, R16

    ;--- Inicializar variables ---
    CLR R18
    CLR R21
    CLR R22
    CLR R23

    ;--- Mostrar 0 en display al inicio ---
    LDI ZH, HIGH(TABLE7SEG<<1)
    LDI ZL, LOW(TABLE7SEG<<1)
    LPM R17, Z
    OUT PORTD, R17

;===========================================================
; SECCION 2: LOOP PRINCIPAL
;===========================================================
LOOP:
    OUT PORTD, R17

    SBIS PINC, 4
    CALL INCREMENTAR
    SBIS PINC, 5
    CALL DECREMENTAR

    CALL TICK_10MS

    RJMP LOOP

;===========================================================
; SECCION 3: TICK_10MS
; Verifica desborde del Timer0 sin bloquear el programa
; Cuenta 10 ticks x 10ms = 100ms
; Cuenta 10 x 100ms = 1 segundo
; Al llegar a 1s incrementa contador y compara con display
;===========================================================
TICK_10MS:
    IN R16, TIFR0
    SBRS R16, TOV0
    RET

    LDI R16, (1<<TOV0)
    OUT TIFR0, R16
    LDI R16, 100
    OUT TCNT0, R16

    INC R21
    CPI R21, 10
    BRNE FIN_TICK

    CLR R21
    INC R22
    CPI R22, 10
    BRNE ACTUALIZAR_LEDS

    CLR R22
    INC R18
    ANDI R18, 0x0F

    CP R18, R23
    BRNE ACTUALIZAR_LEDS

    CLR R18
    IN R16, PORTB
    LDI R26, (1<<PB0)
    EOR R16, R26
    OUT PORTB, R16

ACTUALIZAR_LEDS:
    MOV R16, R18
    ORI R16, 0b00110000
    OUT PORTC, R16

FIN_TICK:
    RET

;===========================================================
; SECCION 4: INCREMENTAR
; Anti-rebote por software + incremento contador display
; Espera soltar boton llamando TICK_10MS para no pausar LEDs
;===========================================================
INCREMENTAR:
    CALL DELAY
    SBIC PINC, 4
    RET
    CALL DELAY

    INC R23
    CPI R23, 16
    BRNE CONT_INC

    CLR R23
    LDI ZH, HIGH((TABLE7SEG<<1)-1)
    LDI ZL, LOW((TABLE7SEG<<1)-1)
    LPM R17, Z

CONT_INC:
    ADIW Z, 1
    LPM R17, Z

ESPERA_SOLTAR_INC:
    CALL TICK_10MS
    SBIC PINC, 4
    RET
    RJMP ESPERA_SOLTAR_INC

;===========================================================
; SECCION 5: DECREMENTAR
; Anti-rebote por software + decremento contador display
; Espera soltar boton llamando TICK_10MS para no pausar LEDs
;===========================================================
DECREMENTAR:
    CALL DELAY
    SBIC PINC, 5
    RET
    CALL DELAY

    DEC R23
    BRPL CONT_DEC

    LDI R23, 15
    LDI ZH, HIGH((TABLE7SEG<<1)+16)
    LDI ZL, LOW((TABLE7SEG<<1)+16)
    LPM R17, Z

CONT_DEC:
    SBIW Z, 1
    LPM R17, Z

ESPERA_SOLTAR_DEC:
    CALL TICK_10MS
    SBIC PINC, 5
    RET
    RJMP ESPERA_SOLTAR_DEC

;===========================================================
; SECCION 6: DELAY
; Retardo ~20ms para anti-rebote de botones
; Usa R24 y R25 para no interferir con registros del timer
;===========================================================
DELAY:
    LDI R24, 255
    LDI R25, 255
D1:
    DEC R24
    BRNE D1
    DEC R25
    BRNE D1
    RET

;===========================================================
; SECCION 7: TABLA 7 SEGMENTOS
; Catodo Comun | PD0=A PD1=B PD2=C PD3=D PD4=E PD5=F PD6=G
;===========================================================
TABLE7SEG:
    .DB 0x3F, 0x06   ; 0, 1
    .DB 0x5B, 0x4F   ; 2, 3
    .DB 0x66, 0x6D   ; 4, 5
    .DB 0x7D, 0x07   ; 6, 7
    .DB 0x7F, 0x6F   ; 8, 9
    .DB 0x77, 0x7C   ; A, B
    .DB 0x39, 0x5E   ; C, D
    .DB 0x79, 0x71   ; E, F
