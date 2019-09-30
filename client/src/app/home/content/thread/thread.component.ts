import { AfterViewInit, Component, ElementRef, EventEmitter, Input, OnInit, Output, QueryList, ViewChildren } from '@angular/core';

import { AddThreadForm, PopulatedThread, AddCommentToThreadForm, Thread } from '../../../models/thread';
import { Speaker } from '../../../models/speaker';
import { Company } from '../../../models/company';
import { Member } from '../../../models/member';
import { Event } from '../../../models/event';
import { FilterMember, FilterField } from '../filter/filter';

import { MembersService } from '../../../deck-api/members.service';
import { MeService } from '../../../deck-api/me.service';
import { SpeakersService } from '../../../deck-api/speakers.service';
import { EventsService } from '../../../deck-api/events.service';
import { ThreadsService } from '../../../deck-api/threads.service';

@Component({
    selector: 'app-thread',
    templateUrl: './thread.component.html',
    styleUrls: ['./thread.component.css']
})
export class ThreadComponent implements OnInit, AfterViewInit {

    @Input('create')
    set create(value: boolean) {
        this.form.active = value;
    }

    @Input('thread')
    set thread(thread: PopulatedThread) {
        this._thread = thread;
        this.newCommentForm.setThread(thread.id);
    }

    @Input() speaker: Speaker;
    @Input() company: Company;

    @Output() updated = new EventEmitter<void>();

    @ViewChildren('commentText', { read: ElementRef }) commentText: QueryList<ElementRef>;

    _thread: PopulatedThread;

    form: AddThreadForm;
    me: Member;

    newCommentForm: AddCommentToThreadForm;

    members: Member[];

    constructor(
        private membersService: MembersService,
        private speakersService: SpeakersService,
        private meService: MeService,
        private eventsService: EventsService,
        private threadsService: ThreadsService
    ) {
        this.form = new AddThreadForm();
        this.meService.getMe().subscribe((me: Member) => {
            this.me = me;
        });

        this.newCommentForm = new AddCommentToThreadForm();

        this.eventsService.getCurrentEvent().subscribe((event: Event) => {
            const filterMember = new FilterMember(this.eventsService);

            filterMember.setValue(FilterField.Event, +event.id);

            this.membersService.getMembers(filterMember).subscribe((members: Member[]) => {
                this.members = members;
            });
        });

    }

    ngOnInit() {
    }

    ngAfterViewInit() {
        this.commentText.changes.subscribe((commentText: QueryList<ElementRef>) => {
            if ((this.form.isActive() || this.newCommentForm.isActive()) && commentText.first.nativeElement) {
                this.commentText.first.nativeElement.focus();
            }
        });
    }

    saveNewThread() {
        if (this.speaker) {
            this.speakersService.addThread(`${this.speaker.id}`, this.form).subscribe(() => {
                this.updated.emit();
            });
        }
    }

    comment() {
        this.newCommentForm.toggle();
    }

    submitComment() {
        if (!this.newCommentForm.valid()) { return; }

        this.threadsService.addCommentToThread(this.newCommentForm).subscribe(() => {
            this.updated.emit();
        });
    }

}
