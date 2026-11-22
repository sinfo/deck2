import type { GmailMessage } from "../useGmailMessages";

// Filter only clear automatic replies and delivery failures, not subjects or body text.
export const isAutomaticGmailResponse = (message: GmailMessage): boolean => {
  const header = (name: string): string =>
    message.payload.headers
      .find((item) => item.name.toLowerCase() === name)
      ?.value.trim()
      .toLowerCase() ?? "";

  if (header("auto-submitted").startsWith("auto-replied")) return true;
  if (header("x-autoreply") || header("x-autorespond")) return true;
  if (header("x-failed-recipients")) return true;
  if (/report-type\s*=\s*"?delivery-status\b/.test(header("content-type"))) {
    return true;
  }
  if (
    message.payload.mimeType === "message/delivery-status" ||
    message.payload.parts?.some((part) => part.mimeType === "message/delivery-status")
  ) {
    return true;
  }
  return (
    header("return-path") === "<>" &&
    /(?:^|[<\s])mailer-daemon@/.test(header("from"))
  );
};
