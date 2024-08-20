# GD-Ballistics

Community Open source advanced Ballistic solution for Godot engine

Anyone can edit and propose changes to the code. Just fork or create a pull request and I will either merge it to main or create a branch specifically for you

Please make contributions, its hard enough as a solo dev working on this, any and all help will be deeply appreciated!

# Saveable Trajectory is the latest version of the Ballistic Movement FYI

all scripts are required for the system to work. BallisticMovement whatever is not, but everything else holds vital roles in the system. if you just download 1 script I do not guarantee it will work.


# New (August 1st 2024)
     New armor simulation:
     >Penetrate
     >Ricochet
          >Richochet and Spall
     >Stopped
          >Stopped and Spall

According to the code, if the kinetic energy of the impact is high enough (impact energy relative to required perforation energy ~50 percent or more) or the shell penetrates enough of the armor (~70 to ~90 percent), the plate will spall*

# Works in Progress

     currently simulates:
     >External Ballistics
          >Gravity
          >Linear Drag
          >Rotational Drag
          >Magnus Effect
     >Terminal Ballistics     
          >Penetration

# Currently Working On:
     >Spall/Fragmentation
          >Mathematical Approach rather than Physical
     >Overpressure
     >Modeling effects on crew members
  

# To do:
     >Fix Hit Detection # Fixed 7/31/24
     >More advanced external ballistics?
          >Temperature ?
          >Wind?
          >Coriolis?
          >More Advanced Air Calculations?
     >Bring heavy calculations into a preloaded graph per projectile (is that even possible in godot?) # yes fixed 7/30/24

     >Database for projectiles


     >Terminal Ballistics
          >3D armor solution 
          >Ricochet x WIP
          >Spalling
     
     >Internal Ballistics
          >Powder Charge
          >Barrel Dimensions
          >Ambient Temp and muzzle velocity
          >Barrel Drag
               >Barrel Drooping?




