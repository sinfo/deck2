import type { ObjectID } from ".";

export interface Post {
  id: ObjectID;
  member: ObjectID;
  text: string;
  posted: string;
  updated: string;
}

export interface UpdatePostData {
  text: string;
}
