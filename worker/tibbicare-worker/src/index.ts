export interface Env {
  AI: Ai;
  MODEL?: string;
  APP_KEY?: string; // optional MVP guard
}

const DEFAULT_MODEL = "@cf/meta/llama-3.3-70b-instruct-fp8-fast";
const MAX_TEXT_CHARS = 12_000;
const STATUSES = ["low", "normal", "high", "critical", "unknown"];

// JSON schema handed to Workers AI "JSON mode"
const RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    report_type: { type: "string" },
    summary: { type: "string" },
    findings: {
      type: "array",
      items: {
        type: "object",
        properties: {
          test: { type: "string" },
          value: { type: "string" },
          unit: { type: "string" },
          reference_range: { type: "string" },
          status: { type: "string", enum: STATUSES },
          explanation: { type: "string" },
          possible_causes: { type: "array", items: { type: "string" } },
        },
        required: ["test", "value", "status", "explanation"],
      },
    },
    urgent_flags: { type: "array", items: { type: "string" } },
    questions_for_doctor: { type: "array", items: { type: "string" } },
    disclaimer: { type: "string" },
  },
  required: ["report_type", "summary", "findings", "urgent_flags", "questions_for_doctor", "disclaimer"],
};

const SYSTEM_PROMPT = `You explain medical test reports (such as blood tests) to non-experts in plain, calm language.
Rules:
- Informational only. Never diagnose, never prescribe, never name a specific treatment or dose.
- The text comes from OCR and may contain errors. Use ONLY tests and values that appear in it. Never invent a test, value, unit or range.
- Set "status" by comparing the value with the reference range printed in the report. If there is no range or the value is unreadable or implausible, use "unknown" and say the value should be verified.
- Use "critical" only when a value is dangerously far outside the range.
- "explanation": 1-2 short sentences: what the test measures and what a low/high value can mean.
- "possible_causes": at most 3 common, general causes; empty array if normal.
- "urgent_flags": short sentences for critical or alarming values; otherwise an empty array.
- "questions_for_doctor": 2-4 useful questions.
- "disclaimer": "Informational only. This is not a medical diagnosis."
- If the text is not a medical report, set report_type to "Not a medical report", explain briefly in summary, and return empty findings.
- Reply with JSON only.`;

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

const err = (message: string, status: number) => json({ error: message }, status);

function extractJson(raw: unknown): any {
  if (raw && typeof raw === "object") return raw; // JSON mode may return a parsed object
  if (typeof raw !== "string") throw new Error("empty");
  try {
    return JSON.parse(raw);
  } catch {
    const start = raw.indexOf("{");
    const end = raw.lastIndexOf("}");
    if (start === -1 || end <= start) throw new Error("no json");
    return JSON.parse(raw.slice(start, end + 1));
  }
}

const str = (v: unknown) => (v == null ? "" : String(v).trim());
const strList = (v: unknown, max: number) =>
  Array.isArray(v) ? v.map(str).filter(Boolean).slice(0, max) : [];

// Never trust model output: normalize it into the exact shape the app expects.
function normalize(d: any) {
  const findings = Array.isArray(d?.findings) ? d.findings : [];
  return {
    report_type: str(d?.report_type) || "Medical report",
    summary: str(d?.summary),
    findings: findings.slice(0, 60).map((f: any) => {
      const status = str(f?.status).toLowerCase();
      return {
        test: str(f?.test),
        value: str(f?.value),
        unit: str(f?.unit),
        reference_range: str(f?.reference_range),
        status: STATUSES.includes(status) ? status : "unknown",
        explanation: str(f?.explanation),
        possible_causes: strList(f?.possible_causes, 3),
      };
    }),
    urgent_flags: strList(d?.urgent_flags, 6),
    questions_for_doctor: strList(d?.questions_for_doctor, 5),
    disclaimer: str(d?.disclaimer) || "Informational only. This is not a medical diagnosis.",
  };
}

async function runModel(env: Env, text: string) {
  const messages = [
    { role: "system", content: SYSTEM_PROMPT },
    { role: "user", content: `Report text (OCR):\n"""\n${text}\n"""` },
  ];

  const out: any = await env.AI.run((env.MODEL || DEFAULT_MODEL) as any, {
    messages,
    max_tokens: 3000, // the default is small and would truncate the JSON
    temperature: 0.2,
    response_format: { type: "json_schema", json_schema: RESPONSE_SCHEMA },
  } as any);

  return extractJson(out?.response);
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);

    if (req.method === "GET" && url.pathname === "/health") return json({ ok: true });
    if (req.method !== "POST" || url.pathname !== "/analyze") return err("Not found", 404);

    if (env.APP_KEY && req.headers.get("x-app-key") !== env.APP_KEY) {
      return err("Unauthorized", 401);
    }

    let text = "";
    try {
      const body: any = await req.json();
      text = str(body?.text);
    } catch {
      return err("Invalid JSON body", 400);
    }
    if (text.length < 20) return err("Report text is too short", 400);
    if (text.length > MAX_TEXT_CHARS) text = text.slice(0, MAX_TEXT_CHARS);

    // One retry if the model returns unusable JSON.
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        const data = await runModel(env, text);
        return json(normalize(data));
      } catch (e) {
        console.log("analyze attempt failed", attempt, String(e)); // never log report text
      }
    }
    return err("The AI service is unavailable right now. Please try again.", 502);
  },
} satisfies ExportedHandler<Env>;