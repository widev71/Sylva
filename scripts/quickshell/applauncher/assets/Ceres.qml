import QtQuick
import QtQuick3D

import QtQuick.Timeline

Node {
    id: node

    // Resources
    property url textureData: "maps/textureData.jpg"
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
        id: material_material
        objectName: "material"
        baseColorMap: _0_texture
        metalnessMap: _1_texture
        roughnessMap: _1_texture
        roughness: 1
        normalMap: _2_texture
        occlusionMap: _1_texture
        alphaMode: PrincipledMaterial.Opaque
    }

    // Nodes:
    Node {
        id: sketchfab_model
        objectName: "Sketchfab_model"
        rotation: Qt.quaternion(0.707107, -0.707107, 0, 0)
        Node {
            id: adcf2212aa5d4a3ba26a0bed0f698253_fbx
            objectName: "adcf2212aa5d4a3ba26a0bed0f698253.fbx"
            rotation: Qt.quaternion(0.707107, 0.707107, 0, 0)
            Node {
                id: object_2
                objectName: "Object_2"
                Node {
                    id: rootNode
                    objectName: "RootNode"
                    Node {
                        id: ceresLP
                        objectName: "CeresLP"
                        position: Qt.vector3d(0.0194588, 0.025906, 0.00363207)
                        rotation: Qt.quaternion(0.707107, -0.707107, 0, 0)
                        scale: Qt.vector3d(1, 1, 1)
                        Model {
                            id: ceresLP_1_0
                            objectName: "CeresLP_1_0"
                            source: "meshes/ceresLP_1_0_mesh.mesh"
                            materials: [
                                material_material
                            ]
                        }
                    }
                }
            }
        }
    }

    // Animations:
    Timeline {
        id: rotation_timeline
        objectName: "Rotation"
        property real framesPerSecond: 1000
        startFrame: 0
        endFrame: 3334
        currentFrame: 0
        enabled: false // Disabled so it doesn't spin too fast automatically
        animations: TimelineAnimation {
            duration: 3334
            from: 0
            to: 3334
            running: false // Disabled automatic animation
            loops: Animation.Infinite
        }
        KeyframeGroup {
            target: ceresLP
            property: "rotation"
            keyframeSource: "animations/ceresLP_rotation_0.qad"
        }
    }
}
