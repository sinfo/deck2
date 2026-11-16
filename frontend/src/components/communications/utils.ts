import { ThreadChannel, ThreadKind, type ThreadWithEntry } from "@/dto/threads";

export interface ParsedEmailContent {
  isEmail: boolean;
  subject?: string;
  from?: string;
  to?: string;
  body: string;
}

// Cache parsed email headers and bodies across template render cycles to avoid repetitive regex/string work.
const emailParseCache = new Map<string, ParsedEmailContent>();

export const parseEmailText = (text?: string): ParsedEmailContent => {
  if (!text) return { isEmail: false, body: "" };
  const cached = emailParseCache.get(text);
  if (cached) return cached;

  const lines = text.split("\n");
  let subject: string | undefined;
  let from: string | undefined;
  let to: string | undefined;
  let headerEndIndex = -1;

  for (let i = 0; i < Math.min(lines.length, 6); i++) {
    const line = lines[i].trim();
    if (line.startsWith("📧")) {
      subject = line.replace(/^📧\s*/, "").trim();
      headerEndIndex = i;
    } else if (line.startsWith("De:") || line.startsWith("From:")) {
      from = line.replace(/^(De|From):\s*/, "").trim();
      headerEndIndex = i;
    } else if (line.startsWith("Para:") || line.startsWith("To:")) {
      to = line.replace(/^(Para|To):\s*/, "").trim();
      headerEndIndex = i;
    } else if (line === "" && (subject || from || to)) {
      headerEndIndex = i;
      break;
    }
  }

  const isEmail = Boolean(subject || from || to);
  let result: ParsedEmailContent;
  if (!isEmail) {
    result = { isEmail: false, body: text };
  } else {
    const body = lines
      .slice(headerEndIndex + 1)
      .join("\n")
      .trim();
    result = {
      isEmail: true,
      subject,
      from,
      to,
      body: body || text,
    };
  }

  if (emailParseCache.size > 200) {
    emailParseCache.clear();
  }
  emailParseCache.set(text, result);
  return result;
};

export const formatFullDateTime = (dateString: string): string => {
  const date = new Date(dateString);
  return date.toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
};

const textLinesCache = new Map<
  string,
  { leadingLines: string[]; lastLine: string }
>();

export const splitTextLines = (
  text?: string,
): { leadingLines: string[]; lastLine: string } => {
  if (!text) return { leadingLines: [], lastLine: "" };
  const cached = textLinesCache.get(text);
  if (cached) return cached;

  const trimmed = text.replace(/\n+$/, "");
  const lines = trimmed.split("\n");
  const result = {
    leadingLines: lines.slice(0, -1),
    lastLine: lines[lines.length - 1] ?? "",
  };

  if (textLinesCache.size > 200) {
    textLinesCache.clear();
  }
  textLinesCache.set(text, result);
  return result;
};

// A subject alone does not identify a unique Gmail conversation.
export const getThreadKey = (thread: ThreadWithEntry): string | null =>
  thread.gmailThreadId || null;

export const getThreadChannel = (thread: ThreadWithEntry): ThreadChannel => {
  if (thread.channel === ThreadChannel.LinkedIn) return ThreadChannel.LinkedIn;
  if (thread.channel === ThreadChannel.Other) return ThreadChannel.Other;
  return ThreadChannel.Gmail;
};

export const getBubbleClasses = (thread: ThreadWithEntry): string => {
  if (thread.kind === ThreadKind.ThreadKindPhoneCall) {
    return "bg-purple-100 text-purple-900 border border-purple-200 dark:bg-purple-950/60 dark:text-purple-200 dark:border-purple-900";
  }

  const isOutgoing = getMessageDirection(thread.kind) === "outgoing";
  const channel = getThreadChannel(thread);

  if (channel === ThreadChannel.LinkedIn) {
    return isOutgoing
      ? "bg-blue-800 text-white border border-blue-900 shadow-xs dark:bg-blue-900 dark:text-blue-50"
      : "bg-blue-100 text-blue-950 border border-blue-200 dark:bg-blue-950/50 dark:text-blue-100 dark:border-blue-900/60";
  }

  if (channel === ThreadChannel.Other) {
    return isOutgoing
      ? "bg-zinc-800 text-white border border-zinc-900 shadow-xs dark:bg-zinc-800 dark:text-zinc-50"
      : "bg-zinc-100 text-zinc-950 border border-zinc-200 dark:bg-zinc-900/60 dark:text-zinc-100 dark:border-zinc-800";
  }

  // Gmail (default)
  return isOutgoing
    ? "bg-[#712b27] text-white border border-[#5c2927] shadow-xs dark:bg-[#712b27] dark:text-red-50 dark:border-[#5c2927]"
    : "bg-red-100 text-red-950 border border-red-200 dark:bg-red-950/50 dark:text-red-100 dark:border-red-900/60";
};

export const getHeaderCardClasses = (thread: ThreadWithEntry): string => {
  const isOutgoing = getMessageDirection(thread.kind) === "outgoing";
  if (isOutgoing) {
    return "bg-white/10 border-white/20 text-white";
  }

  switch (getThreadChannel(thread)) {
    case ThreadChannel.LinkedIn:
      return "bg-white/80 dark:bg-black/30 border-blue-200/60 dark:border-blue-900/40 text-blue-950 dark:text-blue-200";
    case ThreadChannel.Other:
      return "bg-white/80 dark:bg-black/30 border-zinc-200/60 dark:border-zinc-800 text-zinc-950 dark:text-zinc-200";
    default:
      return "bg-white/80 dark:bg-black/30 border-red-200/60 dark:border-red-900/40 text-red-950 dark:text-red-200";
  }
};

export const getDividerLabel = (thread: ThreadWithEntry): string => {
  switch (getThreadChannel(thread)) {
    case ThreadChannel.LinkedIn:
      return "LinkedIn";
    case ThreadChannel.Other:
      return "Outro";
    default: {
      const emailInfo = parseEmailText(thread.entry?.text);
      if (emailInfo.subject) return `Gmail: ${emailInfo.subject}`;
      if (thread.gmailThreadId)
        return `Gmail: #${thread.gmailThreadId.slice(-6)}`;
      return "Gmail";
    }
  }
};

export const getMessageDirection = (
  kind: ThreadKind,
): "incoming" | "outgoing" => {
  return kind === ThreadKind.ThreadKindTo ||
    kind === ThreadKind.ThreadKindTemplate ||
    kind === ThreadKind.ThreadKindPhoneCall
    ? "outgoing"
    : "incoming";
};

export const getKindLabel = (kind: ThreadKind): string => {
  switch (kind) {
    case ThreadKind.ThreadKindTo:
      return "Sent";
    case ThreadKind.ThreadKindFrom:
      return "Received";
    case ThreadKind.ThreadKindPhoneCall:
      return "Phone Call";
    case ThreadKind.ThreadKindMeeting:
      return "Meeting";
    case ThreadKind.ThreadKindTemplate:
      return "Template";
    default:
      return "Unknown";
  }
};

export const getKindColor = (kind: ThreadKind): string => {
  switch (kind) {
    case ThreadKind.ThreadKindTo:
      return "bg-blue-500";
    case ThreadKind.ThreadKindFrom:
      return "bg-green-500";
    case ThreadKind.ThreadKindPhoneCall:
      return "bg-purple-500";
    case ThreadKind.ThreadKindMeeting:
      return "bg-orange-500";
    case ThreadKind.ThreadKindTemplate:
      return "bg-gray-500";
    default:
      return "bg-gray-400";
  }
};

export const isSameDay = (d1: Date, d2: Date): boolean => {
  return (
    d1.getFullYear() === d2.getFullYear() &&
    d1.getMonth() === d2.getMonth() &&
    d1.getDate() === d2.getDate()
  );
};

export const formatDate = (dateString: string): string => {
  const date = new Date(dateString);
  const now = new Date();

  if (isSameDay(date, now)) {
    return date.toLocaleTimeString("en-US", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });
  }

  return date.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
};

export type ChannelTab = "all" | "gmail" | "linkedin" | "other";

export interface ThreadGroupInfo {
  id: string;
  label: string;
  sender?: string;
  count: number;
}
