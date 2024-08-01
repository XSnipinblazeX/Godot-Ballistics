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




https://discussions.unity.com/t/free-bullet-ballistics-script-pejsa-method/634432

^^this is a ballistic trajectory I find interesting for unity
    
