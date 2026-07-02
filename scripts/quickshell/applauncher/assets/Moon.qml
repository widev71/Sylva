import QtQuick
import QtQuick3D

import QtQuick.Timeline

Node {
    id: node

    // Resources
    property url textureData: "maps/textureData.png"
    property url textureData12: "maps/textureData12.png"
    property url textureData14: "maps/textureData14.png"
    Texture {
        id: _0_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: node.textureData
    }
    Texture {
        id: _1_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: node.textureData12
    }
    Texture {
        id: _2_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: node.textureData14
    }
    PrincipledMaterial {
        id: moon_material
        objectName: "moon"
        baseColorMap: _0_texture
        metalnessMap: _1_texture
        roughnessMap: _1_texture
        metalness: 0.800000011920929
        roughness: 1
        normalMap: _2_texture
        normalStrength: 0.25
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }

    // Nodes:
    Node {
        id: sketchfab_model
        objectName: "Sketchfab_model"
        rotation: Qt.quaternion(0.694543, -0.694543, 0.132703, -0.132703)
        Node {
            id: fe445625fbbc4d229596c318dc5705b9_fbx
            objectName: "fe445625fbbc4d229596c318dc5705b9.fbx"
            rotation: Qt.quaternion(0.707107, 0.707107, 0, 0)
            scale: Qt.vector3d(0.01, 0.01, 0.01)
            Node {
                id: object_2
                objectName: "Object_2"
                Node {
                    id: rootNode
                    objectName: "RootNode"
                    Node {
                        id: moon
                        objectName: "moon"
                        rotation: Qt.quaternion(0.403884, -0.403884, 0.580412, 0.580412)
                        scale: Qt.vector3d(100, 100, 100)
                        Model {
                            id: moon_moon_0
                            objectName: "moon_moon_0"
                            source: "meshes/moon_moon_0_mesh.mesh"
                            materials: [
                                moon_material
                            ]
                        }
                    }
                }
            }
        }
    }

    // Animations:
    Timeline {
        id: moon_moonAction_timeline
        objectName: "moon|moonAction"
        property real framesPerSecond: 1000
        startFrame: 0
        endFrame: 154167
        currentFrame: 0
        enabled: true
        animations: TimelineAnimation {
            duration: 154167
            from: 0
            to: 154167
            running: true
            loops: Animation.Infinite
        }
        KeyframeGroup {
            target: moon
            property: "rotation"
            keyframeSource: "animations/moon_rotation_0.qad"
        }
    }
}
