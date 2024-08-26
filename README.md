# GD-Ballistics

Community Open source advanced Ballistic solution for Godot engine

Anyone can edit and propose changes to the code. Just fork or create a pull request and I will either merge it to main or create a branch specifically for you

Please make contributions, its hard enough as a solo dev working on this, any and all help will be deeply appreciated!

# Saveable Trajectory is the latest version of the Ballistic Movement FYI

all scripts are required for the system to work. BallisticMovement whatever is not, but everything else holds vital roles in the system. if you just download 1 script I do not guarantee it will work.


# New (August 26st 2024)
     armor simulation:
     >Effects of sloped armor
          >Shell can deviate inside the plate
          >Blunt noses are more effective against sloped armor
          >longer shells as well

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
     better shell dynamics
     optimization
     
  

# To do:
     >Terminal Ballistics
          >3D armor solution 
          >Ricochet
          
     
     >Internal Ballistics
          >Powder Charge
          >Barrel Dimensions
          >Ambient Temp and muzzle velocity
          >Barrel Drag
               >Barrel Drooping?




