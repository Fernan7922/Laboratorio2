# Laboratorio 2 - Botones y Timer0
**IE2009 - Programación de Microcontroladores**  
Universidad del Valle de Guatemala

## Descripción
Implementación de tres componentes funcionando simultáneamente:
- **Pre-Lab**: Contador binario de 4 bits en LEDs, incrementa cada 1 segundo usando Timer0
- **Lab**: Contador hexadecimal 0-F en display 7 segmentos controlado por botones con anti-rebote
- **Post-Lab**: LED de alarma que togglea cuando el contador de segundos iguala el valor del display

## Conexiones

| Pin Arduino Nano | Función |
|---|---|
| A0 (PC0) | LED bit 0 contador segundos |
| A1 (PC1) | LED bit 1 contador segundos |
| A2 (PC2) | LED bit 2 contador segundos |
| A3 (PC3) | LED bit 3 contador segundos |
| A4 (PC4) | Botón B1 - Incrementar |
| A5 (PC5) | Botón B2 - Decrementar |
| D0 (PD0) | Segmento A del display |
| D1 (PD1) | Segmento B del display |
| D2 (PD2) | Segmento C del display |
| D3 (PD3) | Segmento D del display |
| D4 (PD4) | Segmento E del display |
| D5 (PD5) | Segmento F del display |
| D6 (PD6) | Segmento G del display |
| D8 (PB0) | LED de alarma |

## Requisitos de hardware
- Arduino Nano (ATmega328P)
- Display 7 segmentos cátodo común
- 4 LEDs
- 1 LED de alarma
- 2 botones push
- Resistencias 220Ω para cada LED y segmento

## Herramientas
- Microchip Studio
- avrdude para programar el Nano
