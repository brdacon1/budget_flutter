import UIKit

/// Share Extension do OFLite: recebe imagens e PDF (comprovantes) e abre o
/// app no chat (ver CHAT_AI_AGENT_PLAN §15.4).
class ShareViewController: RSIShareViewController {
    override func shouldAutoRedirect() -> Bool { true }
}
