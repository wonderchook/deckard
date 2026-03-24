import XCTest
@testable import Deckard

final class SidebarFolderTests: XCTestCase {

    // MARK: - SidebarFolderState Codable roundtrips

    func testSidebarFolderStateRoundtrip() throws {
        let state = SidebarFolderState(
            id: "folder-1",
            name: "My Folder",
            isCollapsed: true,
            projectIds: ["proj-a", "proj-b", "proj-c"]
        )

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(SidebarFolderState.self, from: data)

        XCTAssertEqual(decoded.id, "folder-1")
        XCTAssertEqual(decoded.name, "My Folder")
        XCTAssertTrue(decoded.isCollapsed)
        XCTAssertEqual(decoded.projectIds, ["proj-a", "proj-b", "proj-c"])
    }

    func testSidebarFolderStateEmptyProjectIds() throws {
        let state = SidebarFolderState(
            id: "folder-empty",
            name: "Empty Folder",
            isCollapsed: false,
            projectIds: []
        )

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(SidebarFolderState.self, from: data)

        XCTAssertEqual(decoded.id, "folder-empty")
        XCTAssertEqual(decoded.name, "Empty Folder")
        XCTAssertFalse(decoded.isCollapsed)
        XCTAssertEqual(decoded.projectIds, [])
    }

    // MARK: - SidebarOrderItem Codable roundtrips

    func testSidebarOrderItemFolderRoundtrip() throws {
        let item = SidebarOrderItem.folder("folder-abc")

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(SidebarOrderItem.self, from: data)

        if case .folder(let id) = decoded {
            XCTAssertEqual(id, "folder-abc")
        } else {
            XCTFail("Expected .folder case, got \(decoded)")
        }
    }

    func testSidebarOrderItemProjectRoundtrip() throws {
        let item = SidebarOrderItem.project("proj-xyz")

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(SidebarOrderItem.self, from: data)

        if case .project(let id) = decoded {
            XCTAssertEqual(id, "proj-xyz")
        } else {
            XCTFail("Expected .project case, got \(decoded)")
        }
    }

    func testSidebarOrderItemInvalidTypeThrows() throws {
        let json = """
        {"type": "unknown", "id": "some-id"}
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(SidebarOrderItem.self, from: json)) { error in
            guard case DecodingError.dataCorrupted(let context) = error else {
                XCTFail("Expected DecodingError.dataCorrupted, got \(error)")
                return
            }
            XCTAssertTrue(context.debugDescription.contains("Unknown sidebar order item type"))
        }
    }

    func testSidebarOrderItemEncodedShape() throws {
        // Verify the JSON shape is {"type": "folder", "id": "..."}
        let item = SidebarOrderItem.folder("f1")
        let data = try JSONEncoder().encode(item)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: String]

        XCTAssertEqual(dict?["type"], "folder")
        XCTAssertEqual(dict?["id"], "f1")
    }

    func testSidebarOrderItemProjectEncodedShape() throws {
        let item = SidebarOrderItem.project("p1")
        let data = try JSONEncoder().encode(item)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: String]

        XCTAssertEqual(dict?["type"], "project")
        XCTAssertEqual(dict?["id"], "p1")
    }

    // MARK: - DeckardState with folders

    func testDeckardStateWithFoldersRoundtrip() throws {
        var state = DeckardState()
        state.sidebarFolders = [
            SidebarFolderState(id: "f1", name: "Work", isCollapsed: false, projectIds: ["p1", "p2"]),
            SidebarFolderState(id: "f2", name: "Personal", isCollapsed: true, projectIds: ["p3"]),
        ]
        state.sidebarOrder = [
            .folder("f1"),
            .project("p4"),
            .folder("f2"),
        ]
        state.projects = [
            ProjectState(id: "p1", path: "/work/a", name: "a", selectedTabIndex: 0, tabs: []),
            ProjectState(id: "p2", path: "/work/b", name: "b", selectedTabIndex: 0, tabs: []),
            ProjectState(id: "p3", path: "/personal/c", name: "c", selectedTabIndex: 0, tabs: []),
            ProjectState(id: "p4", path: "/other/d", name: "d", selectedTabIndex: 0, tabs: []),
        ]

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(DeckardState.self, from: data)

        XCTAssertEqual(decoded.sidebarFolders?.count, 2)
        XCTAssertEqual(decoded.sidebarFolders?[0].name, "Work")
        XCTAssertEqual(decoded.sidebarFolders?[0].projectIds, ["p1", "p2"])
        XCTAssertEqual(decoded.sidebarFolders?[1].name, "Personal")
        XCTAssertTrue(decoded.sidebarFolders?[1].isCollapsed == true)
        XCTAssertEqual(decoded.sidebarOrder?.count, 3)

        // Verify order items
        if case .folder(let id) = decoded.sidebarOrder?[0] {
            XCTAssertEqual(id, "f1")
        } else {
            XCTFail("Expected .folder at index 0")
        }
        if case .project(let id) = decoded.sidebarOrder?[1] {
            XCTAssertEqual(id, "p4")
        } else {
            XCTFail("Expected .project at index 1")
        }
        if case .folder(let id) = decoded.sidebarOrder?[2] {
            XCTAssertEqual(id, "f2")
        } else {
            XCTFail("Expected .folder at index 2")
        }
    }

    func testDeckardStateNilFoldersBackwardCompat() throws {
        // Simulate a v2 state without folder fields
        var state = DeckardState()
        state.projects = [
            ProjectState(id: "p1", path: "/test", name: "test", selectedTabIndex: 0, tabs: [])
        ]
        // sidebarFolders and sidebarOrder deliberately left nil

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(DeckardState.self, from: data)

        XCTAssertNil(decoded.sidebarFolders)
        XCTAssertNil(decoded.sidebarOrder)
        XCTAssertEqual(decoded.projects?.count, 1)
    }

    func testDeckardStateMixedSidebarOrder() throws {
        var state = DeckardState()
        state.sidebarFolders = [
            SidebarFolderState(id: "f1", name: "Folder", isCollapsed: false, projectIds: [])
        ]
        state.sidebarOrder = [
            .project("p1"),
            .folder("f1"),
            .project("p2"),
            .project("p3"),
            .folder("f1"),  // duplicate folder reference (edge case)
            .project("p4"),
        ]

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(DeckardState.self, from: data)

        XCTAssertEqual(decoded.sidebarOrder?.count, 6)

        // Verify alternating types
        if case .project = decoded.sidebarOrder?[0] {} else { XCTFail("Expected .project at 0") }
        if case .folder = decoded.sidebarOrder?[1] {} else { XCTFail("Expected .folder at 1") }
        if case .project = decoded.sidebarOrder?[2] {} else { XCTFail("Expected .project at 2") }
        if case .project = decoded.sidebarOrder?[3] {} else { XCTFail("Expected .project at 3") }
        if case .folder = decoded.sidebarOrder?[4] {} else { XCTFail("Expected .folder at 4") }
        if case .project = decoded.sidebarOrder?[5] {} else { XCTFail("Expected .project at 5") }
    }

    func testDeckardStateEmptyFoldersAndOrder() throws {
        var state = DeckardState()
        state.sidebarFolders = []
        state.sidebarOrder = []

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(DeckardState.self, from: data)

        XCTAssertEqual(decoded.sidebarFolders?.count, 0)
        XCTAssertEqual(decoded.sidebarOrder?.count, 0)
    }

    // MARK: - SidebarFolder data model

    func testSidebarFolderInitDefaults() {
        let folder = SidebarFolder(name: "Test Folder")

        XCTAssertEqual(folder.name, "Test Folder")
        XCTAssertFalse(folder.isCollapsed)
        XCTAssertEqual(folder.projectIds, [])
        XCTAssertNotEqual(folder.id, UUID()) // has a valid UUID
    }

    func testSidebarFolderProjectIdsAddRemove() {
        let folder = SidebarFolder(name: "Folder")
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        folder.projectIds.append(id1)
        folder.projectIds.append(id2)
        folder.projectIds.append(id3)
        XCTAssertEqual(folder.projectIds.count, 3)
        XCTAssertEqual(folder.projectIds, [id1, id2, id3])

        folder.projectIds.removeAll { $0 == id2 }
        XCTAssertEqual(folder.projectIds.count, 2)
        XCTAssertEqual(folder.projectIds, [id1, id3])

        folder.projectIds.removeAll()
        XCTAssertEqual(folder.projectIds.count, 0)
    }

    func testSidebarFolderIsCollapsedToggle() {
        let folder = SidebarFolder(name: "Folder")
        XCTAssertFalse(folder.isCollapsed)

        folder.isCollapsed.toggle()
        XCTAssertTrue(folder.isCollapsed)

        folder.isCollapsed.toggle()
        XCTAssertFalse(folder.isCollapsed)
    }

    func testSidebarFolderFullInit() {
        let id = UUID()
        let pid1 = UUID()
        let pid2 = UUID()
        let folder = SidebarFolder(id: id, name: "Custom", isCollapsed: true, projectIds: [pid1, pid2])

        XCTAssertEqual(folder.id, id)
        XCTAssertEqual(folder.name, "Custom")
        XCTAssertTrue(folder.isCollapsed)
        XCTAssertEqual(folder.projectIds, [pid1, pid2])
    }

    // MARK: - SidebarItem enum

    func testSidebarItemFolderCase() {
        let folder = SidebarFolder(name: "Test")
        let item = SidebarItem.folder(folder)

        if case .folder(let f) = item {
            XCTAssertTrue(f === folder) // same reference
            XCTAssertEqual(f.name, "Test")
        } else {
            XCTFail("Expected .folder case")
        }
    }

    func testSidebarItemProjectCase() {
        let projectId = UUID()
        let item = SidebarItem.project(projectId)

        if case .project(let id) = item {
            XCTAssertEqual(id, projectId)
        } else {
            XCTFail("Expected .project case")
        }
    }

    func testSidebarItemFolderMutationThroughReference() {
        let folder = SidebarFolder(name: "Before")
        let item = SidebarItem.folder(folder)

        // Mutating the folder should be visible through the enum
        folder.name = "After"

        if case .folder(let f) = item {
            XCTAssertEqual(f.name, "After")
        } else {
            XCTFail("Expected .folder case")
        }
    }

    // MARK: - ProjectTabState with tmuxSessionName

    func testProjectTabStateWithTmuxSessionName() throws {
        let tab = ProjectTabState(
            id: "tab-1",
            name: "Terminal",
            isClaude: false,
            sessionId: "sess-1",
            tmuxSessionName: "deckard-main-1"
        )

        let data = try JSONEncoder().encode(tab)
        let decoded = try JSONDecoder().decode(ProjectTabState.self, from: data)

        XCTAssertEqual(decoded.id, "tab-1")
        XCTAssertEqual(decoded.name, "Terminal")
        XCTAssertFalse(decoded.isClaude)
        XCTAssertEqual(decoded.sessionId, "sess-1")
        XCTAssertEqual(decoded.tmuxSessionName, "deckard-main-1")
    }

    func testProjectTabStateWithNilTmuxSessionName() throws {
        let tab = ProjectTabState(
            id: "tab-2",
            name: "Claude",
            isClaude: true,
            sessionId: "sess-2",
            tmuxSessionName: nil
        )

        let data = try JSONEncoder().encode(tab)
        let decoded = try JSONDecoder().decode(ProjectTabState.self, from: data)

        XCTAssertEqual(decoded.id, "tab-2")
        XCTAssertEqual(decoded.name, "Claude")
        XCTAssertTrue(decoded.isClaude)
        XCTAssertEqual(decoded.sessionId, "sess-2")
        XCTAssertNil(decoded.tmuxSessionName)
    }

    func testProjectTabStateBackwardCompatNoTmuxField() throws {
        // Simulate JSON without tmuxSessionName field (old format)
        let json = """
        {"id": "tab-3", "name": "Terminal", "isClaude": false}
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(ProjectTabState.self, from: json)

        XCTAssertEqual(decoded.id, "tab-3")
        XCTAssertEqual(decoded.name, "Terminal")
        XCTAssertFalse(decoded.isClaude)
        XCTAssertNil(decoded.sessionId)
        XCTAssertNil(decoded.tmuxSessionName)
    }

    // MARK: - SidebarFolderState edge cases

    func testSidebarFolderStateSpecialCharactersInName() throws {
        let state = SidebarFolderState(
            id: "f-special",
            name: "Work / Personal (2024) & More \u{1F4C1}",
            isCollapsed: false,
            projectIds: ["p1"]
        )

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(SidebarFolderState.self, from: data)

        XCTAssertEqual(decoded.name, "Work / Personal (2024) & More \u{1F4C1}")
    }

    func testSidebarFolderStateManyProjectIds() throws {
        let ids = (0..<100).map { "proj-\($0)" }
        let state = SidebarFolderState(
            id: "f-large",
            name: "Large Folder",
            isCollapsed: false,
            projectIds: ids
        )

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(SidebarFolderState.self, from: data)

        XCTAssertEqual(decoded.projectIds.count, 100)
        XCTAssertEqual(decoded.projectIds.first, "proj-0")
        XCTAssertEqual(decoded.projectIds.last, "proj-99")
    }

    // MARK: - SidebarOrderItem array roundtrip

    func testSidebarOrderItemArrayRoundtrip() throws {
        let items: [SidebarOrderItem] = [
            .folder("f1"),
            .project("p1"),
            .project("p2"),
            .folder("f2"),
            .project("p3"),
        ]

        let data = try JSONEncoder().encode(items)
        let decoded = try JSONDecoder().decode([SidebarOrderItem].self, from: data)

        XCTAssertEqual(decoded.count, 5)

        if case .folder(let id) = decoded[0] { XCTAssertEqual(id, "f1") }
        else { XCTFail("Expected .folder at 0") }

        if case .project(let id) = decoded[1] { XCTAssertEqual(id, "p1") }
        else { XCTFail("Expected .project at 1") }

        if case .project(let id) = decoded[2] { XCTAssertEqual(id, "p2") }
        else { XCTFail("Expected .project at 2") }

        if case .folder(let id) = decoded[3] { XCTAssertEqual(id, "f2") }
        else { XCTFail("Expected .folder at 3") }

        if case .project(let id) = decoded[4] { XCTAssertEqual(id, "p3") }
        else { XCTFail("Expected .project at 4") }
    }
}
