import { Post, PopulatedPostComparator, PopulatedPost } from './post';
import { Meeting } from './meeting';
import { PostsService } from '../deck-api/posts.service';
import { MembersService } from '../deck-api/members.service';
import { FormGroup, FormControl, Validators, ValidatorFn, AbstractControl } from '@angular/forms';

export class Thread {
    id: String;
    entry: String;
    meeting: String;
    comments: String[];
    kind: String;
    status: String;
}

declare type PopulatedThreadCallback = () => void;

export class PopulatedThread {
    id: String;
    entry: PopulatedPost;
    meeting: Meeting;
    comments: PopulatedPost[];
    kind: String;
    status: String;

    constructor(
        thread: Thread,
        postsService: PostsService,
        membersService: MembersService,
        callback?: PopulatedThreadCallback
    ) {
        this.id = thread.id;
        this.comments = [];
        this.kind = thread.kind;
        this.status = thread.status;

        postsService.getPost(thread.entry).subscribe((entry: Post) => {
            this.entry = new PopulatedPost(entry, membersService);
            if (this.comments.length === thread.comments.length && this.entry) {
                callback();
            }
        });

        for (const comment of thread.comments) {
            postsService.getPost(comment).subscribe((post: Post) => {
                this.comments.push(new PopulatedPost(post, membersService));
                if (this.comments.length === thread.comments.length && this.entry) {
                    callback();
                }
            });
        }

    }
}

export function PopulatedThreadComparator(t1: PopulatedThread, t2: PopulatedThread) {
    if (t1.entry.posted < t2.entry.posted) { return 1; }
    if (t1.entry.posted > t2.entry.posted) { return -1; }
    return 0;
}

export function SortPopulatedThreads(threads: PopulatedThread[]) {
    threads.sort(PopulatedThreadComparator);
    for (const thread of threads) {
        thread.comments.sort(PopulatedPostComparator);
    }
}

export function threadKindValidator(options: string[]): ValidatorFn {
    return (control: AbstractControl): { [key: string]: any } | null => {
        for (const option of options) {
            if (control.value === option) {
                return null;
            }
        }

        return { 'invalidOption': { value: control.value } };
    };
}

export class AddThreadForm {

    form: FormGroup;
    active: boolean;
    options = ['TEMPLATE', 'TO', 'FROM', 'MEETING'];

    constructor() {
        this.active = false;

        this.form = new FormGroup({
            kind: new FormControl('', [Validators.required, Validators.minLength(1), threadKindValidator(this.options)]),
            text: new FormControl('', [Validators.required, Validators.minLength(1)]),
        });
    }

    isActive() { return this.active; }
    toggle() { this.active = !this.active; }
    value() { return this.form.value; }
    valid() { return this.form.valid; }
}

export class AddCommentToThreadForm {

    form: FormGroup;
    active: boolean;
    threadID: String;

    constructor() {
        this.active = false;

        this.form = new FormGroup({
            text: new FormControl('', [Validators.required, Validators.minLength(1)])
        });
    }

    setThread(threadID: String) { this.threadID = threadID; }
    isActive() { return this.active && this.threadID; }
    toggle() { this.active = !this.active; }
    value() { return this.form.value; }
    valid() { return this.threadID !== undefined && this.form.valid; }
}
