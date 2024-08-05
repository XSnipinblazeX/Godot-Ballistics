https://discussions.unity.com/t/relative-armour-thickness-and-accurate-armour-penetration-ballistics-for-3d-tank-game/666291/12 #amnesias thread for unity

https://warthunder.com/en/news/384--en # war thunder damage model devblog 

https://forum.shrapnelgames.com/showthread.php?t=27440 # something

https://forum.warthunder.com/t/is-there-any-he-penetration-calculation-formula/49315/2 #HE penetration

https://www.slideshare.net/slideshow/bachelors-61286856/61286856#7 # penetration model paper

https://wiki.warthunder.ru/New_formuls_for_calculating_of_the_armour_piercing # war thunder armor penetration

War thunders DeMarre Equation:

MachPower = (Math.pow(speed, 1.43) * Math.pow(mass, 0.71)) 
DMC = (Math.pow(kfbr, 1.43) * Math.pow(caliber / 100, 1.07))
knap = scaling factor based on explosive mass
kf_apcbc = scaling factor for Capped Projectiles
(MachPower / DMC) * 100 * knap * kf_apcbc

Actual full formula:



    var kfbr = 1900
    var caliber 
    var mass 
    var speed
    var tnt
    var apcbc #bool


    tnt = (tnt / mass) * 100
    var kf_apcbc = (apcbc) ? 1 : 0.9
    var knap = 0.75
    
    if tnt < 0.65:
        knap = 1
    elif tnt < 1.6:
        knap = 1 + (tnt - 0.65) * (0.93 - 1) / (1.6 - 0.65)
    elif tnt < 2:
        knap = 0.93 + (tnt - 1.6) * (0.9 - 0.93) / (2 - 1.6)
    elif tnt < 3:
        knap = 0.9 + (tnt - 2) * (0.85 - 0.9) / (3 - 2)
    elif tnt < 4:
        knap = 0.85 + (tnt - 3) * (0.75 - 0.85) / (4 - 3)
    
    var result = (((pow(speed, 1.43) * pow(mass, 0.71)) / (pow(kfbr, 1.43) * pow(caliber / 100, 1.07))) * 100 * knap * kf_apcbc)



# CHATGPT formulas:

To determine the maximum angle of penetration (critical angle) before a bullet bounces off a metal target using input values of mass, diameter, and speed, we can use a physics-based approach involving the material properties of the target and the bullet's kinetic energy. Here's a step-by-step method to derive the critical angle:

### Step-by-Step Method

1. **Input Variables:**
   - Mass of the bullet $\ m \$: in kg
   - Diameter of the bullet $\ d \$: in meters
   - Speed of the bullet $\ v \$: in m/s
   - Yield strength of the target material $\ \sigma_y \$: in Pa (can be assumed based on common metals)
   - Thickness of the target $\ t \$: in meters

2. **Derived Variables:**
   - Cross-sectional area of the bullet $A$:

     $\ A = \pi \left( \frac{d}{2} \right)^2 \$

3. **Kinetic Energy of the Bullet:**

   $\ E_k = \frac{1}{2} m v^2 \$

4. **Penetration Condition:**
   The bullet will penetrate if the normal component of the kinetic energy is sufficient to overcome the material resistance of the target. The critical angle \(\theta_c\) is the maximum angle at which the bullet will just penetrate.

   $\ \frac{1}{2} m v^2 \cos^2(\theta_c) \geq t \cdot A \cdot \sigma_y \$

5. **Solving for the Critical Angle:**
   Rearrange the penetration condition to solve for \(\cos(\theta_c)\):

   $\ \cos^2(\theta_c) \geq \frac{2 t A \sigma_y}{m v^2} \$

   Taking the square root and then the arccosine:

   $\ \cos(\theta_c) \geq \sqrt{\frac{2 t A \sigma_y}{m v^2}} \$

   $\ \theta_c \leq \arccos\left(\sqrt{\frac{2 t A \sigma_y}{m v^2}}\right) \$

### Example Calculation

Assume:
- Mass of bullet, $\ m \$ = 0.01 kg (10 grams)
- Diameter of bullet, $\ d \$ = 0.01 m (10 mm)
- Speed of bullet, $\ v \$ = 800 m/s
- Yield strength of target material, $\ \sigma_y \$ = 1.5 GPa (1.5 \times 10^9 Pa)
- Thickness of target, $\ t \$ = 0.01 m (10 mm)

1. **Calculate the Cross-Sectional Area:**

   $\[ A = \pi \left( \frac{0.01}{2} \right)^2 = \pi \left( 0.005 \right)^2 = \pi \cdot 0.000025 = 0.00007854 \text{ m}^2 \]$

2. **Calculate the Term Inside the Square Root:**

   $\[ \frac{2 t A \sigma_y}{m v^2} = \frac{2 \cdot 0.01 \cdot 0.00007854 \cdot 1.5 \times 10^9}{0.01 \cdot 800^2} \]$

3. **Simplify the Expression:**

    = 368.15625 

   Since $\\cos\theta_c\$ must be between -1 and 1, this result indicates that the initial assumptions might lead to penetration at all angles for the given conditions. In realistic scenarios, material properties and empirical factors must be accurately considered.

4. **Taking the Square Root and Arccosine:**

  $sqrt{\frac{2 t A \sigma_y}{m v^2}}$ 
  
  approx 19.19 

   Since this value exceeds 1, it suggests that under the given conditions, penetration is likely at all angles. For practical purposes, re-evaluate with adjusted parameters or consider an empirical approach.


This function will give you the maximum angle of penetration before the bullet ricochets off the target. Adjust the inputs based on your specific scenario and material properties for accurate results.


This is what I used to check for ricochets. For those who have a hard time understanding it calculates the kinetic energy of the shell in the direction of the velocity, then it calculates the KE towards the normal. if the Kinetic energy towards the armor isnt enough then it doesnt penetrate. But if theres enough KE towards the velocity it may ricochet 

have a look at how ricochets dont really penetrate into the armor, since the KE isnt enough to punch through it just shaves off whatever it was able to dig into if it wasnt too deep:

Fig 1A.
<a title="FOTO:FORTEPAN / Konok Tamás id, CC BY-SA 3.0 &lt;https://creativecommons.org/licenses/by-sa/3.0&gt;, via Wikimedia Commons" href="https://commons.wikimedia.org/wiki/File:A_szovjet_hadsereg_KV-1_t%C3%ADpus%C3%BA_neh%C3%A9z_harckocsija._Fortepan_27683.jpg"><img width="512" alt="A szovjet hadsereg KV-1 típusú nehéz harckocsija. Fortepan 27683" src="https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/A_szovjet_hadsereg_KV-1_t%C3%ADpus%C3%BA_neh%C3%A9z_harckocsija._Fortepan_27683.jpg/512px-A_szovjet_hadsereg_KV-1_t%C3%ADpus%C3%BA_neh%C3%A9z_harckocsija._Fortepan_27683.jpg?20160629090700"></a>

Have a look here (this is from my interpretation) shot number 2 had a little more KE towards the turret roof plate allowing it to perforate unlike shot number 1 which didnt have enough and it glanced off

Fig 1B
![image](https://github.com/user-attachments/assets/e3fb1480-bf92-4454-a4e4-33be9baba038)

Right now (as of Aug 1 2024), the code has it so that if the shells energy into the plate doesnt exceed 20% of the energy required to penetrate, then it will ricochet (the main direction of the KE isnt into the plate so such circumstances work) if more than 20% of the KE is directed into the plate then either it will get stuck or penetrate. See Fig 1A.

https://github.com/NashDrilla/WarThunder-ProjectileSimulation/tree/main



https://discussions.unity.com/t/free-bullet-ballistics-script-pejsa-method/634432

^^this is a ballistic trajectory I find interesting for unity

I will be working on more realistic ricochets but im too lazy for that right now Im working on getting shit running on web browsers lmao.
    
