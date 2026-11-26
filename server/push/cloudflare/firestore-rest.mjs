export function decodeValue(value) {
  if ('stringValue' in value) return value.stringValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('integerValue' in value) return Number(value.integerValue);
  if ('doubleValue' in value) return value.doubleValue;
  if ('timestampValue' in value) return value.timestampValue;
  if ('arrayValue' in value) return (value.arrayValue.values ?? []).map(decodeValue);
  if ('mapValue' in value) return decodeFields(value.mapValue.fields ?? {});
  return null;
}
export function decodeFields(fields = {}) {
  return Object.fromEntries(Object.entries(fields).map(([key, value]) => [key, decodeValue(value)]));
}
export function encodeValue(value) {
  if (value == null) return {nullValue: null};
  if (value instanceof Date) return {timestampValue: value.toISOString()};
  if (typeof value === 'boolean') return {booleanValue: value};
  if (typeof value === 'number') return Number.isInteger(value)
    ? {integerValue: String(value)} : {doubleValue: value};
  if (Array.isArray(value)) return {arrayValue: {values: value.map(encodeValue)}};
  if (typeof value === 'object') return {mapValue: {fields: encodeFields(value)}};
  return {stringValue: String(value)};
}
export function encodeFields(data) {
  return Object.fromEntries(Object.entries(data).map(([key, value]) => [key, encodeValue(value)]));
}

export class ApiError extends Error {
  constructor(status, code) { super(`Google API ${status} (${code})`); this.status = status; this.code = code; }
}
export class BudgetExceeded extends Error {}

export class FirebaseRest {
  constructor(projectId, token, fetcher = (...args) => fetch(...args)) {
    this.root = `projects/${projectId}/databases/(default)/documents`;
    this.token = token; this.fetcher = fetcher; this.calls = 0;
  }
  async request(url, body, method = 'POST') {
    // Leave headroom below the Workers Free subrequest cap, including OAuth.
    if (++this.calls > 40) throw new BudgetExceeded('Continue remaining jobs on next cron');
    const response = await this.fetcher(url, {method,
      signal: AbortSignal.timeout(12000),
      headers: {Authorization: `Bearer ${this.token}`, 'Content-Type': 'application/json'},
      ...(body === undefined ? {} : {body: JSON.stringify(body)})});
    const data = await response.json();
    if (!response.ok) {
      const error = (Array.isArray(data) ? data[0] : data)?.error;
      const fcmCode = error?.details?.find(detail => detail.errorCode)?.errorCode;
      throw new ApiError(response.status, fcmCode ?? error?.status ?? 'UNKNOWN');
    }
    return data;
  }
  async query(collection, field, value, parent = this.root, group = false, limit = 100, op = 'EQUAL') {
    const data = await this.request(`https://firestore.googleapis.com/v1/${parent}:runQuery`, {
      structuredQuery: {from: [{collectionId: collection, allDescendants: group}],
        ...(field ? {where: {fieldFilter: {field: {fieldPath: field}, op, value: encodeValue(value)}}} : {}),
        limit}});
    return data.filter(row => row.document).map(row => row.document);
  }
  async get(name) {
    try { return await this.request(`https://firestore.googleapis.com/v1/${name}`, undefined, 'GET'); }
    catch (error) { if (error.status === 404) return null; throw error; }
  }
  async commit(writes) {
    return this.request(`https://firestore.googleapis.com/v1/${this.root}:commit`, {writes});
  }
  async patch(doc, data) {
    const result = await this.commit([{update: {name: doc.name, fields: encodeFields(data)},
      updateMask: {fieldPaths: Object.keys(data)}, currentDocument: {updateTime: doc.updateTime}}]);
    return {...doc, fields: {...doc.fields, ...encodeFields(data)}, updateTime: result.writeResults[0].updateTime};
  }
  async claim(doc, flag) {
    const data = decodeFields(doc.fields);
    if (!data[flag] || data.pushComplete === true || Date.parse(data.notificationLeaseUntil ?? '') > Date.now()) return null;
    try { return await this.patch(doc, {notificationLeaseUntil: new Date(Date.now() + 90000)}); }
    catch (error) { if ([409, 412].includes(error.status)) return null; throw error; }
  }
  async create(name, data) {
    try {
      const result = await this.commit([{update: {name, fields: encodeFields(data)}, currentDocument: {exists: false}}]);
      return {name, fields: encodeFields(data), updateTime: result.writeResults[0].updateTime};
    } catch (error) { if ([409, 412].includes(error.status)) return this.get(name); throw error; }
  }
  async send(projectId, message) {
    return this.request(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {message});
  }
}
