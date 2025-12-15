/**
 * Check whether a string is a valid MongoDB ObjectID (24 hex characters)
 */
export function isObjectId(id: unknown): boolean {
  if (!id || typeof id !== "string") return false;
  return /^[a-fA-F0-9]{24}$/.test(id);
}

/**
 * Validate an array of items with shape { item: string }
 * Returns array of invalid item ids (strings)
 */
export function findInvalidItemIds(items: Array<{ item?: unknown }>): string[] {
  const invalid: string[] = [];
  for (const it of items || []) {
    const id = it?.item;
    if (!isObjectId(id)) {
      invalid.push(String(id ?? ""));
    }
  }
  return invalid;
}
