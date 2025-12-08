org 100h
section .data
    SCREEN_WIDTH    equ 80
    SCREEN_HEIGHT   equ 25
    GRASS_START     equ 0
    GRASS_WIDTH     equ 8
    BORDER1_COL     equ 8      
    BORDER1_WIDTH   equ 2
    FOOTPATH1_COL   equ 10     
    FOOTPATH1_WIDTH equ 2
    ROAD_START      equ 12     
    ROAD_WIDTH      equ 40      
    ROAD_END        equ 52
    FOOTPATH2_COL   equ 52      
    FOOTPATH2_WIDTH equ 2
    BORDER2_COL     equ 54      
    BORDER2_WIDTH   equ 2
    GRASS_END_COL   equ 56
    HUD_START       equ 64      
    NUM_LANES       equ 3
    LANE_WIDTH      equ 13      
    LANE1_CENTER    equ 18      
    LANE2_CENTER    equ 32      
    LANE3_CENTER    equ 45      
    DIVIDER1_COL    equ 25      
    DIVIDER2_COL    equ 38      
    CAR_WIDTH       equ 5
    CAR_HEIGHT      equ 3
    COLOR_GRASS     equ 66h     
    COLOR_BORDER    equ 4Ch     
    COLOR_FOOTPATH  equ 7Fh     
    COLOR_ROAD      equ 08h     
    COLOR_DIVIDER   equ 0Fh     
    COLOR_PLAYER    equ 4Eh     
    COLOR_PLAYER2   equ 3Bh     
    COLOR_OBSTACLE  equ 0Eh     
    COLOR_OBST2     equ 09h     
    COLOR_HUD       equ 70h     
    player_col      db LANE2_CENTER
    player_row      db 20
    obstacle_col    db LANE1_CENTER
    obstacle_row    db 5
    rand_seed       dw 12345        
section .text
start:
    mov ax, 0003h
    int 10h
    mov ah, 01h
    mov cx, 2000h
    int 10h
    call randomize_obstacle
main_loop:
    call draw_scene
    call delay
    mov ah, 01h
    int 16h
    jz main_loop
    mov ah, 00h
    int 16h
    cmp al, 27          
    je exit_game
    cmp ah, 4Bh         
    je move_left
    cmp ah, 4Dh         
    je move_right
    jmp main_loop
move_left:
    mov al, [player_col]
    cmp al, LANE1_CENTER
    jle main_loop
    cmp al, LANE3_CENTER
    je .from_lane3
    mov byte [player_col], LANE1_CENTER
    jmp main_loop
.from_lane3:
    mov byte [player_col], LANE2_CENTER
    jmp main_loop
move_right:
    mov al, [player_col]
    cmp al, LANE3_CENTER
    jge main_loop
    cmp al, LANE1_CENTER
    je .from_lane1
    mov byte [player_col], LANE3_CENTER
    jmp main_loop
.from_lane1:
    mov byte [player_col], LANE2_CENTER
    jmp main_loop
exit_game:
    mov ah, 01h
    mov cx, 0607h
    int 10h
    mov ax, 0003h
    int 10h
    mov ax, 4C00h
    int 21h
draw_scene:
    call draw_grass_areas
    call draw_borders
    call draw_footpaths
    call draw_road_surface
    call draw_lane_dividers
    call draw_hud_area
    call draw_obstacle_car
    call draw_player_car
    ret
draw_grass_areas:
    push ax
    push bx
    push cx
    push dx
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_GRASS
    mov al, 0xB1        
    mov dh, 0
.row_loop:
    mov dl, GRASS_START
    call set_cursor
    mov cx, GRASS_WIDTH
    int 10h
    mov dl, GRASS_END_COL
    call set_cursor
    mov cx, HUD_START - GRASS_END_COL
    int 10h
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .row_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_borders:
    push ax
    push bx
    push cx
    push dx
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_BORDER
    mov al, 0xDB        
    mov dh, 0
.row_loop:
    mov dl, BORDER1_COL
    call set_cursor
    mov cx, BORDER1_WIDTH
    int 10h
    mov dl, BORDER2_COL
    call set_cursor
    mov cx, BORDER2_WIDTH
    int 10h
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .row_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_footpaths:
    push ax
    push bx
    push cx
    push dx
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_FOOTPATH
    mov dh, 0
.row_loop:
    mov al, dh
    and al, 03h
    cmp al, 0
    je .pattern_red
    cmp al, 2
    je .pattern_red
    mov al, 0xDB
    jmp .draw_footpaths
.pattern_red:
    mov bl, COLOR_BORDER
    mov al, 0xDB
.draw_footpaths:
    push bx
    mov dl, FOOTPATH1_COL
    call set_cursor
    mov cx, FOOTPATH1_WIDTH
    int 10h
    pop bx
    mov dl, FOOTPATH2_COL
    call set_cursor
    mov cx, FOOTPATH2_WIDTH
    int 10h
    mov bl, COLOR_FOOTPATH  
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .row_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_road_surface:
    push ax
    push bx
    push cx
    push dx
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_ROAD
    mov al, 0xB0        
    mov dh, 0
.row_loop:
    mov dl, ROAD_START
    call set_cursor
    mov cx, ROAD_WIDTH
    int 10h
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .row_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_lane_dividers:
    push ax
    push bx
    push cx
    push dx
    mov dh, 0
.row_loop:
    mov al, dh
    and al, 03h         
    cmp al, 2
    jge .skip_row       
    mov dl, DIVIDER1_COL
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_DIVIDER
    mov al, 0xDB        
    mov cx, 1
    int 10h
    mov dl, DIVIDER2_COL
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_DIVIDER
    mov al, 0xDB
    mov cx, 1
    int 10h
.skip_row:
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .row_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_hud_area:
    push ax
    push bx
    push cx
    push dx
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_HUD
    mov al, ' '
    mov dh, 0
.row_loop:
    mov dl, HUD_START
    call set_cursor
    mov cx, SCREEN_WIDTH - HUD_START
    int 10h
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .row_loop
    mov dh, 0
.border_loop:
    mov dl, HUD_START
    call set_cursor
    mov ah, 09h
    mov bl, 08h
    mov al, 0xB3
    mov cx, 1
    int 10h
    inc dh
    cmp dh, SCREEN_HEIGHT
    jl .border_loop
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_player_car:
    push ax
    push bx
    push cx
    push dx
    mov dh, [player_row]
    mov dl, [player_col]
    sub dl, 2
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_PLAYER
    mov al, 0xDC
    mov cx, CAR_WIDTH
    int 10h
    inc dh
    mov dl, [player_col]
    sub dl, 2
    call set_cursor
    mov bl, 00h         
    mov al, 0xDB
    mov cx, CAR_WIDTH
    int 10h
    inc dh
    mov dl, [player_col]
    sub dl, 2
    call set_cursor
    mov bl, COLOR_PLAYER2
    mov al, 0xDF
    mov cx, CAR_WIDTH
    int 10h
    mov dl, [player_col]
    call set_cursor
    mov bl, COLOR_PLAYER
    mov al, 0xDB
    mov cx, 1
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
draw_obstacle_car:
    push ax
    push bx
    push cx
    push dx
    mov dh, [obstacle_row]
    mov dl, [obstacle_col]
    sub dl, 2
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_OBST2
    mov al, 0xDC
    mov cx, CAR_WIDTH
    int 10h
    inc dh
    mov dl, [obstacle_col]
    sub dl, 2
    call set_cursor
    mov bl, 00h
    mov al, 0xDB
    mov cx, CAR_WIDTH
    int 10h
    inc dh
    mov dl, [obstacle_col]
    sub dl, 2
    call set_cursor
    mov bl, COLOR_OBSTACLE
    mov al, 0xDF
    mov cx, CAR_WIDTH
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
    ret
set_cursor:
    push ax
    push bx
    mov ah, 02h
    mov bh, 0
    int 10h
    pop bx
    pop ax
    ret
delay:
    push ax
    push cx
    mov cx, 3
.outer:
    push cx
    mov cx, 0FFFFh
.inner:
    loop .inner
    pop cx
    loop .outer
    pop cx
    pop ax
    ret
randomize_obstacle:
    push ax
    push dx
    mov ah, 00h
    int 1Ah           
    mov ax, dx
    mov dx, 0
    mov bx, 3         
    div bx              
    cmp dl, 0
    je .lane1
    cmp dl, 1
    je .lane2
    mov byte [obstacle_col], LANE3_CENTER
    jmp .done
.lane1:
    mov byte [obstacle_col], LANE1_CENTER
    jmp .done
.lane2:
    mov byte [obstacle_col], LANE2_CENTER
.done:
    pop dx
    pop ax
    ret
