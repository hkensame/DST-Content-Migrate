-- DST 移植特效合集：天体英雄、蚁狮、邪天翁、月岛、克劳斯、织影者、蘑菇地精等战斗/环境特效

local function FinalOffset1(inst)
    inst.AnimState:SetFinalOffset(1)
end

local function FinalOffset2(inst)
    inst.AnimState:SetFinalOffset(2)
end

local function FinalOffset3(inst)
    inst.AnimState:SetFinalOffset(3)
end

local function GroundOrientation(inst)
    inst.AnimState:SetSortOrder( 1 )
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
end

local function UsePointFiltering(inst)
    inst.AnimState:UsePointFiltering(true)
end

local dst_fx =
{

    {
        name = "mining_moonglass_fx",
        bank = "glass_mining_fx",
        build = "glass_mining_fx",
        subfolder = "moonisland",
        anim = "anim",
    },
    {
        name = "splash_sink",
        bank = "splash_water_drop",
        build = "splash_water_drop",
        anim = "idle_sink",
        --fn = function(inst) inst.AnimState:SetOceanBlendParams(TUNING.OCEAN_SHADER.EFFECT_TINT_AMOUNT) end,
        sound = "turnoftides/common/together/water/splash/small",
    },
--天体英雄
    {
        name = "alterguardian_spike_breakfx",
        bank = "alterguardian_spike",
        build = "alterguardian_spike",
        subfolder = "alterguardian",
        anim = "spike_pst",
    },
    {
        name = "alterguardian_spintrail_fx",
        bank = "alterguardian_sinkhole",
        build = "alterguardian_sinkhole",
        subfolder = "alterguardian",
        anim = "pre",
        animqueue = true,
        fn = function(inst)
            GroundOrientation(inst)
            inst.Transform:SetEightFaced()

            inst.AnimState:PushAnimation("idle", true)
            inst:DoTaskInTime(60*FRAMES, function(i)
                ErodeAway(i, 60*FRAMES)
            end)
        end,
    },
    {
        name = "alterguardian_phase1fallfx",
        bank = "alterguardian_spawn_death",
        build = "alterguardian_spawn_death",
        subfolder = "alterguardian",
        anim = "fall_pre",
    },
    {
        name = "alterguardian_phase3trappst",
        bank = "alterguardian_meteor",
        build = "alterguardian_meteor",
        subfolder = "alterguardian",
        anim = "meteor_pst",
        sound = "turnoftides/common/together/moon_glass/mine",
    },
	--邪天翁
    {
        name = "splash_green_small",
        bank = "pond_splash_fx",
        build = "pond_splash_fx",
        subfolder = "moonisland",
        anim = "pond_splash",
        sound = "turnoftides/common/together/water/splash/small",
        fn = FinalOffset1,
    },
    {
        name = "splash_green",
        bank = "pond_splash_fx",
        build = "pond_splash_fx",
        subfolder = "moonisland",
        anim = "pond_splash",
        sound = "turnoftides/common/together/water/splash/medium",
        fn = function(inst) inst.Transform:SetScale(2,2,2) inst.AnimState:SetFinalOffset(1) end,
    },
    {
        name = "splash_green_large",
        bank = "pond_splash_fx",
        build = "pond_splash_fx",
        subfolder = "moonisland",
        anim = "pond_splash",
        sound = "turnoftides/common/together/water/splash/large",
        fn = function(inst) inst.Transform:SetScale(4,4,4) inst.AnimState:SetFinalOffset(1) end,
    },
    { --蚁狮和克眼钻地特效
        name = "sinkhole_spawn_fx_1",
        bank = "sinkhole_spawn_fx",
        build = "sinkhole_spawn_fx",
        subfolder = "antlion",
        anim = "idle1",
    },
    {
        name = "sinkhole_spawn_fx_2",
        bank = "sinkhole_spawn_fx",
        build = "sinkhole_spawn_fx",
        subfolder = "antlion",
        anim = "idle2",
    },
    {
        name = "sinkhole_spawn_fx_3",
        bank = "sinkhole_spawn_fx",
        build = "sinkhole_spawn_fx",
        subfolder = "antlion",
        anim = "idle3",
    },

    {--给予泰拉瑞亚噩梦燃料的特效
        name = "shadow_despawn",
        bank = "statue_ruins_fx",
        build = "statue_ruins_fx",
        anim = "transform_nightmare",
        sound = "dontstarve/maxwell/shadowmax_despawn",
        tintalpha = 0.6,
    },
    {--编织者
        name = "erode_ash",
        bank = "erode_ash",
        build = "erode_ash",
        anim = "idle",
        sound = "dontstarve/common/dust_blowaway",
    },
    { --水中木
        name = "oceantree_leaf_fx_fall",
        bank = "oceantree_leaf_fx",
        build = "oceantree_leaf_fx",
        subfolder = "moonisland",
        anim = "fall",
        fn = function(inst)
            local scale = 2 + 0.3 * math.random()
            inst.Transform:SetScale(scale, scale, scale)
            inst.fall_speed = 2.75 + 3.5 * math.random()
            inst:DoPeriodicTask(FRAMES, function(inst)
              local x, y, z = inst.Transform:GetWorldPosition()
              inst.Transform:SetPosition(x, y - inst.fall_speed * FRAMES, z)
            end)
        end,
    },
    { --月树
        name = "tree_petal_fx_chop",
        bank = "tree_petal_fx",
        build = "tree_petal_fx",
        anim = "chop",
    },

    { --天体科技
        name = "moon_altar_link_fx",
        bank = "moon_altar_link_fx",
        build ="moon_altar_link_fx",
        subfolder = "moonisland",
        anim = "fx1",
        fn = function(inst)
            local rand = math.random()
            if rand < 0.33 then
                inst.AnimState:PlayAnimation("fx2")
            elseif rand < 0.67 then
                inst.AnimState:PlayAnimation("fx3")
            end
        end
    },
    
    {--月亮虹吸器
        name = "moon_geyser_explode",
        bank = "moon_altar_geyser",
        build = "moon_geyser",
        subfolder = "moonisland",
        anim = "explode",
    },
    {--洞穴洞闪烁警告
        name = "cavehole_flick_warn",
        bank = "attune_fx",
        build = "attune_fx",
        anim = "attune_in",
        tint = Vector3(0, 0, 0),
        tintalpha = 0.8,
    },
    {--洞穴洞闪烁
        name = "cavehole_flick",
        bank = "statue_ruins_fx",
        build = "statue_ruins_fx",
        anim = "transform_nightmare",
        sound = "dontstarve/maxwell/shadowmax_despawn",
        tintalpha = 0.8,
        fn = UsePointFiltering,
    },
} --表

for cratersteamindex = 1, 4 do --温泉
    table.insert(dst_fx, {
        name = "crater_steam_fx"..cratersteamindex,
        bank = "crater_steam",
        build = "crater_steam",
        subfolder = "moonisland",
        anim = "steam"..cratersteamindex,
        fn = FinalOffset1,
    })
end

for slowsteamindex = 1, 5 do --温泉热气特效
    table.insert(dst_fx, {
        name = "slow_steam_fx"..slowsteamindex,
        bank = "slow_steam",
        build = "slow_steam",
        subfolder = "moonisland",
        anim = "steam"..slowsteamindex,
        fn = FinalOffset1,
    })
end

-- 月蘑菇地精吐孢子特效
table.insert(dst_fx, {
    name = "spore_moon_coughout",
    bank = "spore_moon",
    build = "mushroom_spore_moon",
    subfolder = "cave",
    anim = "pre_cough_out",
})

local function MakeFx(t)
    local assets = 
        {
            Asset("ANIM", "anim"..(t.subfolder and ("/"..t.subfolder) or "").."/"..t.build..".zip")
        }

    local function fn()
        --print ("SPAWN", debugstack())
    	local inst = CreateEntity()
    	inst.entity:AddTransform()
    	inst.entity:AddAnimState()

        if not t.twofaced then
            inst.Transform:SetFourFaced()
        else
            inst.Transform:SetTwoFaced()
        end

        if type(t.anim) ~= "string" then
            t.anim = t.anim[math.random(#t.anim)]
        end

        if t.sound or t.sound2 then
            inst.entity:AddSoundEmitter()
        end
        
        if t.fn ~= nil then
            if t.fntime ~= nil then
                inst:DoTaskInTime(t.fntime, t.fn)
            else
                t.fn(inst)
            end
        end

        if t.sound then
            inst:DoTaskInTime(t.sounddelay or 0, function() inst.SoundEmitter:PlaySound(t.sound) end)
        end

        if t.sound2 then
            inst:DoTaskInTime(t.sounddelay2 or 0, function() inst.SoundEmitter:PlaySound(t.sound2) end)
        end

        inst.AnimState:SetBank(t.bank)
        inst.AnimState:SetBuild(t.build)
        inst.AnimState:PlayAnimation(t.anim, false)
        if t.tint or t.tintalpha then
            inst.AnimState:SetMultColour((t.tint and t.tint.x) or (t.tintalpha or 1),(t.tint and t.tint.y)  or (t.tintalpha or 1),(t.tint and t.tint.z)  or (t.tintalpha or 1), t.tintalpha or 1)
        end
        --print(inst.AnimState:GetMultColour())
        if t.transform then
            inst.AnimState:SetScale(t.transform:Get())
        end

        if t.nameoverride then
            inst:AddComponent("inspectable")
            inst.components.inspectable.nameoverride = t.nameoverride
            inst.name = t.nameoverride
        end

        if t.description then
            if not inst.components.inspectable then inst:AddComponent("inspectable") end
            inst.components.inspectable.description = t.description
        end

        if t.bloom then
            inst.bloom = true
            inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )
        end

        inst:AddTag("FX")
        inst.persists = false

        if t.animqueue then
	        inst:ListenForEvent("animqueueover", inst.Remove)
	       end
        inst:ListenForEvent("animover", function() 
            if inst.bloom then inst.AnimState:ClearBloomEffectHandle() end
            inst:Remove() 
        end)

        return inst
    end
    return Prefab("common/fx/"..t.name, fn, assets)
end

local prefs = {}
for k,v in pairs(dst_fx) do
    table.insert(prefs, MakeFx(v))
end

return unpack(prefs)
