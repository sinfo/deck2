import { Member } from './member';
import { MembersService } from '../deck-api/members.service';
import { FormGroup, FormControl, Validators } from '@angular/forms';

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

    editPostForm: EditPostContentForm;


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
        
        this.editPostForm = new EditPostContentForm(this);
    }

    edit(){
        this.editPostForm.toggle();
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

export class EditPostContentForm {

    form: FormGroup;
    active: boolean;
    postID: String;

    constructor(post: PopulatedPost) {
        this.active = false;

        this.form = new FormGroup({
            text: new FormControl(post.text, [Validators.required, Validators.minLength(1)])
        });

        this.postID = post.id;
    }

    isActive() { return this.active && this.postID; }
    toggle() { this.active = !this.active; }
    value() { return this.form.value; }
    valid() { return this.postID !== undefined && this.form.valid; }
}

