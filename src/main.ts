import * as rm from "https://deno.land/x/remapper@4.2.0/src/mod.ts"
import * as bundleInfo from '../bundleinfo.json' with { type: 'json' }

const pipeline = await rm.createPipeline({ bundleInfo })

const bundle = rm.loadBundle(bundleInfo)
const materials = bundle.materials
const prefabs = bundle.prefabs

// ----------- { SCRIPT } -----------

async function doMap(file: rm.DIFFICULTY_NAME) {
    const map = await rm.readDifficultyV3(pipeline, file)
    map.difficultyInfo.requirements = [
        'Chroma',
        'Noodle Extensions',
        'Vivify',
    ]
    rm.environmentRemoval(map, ['Environment', 'GameCore'])

    map.difficultyInfo.settingsSetter = {
        graphics: {
            screenDisplacementEffectsEnabled: true,
        },
        chroma: {
            disableEnvironmentEnhancements: false,
        },
        playerOptions: {
            leftHanded: rm.BOOLEAN.False,
            reduceDebris: rm.BOOLEAN.True,
        },
        colors: {},
        environments: {},
    }

    rm.setRenderingSettings(map, {
        qualitySettings: {
            realtimeReflectionProbes: rm.BOOLEAN.True,
            shadows: rm.SHADOWS.HardOnly,
            shadowDistance: 64,
            shadowResolution: rm.SHADOW_RESOLUTION.VeryHigh,
            
        },
        renderSettings: {
            fog: rm.BOOLEAN.True,
            fogEndDistance: 64,
        },
    })

    const Intro = prefabs.intro.instantiate(map, 0)
    const Talk1 = prefabs.talk1.instantiate(map, 0)
    const Talk2 = prefabs.talk2.instantiate(map, 0)
    const OldKing = prefabs.oldking.instantiate(map, 0)
    const Kill = prefabs.kill.instantiate(map, 0)

    rm.assignObjectPrefab(map, {
        saber: {
            type: 'Both',
            asset: prefabs.customsaber.path
        }
    })

    rm.assignObjectPrefab(map, {
        colorNotes: {
            track: 'MainNotes',
            asset: prefabs['custom note'].path,
            Desbrisasset: prefabs['custom note debris'].path,
            anyDirectionAsset: prefabs['custom note dot'].path
        }
    })

    map.allNotes.forEach(note => {
         note.track.add('MainNotes')
         note.unsafeCustomData._disableSpawnEffect = rm.BOOLEAN.True
     })

    // For more help, read: https://github.com/Swifter1243/ReMapper/wiki
}




await Promise.all([
    doMap('ExpertPlusStandard')
])

// ----------- { OUTPUT } -----------

pipeline.export({
    outputDirectory: '../Oddyseus'
})

// deno run --allow-all src/main.ts