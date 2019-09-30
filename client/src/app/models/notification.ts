import { Member } from './member';
import { Post } from './post';
import { Thread, PopulatedThread } from './thread';
import { Speaker } from './speaker';
import { Company } from './company';
import { Meeting } from './meeting';
import { Session } from './session';
import { MembersService } from '../deck-api/members.service';
import { PostsService } from '../deck-api/posts.service';
import { ThreadsService } from '../deck-api/threads.service';
import { SpeakersService } from '../deck-api/speakers.service';

export enum NotificationKind {
    Created = 'CREATED',
    Updated = 'UPDATED',
    Deleted = 'DELETED',
    UpdatedPrivateImage = 'UPDATED_PRIVATE_IMAGE',
    UpdatedPublicImage = 'UPDATED_PUBLIC_IMAGE',
    UpdateCompanyImage = 'UPDATED_PUBLIC_IMAGE',
    CreatedParticipation = 'CREATED_PARTICIPATION',
    UpdatedParticipation = 'UPDATED_PARTICIPATION',
    DeletedParticipation = 'DELETED_PARTICIPATION',
    CreatedParticipationPackage = 'CREATED_PARTICIPATION_PACKAGE',
    UpdatedParticipationPackage = 'UPDATED_PARTICIPATION_PACKAGE',
    DeletedParticipationPackage = 'DELETED_PARTICIPATION_PACKAGE',
    UpdatedParticipationStatus = 'UPDATED_PARTICIPATION_STATUS',
    Tagged = 'TAGGED',
}

export class Notification {
    id: String;
    kind: NotificationKind;
    member: String;
    post: String;
    thread: String;
    speaker: String;
    company: String;
    meeting: String;
    session: String;
    date: Date;
    signature: String;
}

export function NotificationArraysEqual(n1: Notification[], n2: Notification[]): boolean {
    const signatures1 = n1.map(n => n.signature);
    const signatures2 = n2.map(n => n.signature);
    const union = new Set([...signatures1, ...signatures2]);
    return union.size === signatures1.length && union.size === signatures2.length;
}

export class PopulatedNotification {
    id: String;
    kind: NotificationKind;
    member: Member;
    post: Post;
    thread: PopulatedThread;
    speaker: Speaker;
    company: Company;
    meeting: Meeting;
    session: Session;
    date: Date;
    signature: String;

    message: String;
    preview: String;
    url: String;

    private missing = 0;
    private PREVIEW_MAX_CHARS = 150;

    constructor(
        notification: Notification,
        private membersService: MembersService,
        private postsService: PostsService,
        private threadsService: ThreadsService,
        private speakersService: SpeakersService
    ) {
        this.id = notification.id;
        this.kind = notification.kind;
        this.date = notification.date;
        this.signature = notification.signature;

        if (notification.member) {
            this.missing += 1;
            this.membersService.getMember(notification.member).subscribe((member: Member) => {
                this.member = member;
                this.missing -= 1;
                if (!this.missing) { this.generateMessage(); }
            });
        }

        if (notification.post) {
            this.missing += 1;
            this.postsService.getPost(notification.post).subscribe((post: Post) => {
                this.post = post;
                this.missing -= 1;
                if (!this.missing) { this.generateMessage(); }
            });
        }

        if (notification.thread) {
            this.missing += 1;
            this.threadsService.getThread(notification.thread).subscribe((thread: Thread) => {
                this.thread = new PopulatedThread(thread, this.postsService, this.membersService, () => {
                    this.missing -= 1;
                    if (!this.missing) { this.generateMessage(); }
                });
            });
        }

        if (notification.speaker) {
            this.missing += 1;
            this.speakersService.getSpeaker(`${notification.speaker}`).subscribe((speaker: Speaker) => {
                this.speaker = speaker;
                this.missing -= 1;
                if (!this.missing) { this.generateMessage(); }
            });
        }
    }

    private generateMessage() {
        let message: String;
        let preview: String;
        let url: String;

        if (this.speaker) {
            url = `/speakers/${this.speaker.id}`;
        } else if (this.company) {
            url = `/companies/${this.company.id}`;
        } else if (this.session) {
            url = `/sessions/${this.session.id}`;
        }

        switch (this.kind) {
            case NotificationKind.Created:
                if (this.thread && !this.post) {
                    message = `${this.member.name} added a communication to `;
                    message += `${this.speaker ? this.speaker.name : this.company.name}'`;
                    message += `${
                        (this.speaker && this.speaker.name[this.speaker.name.length - 1] === 's') ||
                            (this.company && this.company.name[this.company.name.length - 1] === 's')
                            ? '' : 's'} page`;

                    preview = this.thread.entry.text;
                } else if (this.thread && this.post) {
                    message = `${this.member.name} commented a communication on `;
                    message += `${this.speaker ? this.speaker.name : this.company.name}'`;
                    message += `${
                        (this.speaker && this.speaker.name[this.speaker.name.length - 1] === 's') ||
                            (this.company && this.company.name[this.company.name.length - 1] === 's')
                            ? '' : 's'} page`;

                    preview = this.post.text;
                }

                break;

            case NotificationKind.Tagged:
                if (this.speaker || this.company) {
                    message = `${this.member.name} tagged you in a communication on `;
                    message += `${this.speaker ? this.speaker.name : this.company.name}'`;
                    message += `${
                        (this.speaker && this.speaker.name[this.speaker.name.length - 1] === 's') ||
                            (this.company && this.company.name[this.company.name.length - 1] === 's')
                            ? '' : 's'} page`;
                } else {
                    message = `${this.member.name} tagged you in a comment`;
                }

                preview = this.post.text;
                break;
        }

        this.message = message;
        this.url = url;

        if (preview && preview.length > this.PREVIEW_MAX_CHARS) { preview = `${preview.substring(0, this.PREVIEW_MAX_CHARS)} [...]`; }
        this.preview = preview;
    }
}

export function PopulatedNotificationComparator(n1: PopulatedNotification, n2: PopulatedNotification) {
    if (n1.date < n2.date) { return 1; }
    if (n1.date > n2.date) { return -1; }
    return 0;
}
