import assert from "node:assert/strict";
import test from "node:test";
import { isAutomaticGmailResponse } from "../src/composables/gmailSync/automaticReplies.ts";

const message = (headers = [], mimeType = "text/plain", parts = []) => ({
  payload: {
    headers: headers.map(([name, value]) => ({ name, value })),
    mimeType,
    parts,
  },
});

test("filters automatic out-of-office replies by metadata", () => {
  assert.equal(
    isAutomaticGmailResponse(message([["AUTO-SUBMITTED", "auto-replied"]])),
    true,
  );
  assert.equal(
    isAutomaticGmailResponse(message([["X-Autoreply", "yes"]])),
    true,
  );
  assert.equal(
    isAutomaticGmailResponse(message([["X-Autorespond", "yes"]])),
    true,
  );
});

test("filters delivery-failure reports", () => {
  assert.equal(
    isAutomaticGmailResponse(
      message([["Content-Type", "multipart/report; report-type=delivery-status"]]),
    ),
    true,
  );
  assert.equal(
    isAutomaticGmailResponse(
      message([], "multipart/report", [{ mimeType: "message/delivery-status" }]),
    ),
    true,
  );
  assert.equal(
    isAutomaticGmailResponse(message([["X-Failed-Recipients", "name@example.org"]])),
    true,
  );
  assert.equal(
    isAutomaticGmailResponse(
      message([
        ["Return-Path", "<>"],
        ["From", "Mail Delivery Subsystem <mailer-daemon@example.org>"],
      ]),
    ),
    true,
  );
});

test("preserves ordinary messages and misleading non-reply metadata", () => {
  assert.equal(isAutomaticGmailResponse(message()), false);
  assert.equal(
    isAutomaticGmailResponse(message([["Auto-Submitted", "no"]])),
    false,
  );
  assert.equal(
    isAutomaticGmailResponse(message([["Auto-Submitted", "auto-generated"]])),
    false,
  );
  assert.equal(
    isAutomaticGmailResponse(
      message([["X-Auto-Response-Suppress", "All"], ["Precedence", "bulk"]]),
    ),
    false,
  );
  assert.equal(
    isAutomaticGmailResponse(message([["From", "postmaster@example.org"]])),
    false,
  );
});
