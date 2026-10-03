// Local time throughout: the journal is for a human reading it in their own time zone.
const pad = (n: number) => String(n).padStart(2, "0");

export const yyyymm = (d: Date) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}`;
export const ymd = (d: Date) => `${yyyymm(d)}-${pad(d.getDate())}`;
export const hm = (d: Date) => `${pad(d.getHours())}:${pad(d.getMinutes())}`;

export function minutesBetween(fromIso: string, to: Date): number {
    return Math.max(0, Math.floor((to.getTime() - Date.parse(fromIso)) / 60_000));
}
