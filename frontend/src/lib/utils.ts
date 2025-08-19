import type { ImplementsParticipationStatus, Participation } from "@/dto";
import type { Event } from "@/dto/events";
import type { ClassValue } from "clsx";
import { clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

const statusOrder = [
  "ANNOUNCED",
  "ACCEPTED",
  "IN_CONVERSATIONS",
  "CONTACTED",
  "SELECTED",
  "ON_HOLD",
  "SUGGESTED",
  "REJECTED",
  "GIVEN_UP",
];
export const useSortByParticipationStatus = (
  a?: ImplementsParticipationStatus,
  b?: ImplementsParticipationStatus,
) =>
  statusOrder.indexOf(a?.status || "SUGGESTED") -
  statusOrder.indexOf(b?.status || "SUGGESTED");

export const useInsertionSort = <T>(
  arr: T[],
  el: T,
  compareFn: (a: T, b: T) => number,
): T[] => {
  for (let i = 0; i < arr.length; i++) {
    if (compareFn(el, arr[i]) < 0) {
      arr.splice(i, 0, el);
      return arr;
    }
  }

  arr.push(el);
  return arr;
};

export const withCurrentParticipation = <
  T extends { participations: Participation[] },
>(
  obj: T,
  event: Event,
): T & { participation?: Participation } => {
  const participation = obj.participations.find((p) => p.event === event.id);

  if (!participation) return { ...obj, participation: undefined };
  return { ...obj, participation };
};

export const ordinalSuffix = (i: number): string => {
  // https://stackoverflow.com/a/13627586
  let j = i % 10,
    k = i % 100;

  if (j === 1 && k !== 11) {
    return i + "st";
  }

  if (j === 2 && k !== 12) {
    return i + "nd";
  }

  if (j === 3 && k !== 13) {
    return i + "rd";
  }

  return i + "th";
};

export const isEmailValid = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

export const toBase64 = (str: string) => {
  const bytes = new TextEncoder().encode(str);
  let binary = "";
  bytes.forEach((b) => (binary += String.fromCharCode(b)));
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
};
