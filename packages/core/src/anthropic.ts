import Anthropic from "@anthropic-ai/sdk";

export type ClaudeAttachment =
  | {
      kind: "pdf";
      mediaType: "application/pdf";
      dataBase64: string;
    }
  | {
      kind: "image";
      mediaType: "image/jpeg" | "image/png" | "image/gif" | "image/webp";
      dataBase64: string;
    };

export type ClaudeMessageInput = {
  system?: string;
  text: string;
  attachments?: ClaudeAttachment[];
  model?: string;
  maxTokens?: number;
};

export function createAnthropicClient(apiKey: string): Anthropic {
  return new Anthropic({ apiKey });
}

export async function sendClaudeMessage(client: Anthropic, input: ClaudeMessageInput) {
  const content: Anthropic.Messages.ContentBlockParam[] = [
    {
      type: "text",
      text: input.text
    }
  ];

  for (const attachment of input.attachments ?? []) {
    if (attachment.kind === "pdf") {
      content.push({
        type: "document",
        source: {
          type: "base64",
          media_type: attachment.mediaType,
          data: attachment.dataBase64
        }
      });
      continue;
    }

    content.push({
      type: "image",
      source: {
        type: "base64",
        media_type: attachment.mediaType,
        data: attachment.dataBase64
      }
    });
  }

  return client.messages.create({
    model: input.model ?? "claude-3-5-sonnet-latest",
    max_tokens: input.maxTokens ?? 4096,
    system: input.system,
    messages: [
      {
        role: "user",
        content
      }
    ]
  });
}
