// @ts-check
// Source-regression attestation only, never a downstream readiness decision.
const fs = require('fs');
const { createHash } = require('crypto');

function inventory(paths) {
  return paths.map((file) => ({
    path: file, bytes: fs.statSync(file).size,
    sha256: createHash('sha256').update(fs.readFileSync(file)).digest('hex'),
  }));
}

function assessEvidence(report, requiredChecks) {
  if (!report || report.scope !== 'source-regression' || report.state !== 'DRAFT' ||
      !requiredChecks.length) return 'UNKNOWN';
  if (report.runFailure) return 'FAIL';
  const checks = requiredChecks.map((name) => report.checks?.[name]);
  if (checks.some((check) => check?.result === 'FAIL')) return 'FAIL';
  if (checks.some((check) => check?.result !== 'PASS' ||
      !check.measurements || !Object.keys(check.measurements).length)) return 'UNKNOWN';
  if (!report.artifact?.length || !report.evidence?.length) return 'UNKNOWN';
  for (const record of [...report.artifact, ...report.evidence]) {
    if (!record.path || !/^[a-f0-9]{64}$/.test(record.sha256) || !Number.isInteger(record.bytes)) return 'UNKNOWN';
    try {
      const current = inventory([record.path])[0];
      if (current.sha256 !== record.sha256 || current.bytes !== record.bytes) return 'FAIL';
    } catch {
      return 'FAIL';
    }
  }
  return 'PASS';
}

async function recordCheck(report, name, operation) {
  report.checks[name] = { result: 'UNKNOWN' };
  try {
    const measurements = await operation();
    report.checks[name] = { result: 'PASS', measurements };
  } catch (error) {
    report.checks[name] = { result: 'FAIL', rationale: String(error) };
    throw error;
  }
}

module.exports = { inventory, assessEvidence, recordCheck };
