import QtQuick
import QtQuick3D

import QtQuick.Timeline

Node {
    id: node

    // Resources
    property url textureData: "maps/textureData.jpg"
    property url textureData12: "maps/textureData12.png"
    property url textureData14: "maps/textureData14.jpg"
    property url textureData20: "maps/textureData20.png"
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
    Texture {
        id: _3_texture
        generateMipmaps: true
        mipFilter: Texture.Linear
        source: node.textureData20
    }
    PrincipledMaterial {
        id: material_7_material
        objectName: "material_7"
        baseColor: "#03000000"
        roughness: 1
        emissiveFactor: Qt.vector3d(0.123667, 0.336039, 1)
        alphaMode: PrincipledMaterial.Blend
    }
    PrincipledMaterial {
        id: material_6_material
        objectName: "material_6"
        baseColor: "#03000000"
        roughness: 1
        emissiveFactor: Qt.vector3d(0.121668, 0.327322, 1)
        alphaMode: PrincipledMaterial.Blend
    }
    PrincipledMaterial {
        id: material_5_material
        objectName: "material_5"
        baseColor: "#03000000"
        roughness: 1
        emissiveFactor: Qt.vector3d(0.121668, 0.327322, 1)
        alphaMode: PrincipledMaterial.Blend
    }
    PrincipledMaterial {
        id: material_4_material
        objectName: "material_4"
        baseColor: "#03000000"
        roughness: 1
        emissiveFactor: Qt.vector3d(0.121668, 0.327322, 1)
        alphaMode: PrincipledMaterial.Blend
    }
    PrincipledMaterial {
        id: material_3_material
        objectName: "material_3"
        baseColor: "#03000000"
        roughness: 1
        emissiveFactor: Qt.vector3d(0.121668, 0.327322, 1)
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Blend
    }
    PrincipledMaterial {
        id: material_material
        objectName: "material"
        baseColor: "#03000000"
        roughness: 1
        emissiveFactor: Qt.vector3d(0.121668, 0.327322, 1)
        alphaMode: PrincipledMaterial.Blend
    }
    PrincipledMaterial {
        id: nuages_material
        objectName: "NUAGES"
        baseColor: "#33ffffff"
        baseColorMap: _3_texture
        metalness: 1
        roughness: 0.8399999737739563
        emissiveFactor: Qt.vector3d(0.0532298, 0.143203, 0.50445)
        alphaMode: PrincipledMaterial.Blend
    }
    PrincipledMaterial {
        id: terre_material
        objectName: "TERRE"
        baseColor: "#ffb3b3b3"
        baseColorMap: _0_texture
        metalnessMap: _1_texture
        roughnessMap: _1_texture
        metalness: 1
        roughness: 0.550000011920929
        emissiveMap: _2_texture
        emissiveFactor: Qt.vector3d(1, 1, 1)
        cullMode: PrincipledMaterial.NoCulling
        alphaMode: PrincipledMaterial.Opaque
    }

    // Nodes:
    Node {
        id: sketchfab_model
        objectName: "Sketchfab_model"
        rotation: Qt.quaternion(0.707107, -0.707107, 0, 0)
        scale: Qt.vector3d(0.000228699, 0.000228699, 0.000228699)
        Node {
            id: node5fbd3316863b4d98adffc1dec302e69e_fbx
            objectName: "5fbd3316863b4d98adffc1dec302e69e.fbx"
            rotation: Qt.quaternion(0.707107, 0.707107, 0, 0)
            Node {
                id: object_2
                objectName: "Object_2"
                Node {
                    id: rootNode
                    objectName: "RootNode"
                    Node {
                        id: earth_Layer1
                        objectName: "EARTH:Layer1"
                        Model {
                            id: earth_Layer1_TERRE_0
                            objectName: "EARTH:Layer1_TERRE_0"
                            source: "meshes/earth_Layer1_TERRE_0_mesh.mesh"
                            materials: [
                                terre_material
                            ]
                        }
                    }
                    Node {
                        id: earth_Layer2
                        objectName: "EARTH:Layer2"
                        Model {
                            id: earth_Layer2_NUAGES_0
                            objectName: "EARTH:Layer2_NUAGES_0"
                            source: "meshes/earth_Layer2_NUAGES_0_mesh.mesh"
                            materials: [
                                nuages_material
                            ]
                        }
                    }
                    Node {
                        id: earth_Layer3
                        objectName: "EARTH:Layer3"
                        Model {
                            id: earth_Layer3_01_0
                            objectName: "EARTH:Layer3_01_0"
                            source: "meshes/earth_Layer3_01_0_mesh.mesh"
                            materials: [
                                material_material
                            ]
                        }
                    }
                    Node {
                        id: earth_Layer4
                        objectName: "EARTH:Layer4"
                        Model {
                            id: earth_Layer4_02_0
                            objectName: "EARTH:Layer4_02_0"
                            source: "meshes/earth_Layer4_02_0_mesh.mesh"
                            materials: [
                                material_3_material
                            ]
                        }
                    }
                    Node {
                        id: earth_Layer5
                        objectName: "EARTH:Layer5"
                        Model {
                            id: earth_Layer5_03_0
                            objectName: "EARTH:Layer5_03_0"
                            source: "meshes/earth_Layer5_03_0_mesh.mesh"
                            materials: [
                                material_4_material
                            ]
                        }
                    }
                    Node {
                        id: earth_Layer6
                        objectName: "EARTH:Layer6"
                        Model {
                            id: earth_Layer6_04_0
                            objectName: "EARTH:Layer6_04_0"
                            source: "meshes/earth_Layer6_04_0_mesh.mesh"
                            materials: [
                                material_5_material
                            ]
                        }
                    }
                    Node {
                        id: earth_Layer7
                        objectName: "EARTH:Layer7"
                        Model {
                            id: earth_Layer7_05_0
                            objectName: "EARTH:Layer7_05_0"
                            source: "meshes/earth_Layer7_05_0_mesh.mesh"
                            materials: [
                                material_6_material
                            ]
                        }
                    }
                    Node {
                        id: earth_Layer8
                        objectName: "EARTH:Layer8"
                        Model {
                            id: earth_Layer8_06_0
                            objectName: "EARTH:Layer8_06_0"
                            source: "meshes/earth_Layer8_06_0_mesh.mesh"
                            materials: [
                                material_7_material
                            ]
                        }
                    }
                }
            }
        }
    }

    // Animations:
    Timeline {
        id: base_Stack_timeline
        objectName: "Base Stack"
        property real framesPerSecond: 1000
        startFrame: 0
        endFrame: 75000
        currentFrame: 0
        enabled: true
        animations: TimelineAnimation {
            duration: 75000
            from: 0
            to: 75000
            running: true
            loops: Animation.Infinite
        }
        KeyframeGroup {
            target: earth_Layer8
            property: "rotation"
            keyframeSource: "animations/earth_Layer8_rotation_0.qad"
        }
        KeyframeGroup {
            target: earth_Layer7
            property: "rotation"
            keyframeSource: "animations/earth_Layer7_rotation_0.qad"
        }
        KeyframeGroup {
            target: earth_Layer6
            property: "rotation"
            keyframeSource: "animations/earth_Layer6_rotation_0.qad"
        }
        KeyframeGroup {
            target: earth_Layer5
            property: "rotation"
            keyframeSource: "animations/earth_Layer5_rotation_0.qad"
        }
        KeyframeGroup {
            target: earth_Layer4
            property: "rotation"
            keyframeSource: "animations/earth_Layer4_rotation_0.qad"
        }
        KeyframeGroup {
            target: earth_Layer3
            property: "rotation"
            keyframeSource: "animations/earth_Layer3_rotation_0.qad"
        }
        KeyframeGroup {
            target: earth_Layer2
            property: "rotation"
            keyframeSource: "animations/earth_Layer2_rotation_0.qad"
        }
        KeyframeGroup {
            target: earth_Layer1
            property: "rotation"
            keyframeSource: "animations/earth_Layer1_rotation_0.qad"
        }
    }
}
