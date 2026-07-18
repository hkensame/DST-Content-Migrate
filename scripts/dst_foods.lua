
local DST_FOODS = {
--爆炒填馅辣椒，1.2倍攻击加成
  pepperpopper =
  {
   test = function(cooker, names, tags) return (names.pepper or names.pepper_cooked) and tags.meat and tags.meat <= 1.5 and not tags.inedible end,
   priority = 20,
   foodtype = "MEAT",
   health = TUNING.HEALING_MEDLARGE,
   hunger = TUNING.CALORIES_MED,
   perishtime = TUNING.PERISH_SLOW,
   sanity = -TUNING.SANITY_TINY,
   temperature = TUNING.HOT_FOOD_BONUS_TEMP,
   temperatureduration = TUNING.FOOD_TEMP_LONG,
   cooktime = 2,
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) then
                eater.components.debuffable:AddDebuff("buff_attack", "buff_attack")
            end
       	end,
  },

--辣龙椒沙拉，1.5倍攻击加成
  dragonchilisalad =
  {
      test = function(cooker, names, tags) return (names.dragonfruit or names.dragonfruit_cooked) and (names.pepper or names.pepper_cooked) and not tags.meat and not tags.inedible and not tags.egg end,
      priority = 30,
      foodtype = "VEGGIE",
      health = -TUNING.HEALING_SMALL,
      hunger = TUNING.CALORIES_MED,
      sanity = TUNING.SANITY_SMALL,
      temperature = TUNING.HOT_FOOD_BONUS_TEMP,
      temperatureduration = TUNING.BUFF_FOOD_TEMP_DURATION,
      --nochill = true,
      perishtime = TUNING.PERISH_SLOW,
      cooktime = 0.75,
      tags = { "masterfood" },
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) then
                eater.components.debuffable:AddDebuff("buff_attack2", "buff_attack2")
            end
       	end,
  },

--鲜果可丽饼，2倍攻击加成
    freshfruitcrepes =
    {
        test = function(cooker, names, tags) return tags.fruit and tags.fruit >= 1.5 and names.butter and names.honey end,
        priority = 30,
        foodtype = "VEGGIE",
        health = TUNING.HEALING_HUGE,
        hunger = TUNING.CALORIES_SUPERHUGE,
        perishtime = TUNING.PERISH_MED,
        sanity = TUNING.SANITY_MED,
        cooktime = 2,
        tags = { "masterfood" },
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) then
                eater.components.debuffable:AddDebuff("buff_attack3", "buff_attack3")
            end
       	end,
    },

--骨头汤，无僵直
    bonesoup =
    {
        test = function(cooker, names, tags) return names.boneshard and names.boneshard == 2 and (names.onion or names.onion_cooked) and (tags.inedible and tags.inedible < 3) end,
        priority = 30,
        foodtype = "MEAT",
        health = TUNING.HEALING_MEDSMALL * 4,
        hunger = TUNING.CALORIES_LARGE * 4,
        perishtime = TUNING.PERISH_MED,
        sanity = TUNING.SANITY_TINY,
        cooktime = 2,
        tags = { "masterfood" },
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) then
                eater.components.debuffable:AddDebuff("buff_stun", "buff_stun")
            end
       	end,
    },

--蓝带鱼排
    frogfishbowl =
    {
        test = function(cooker, names, tags) return ((names.froglegs and names.froglegs >= 2) or (names.froglegs_cooked and names.froglegs_cooked >= 2 ) or (names.froglegs and names.froglegs_cooked)) and tags.fish and tags.fish >= 1 and not tags.inedible end,
        priority = 30,
        foodtype = "MEAT",
        health = TUNING.HEALING_MED,
        hunger = TUNING.CALORIES_LARGE,
        sanity = -TUNING.SANITY_SMALL,
        perishtime = TUNING.PERISH_FASTISH,
        cooktime = 2,
        tags = { "buff_moistureimmunity" },
        --prefabs = { "buff_moistureimmunity" },
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) then
                --eater.components.debuffable:AddDebuff("buff_moistureimmunity", "buff_moistureimmunity")
            end
       	end,
    },

--伏特羊肉冻
	voltgoatjelly = 
	{
		test = function(cooker, names, tags) return (names.lightninggoathorn) and (tags.sweetener and tags.sweetener >= 2) and not tags.meat end,
		priority = 30,
		foodtype = "GOODIES",
		health = TUNING.HEALING_SMALL,
		hunger = TUNING.CALORIES_LARGE,
		perishtime = TUNING.PERISH_MED,
		sanity = TUNING.SANITY_SMALL,
		cooktime = 2,
		tags = {"masterfood"},
		--prefabs = { "buff_electricattack" },
        oneatenfn = function(inst, eater)
            if eater.components.debuffable ~= nil and eater.components.debuffable:IsEnabled() and
                not (eater.components.health ~= nil and eater.components.health:IsDead()) then
                --eater.components.debuffable:AddDebuff("buff_workeffectiveness", "buff_workeffectiveness")
            end
       	end,
	},

--发光慕斯，4倍时长的发光蓝莓
    glowberrymousse =
    {
        test = function(cooker, names, tags) return (names.wormlight) and (tags.fruit and tags.fruit >= 2) and not tags.meat and not tags.inedible end,
        priority = 30,
        foodtype = "VEGGIE",
        health = TUNING.HEALING_SMALL,
        hunger = TUNING.CALORIES_LARGE,
        perishtime = TUNING.PERISH_FASTISH,
        sanity = TUNING.SANITY_SMALL,
        cooktime = 1,
        oneatenfn = function(inst, eater)
          if eater.wormlight then
            eater.wormlight.components.spell.lifetime = 0
            eater.wormlight.components.spell:ResumeSpell()
          else
            local light = SpawnPrefab("wormlight_light")
            light.components.spell.duration = TUNING.WORMLIGHT_DURATION * 4
            light.components.spell:SetTarget(eater)
            if not light.components.spell.target then
                light:Remove()
            end
            light.components.spell:StartSpell()
          end
        end,
        tags = { "masterfood" },
    },


--叶肉糕
    leafloaf = 
    {
        test = function(cooker, names, tags)
            return ((names.plantmeat or 0) + (names.plantmeat_cooked or 0) >= 2 )
        end,
        priority = 25,
        foodtype = "MEAT",
        health = TUNING.HEALING_MEDSMALL,
        hunger = TUNING.CALORIES_LARGE,
        perishtime = TUNING.PERISH_PRESERVED,
        sanity = TUNING.SANITY_TINY,
        cooktime = 2,
    },

--素食堡
    leafymeatburger = 
    {
        test = function(cooker, names, tags)
            return (names.plantmeat or names.plantmeat_cooked)
            		and (names.onion or names.onion_cooked)
                    and tags.veggie and tags.veggie >= 2
        end,
        priority = 25,
        foodtype = "MEAT",
        health = TUNING.HEALING_MEDLARGE,
        hunger = TUNING.CALORIES_LARGE,
        perishtime = TUNING.PERISH_FAST,
        sanity = TUNING.SANITY_LARGE,
        cooktime = 2,
    },

--果冻沙拉
    leafymeatsouffle = 
    {
        test = function(cooker, names, tags)
            return ((names.plantmeat or 0) + (names.plantmeat_cooked or 0) >= 2 )
                    and tags.sweetener and tags.sweetener >= 2
        end,
        priority = 50,
        foodtype = "MEAT",
        health = 0,
        hunger = TUNING.CALORIES_LARGE,
        perishtime = TUNING.PERISH_FAST,
        sanity = TUNING.SANITY_HUGE,
        cooktime = 2,
    },

--牛肉绿叶菜
    meatysalad = 
    {
        test = function(cooker, names, tags)
            return (names.plantmeat or names.plantmeat_cooked)
                    and tags.veggie and tags.veggie >= 3
        end,
        priority = 25,
        foodtype = "MEAT",
        health = TUNING.HEALING_LARGE,
        hunger = TUNING.CALORIES_LARGE*2,
        perishtime = TUNING.PERISH_FAST,
        sanity = TUNING.SANITY_TINY,
        cooktime = 2,
	},

--琥珀美食（尘蛾食物）
    dustmeringue =
    {
        test = function(cooker, names, tags) return names.refined_dust end,
        priority = 100,
        foodtype = "ELEMENTAL",
        perishtime = nil,
        cooktime = 2,
        overridebuild = "cook_pot_food6",
        health = 0,
        hunger = TUNING.CALORIES_SMALL,
        sanity = 0,
    },

}

AddIngredientValues({"refined_dust"}, {elemental=1}, true)
AddIngredientValues({"onion", "pepper"}, {veggie=1}, true)
AddIngredientValues({"boneshard"}, {inedible=1})
AddIngredientValues({"wormlight"}, {fruit=1})
AddIngredientValues({"lightninggoathorn"}, {inedible=1})
AddIngredientValues({"plantmeat","plantmeat_cooked"}, {meat=1})
AddIngredientValues({"trunk_summer","trunk_winter","trunk_cooked"}, {meat=1})

for k, v in pairs(DST_FOODS) do
    v.name = k
    v.weight = v.weight or 1
    v.priority = v.priority or 0

    AddCookerRecipe("cookpot",v)
    AddCookerRecipe("portablecookpot",v)
end

return DST_FOODS
