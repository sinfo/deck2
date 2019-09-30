import { Member } from './member';
import { MembersService } from '../deck-api/members.service';

export class Post {
    id: String;
    member: String;
    text: String;
    posted: Date;
    updated: Date;
}

export class PopulatedPost {
    id: String;
    member: Member;
    text: String;
    posted: Date;
    updated: Date;

    constructor(
        post: Post,
        membersService: MembersService
    ) {
        this.id = post.id;
        this.text = post.text;
        this.posted = post.posted;
        this.updated = post.updated;

        membersService.getMember(post.member).subscribe((member: Member) => {
            this.member = member;
        });
    }
}

export function PostComparator(p1: Post, p2: Post) {
    if (p1.posted < p2.posted) { return 1; }
    if (p1.posted > p2.posted) { return -1; }
    return 0;
}

export function PopulatedPostComparator(p1: PopulatedPost, p2: PopulatedPost) {
    if (p1.posted < p2.posted) { return 1; }
    if (p1.posted > p2.posted) { return -1; }
    return 0;
}
