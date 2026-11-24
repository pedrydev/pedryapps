import Foundation
import MCP

protocol AgentNotificationPosting: Sendable {
    func post(source: MiniApp, type: NotificationType, title: String, body: String) async
}

func makeAgentMCPServer(posting: any AgentNotificationPosting) async -> Server {
    let server = Server(
        name: "PedryApps",
        version: "1.0",
        capabilities: .init(tools: .init())
    )
    let tool = sendNotificationTool

    await server.withMethodHandler(ListTools.self) { _ in
        ListTools.Result(tools: [tool])
    }

    await server.withMethodHandler(CallTool.self) { request in
        guard request.name == "send_notification" else {
            return errorResult("Unknown tool: \(request.name)")
        }

        let arguments = request.arguments ?? [:]
        guard let title = arguments["title"]?.stringValue, !title.isEmpty,
            let body = arguments["body"]?.stringValue, !body.isEmpty,
            let rawType = arguments["type"]?.stringValue,
            let type = NotificationType(rawValue: rawType)
        else {
            return errorResult("send_notification requires a title, body and valid type")
        }

        await posting.post(source: .notifications, type: type, title: title, body: body)
        return CallTool.Result(
            content: [.text(text: "Notification posted to the Inbox.", annotations: nil, _meta: nil)]
        )
    }

    return server
}

private let sendNotificationTool = Tool(
    name: "send_notification",
    description:
        "Post a Notification into the Inbox. Choose Information for something that already happened and may be worth checking now or later. Choose Attention request for something that happened and needs further action from the user.",
    inputSchema: [
        "type": "object",
        "properties": [
            "title": ["type": "string", "description": "Short notification title"],
            "body": ["type": "string", "description": "Notification body"],
            "type": [
                "type": "string",
                "enum": ["information", "attentionRequest"],
                "description":
                    "Information: something that already happened and may be worth checking now or later. Attention request: something that happened and needs further action from the user.",
            ],
        ],
        "required": ["title", "body", "type"],
        "additionalProperties": false,
    ]
)

nonisolated private func errorResult(_ message: String) -> CallTool.Result {
    CallTool.Result(
        content: [.text(text: message, annotations: nil, _meta: nil)],
        isError: true
    )
}
