import { Component, OnInit, Input } from '@angular/core';
import { Router } from '@angular/router';

import { Notification, PopulatedNotification, PopulatedNotificationComparator } from '../../../models/notification';

import { MembersService } from '../../../deck-api/members.service';
import { PostsService } from '../../../deck-api/posts.service';
import { ThreadsService } from '../../../deck-api/threads.service';
import { SpeakersService } from '../../../deck-api/speakers.service';
import { MeService } from '../../../deck-api/me.service';

@Component({
    selector: 'app-notifications',
    templateUrl: './notifications.component.html',
    styleUrls: ['./notifications.component.css']
})
export class NotificationsComponent implements OnInit {

    populatedNotifications: PopulatedNotification[] = [];

    @Input('notifications') set notifications(notifications: Notification[]) {
        this.populatedNotifications = [];
        for (const notification of notifications) {
            this.populatedNotifications.push(new PopulatedNotification(
                notification,
                this.membersService,
                this.postsService,
                this.threadsService,
                this.speakersService
            ));
        }

        this.populatedNotifications.sort(PopulatedNotificationComparator);
        console.log(this.populatedNotifications);
    }

    constructor(
        private membersService: MembersService,
        private postsService: PostsService,
        private threadsService: ThreadsService,
        private speakersService: SpeakersService,
        private meService: MeService,
        private router: Router
    ) { }

    ngOnInit() {
    }

    visitNotification(notification: PopulatedNotification) {
        this.meService.removeNotification(notification.id).subscribe(() => {
            this.meService.refreshNotifications();
        });

        if (notification.url && notification.url.length) {
            this.router.navigate([notification.url]);
        }
    }

}
