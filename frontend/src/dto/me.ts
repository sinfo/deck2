import type { Company } from "./companies";
import type { Speaker } from "./speakers";

export interface MyResponsibilities {
  companies: Company[];
  speakers: Speaker[];
}

export interface MyResponsibilitiesFilters {
  event?: number;
}
