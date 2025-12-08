[org 0x0100]
jmp start
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
COLOR_COIN      equ 0EFh    
MAX_FUEL        equ 6
FUEL_DECREASE_RATE equ 80   
player_col      db LANE2_CENTER
player_row      db 20
obstacle_col    db LANE1_CENTER
obstacle_row    db 5
obstacle_timer  db 0
coin_row        db 0
coin_col        db 0
coin_active     db 0        
coin_timer      db 0
fuel_level      db MAX_FUEL
fuel_timer      db 0
divider_offset  db 0
frame_counter   db 0
fuel_text:      db 'FUEL:', 0
game_over_text: db 'GAME OVER!', 0
start:
    mov ax, 0003h
    int 10h
    mov ah, 01h
    mov cx, 2000h
    int 10h
    call randomize_obstacle
    mov byte [obstacle_row], 0  
    call draw_static_background
main_loop:
    call clear_road_area
    call draw_lane_dividers
    call draw_obstacle_car
    call draw_coin
    call draw_player_car
    call draw_hud_content
    call move_obstacle
    call move_coin
    call try_spawn_coin
    call update_fuel
    call delay
    mov ah, 01h
    int 16h
    jz .no_key
    mov ah, 00h
    int 16h
    cmp al, 27          
    je exit_game
    cmp ah, 4Bh         
    je move_left
    cmp ah, 4Dh         
    je move_right
.no_key:
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
move_obstacle:
    push ax
    mov al, [obstacle_timer]
    inc al
    mov [obstacle_timer], al
    cmp al, 2
    jl .done
    mov byte [obstacle_timer], 0
    mov al, [obstacle_row]
    inc al                      
    cmp al, SCREEN_HEIGHT - 2   
    jl .update_position
    mov byte [obstacle_row], 0
    call randomize_obstacle     
    jmp .done
.update_position:
    mov [obstacle_row], al
.done:
    pop ax
    ret
move_coin:
    push ax
    mov al, [coin_timer]
    inc al
    mov [coin_timer], al
    cmp al, 2
    jl .done
    mov byte [coin_timer], 0
    cmp byte [coin_active], 0
    je .done
    mov al, [coin_row]
    inc al                      
    cmp al, SCREEN_HEIGHT
    jge .remove_coin
    mov ah, [player_row]
    sub ah, 1                   
    cmp al, ah
    jl .no_collision
    add ah, 3                   
    cmp al, ah
    jg .no_collision
    mov ah, [coin_col]
    mov al, [player_col]
    cmp ah, al
    jne .no_collision
    mov al, [fuel_level]
    add al, 5
    cmp al, MAX_FUEL
    jle .set_fuel
    mov al, MAX_FUEL
.set_fuel:
    mov [fuel_level], al
    mov byte [coin_active], 0   
    jmp .done
.no_collision:
    mov al, [coin_row]
    inc al
    mov [coin_row], al
    jmp .done
.remove_coin:
    mov byte [coin_active], 0
.done:
    pop ax
    ret
try_spawn_coin:
    push ax
    push dx
    cmp byte [coin_active], 1
    je .done
    mov ah, 00h
    int 1Ah                     
    and dl, 0x1F                
    cmp dl, 2                   
    jg .done
    mov byte [coin_active], 1
    mov byte [coin_row], 0
    mov ax, dx
    shr ax, 8
    mov dx, 0
    mov bx, 3
    div bx                      
    cmp dl, 0
    je .lane1_coin
    cmp dl, 1
    je .lane2_coin
    mov byte [coin_col], LANE3_CENTER
    jmp .done
.lane1_coin:
    mov byte [coin_col], LANE1_CENTER
    jmp .done
.lane2_coin:
    mov byte [coin_col], LANE2_CENTER
.done:
    pop dx
    pop ax
    ret
update_fuel:
    push ax
    mov al, [frame_counter]
    inc al
    mov [frame_counter], al
    cmp al, FUEL_DECREASE_RATE
    jl .done
    mov byte [frame_counter], 0
    mov al, [fuel_level]
    cmp al, 0
    je .done
    dec al
    mov [fuel_level], al
.done:
    pop ax
    ret
draw_static_background:
    call draw_grass_areas
    call draw_borders
    call draw_footpaths
    call draw_hud_area
    ret
clear_road_area:
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
draw_lane_dividers:
    push ax
    push bx
    push cx
    push dx
    mov dh, 0
.row_loop:
    mov al, dh
    add al, [divider_offset]
    and al, 03h
    cmp al, 3
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
    mov al, [frame_counter]
    and al, 01h                 
    jnz .no_update
    mov al, [divider_offset]
    inc al
    and al, 03h
    mov [divider_offset], al
.no_update:
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
draw_hud_content:
    push ax
    push bx
    push cx
    push dx
    mov dh, 2
    mov dl, 66
    call set_cursor
    mov si, fuel_text
    call print_string
    mov dh, 4
    mov dl, 66
    mov cl, [fuel_level]
    mov ch, 0
.fuel_bar_loop:
    cmp cx, 0
    je .empty_bars
    call set_cursor
    mov ah, 09h
    mov bh, 0
    cmp cx, 15
    jg .green
    cmp cx, 8
    jg .yellow
    mov bl, 0C0h        
    jmp .draw_bar
.yellow:
    mov bl, 0E0h        
    jmp .draw_bar
.green:
    mov bl, 0A0h        
.draw_bar:
    mov al, 0xDB        
    push cx
    mov cx, 1
    int 10h
    pop cx
    inc dl
    dec cx
    jmp .fuel_bar_loop
.empty_bars:
    mov cl, MAX_FUEL
    sub cl, [fuel_level]
    mov ch, 0
.empty_loop:
    cmp cx, 0
    je .done
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, 78h         
    mov al, 0xB0        
    push cx
    mov cx, 1
    int 10h
    pop cx
    inc dl
    dec cx
    jmp .empty_loop
.done:
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
draw_coin:
    push ax
    push bx
    push cx
    push dx
    cmp byte [coin_active], 0
    je .done
    mov dh, [coin_row]
    mov dl, [coin_col]
    dec dl                  
    call set_cursor
    mov ah, 09h
    mov bh, 0
    mov bl, COLOR_COIN
    mov al, '('
    mov cx, 1
    int 10h
    inc dl
    call set_cursor
    mov ah, 09h
    mov al, '$'
    mov cx, 1
    int 10h
    inc dl
    call set_cursor
    mov ah, 09h
    mov al, ')'
    mov cx, 1
    int 10h
.done:
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
print_string:
    push ax
    push bx
    push si
    mov ah, 0Eh
    mov bh, 0
    mov bl, 0CEh        
.loop:
    lodsb
    cmp al, 0
    je .done
    int 10h
    jmp .loop
.done:
    pop si
    pop bx
    pop ax
    ret
delay:
    push ax
    push cx
    mov cx, 5           
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
