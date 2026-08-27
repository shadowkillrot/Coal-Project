# 2D Retro Racing Game (x86 NASM Assembly)

A 2D arcade-style racing game written entirely from scratch in **16-bit x86 Assembly Language** using the **Netwide Assembler (NASM)** for DOS environments and DOSBox. 

Developed as a semester project for **Computer Organization and Assembly Language (COAL)**.

---

##  Gameplay & Features

- **Player Controls:** Responsive lane switching and acceleration/braking using keyboard inputs.
- **Dynamic Track Scrolling:** Continuously moving road lanes and animated track boundaries to simulate high-speed motion.
- **Obstacle & Traffic System:** Dynamically generated incoming traffic and road hazards with coordinate-based collision detection.
- **HUD & Score Tracking:** Real-time on-screen display tracking distance traveled, current score, player lives, and speed.
- **Progressive Difficulty:** Road scrolling and obstacle frequency dynamically scale up as your score increases.
- **Audio Feedback:** PC speaker sound effects triggered on engine revs, score increments, and collisions (via PIT I/O ports `0x42`/`0x61`).
- **Game State Screens:** Start / Title screen, Instructions page, Pause overlay, and Game Over screen with replay options.

---

## 🛠️ Low-Level Technical Concepts Demonstrated

This project demonstrates core low-level programming and computer architecture principles:

1. **Direct Video Memory Access:**
   - Directly manipulates video memory buffers (`0xB800:0000` for color text mode or `0xA000:0000` for 320×200 256-color VGA Mode 13h) for high-performance rendering without flickering.
2. **BIOS & DOS Interrupts:**
   - **`INT 10h`**: Video services (cursor control, screen clearing, video mode configuration).
   - **`INT 16h`**: Non-blocking keyboard buffer polling for responsive player controls.
   - **`INT 1Ah` / `INT 08h`**: Hardware timer hooks and delay loops for consistent frame pacing across different CPU speeds.
   - **`INT 21h`**: DOS system functions for character/string I/O and program termination.
3. **Collision Detection Algorithm:**
   - Pixel-grid and coordinate bounding-box intersection calculations between player coordinates and obstacle matrices.
4. **Pseudo-Random Number Generation (PRNG):**
   - Time-seeded Linear Congruential Generator (LCG) derived from system clock ticks for randomizing obstacle lane spawns.
5. **Modular Assembly Architecture:**
   - Subroutine calls (`CALL` / `RET`), stack management, register preservation (`PUSHA` / `POPA`), and memory-efficient string manipulation primitives (`MOVSW`, `STOSW`, `REP STOSB`).

---

## 🕹️ Controls

| Key | Action |
| :--- | :--- |
| **`Left Arrow`** | Steer Car Left |
| **`Right Arrow`** | Steer Car Right |
| **`Up Arrow`** | Accelerate / Boost Speed |
| **`Down Arrow`** | Decelerate / Brake |
| **`P`** | Pause / Resume Game |
| **`ESC`** | Exit to DOS |

---

## 🚀 Prerequisites & Tools

To assemble and run the game, you will need:

1. **NASM (Netwide Assembler)** — To compile the `.asm` source into 16-bit machine code.
2. **DOSBox** (or DOSBox-X / DOSBox-Staging) — An x86 emulator with DOS subsystem for modern operating systems (Windows / macOS / Linux).

---
