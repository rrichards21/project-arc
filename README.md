# Project ARC: 3D Football MVP

A 3D physics-based football game prototype built with **Godot 4**.

## Features
- **Physics-based Gameplay**: Ball bouncing, drag, and collisions.
- **Grabbing Mechanic**: Players can grab and drag the goals (using a Generic6DOFJoint3D system).
- **Realistic Goals**: Composite RigidBody goals with "Hollow Box" design.
- **Scoring System**: Dual-goal detection with team scoring logic.
- **Camera Follow**: Smooth camera tracking system.

## Controls
| Action | Key(s) |
| :--- | :--- |
| **Move** | `W`, `A`, `S`, `D` or Arrow Keys |
| **Dash** | `Space` or `Shift` |
| **Grab Goal** | `E`, `Enter`, or `Left Click` (Hold to grab) |
| **Reset Match** | `R` |

## Technical Details
- **Engine**: Godot 4.x (GDScript)
- **Architecture**:
    - `core/`: Main game loop, GameManager, Scene setup.
    - `objects/`: Game entities (Player, Ball, Goal, Arena).
    - `configs/`: Singleton configurations (Physics constants).
- **Physics**: Uses Jolt (if available) or default Godot Physics 3D.

## Setup
1. Clone the repository.
2. Open `project.godot` in Godot Engine 4.x.
3. Run the project (F5).
